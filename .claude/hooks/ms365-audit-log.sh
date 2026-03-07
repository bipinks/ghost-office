#!/bin/bash
# Hook: PreToolUse (mcp__ms365__) — MS365 Audit Logging
# Logs all Microsoft 365 operations for compliance audit trail.
# Exit 0 = allow (log only, never block)

INPUT_JSON="$(cat)"
TOOL_NAME=""
SESSION_ID=""

if command -v jq >/dev/null 2>&1; then
  TOOL_NAME="$(printf '%s' "$INPUT_JSON" | jq -r '.tool_name // empty' 2>/dev/null)"
  SESSION_ID="$(printf '%s' "$INPUT_JSON" | jq -r '.session_id // "unknown"' 2>/dev/null)"
fi

if [ -z "$TOOL_NAME" ]; then
  exit 0
fi

# --- Determine log directory ---
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
mkdir -p -m 0700 "$LOG_DIR" 2>/dev/null

LOG_FILE="$LOG_DIR/ms365-audit.log"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# --- Extract operation details ---
OPERATION=""
if command -v jq >/dev/null 2>&1; then
  # Get a summary of the tool input (first 200 chars)
  OPERATION="$(printf '%s' "$INPUT_JSON" | jq -c '.tool_input // {}' 2>/dev/null | head -c 200)"
fi

# --- Log the operation ---
echo "[$TIMESTAMP] session=$SESSION_ID tool=$TOOL_NAME input=$OPERATION" >> "$LOG_FILE" 2>/dev/null

# --- Warn on sensitive operations ---
case "$TOOL_NAME" in
  *send-shared-mailbox-mail*|*send-chat-message*|*send-channel-message*)
    echo "ℹ️  [Hook] MS365 message/email operation logged for audit." >&2
    ;;
  *update-planner-task*|*create-planner-task*)
    echo "ℹ️  [Hook] MS365 task modification logged for audit." >&2
    ;;
esac

exit 0
