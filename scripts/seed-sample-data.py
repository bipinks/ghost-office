#!/usr/bin/env python3
"""Seed rich sample data for the Ghost Office dashboard and analytics pages.

Run:  python3 scripts/seed-sample-data.py
Then: docker compose up --build
"""

import json
import os
import random
import sqlite3
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STATUS_DIR = ROOT / ".claude" / "status"
DATA_DIR = ROOT / "scripts" / "web" / "data"
DB_PATH = DATA_DIR / "dashboard.db"

AGENTS = {
    "master-orchestrator": {"dept": "Orchestration", "tools": 45},
    "product-manager": {"dept": "Product", "tools": 22},
    "ui-ux-designer": {"dept": "Product", "tools": 18},
    "architecture-agent": {"dept": "Engineering", "tools": 38},
    "backend-engineer": {"dept": "Engineering", "tools": 52},
    "frontend-engineer": {"dept": "Engineering", "tools": 41},
    "database-engineer": {"dept": "Engineering", "tools": 29},
    "prompt-engineer": {"dept": "Engineering", "tools": 15},
    "qa-agent": {"dept": "Quality", "tools": 35},
    "security-agent": {"dept": "Quality", "tools": 27},
    "devops-engineer": {"dept": "Operations", "tools": 48},
    "monitoring-agent": {"dept": "Operations", "tools": 24},
    "performance-agent": {"dept": "Operations", "tools": 19},
    "content-strategist": {"dept": "Marketing", "tools": 16},
    "social-media-manager": {"dept": "Marketing", "tools": 14},
    "support-agent": {"dept": "Support", "tools": 21},
    "documentation-agent": {"dept": "Support", "tools": 17},
    "ms-it-admin": {"dept": "IT", "tools": 23},
}

STATUSES = ["completed", "completed", "completed", "completed", "error"]
TOOLS = ["Read", "Bash", "Grep", "Glob", "Edit", "Write", "Agent", "WebFetch"]
ERROR_MESSAGES = [
    "Command failed: npm test — 3 tests failing in invoice module",
    "File not found: src/services/PaymentGateway.ts",
    "Timeout waiting for database connection pool",
    "Permission denied: cannot write to /etc/nginx/conf.d/",
    "Terraform plan failed: provider version mismatch",
    "Docker build error: layer COPY failed — missing package.json",
    "Migration failed: column 'branch_id' already exists",
    "API rate limit exceeded for GitHub Actions",
    "SSL certificate validation failed for staging.example.com",
    "Memory limit exceeded during PDF report generation",
    "K8s pod CrashLoopBackOff: readiness probe failed",
    "Redis connection refused: max clients reached",
]

MSG_CONTENTS = [
    ("instruction", "Focus on the payment gateway integration first"),
    ("instruction", "Use cursor-based pagination instead of offset"),
    ("question", "What's the estimated completion time for the API?"),
    ("question", "Should we use WebSocket or SSE for real-time updates?"),
    ("priority", "Security scan is blocking the release — prioritize fixes"),
    ("note", "Client approved the wireframe design"),
    ("instruction", "Add branch_id scoping to all new queries"),
    ("question", "Is the test coverage above 80% for the invoicing module?"),
    ("instruction", "Implement retry logic with exponential backoff"),
    ("note", "Staging deployment successful — ready for QA"),
    ("priority", "P0 bug in production tax calculation — drop everything"),
    ("instruction", "Add OpenTelemetry tracing to all API endpoints"),
]

TASK_TEMPLATES = {
    "product-manager": [
        "Write user stories for invoice PDF generation",
        "Define acceptance criteria for multi-currency support",
        "Create feature spec for customer aging report",
        "Review UX requirements for dashboard redesign",
        "Prioritize backlog items for Q2 sprint",
    ],
    "architecture-agent": [
        "Design event-driven architecture for notifications",
        "Review database schema for inventory module",
        "Create ADR for choosing message queue (Redis vs RabbitMQ)",
        "Design API versioning strategy",
        "Evaluate microservice extraction for payment processing",
    ],
    "backend-engineer": [
        "Implement invoice PDF generation endpoint",
        "Add tax calculation service with jurisdiction support",
        "Build customer aging report API",
        "Implement webhook delivery system",
        "Add bulk import endpoint for products",
        "Create payment reconciliation service",
        "Implement audit trail for financial transactions",
    ],
    "frontend-engineer": [
        "Build invoice preview component",
        "Implement data table with virtual scrolling",
        "Create dashboard widget for sales overview",
        "Add dark mode theme support",
        "Build multi-step form for purchase orders",
    ],
    "database-engineer": [
        "Create migration for invoice_items partitioning",
        "Add composite indexes for report queries",
        "Optimize N+1 queries in sales module",
        "Design schema for manufacturing BOM",
        "Set up read replica for reporting queries",
    ],
    "qa-agent": [
        "Write integration tests for payment flow",
        "Add multi-tenant isolation tests",
        "Create load test scenarios for API endpoints",
        "Verify regression for tax calculation fix",
        "Test PDF generation across all invoice types",
    ],
    "security-agent": [
        "Run OWASP dependency check",
        "Audit API authentication endpoints",
        "Review RBAC permissions for admin role",
        "Scan Docker images with Trivy",
        "Verify encryption at rest configuration",
    ],
    "devops-engineer": [
        "Set up GitHub Actions CI/CD pipeline",
        "Configure auto-scaling for ECS services",
        "Implement blue-green deployment strategy",
        "Set up CloudWatch alarms for API latency",
        "Create Terraform modules for VPC networking",
    ],
    "monitoring-agent": [
        "Configure Prometheus scrape targets",
        "Build Grafana dashboard for API metrics",
        "Set up PagerDuty integration for P0 alerts",
        "Define SLOs for payment processing",
        "Create runbook for database failover",
    ],
    "documentation-agent": [
        "Update API documentation for v2 endpoints",
        "Write deployment runbook for production",
        "Create onboarding guide for new developers",
        "Document database migration procedures",
        "Write changelog for v2.4.0 release",
    ],
}

# Default tasks for agents without specific templates
DEFAULT_TASKS = [
    "Analyze requirements and plan approach",
    "Implement core functionality",
    "Review and refine implementation",
    "Document changes and update specs",
    "Validate output and run quality checks",
]


def ts(dt):
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def rand_session_id():
    return str(uuid.uuid4())


def fmt_duration(seconds):
    """Format seconds into a human-readable duration string."""
    if seconds < 60:
        return f"{seconds}s"
    m, s = divmod(seconds, 60)
    if m < 60:
        return f"{m}m {s}s"
    h, m = divmod(m, 60)
    return f"{h}h {m}m"


def generate_current_session():
    """Generate a realistic current session with active agents."""
    now = datetime.now(timezone.utc)
    session_start = now - timedelta(minutes=random.randint(15, 45))
    sid = rand_session_id()

    # Pick 8-12 agents for the current session
    active_agents = random.sample(list(AGENTS.keys()), k=random.randint(8, 12))
    # Always include orchestrator
    if "master-orchestrator" not in active_agents:
        active_agents[0] = "master-orchestrator"

    agents = {}
    for i, name in enumerate(active_agents):
        info = AGENTS[name]
        agent_start = session_start + timedelta(seconds=i * random.randint(10, 60))
        duration = random.randint(30, 600)

        # Most done, a couple still running, maybe one error
        if i < len(active_agents) - 3:
            status = "done"
            completed_at = ts(agent_start + timedelta(seconds=duration))
        elif i < len(active_agents) - 1:
            status = "active"
            completed_at = None
            duration = int((now - agent_start).total_seconds())
        else:
            status = random.choice(["active", "error"])
            completed_at = ts(now - timedelta(seconds=10)) if status == "error" else None

        tok_in = random.randint(2000, 15000)
        tok_out = random.randint(1000, 8000)
        tasks = TASK_TEMPLATES.get(name, DEFAULT_TASKS)
        total_tasks = min(len(tasks), random.randint(3, 6))
        done_tasks = total_tasks if status == "done" else random.randint(1, max(1, total_tasks - 1))
        # Pick the current task (first incomplete, or last if all done)
        current_task = tasks[min(done_tasks, len(tasks) - 1)]

        agents[name] = {
            "name": name,
            "status": status,
            "department": info["dept"],
            "started_at": ts(agent_start),
            "completed_at": completed_at,
            "duration_seconds": duration,
            "duration": fmt_duration(duration),
            "task": current_task,
            "error_count": random.randint(1, 3) if status == "error" else 0,
            "tokens": {
                "total": tok_in + tok_out,
                "input": tok_in,
                "output": tok_out,
                "tool_uses": random.randint(8, info["tools"]),
            },
            "todos": {"total": total_tasks, "done": done_tasks},
            "workflow": {"phase": random.choice([
                "Requirements", "Design", "Implementation",
                "Testing", "Review", "Deploy",
            ])},
        }

    return {
        "session_id": sid,
        "updated_at": ts(now),
        "agents": agents,
    }


def generate_historical_sessions(count=15):
    """Generate realistic past sessions spanning the last 2 weeks."""
    sessions = []
    now = datetime.now(timezone.utc)

    for i in range(count):
        start = now - timedelta(days=random.uniform(0.5, 14), hours=random.randint(0, 8))
        num_agents = random.randint(4, 14)
        picked = random.sample(list(AGENTS.keys()), k=num_agents)

        agent_list = []
        total_dur = 0
        total_tok = 0
        for name in picked:
            info = AGENTS[name]
            dur = random.randint(30, 900)
            tok = random.randint(3000, 25000)
            total_dur += dur
            total_tok += tok
            a_start = start + timedelta(seconds=random.randint(0, 120))
            agent_list.append({
                "name": name,
                "department": info["dept"],
                "started_at": ts(a_start),
                "completed_at": ts(a_start + timedelta(seconds=dur)),
                "duration_seconds": dur,
                "tokens": tok,
            })

        sessions.append({
            "session_id": rand_session_id(),
            "started_at": ts(start),
            "updated_at": ts(start + timedelta(seconds=total_dur + 60)),
            "total_duration": total_dur,
            "total_tokens": total_tok,
            "agents": agent_list,
        })

    sessions.sort(key=lambda s: s["started_at"])
    return {"sessions": sessions}


def generate_todos(agents_data):
    """Generate todo files for each agent."""
    todos = {}
    for name, info in agents_data["agents"].items():
        tasks = TASK_TEMPLATES.get(name, DEFAULT_TASKS)
        total = info["todos"]["total"]
        completed = info["todos"]["done"]
        todo_list = []
        for j in range(total):
            task_content = tasks[j % len(tasks)]
            if j < completed:
                status = "completed"
            elif j == completed:
                status = "in_progress"
            else:
                status = "pending"
            todo_list.append({
                "id": f"todo_{j+1}",
                "content": task_content,
                "status": status,
                "completed_at": ts(datetime.now(timezone.utc) - timedelta(minutes=random.randint(1, 30))) if status == "completed" else None,
            })
        todos[name] = {
            "agent": name,
            "progress": {"total": total, "completed": completed},
            "todos": todo_list,
        }
    return todos


def generate_errors(agents_data):
    """Generate error files for agents that had errors."""
    errors = {}
    now = datetime.now(timezone.utc)
    for name, info in agents_data["agents"].items():
        count = info["error_count"]
        if count == 0:
            # Still give some agents historical errors for richer data
            if random.random() < 0.3:
                count = 1
            else:
                continue
        err_list = []
        for _ in range(count):
            err_list.append({
                "tool": random.choice(TOOLS),
                "message": random.choice(ERROR_MESSAGES),
                "timestamp": ts(now - timedelta(minutes=random.randint(1, 60))),
                "severity": random.choice(["error", "error", "warning"]),
            })
        errors[name] = {"agent": name, "errors": err_list}
    return errors


def generate_messages(agents_data):
    """Generate message files for a few agents."""
    messages = {}
    now = datetime.now(timezone.utc)
    # Pick 5-7 agents to have messages
    msg_agents = random.sample(list(agents_data["agents"].keys()), k=min(7, len(agents_data["agents"])))

    for name in msg_agents:
        msg_list = []
        num_msgs = random.randint(2, 5)
        for j in range(num_msgs):
            msg_type, content = random.choice(MSG_CONTENTS)
            created = now - timedelta(minutes=random.randint(5, 120))
            delivered = created + timedelta(seconds=random.randint(1, 5))
            # Most messages acknowledged
            if random.random() < 0.8:
                acked = delivered + timedelta(seconds=random.randint(3, 45))
                status = "acknowledged"
                response = random.choice([
                    "Understood, adjusting approach accordingly.",
                    "Working on it now. ETA ~5 minutes.",
                    "Done. Changes committed.",
                    "Acknowledged. Reprioritizing tasks.",
                    "Yes, coverage is at 84% currently.",
                    "Switching to the recommended approach.",
                    "Completed. See updated spec document.",
                ])
            else:
                acked = None
                status = "delivered"
                response = None

            msg_list.append({
                "id": f"msg_{int(created.timestamp())}_{j:03d}",
                "type": msg_type,
                "from": "user",
                "content": content,
                "priority": random.choice(["normal", "normal", "high", "urgent"]),
                "status": status,
                "created_at": ts(created),
                "delivered_at": ts(delivered),
                "acknowledged_at": ts(acked) if acked else None,
                "response": response,
            })

        messages[name] = {"agent": name, "messages": msg_list}
    return messages


def seed_sqlite(agents_data, history_data, errors_all, messages_all):
    """Populate the SQLite database for analytics."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()

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

    # Insert current session
    sid = agents_data["session_id"]
    agents = agents_data["agents"]
    started_times = [a["started_at"] for a in agents.values() if a.get("started_at")]
    started_at = min(started_times) if started_times else ""
    total_dur = sum(a.get("duration_seconds", 0) for a in agents.values())
    total_tok = sum(a.get("tokens", {}).get("total", 0) for a in agents.values())

    conn.execute(
        "INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?)",
        (sid, started_at, agents_data["updated_at"], total_dur, total_tok, len(agents)),
    )
    for name, info in agents.items():
        tokens = info.get("tokens", {})
        todos = info.get("todos", {})
        conn.execute(
            "INSERT INTO agent_runs (session_id, agent_name, department, status, started_at, completed_at, duration_seconds, error_count, todo_total, todo_completed, tokens_total, tokens_input, tokens_output, tool_uses) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (sid, name, info["department"], info["status"], info["started_at"],
             info.get("completed_at", ""), info["duration_seconds"], info.get("error_count", 0),
             todos.get("total", 0), todos.get("done", 0),
             tokens.get("total", 0), tokens.get("input", 0), tokens.get("output", 0),
             tokens.get("tool_uses", 0)),
        )

    # Insert historical sessions
    for sess in history_data["sessions"]:
        hsid = sess["session_id"]
        conn.execute(
            "INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?)",
            (hsid, sess["started_at"], sess["updated_at"],
             sess["total_duration"], sess["total_tokens"], len(sess["agents"])),
        )
        for agent in sess["agents"]:
            tok = agent.get("tokens", 0)
            tok_in = int(tok * 0.4)
            tok_out = tok - tok_in
            conn.execute(
                "INSERT INTO agent_runs (session_id, agent_name, department, status, started_at, completed_at, duration_seconds, error_count, todo_total, todo_completed, tokens_total, tokens_input, tokens_output, tool_uses) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (hsid, agent["name"], agent["department"], "completed",
                 agent["started_at"], agent["completed_at"], agent["duration_seconds"],
                 random.randint(0, 1), random.randint(3, 8), random.randint(3, 8),
                 tok, tok_in, tok_out, random.randint(5, 50)),
            )
            # Add some errors to historical sessions
            if random.random() < 0.15:
                conn.execute(
                    "INSERT OR IGNORE INTO errors VALUES (NULL, ?, ?, ?, ?, ?)",
                    (hsid, agent["name"], random.choice(TOOLS),
                     random.choice(ERROR_MESSAGES), agent["started_at"]),
                )

    # Insert errors for current session
    for name, err_data in errors_all.items():
        for err in err_data["errors"]:
            conn.execute(
                "INSERT OR IGNORE INTO errors VALUES (NULL, ?, ?, ?, ?, ?)",
                (sid, name, err["tool"], err["message"], err["timestamp"]),
            )

    # Insert messages
    for name, msg_data in messages_all.items():
        for msg in msg_data["messages"]:
            resp_time = None
            if msg.get("acknowledged_at") and msg.get("created_at"):
                try:
                    from datetime import datetime as _dt
                    c = _dt.strptime(msg["created_at"], "%Y-%m-%dT%H:%M:%SZ")
                    a = _dt.strptime(msg["acknowledged_at"], "%Y-%m-%dT%H:%M:%SZ")
                    resp_time = int((a - c).total_seconds())
                except Exception:
                    pass
            conn.execute(
                "INSERT OR IGNORE INTO messages VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                (msg["id"], sid, name, msg["type"],
                 "user_to_agent" if msg.get("from") == "user" else "agent_to_user",
                 msg["content"], msg["status"], msg["created_at"],
                 msg.get("acknowledged_at"), resp_time),
            )
    # Add messages to historical sessions too
    for sess in history_data["sessions"]:
        hsid = sess["session_id"]
        for agent in random.sample(sess["agents"], k=min(3, len(sess["agents"]))):
            for j in range(random.randint(1, 3)):
                msg_type, content = random.choice(MSG_CONTENTS)
                created = datetime.strptime(agent["started_at"], "%Y-%m-%dT%H:%M:%SZ")
                resp_time = random.randint(5, 60)
                mid = f"msg_{int(created.timestamp())}_{j:03d}_{hsid[:8]}"
                conn.execute(
                    "INSERT OR IGNORE INTO messages VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    (mid, hsid, agent["name"], msg_type, "user_to_agent",
                     content, "acknowledged",
                     ts(created), ts(created + timedelta(seconds=resp_time)), resp_time),
                )

    conn.commit()
    conn.close()


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


def main():
    print("Seeding sample data for Ghost Office dashboard...")

    # Generate all data
    agents_data = generate_current_session()
    history_data = generate_historical_sessions(15)
    todos_data = generate_todos(agents_data)
    errors_data = generate_errors(agents_data)
    messages_data = generate_messages(agents_data)

    # Write status files (used by live dashboard)
    write_json(STATUS_DIR / "agents.json", agents_data)
    write_json(STATUS_DIR / "history.json", history_data)

    (STATUS_DIR / "todos").mkdir(parents=True, exist_ok=True)
    for name, data in todos_data.items():
        write_json(STATUS_DIR / "todos" / f"{name}.json", data)

    (STATUS_DIR / "errors").mkdir(parents=True, exist_ok=True)
    for name, data in errors_data.items():
        write_json(STATUS_DIR / "errors" / f"{name}.json", data)

    (STATUS_DIR / "messages").mkdir(parents=True, exist_ok=True)
    for name, data in messages_data.items():
        write_json(STATUS_DIR / "messages" / f"{name}.json", data)

    # Write data/ copies (used by Docker container)
    write_json(DATA_DIR / "agents.json", agents_data)
    write_json(DATA_DIR / "history.json", history_data)
    (DATA_DIR / "todos").mkdir(parents=True, exist_ok=True)
    for name, data in todos_data.items():
        write_json(DATA_DIR / "todos" / f"{name}.json", data)
    (DATA_DIR / "errors").mkdir(parents=True, exist_ok=True)
    for name, data in errors_data.items():
        write_json(DATA_DIR / "errors" / f"{name}.json", data)

    # Seed SQLite
    seed_sqlite(agents_data, history_data, errors_data, messages_data)

    # Summary
    num_agents = len(agents_data["agents"])
    num_sessions = len(history_data["sessions"]) + 1
    num_errors = sum(len(e["errors"]) for e in errors_data.values())
    num_messages = sum(len(m["messages"]) for m in messages_data.values())
    print(f"  Current session: {agents_data['session_id'][:12]}... ({num_agents} agents)")
    print(f"  Historical sessions: {len(history_data['sessions'])}")
    print(f"  Total sessions in DB: {num_sessions}")
    print(f"  Todo lists: {len(todos_data)}")
    print(f"  Error entries: {num_errors}")
    print(f"  Messages: {num_messages}")
    print(f"  SQLite DB: {DB_PATH}")
    print("Done! Run 'docker compose up --build' to see the dashboard.")


if __name__ == "__main__":
    main()
