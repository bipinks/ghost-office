#!/usr/bin/env python3
"""Agent Dashboard Web Server — serves static files, message API, and analytics.

Endpoints:
  GET  /                              → dashboard.html
  GET  /analytics.html                → analytics dashboard
  GET  /data/*                        → static JSON files (agents, todos, errors)
  GET  /api/health                     → health check
  GET  /api/messages/{agent}          → read agent's message queue
  POST /api/messages/{agent}          → send message to agent
  GET  /api/analytics/summary         → aggregate stats
  GET  /api/analytics/agent-performance → per-agent stats
  GET  /api/analytics/department-performance → per-department stats
  GET  /api/analytics/session-trends   → session-over-session trends
  GET  /api/analytics/workflow-bottlenecks → avg time per department
  GET  /api/analytics/error-breakdown  → errors by tool and agent
  GET  /api/analytics/token-usage      → token usage trends
  GET  /api/analytics/message-stats    → message volume and response times
"""

import http.server
import json
import os
import re
import shutil
import sqlite3
import sys
import time
from pathlib import Path
from urllib.parse import urlparse, parse_qs

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else int(os.environ.get("DASHBOARD_PORT", "8686"))

# Resolve paths
SCRIPT_DIR = Path(__file__).resolve().parent
WEB_DIR = SCRIPT_DIR
STATUS_DIR = Path(os.environ.get("STATUS_DIR", str(SCRIPT_DIR.parent.parent / ".claude" / "status")))
DATA_DIR = WEB_DIR / "data"
MESSAGES_DIR = STATUS_DIR / "messages"
DB_PATH = DATA_DIR / "dashboard.db"


# ── JSON helpers ──────────────────────────────────────────────────────────────

def safe_read_json(path, fallback=None):
    """Read a JSON file with corruption recovery."""
    if fallback is None:
        fallback = {}
    if not path.exists():
        return fallback
    try:
        with open(path) as f:
            data = json.load(f)
        if not isinstance(data, (dict, list)):
            return fallback
        return data
    except (json.JSONDecodeError, IOError, OSError):
        return fallback


def sync_status_to_data():
    """Copy .claude/status/ files to scripts/web/data/ for serving.

    Validates JSON on copy — writes safe fallback if source is corrupt.
    """
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    # Copy top-level JSON files with validation
    for name, fallback in [
        ("agents.json", {"session_id": "", "updated_at": "", "agents": {}}),
        ("history.json", {"sessions": []}),
    ]:
        src = STATUS_DIR / name
        dst = DATA_DIR / name
        data = safe_read_json(src, fallback)
        # Validate expected structure
        if name == "agents.json" and "agents" not in data:
            data["agents"] = {}
        if name == "history.json" and "sessions" not in data:
            data["sessions"] = []
        with open(dst, "w") as f:
            json.dump(data, f, indent=2)

    # Copy subdirectory JSON files
    for subdir in ("todos", "errors"):
        src_dir = STATUS_DIR / subdir
        dst_dir = DATA_DIR / subdir
        dst_dir.mkdir(parents=True, exist_ok=True)
        if src_dir.exists():
            for f in src_dir.glob("*.json"):
                data = safe_read_json(f)
                if data:
                    with open(dst_dir / f.name, "w") as out:
                        json.dump(data, out, indent=2)


def read_message_file(agent):
    """Read an agent's message queue file."""
    path = MESSAGES_DIR / f"{agent}.json"
    return safe_read_json(path, {"agent": agent, "messages": []})


def write_message_file(agent, data):
    """Atomically write an agent's message queue file."""
    MESSAGES_DIR.mkdir(parents=True, exist_ok=True)
    path = MESSAGES_DIR / f"{agent}.json"
    tmp = path.with_suffix(".json.tmp")
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
    tmp.rename(path)


# ── SQLite analytics ──────────────────────────────────────────────────────────

def init_db():
    """Create SQLite database and tables if they don't exist."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    conn.execute("PRAGMA journal_mode=WAL")
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS sessions (
            session_id TEXT PRIMARY KEY,
            started_at TEXT,
            updated_at TEXT,
            total_duration INTEGER DEFAULT 0,
            total_tokens INTEGER DEFAULT 0,
            agent_count INTEGER DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS agent_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            agent_name TEXT NOT NULL,
            department TEXT,
            status TEXT,
            started_at TEXT,
            completed_at TEXT,
            duration_seconds INTEGER DEFAULT 0,
            error_count INTEGER DEFAULT 0,
            todo_total INTEGER DEFAULT 0,
            todo_completed INTEGER DEFAULT 0,
            tokens_total INTEGER DEFAULT 0,
            tokens_input INTEGER DEFAULT 0,
            tokens_output INTEGER DEFAULT 0,
            tool_uses INTEGER DEFAULT 0,
            UNIQUE(session_id, agent_name)
        );

        CREATE TABLE IF NOT EXISTS errors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT,
            agent_name TEXT,
            tool TEXT,
            message TEXT,
            timestamp TEXT,
            UNIQUE(session_id, agent_name, tool, timestamp)
        );

        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            msg_id TEXT UNIQUE,
            session_id TEXT,
            agent_name TEXT,
            msg_type TEXT,
            direction TEXT,
            content TEXT,
            status TEXT,
            created_at TEXT,
            acknowledged_at TEXT,
            response_time_seconds INTEGER
        );

        CREATE INDEX IF NOT EXISTS idx_agent_runs_session ON agent_runs(session_id);
        CREATE INDEX IF NOT EXISTS idx_agent_runs_agent ON agent_runs(agent_name);
        CREATE INDEX IF NOT EXISTS idx_errors_session ON errors(session_id);
        CREATE INDEX IF NOT EXISTS idx_messages_session ON messages(session_id);
    """)
    conn.close()


def sync_json_to_sqlite():
    """Sync JSON status files into SQLite for analytics queries."""
    conn = sqlite3.connect(str(DB_PATH))
    conn.execute("PRAGMA journal_mode=WAL")

    try:
        # Sync current session from agents.json
        agents_data = safe_read_json(STATUS_DIR / "agents.json",
                                     {"session_id": "", "agents": {}})
        sid = agents_data.get("session_id", "")
        if sid:
            agents = agents_data.get("agents", {})
            # Upsert session
            started_times = [a.get("started_at", "") for a in agents.values()
                             if a.get("started_at")]
            started_at = min(started_times) if started_times else ""
            total_dur = sum(a.get("duration_seconds", 0) for a in agents.values())
            total_tok = sum(
                (a.get("tokens", {}).get("total", 0) if isinstance(a.get("tokens"), dict) else 0)
                for a in agents.values()
            )
            conn.execute("""
                INSERT INTO sessions (session_id, started_at, updated_at,
                                      total_duration, total_tokens, agent_count)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(session_id) DO UPDATE SET
                    updated_at=excluded.updated_at,
                    total_duration=excluded.total_duration,
                    total_tokens=excluded.total_tokens,
                    agent_count=excluded.agent_count
            """, (sid, started_at, agents_data.get("updated_at", ""),
                  total_dur, total_tok, len(agents)))

            # Upsert agent runs
            for name, info in agents.items():
                tokens = info.get("tokens", {})
                if not isinstance(tokens, dict):
                    tokens = {}
                # Read todo progress for this agent
                todo_data = safe_read_json(STATUS_DIR / "todos" / f"{name}.json")
                todo_total = todo_data.get("progress", {}).get("total", 0)
                todo_completed = todo_data.get("progress", {}).get("completed", 0)

                conn.execute("""
                    INSERT INTO agent_runs (session_id, agent_name, department, status,
                        started_at, completed_at, duration_seconds, error_count,
                        todo_total, todo_completed, tokens_total, tokens_input,
                        tokens_output, tool_uses)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(session_id, agent_name) DO UPDATE SET
                        status=excluded.status,
                        completed_at=excluded.completed_at,
                        duration_seconds=excluded.duration_seconds,
                        error_count=excluded.error_count,
                        todo_total=excluded.todo_total,
                        todo_completed=excluded.todo_completed,
                        tokens_total=excluded.tokens_total,
                        tokens_input=excluded.tokens_input,
                        tokens_output=excluded.tokens_output,
                        tool_uses=excluded.tool_uses
                """, (sid, name, info.get("department", ""),
                      info.get("status", ""), info.get("started_at", ""),
                      info.get("completed_at", ""),
                      info.get("duration_seconds", 0),
                      info.get("error_count", 0),
                      todo_total, todo_completed,
                      tokens.get("total", 0), tokens.get("input", 0),
                      tokens.get("output", 0), tokens.get("tool_uses", 0)))

        # Sync history.json for past sessions
        history = safe_read_json(STATUS_DIR / "history.json", {"sessions": []})
        for sess in history.get("sessions", []):
            hsid = sess.get("session_id", "")
            if not hsid:
                continue
            conn.execute("""
                INSERT INTO sessions (session_id, started_at, updated_at,
                                      total_duration, total_tokens, agent_count)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(session_id) DO UPDATE SET
                    updated_at=excluded.updated_at,
                    total_duration=excluded.total_duration,
                    total_tokens=excluded.total_tokens,
                    agent_count=excluded.agent_count
            """, (hsid, sess.get("started_at", ""), sess.get("updated_at", ""),
                  sess.get("total_duration", 0), sess.get("total_tokens", 0),
                  len(sess.get("agents", []))))

            for agent in sess.get("agents", []):
                conn.execute("""
                    INSERT INTO agent_runs (session_id, agent_name, department,
                        status, started_at, completed_at, duration_seconds,
                        tokens_total)
                    VALUES (?, ?, ?, 'completed', ?, ?, ?, ?)
                    ON CONFLICT(session_id, agent_name) DO NOTHING
                """, (hsid, agent.get("name", ""), agent.get("department", ""),
                      agent.get("started_at", ""), agent.get("completed_at", ""),
                      agent.get("duration_seconds", 0), agent.get("tokens", 0)))

        # Sync errors
        errors_dir = STATUS_DIR / "errors"
        if errors_dir.exists():
            for f in errors_dir.glob("*.json"):
                agent_name = f.stem
                err_data = safe_read_json(f, {"errors": []})
                for err in err_data.get("errors", []):
                    conn.execute("""
                        INSERT OR IGNORE INTO errors
                            (session_id, agent_name, tool, message, timestamp)
                        VALUES (?, ?, ?, ?, ?)
                    """, (sid, agent_name, err.get("tool", ""),
                          err.get("message", "")[:500], err.get("timestamp", "")))

        # Sync messages
        if MESSAGES_DIR.exists():
            for f in MESSAGES_DIR.glob("*.json"):
                agent_name = f.stem
                msg_data = safe_read_json(f, {"messages": []})
                for msg in msg_data.get("messages", []):
                    msg_id = msg.get("id", "")
                    if not msg_id:
                        continue
                    # Calculate response time
                    resp_time = None
                    created = msg.get("created_at", "")
                    acked = msg.get("acknowledged_at")
                    if created and acked:
                        try:
                            ct = time.strptime(created, "%Y-%m-%dT%H:%M:%SZ")
                            at = time.strptime(acked, "%Y-%m-%dT%H:%M:%SZ")
                            resp_time = int(time.mktime(at) - time.mktime(ct))
                        except (ValueError, TypeError):
                            pass
                    conn.execute("""
                        INSERT OR IGNORE INTO messages
                            (msg_id, session_id, agent_name, msg_type, direction,
                             content, status, created_at, acknowledged_at,
                             response_time_seconds)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, (msg_id, sid, agent_name, msg.get("type", ""),
                          "user_to_agent" if msg.get("from") == "user" else "agent_to_user",
                          msg.get("content", "")[:500], msg.get("status", ""),
                          created, acked, resp_time))

        # Prune old data (keep last 200 sessions)
        conn.execute("""
            DELETE FROM agent_runs WHERE session_id IN (
                SELECT session_id FROM sessions
                ORDER BY started_at DESC
                LIMIT -1 OFFSET 200
            )
        """)
        conn.execute("""
            DELETE FROM errors WHERE session_id IN (
                SELECT session_id FROM sessions
                ORDER BY started_at DESC
                LIMIT -1 OFFSET 200
            )
        """)
        conn.execute("""
            DELETE FROM messages WHERE session_id IN (
                SELECT session_id FROM sessions
                ORDER BY started_at DESC
                LIMIT -1 OFFSET 200
            )
        """)
        conn.execute("""
            DELETE FROM sessions WHERE session_id NOT IN (
                SELECT session_id FROM sessions
                ORDER BY started_at DESC
                LIMIT 200
            )
        """)

        conn.commit()
    except Exception as e:
        print(f"[SQLite sync error] {e}", file=sys.stderr)
    finally:
        conn.close()


def query_db(sql, params=()):
    """Execute a SELECT query and return rows as list of dicts."""
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    try:
        rows = conn.execute(sql, params).fetchall()
        return [dict(r) for r in rows]
    except Exception as e:
        print(f"[SQLite query error] {e}", file=sys.stderr)
        return []
    finally:
        conn.close()


# ── Analytics endpoints ───────────────────────────────────────────────────────

def _date_filter(date_from=None, date_to=None):
    """Build SQL WHERE clause and params for date range filtering on sessions."""
    clauses = []
    params = []
    if date_from:
        clauses.append("started_at >= ?")
        params.append(date_from)
    if date_to:
        # Include the full end day
        clauses.append("started_at <= ?")
        params.append(date_to + "T23:59:59Z" if "T" not in date_to else date_to)
    return clauses, params


def _session_ids_for_range(date_from=None, date_to=None):
    """Get session IDs within a date range, or None for all."""
    if not date_from and not date_to:
        return None
    clauses, params = _date_filter(date_from, date_to)
    where = " AND ".join(clauses)
    rows = query_db(f"SELECT session_id FROM sessions WHERE {where}", tuple(params))
    return [r["session_id"] for r in rows]


def analytics_summary(date_from=None, date_to=None):
    """Aggregate stats across all sessions."""
    clauses, params = _date_filter(date_from, date_to)
    where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
    rows = query_db(f"""
        SELECT
            COUNT(*) as total_sessions,
            COALESCE(SUM(agent_count), 0) as total_agents,
            COALESCE(SUM(total_tokens), 0) as total_tokens,
            COALESCE(AVG(total_duration), 0) as avg_duration,
            COALESCE(MAX(updated_at), '') as last_activity
        FROM sessions {where}
    """, tuple(params))
    summary = rows[0] if rows else {}
    # Add error count (filtered by session range)
    sids = _session_ids_for_range(date_from, date_to)
    if sids is not None:
        placeholders = ",".join("?" * len(sids))
        err_rows = query_db(
            f"SELECT COUNT(*) as total_errors FROM errors WHERE session_id IN ({placeholders})",
            tuple(sids)
        ) if sids else [{"total_errors": 0}]
    else:
        err_rows = query_db("SELECT COUNT(*) as total_errors FROM errors")
    summary["total_errors"] = err_rows[0]["total_errors"] if err_rows else 0
    # Add message count
    if sids is not None:
        placeholders = ",".join("?" * len(sids))
        msg_rows = query_db(
            f"SELECT COUNT(*) as total_messages FROM messages WHERE session_id IN ({placeholders})",
            tuple(sids)
        ) if sids else [{"total_messages": 0}]
    else:
        msg_rows = query_db("SELECT COUNT(*) as total_messages FROM messages")
    summary["total_messages"] = msg_rows[0]["total_messages"] if msg_rows else 0
    return summary


def analytics_agent_performance(date_from=None, date_to=None):
    """Per-agent aggregate stats."""
    sids = _session_ids_for_range(date_from, date_to)
    if sids is not None:
        if not sids:
            return []
        placeholders = ",".join("?" * len(sids))
        return query_db(f"""
            SELECT
                agent_name, department,
                COUNT(*) as run_count,
                COALESCE(AVG(duration_seconds), 0) as avg_duration,
                COALESCE(SUM(error_count), 0) as total_errors,
                COALESCE(SUM(tokens_total), 0) as total_tokens,
                COALESCE(AVG(tokens_total), 0) as avg_tokens,
                COALESCE(SUM(todo_completed), 0) as total_tasks_completed,
                COALESCE(SUM(tool_uses), 0) as total_tool_uses
            FROM agent_runs WHERE session_id IN ({placeholders})
            GROUP BY agent_name ORDER BY run_count DESC
        """, tuple(sids))
    return query_db("""
        SELECT
            agent_name, department,
            COUNT(*) as run_count,
            COALESCE(AVG(duration_seconds), 0) as avg_duration,
            COALESCE(SUM(error_count), 0) as total_errors,
            COALESCE(SUM(tokens_total), 0) as total_tokens,
            COALESCE(AVG(tokens_total), 0) as avg_tokens,
            COALESCE(SUM(todo_completed), 0) as total_tasks_completed,
            COALESCE(SUM(tool_uses), 0) as total_tool_uses
        FROM agent_runs GROUP BY agent_name ORDER BY run_count DESC
    """)


def analytics_department_performance(date_from=None, date_to=None):
    """Per-department aggregate stats."""
    sids = _session_ids_for_range(date_from, date_to)
    if sids is not None:
        if not sids:
            return []
        placeholders = ",".join("?" * len(sids))
        return query_db(f"""
            SELECT department, COUNT(DISTINCT agent_name) as agent_count,
                COUNT(*) as total_runs,
                COALESCE(AVG(duration_seconds), 0) as avg_duration,
                COALESCE(SUM(error_count), 0) as total_errors,
                COALESCE(SUM(tokens_total), 0) as total_tokens
            FROM agent_runs WHERE department != '' AND session_id IN ({placeholders})
            GROUP BY department ORDER BY total_runs DESC
        """, tuple(sids))
    return query_db("""
        SELECT department, COUNT(DISTINCT agent_name) as agent_count,
            COUNT(*) as total_runs,
            COALESCE(AVG(duration_seconds), 0) as avg_duration,
            COALESCE(SUM(error_count), 0) as total_errors,
            COALESCE(SUM(tokens_total), 0) as total_tokens
        FROM agent_runs WHERE department != ''
        GROUP BY department ORDER BY total_runs DESC
    """)


def analytics_session_trends(date_from=None, date_to=None):
    """Session-over-session trends (last 50)."""
    clauses, params = _date_filter(date_from, date_to)
    where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
    sessions = query_db(f"""
        SELECT session_id, started_at, total_duration, total_tokens, agent_count
        FROM sessions {where}
        ORDER BY started_at DESC LIMIT 50
    """, tuple(params))
    for s in sessions:
        err = query_db(
            "SELECT COUNT(*) as cnt FROM errors WHERE session_id = ?",
            (s["session_id"],)
        )
        s["error_count"] = err[0]["cnt"] if err else 0
    return list(reversed(sessions))


def analytics_workflow_bottlenecks(date_from=None, date_to=None):
    """Average time per department (proxy for workflow phases)."""
    sids = _session_ids_for_range(date_from, date_to)
    if sids is not None:
        if not sids:
            return []
        placeholders = ",".join("?" * len(sids))
        return query_db(f"""
            SELECT department,
                COALESCE(AVG(duration_seconds), 0) as avg_duration,
                COUNT(*) as sample_count
            FROM agent_runs
            WHERE department != '' AND duration_seconds > 0
                AND session_id IN ({placeholders})
            GROUP BY department ORDER BY avg_duration DESC
        """, tuple(sids))
    return query_db("""
        SELECT department,
            COALESCE(AVG(duration_seconds), 0) as avg_duration,
            COUNT(*) as sample_count
        FROM agent_runs
        WHERE department != '' AND duration_seconds > 0
        GROUP BY department ORDER BY avg_duration DESC
    """)


def analytics_error_breakdown(date_from=None, date_to=None):
    """Errors by tool and agent."""
    sids = _session_ids_for_range(date_from, date_to)
    if sids is not None and not sids:
        return {"by_tool": [], "by_agent": [], "recent": []}
    sid_filter = ""
    sid_params = ()
    if sids is not None:
        placeholders = ",".join("?" * len(sids))
        sid_filter = f"WHERE session_id IN ({placeholders})"
        sid_params = tuple(sids)
    by_tool = query_db(f"""
        SELECT tool, COUNT(*) as count FROM errors {sid_filter}
        GROUP BY tool ORDER BY count DESC LIMIT 20
    """, sid_params)
    by_agent = query_db(f"""
        SELECT agent_name, COUNT(*) as count FROM errors {sid_filter}
        GROUP BY agent_name ORDER BY count DESC LIMIT 20
    """, sid_params)
    recent = query_db(f"""
        SELECT agent_name, tool, message, timestamp FROM errors {sid_filter}
        ORDER BY timestamp DESC LIMIT 50
    """, sid_params)
    return {"by_tool": by_tool, "by_agent": by_agent, "recent": recent}


def analytics_token_usage(date_from=None, date_to=None):
    """Token usage trends per session."""
    clauses, params = _date_filter(date_from, date_to)
    where = ("WHERE " + " AND ".join(["s." + c for c in clauses])) if clauses else ""
    per_session = query_db(f"""
        SELECT s.session_id, s.started_at, s.total_tokens,
            COALESCE(SUM(ar.tokens_input), 0) as input_tokens,
            COALESCE(SUM(ar.tokens_output), 0) as output_tokens
        FROM sessions s
        LEFT JOIN agent_runs ar ON s.session_id = ar.session_id
        {where}
        GROUP BY s.session_id ORDER BY s.started_at DESC LIMIT 50
    """, tuple(params))
    # Per-agent filtered by session range
    sids = _session_ids_for_range(date_from, date_to)
    if sids is not None:
        if not sids:
            per_agent = []
        else:
            placeholders = ",".join("?" * len(sids))
            per_agent = query_db(f"""
                SELECT agent_name,
                    COALESCE(SUM(tokens_total), 0) as total,
                    COALESCE(SUM(tokens_input), 0) as input_tokens,
                    COALESCE(SUM(tokens_output), 0) as output_tokens
                FROM agent_runs WHERE session_id IN ({placeholders})
                GROUP BY agent_name ORDER BY total DESC
            """, tuple(sids))
    else:
        per_agent = query_db("""
            SELECT agent_name,
                COALESCE(SUM(tokens_total), 0) as total,
                COALESCE(SUM(tokens_input), 0) as input_tokens,
                COALESCE(SUM(tokens_output), 0) as output_tokens
            FROM agent_runs GROUP BY agent_name ORDER BY total DESC
        """)
    return {"per_session": list(reversed(per_session)), "per_agent": per_agent}


def analytics_message_stats(date_from=None, date_to=None):
    """Message volume and response times."""
    sids = _session_ids_for_range(date_from, date_to)
    if sids is not None and not sids:
        return {"by_type": [], "by_status": [], "response_times": {}, "per_agent": []}
    sid_filter = ""
    sid_params = ()
    if sids is not None:
        placeholders = ",".join("?" * len(sids))
        sid_filter = f"WHERE session_id IN ({placeholders})"
        sid_params = tuple(sids)
    by_type = query_db(f"""
        SELECT msg_type, COUNT(*) as count FROM messages {sid_filter}
        GROUP BY msg_type ORDER BY count DESC
    """, sid_params)
    by_status = query_db(f"""
        SELECT status, COUNT(*) as count FROM messages {sid_filter}
        GROUP BY status ORDER BY count DESC
    """, sid_params)
    resp_filter = sid_filter.replace("WHERE", "WHERE response_time_seconds IS NOT NULL AND response_time_seconds > 0 AND") if sid_filter else "WHERE response_time_seconds IS NOT NULL AND response_time_seconds > 0"
    avg_response = query_db(f"""
        SELECT
            COALESCE(AVG(response_time_seconds), 0) as avg_response_time,
            COALESCE(MIN(response_time_seconds), 0) as min_response_time,
            COALESCE(MAX(response_time_seconds), 0) as max_response_time,
            COUNT(*) as acknowledged_count
        FROM messages {resp_filter}
    """, sid_params)
    per_agent = query_db(f"""
        SELECT agent_name, COUNT(*) as total_messages,
            COALESCE(AVG(response_time_seconds), 0) as avg_response_time
        FROM messages {sid_filter}
        GROUP BY agent_name ORDER BY total_messages DESC
    """, sid_params)
    return {
        "by_type": by_type,
        "by_status": by_status,
        "response_times": avg_response[0] if avg_response else {},
        "per_agent": per_agent,
    }


ANALYTICS_ROUTES = {
    "summary": analytics_summary,
    "agent-performance": analytics_agent_performance,
    "department-performance": analytics_department_performance,
    "session-trends": analytics_session_trends,
    "workflow-bottlenecks": analytics_workflow_bottlenecks,
    "error-breakdown": analytics_error_breakdown,
    "token-usage": analytics_token_usage,
    "message-stats": analytics_message_stats,
}


# ── HTTP handler ──────────────────────────────────────────────────────────────

class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler with static file serving, message API, and analytics."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)

    def do_GET(self):
        # API: health check
        if self.path == "/api/health":
            self._json_response(200, {"status": "ok", "port": PORT})
            return

        # API: read messages for an agent
        m = re.match(r"^/api/messages/([\w-]+)$", self.path)
        if m:
            agent = m.group(1)
            data = read_message_file(agent)
            self._json_response(200, data)
            return

        # API: analytics endpoints
        parsed = urlparse(self.path)
        m = re.match(r"^/api/analytics/([\w-]+)$", parsed.path)
        if m:
            route = m.group(1)
            handler = ANALYTICS_ROUTES.get(route)
            if handler:
                # Parse date range query params
                qs = parse_qs(parsed.query)
                date_from = qs.get("from", [None])[0]
                date_to = qs.get("to", [None])[0]
                # Sync before analytics query
                sync_json_to_sqlite()
                self._json_response(200, handler(date_from=date_from, date_to=date_to))
            else:
                self._json_response(404, {"error": f"Unknown analytics route: {route}"})
            return

        # Sync status files before serving data
        if self.path.startswith("/data/"):
            sync_status_to_data()

        super().do_GET()

    def do_POST(self):
        m = re.match(r"^/api/messages/([\w-]+)$", self.path)
        if not m:
            self._json_response(404, {"error": "Not found"})
            return

        agent = m.group(1)

        # Read request body
        length = int(self.headers.get("Content-Length", 0))
        if length == 0 or length > 10000:
            self._json_response(400, {"error": "Invalid content length"})
            return

        try:
            body = json.loads(self.rfile.read(length))
        except (json.JSONDecodeError, ValueError):
            self._json_response(400, {"error": "Invalid JSON"})
            return

        # Validate required fields
        content = body.get("content", "").strip()
        if not content:
            self._json_response(400, {"error": "Message content is required"})
            return

        msg_type = body.get("type", "instruction")
        valid_types = [
            "instruction", "question", "priority", "note", "pause", "cancel",
            "reassign", "reprioritize", "pause-workflow", "resume-workflow",
        ]
        if msg_type not in valid_types:
            self._json_response(400, {"error": f"Invalid type. Valid: {valid_types}"})
            return

        priority = body.get("priority", "normal")
        if priority not in ("normal", "high", "urgent"):
            priority = "normal"

        # Build message
        now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        msg_id = f"msg_{int(time.time())}_{int(time.time() * 1000) % 1000:03d}"
        message = {
            "id": msg_id,
            "type": msg_type,
            "from": "user",
            "content": content,
            "priority": priority,
            "status": "pending",
            "created_at": now,
            "delivered_at": None,
            "acknowledged_at": None,
            "response": None,
        }

        # Append to agent's message file (cap at 100 messages)
        data = read_message_file(agent)
        data["messages"].append(message)
        data["messages"] = data["messages"][-100:]
        write_message_file(agent, data)

        self._json_response(201, {"ok": True, "message": message})

    def _json_response(self, code, data):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(body))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        """Handle CORS preflight."""
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def log_message(self, fmt, *args):
        """Suppress noisy access logs, only show errors."""
        if args and isinstance(args[0], str):
            if args[0].startswith("GET /data/") or args[0].startswith("GET /api/analytics/"):
                return
        super().log_message(fmt, *args)


if __name__ == "__main__":
    init_db()
    sync_status_to_data()
    sync_json_to_sqlite()
    server = http.server.HTTPServer(("0.0.0.0", PORT), DashboardHandler)
    print(f"Agent Dashboard server running on http://localhost:{PORT}")
    print(f"Analytics dashboard at http://localhost:{PORT}/analytics.html")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.shutdown()
