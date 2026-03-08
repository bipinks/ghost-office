#!/usr/bin/env python3
"""Agent Dashboard Web Server — serves static files + message API.

Replaces vanilla `python3 -m http.server` to add POST support for
writing messages from the dashboard to agents.

Endpoints:
  GET  /                       → dashboard.html
  GET  /data/*                 → static JSON files (agents, todos, errors)
  GET  /api/messages/{agent}   → read agent's message queue
  POST /api/messages/{agent}   → send message to agent
"""

import http.server
import json
import os
import re
import shutil
import sys
import time
from pathlib import Path

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8686

# Resolve paths
SCRIPT_DIR = Path(__file__).resolve().parent
WEB_DIR = SCRIPT_DIR
STATUS_DIR = SCRIPT_DIR.parent.parent / ".claude" / "status"
DATA_DIR = WEB_DIR / "data"
MESSAGES_DIR = STATUS_DIR / "messages"


def sync_status_to_data():
    """Copy .claude/status/ files to scripts/web/data/ for serving."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    for name in ("agents.json", "history.json"):
        src = STATUS_DIR / name
        if src.exists():
            shutil.copy2(str(src), str(DATA_DIR / name))
    for subdir in ("todos", "errors"):
        src_dir = STATUS_DIR / subdir
        dst_dir = DATA_DIR / subdir
        dst_dir.mkdir(parents=True, exist_ok=True)
        if src_dir.exists():
            for f in src_dir.glob("*.json"):
                shutil.copy2(str(f), str(dst_dir / f.name))


def read_message_file(agent):
    """Read an agent's message queue file."""
    path = MESSAGES_DIR / f"{agent}.json"
    if not path.exists():
        return {"agent": agent, "messages": []}
    try:
        with open(path) as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {"agent": agent, "messages": []}


def write_message_file(agent, data):
    """Atomically write an agent's message queue file."""
    MESSAGES_DIR.mkdir(parents=True, exist_ok=True)
    path = MESSAGES_DIR / f"{agent}.json"
    tmp = path.with_suffix(".json.tmp")
    with open(tmp, "w") as f:
        json.dump(data, f, indent=2)
    tmp.rename(path)


class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler with static file serving and message API."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)

    def do_GET(self):
        # API: read messages for an agent
        m = re.match(r"^/api/messages/([\w-]+)$", self.path)
        if m:
            agent = m.group(1)
            data = read_message_file(agent)
            self._json_response(200, data)
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

        # Append to agent's message file
        data = read_message_file(agent)
        data["messages"].append(message)
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
        if args and isinstance(args[0], str) and args[0].startswith("GET /data/"):
            return  # suppress data polling logs
        super().log_message(fmt, *args)


if __name__ == "__main__":
    sync_status_to_data()
    server = http.server.HTTPServer(("0.0.0.0", PORT), DashboardHandler)
    print(f"Agent Dashboard server running on http://localhost:{PORT}")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.shutdown()
