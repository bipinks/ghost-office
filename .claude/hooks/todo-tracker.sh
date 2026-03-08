#!/bin/bash
# Hook: PostToolUse (TodoWrite) — Agent Task Progress Tracking
# Captures todo list updates from agents and writes them to per-agent JSON files
# for the agent dashboard to display. Exit 0 = allow (never block).

INPUT_JSON="$(cat)"

# Require jq
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Extract todo items from tool_input
TODOS="$(printf '%s' "$INPUT_JSON" | jq -r '.tool_input.todos // empty' 2>/dev/null)"
if [ -z "$TODOS" ] || [ "$TODOS" = "null" ]; then
  exit 0
fi

SESSION_ID="$(printf '%s' "$INPUT_JSON" | jq -r '.session_id // "unknown"' 2>/dev/null)"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Detect agent name: check if a running agent exists in agents.json
STATUS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/status"
TODOS_DIR="$STATUS_DIR/todos"
mkdir -p "$TODOS_DIR" 2>/dev/null

AGENTS_FILE="$STATUS_DIR/agents.json"
AGENT_NAME="session"

# Find the most recently started running agent
if [ -f "$AGENTS_FILE" ] && jq empty "$AGENTS_FILE" 2>/dev/null; then
  RUNNING_AGENT="$(jq -r '
    [.agents | to_entries[] | select(.value.status == "running")]
    | sort_by(.value.started_at) | last | .key // empty
  ' "$AGENTS_FILE" 2>/dev/null)"
  if [ -n "$RUNNING_AGENT" ]; then
    AGENT_NAME="$RUNNING_AGENT"
  fi
fi

# Count progress
COMPLETED="$(printf '%s' "$INPUT_JSON" | jq '[.tool_input.todos[] | select(.status == "completed")] | length' 2>/dev/null)" || COMPLETED=0
IN_PROGRESS="$(printf '%s' "$INPUT_JSON" | jq '[.tool_input.todos[] | select(.status == "in_progress")] | length' 2>/dev/null)" || IN_PROGRESS=0
PENDING="$(printf '%s' "$INPUT_JSON" | jq '[.tool_input.todos[] | select(.status == "pending")] | length' 2>/dev/null)" || PENDING=0
TOTAL="$(printf '%s' "$INPUT_JSON" | jq '.tool_input.todos | length' 2>/dev/null)" || TOTAL=0

# Build output JSON
TMPFILE="$(mktemp "${TODOS_DIR}/${AGENT_NAME}.json.XXXXXX" 2>/dev/null)" || exit 0

printf '%s' "$INPUT_JSON" | jq --arg agent "$AGENT_NAME" \
   --arg ts "$TIMESTAMP" \
   --argjson completed "$COMPLETED" \
   --argjson in_progress "$IN_PROGRESS" \
   --argjson pending "$PENDING" \
   --argjson total "$TOTAL" \
   '{
     "agent": $agent,
     "updated_at": $ts,
     "todos": ([.tool_input.todos[] | {content, status}] | .[-100:]),
     "progress": {
       "completed": $completed,
       "in_progress": $in_progress,
       "pending": $pending,
       "total": $total
     }
   }' > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$TODOS_DIR/${AGENT_NAME}.json"

# Clean up on failure
rm -f "$TMPFILE" 2>/dev/null

exit 0
