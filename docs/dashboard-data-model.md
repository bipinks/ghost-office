# Dashboard Data Model

## Overview

The agent dashboard uses a two-layer data architecture:

1. **JSON files** — Written by bash hooks during Claude Code sessions (real-time)
2. **SQLite database** — Synced from JSON by the web server for queryable analytics

```
Claude Code Hooks (bash + jq)
        │
        ▼
  .claude/status/*.json    ← Real-time session data
        │
        ▼
  server.py sync engine    ← JSON → SQLite sync on each request
        │
        ▼
  data/dashboard.db        ← SQLite for analytics queries
        │
        ▼
  /api/analytics/* endpoints → analytics.html (Chart.js)
```

## JSON File Schemas

All JSON files live under `.claude/status/`.

### agents.json

Tracks all agents in the current session.

```json
{
  "session_id": "abc123",
  "updated_at": "2026-03-08T12:00:00Z",
  "agents": {
    "backend-engineer": {
      "status": "running|completed",
      "started_at": "2026-03-08T12:00:00Z",
      "completed_at": "2026-03-08T12:05:00Z",
      "duration_seconds": 300,
      "department": "Engineering",
      "error_count": 0,
      "tokens": {
        "total": 0,
        "input": 0,
        "output": 0,
        "tool_uses": 0
      }
    }
  }
}
```

**Written by**: `subagent-lifecycle.sh` (SubagentStart/SubagentStop events)
**Modified by**: `tool-failure.sh` (increments `error_count`)
**Reset**: On session startup by `session-start.sh`

### history.json

Stores completed session history across sessions.

```json
{
  "sessions": [
    {
      "session_id": "abc123",
      "started_at": "2026-03-08T12:00:00Z",
      "updated_at": "2026-03-08T12:30:00Z",
      "total_duration": 1800,
      "total_tokens": 50000,
      "agents": [
        {
          "name": "backend-engineer",
          "department": "Engineering",
          "started_at": "2026-03-08T12:00:00Z",
          "completed_at": "2026-03-08T12:05:00Z",
          "duration_seconds": 300,
          "tokens": 5000
        }
      ]
    }
  ]
}
```

**Written by**: `subagent-lifecycle.sh` (on SubagentStop)
**Cap**: 50 sessions (enforced in hook)
**Preserved**: Not cleared on session startup

### todos/{agent}.json

Per-agent task tracking.

```json
{
  "agent": "backend-engineer",
  "todos": [
    { "content": "Implement API endpoint", "status": "completed" },
    { "content": "Write tests", "status": "in_progress" }
  ]
}
```

**Written by**: `todo-tracker.sh` (on TodoWrite tool use)
**Cap**: 100 items per agent
**Reset**: Cleared on session startup

### errors/{agent}.json

Per-agent error log.

```json
{
  "agent": "backend-engineer",
  "errors": [
    {
      "tool": "Bash",
      "message": "command not found: npm",
      "timestamp": "2026-03-08T12:01:00Z"
    }
  ]
}
```

**Written by**: `tool-failure.sh` (on PostToolUseFailure)
**Cap**: 20 errors per agent (enforced in hook)
**Reset**: Cleared on session startup

### messages/{agent}.json

Inter-agent messaging for dashboard communication.

```json
{
  "agent": "backend-engineer",
  "messages": [
    {
      "id": "msg_abc123",
      "type": "instruction|question|priority|note|pause|cancel",
      "from": "user",
      "content": "Focus on the API endpoint first",
      "priority": "normal|high|urgent",
      "status": "pending|delivered|acknowledged",
      "created_at": "2026-03-08T12:00:00Z",
      "delivered_at": "2026-03-08T12:00:05Z",
      "acknowledged_at": null,
      "response": null
    }
  ]
}
```

**Written by**: Web dashboard (POST /data/messages/{agent}.json), `message-check.sh` hook
**Cap**: 100 messages per agent (enforced in hook and server)
**Reset**: Cleared on session startup

## SQLite Schema

The SQLite database (`data/dashboard.db`) is auto-created by `server.py` on first run.

### sessions

```sql
CREATE TABLE sessions (
    session_id TEXT PRIMARY KEY,
    started_at TEXT,
    updated_at TEXT,
    total_duration INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    agent_count INTEGER DEFAULT 0
);
```

### agent_runs

```sql
CREATE TABLE agent_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    agent_name TEXT,
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
CREATE INDEX idx_agent_runs_session ON agent_runs(session_id);
CREATE INDEX idx_agent_runs_agent ON agent_runs(agent_name);
```

### errors

```sql
CREATE TABLE errors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    agent_name TEXT,
    tool TEXT,
    message TEXT,
    timestamp TEXT,
    UNIQUE(session_id, agent_name, tool, timestamp)
);
CREATE INDEX idx_errors_session ON errors(session_id);
```

### messages

```sql
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    agent_name TEXT,
    msg_type TEXT,
    direction TEXT,
    content TEXT,
    status TEXT,
    created_at TEXT,
    acknowledged_at TEXT,
    response_time_seconds INTEGER DEFAULT 0,
    UNIQUE(session_id, agent_name, created_at, content)
);
CREATE INDEX idx_messages_session ON messages(session_id);
```

## Data Flow

```
┌──────────────────────────────────────────────────────────┐
│                    Claude Code Session                    │
│                                                          │
│  SubagentStart/Stop  →  subagent-lifecycle.sh            │
│                            ├─ agents.json (current)      │
│                            └─ history.json (append)      │
│                                                          │
│  TodoWrite           →  todo-tracker.sh                  │
│                            └─ todos/{agent}.json         │
│                                                          │
│  PostToolUseFailure  →  tool-failure.sh                  │
│                            ├─ errors/{agent}.json        │
│                            └─ agents.json (error_count)  │
│                                                          │
│  Tool use (any)      →  message-check.sh                 │
│                            └─ messages/{agent}.json      │
│                                                          │
│  SessionStart        →  session-start.sh                 │
│                            └─ Cleans stale data          │
└──────────────────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│              Web Server (server.py :8686)                 │
│                                                          │
│  sync_status_to_data()  — copies JSON to data/ dir       │
│  sync_json_to_sqlite()  — upserts JSON → SQLite          │
│                                                          │
│  GET /data/*.json       — serves raw JSON                │
│  GET /api/analytics/*   — queries SQLite, returns JSON   │
│  GET /dashboard.html    — main dashboard                 │
│  GET /analytics.html    — full analytics with charts     │
└──────────────────────────────────────────────────────────┘
```

## Retention Limits

| Data | Cap | Enforced By |
|------|-----|-------------|
| agents.json | Current session only | session-start.sh (reset on startup) |
| history.json | 50 sessions | subagent-lifecycle.sh |
| todos/{agent}.json | 100 items | todo-tracker.sh |
| errors/{agent}.json | 20 errors | tool-failure.sh |
| messages/{agent}.json | 100 messages | message-check.sh, server.py |
| SQLite sessions | 200 sessions | sync_json_to_sqlite() (auto-prune) |

## Concurrency Model

Multiple hooks may write to `agents.json` simultaneously (e.g., two subagents starting at once).

**File locking**: `.claude/hooks/lib/filelock.sh` provides `acquire_lock` / `release_lock` functions using `mkdir` (atomic on POSIX, works on macOS and Linux).

- Lock timeout: 5 seconds (25 attempts × 0.2s)
- Stale lock detection: locks older than 30 seconds are auto-removed
- Lock dir pattern: `{file}.lock/` (contains `pid` file)

**Atomic writes**: All hooks use the `mktemp` + `mv` pattern — write to a temp file, then atomically rename. This prevents partial reads.

**SQLite**: Uses WAL journal mode for concurrent read/write access. The sync engine runs on each web request with `INSERT ... ON CONFLICT ... DO UPDATE` (upsert) for idempotent sync.

## Analytics API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/analytics/summary` | Total sessions, agents, errors, tokens, avg duration |
| `GET /api/analytics/agent-performance` | Per-agent stats: avg duration, error rate, usage count |
| `GET /api/analytics/department-performance` | Per-department aggregates |
| `GET /api/analytics/session-trends` | Last 50 sessions: duration, agent count, errors, tokens |
| `GET /api/analytics/workflow-bottlenecks` | Average time per workflow phase (by department) |
| `GET /api/analytics/error-breakdown` | Errors grouped by tool and by agent |
| `GET /api/analytics/token-usage` | Token usage trends per session |
| `GET /api/analytics/message-stats` | Message volume, types, response times |
