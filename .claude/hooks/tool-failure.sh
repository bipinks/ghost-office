#!/bin/bash
# Hook: PostToolUseFailure — Tool Failure Handler
# Logs tool failures and provides diagnostic hints.
# Exit 0 = allow (logging only, never block)

INPUT_JSON="$(cat)"
TOOL_NAME=""
ERROR_MSG=""

if command -v jq >/dev/null 2>&1; then
  TOOL_NAME="$(printf '%s' "$INPUT_JSON" | jq -r '.tool_name // empty' 2>/dev/null)"
  ERROR_MSG="$(printf '%s' "$INPUT_JSON" | jq -r '.tool_response.stderr // .tool_response.error // empty' 2>/dev/null | head -c 300)"
fi

if [ -z "$TOOL_NAME" ]; then
  exit 0
fi

# --- Log the failure ---
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "[$TIMESTAMP] tool=$TOOL_NAME error=$ERROR_MSG" >> "$LOG_DIR/tool-failures.log" 2>/dev/null

# --- Provide diagnostic hints ---
case "$TOOL_NAME" in
  Bash)
    if echo "$ERROR_MSG" | grep -qi "permission denied"; then
      echo "ℹ️  [Hook] Permission denied — check file ownership or use sudo if authorized." >&2
    elif echo "$ERROR_MSG" | grep -qi "command not found"; then
      echo "ℹ️  [Hook] Command not found — the tool may not be installed in this environment." >&2
    elif echo "$ERROR_MSG" | grep -qi "connection refused\|timeout"; then
      echo "ℹ️  [Hook] Connection issue — check network connectivity and service availability." >&2
    fi
    ;;
  mcp__ms365__*)
    if echo "$ERROR_MSG" | grep -qi "unauthorized\|401\|403"; then
      echo "ℹ️  [Hook] MS365 auth error — run mcp__ms365__login to re-authenticate." >&2
    fi
    ;;
esac

exit 0
