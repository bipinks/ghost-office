#!/bin/bash
# Hook: SubagentStart / SubagentStop — Subagent Lifecycle Tracking
# Logs when subagents are spawned and completed for orchestration visibility.
# Exit 0 = allow (log only, never block)

INPUT_JSON="$(cat)"
EVENT_TYPE="${HOOK_EVENT:-unknown}"
AGENT_NAME=""
SESSION_ID=""

if command -v jq >/dev/null 2>&1; then
  AGENT_NAME="$(printf '%s' "$INPUT_JSON" | jq -r '.agent_name // .tool_input.subagent_type // empty' 2>/dev/null)"
  SESSION_ID="$(printf '%s' "$INPUT_JSON" | jq -r '.session_id // "unknown"' 2>/dev/null)"
fi

if [ -z "$AGENT_NAME" ]; then
  exit 0
fi

# --- Determine log directory ---
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null

LOG_FILE="$LOG_DIR/subagent-lifecycle.log"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# --- Log the event ---
echo "[$TIMESTAMP] event=$EVENT_TYPE session=$SESSION_ID agent=$AGENT_NAME" >> "$LOG_FILE" 2>/dev/null

# --- User-visible status ---
case "$EVENT_TYPE" in
  SubagentStart)
    echo "ℹ️  [Hook] Subagent started: $AGENT_NAME" >&2
    ;;
  SubagentStop)
    echo "ℹ️  [Hook] Subagent completed: $AGENT_NAME" >&2
    ;;
esac

exit 0
