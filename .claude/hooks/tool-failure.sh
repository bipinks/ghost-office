#!/bin/bash
# Hook: PostToolUseFailure — Tool Failure Handler
# Logs tool failures, provides diagnostic hints, and tracks errors per agent
# for the agent dashboard to display. Exit 0 = allow (logging only, never block)

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
mkdir -p -m 0700 "$LOG_DIR" 2>/dev/null
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

# --- Track errors per agent for dashboard ---
if command -v jq >/dev/null 2>&1; then
  # Source file locking helper
  HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "$HOOK_DIR/lib/filelock.sh" ]; then
    . "$HOOK_DIR/lib/filelock.sh"
  fi
  STATUS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/status"
  ERRORS_DIR="$STATUS_DIR/errors"
  AGENTS_FILE="$STATUS_DIR/agents.json"
  mkdir -p "$ERRORS_DIR" 2>/dev/null

  # Find the currently running agent
  AGENT_NAME="session"
  if [ -f "$AGENTS_FILE" ] && jq empty "$AGENTS_FILE" 2>/dev/null; then
    RUNNING_AGENT="$(jq -r '
      [.agents | to_entries[] | select(.value.status == "running")]
      | sort_by(.value.started_at) | last | .key // empty
    ' "$AGENTS_FILE" 2>/dev/null)"
    if [ -n "$RUNNING_AGENT" ]; then
      AGENT_NAME="$RUNNING_AGENT"

      # Increment error_count in agents.json (with lock)
      if type acquire_lock >/dev/null 2>&1; then acquire_lock "$AGENTS_FILE"; fi
      TMPFILE="$(mktemp "${AGENTS_FILE}.XXXXXX" 2>/dev/null)"
      if [ -n "$TMPFILE" ]; then
        jq --arg agent "$AGENT_NAME" \
           '.agents[$agent].error_count = ((.agents[$agent].error_count // 0) + 1)' \
           "$AGENTS_FILE" > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$AGENTS_FILE"
        rm -f "$TMPFILE" 2>/dev/null
      fi
      if type release_lock >/dev/null 2>&1; then release_lock "$AGENTS_FILE"; fi
    fi
  fi

  # Append error to per-agent error log
  ERROR_FILE="$ERRORS_DIR/${AGENT_NAME}.json"
  if [ ! -f "$ERROR_FILE" ] || ! jq empty "$ERROR_FILE" 2>/dev/null; then
    printf '{"agent":"%s","errors":[]}' "$AGENT_NAME" > "$ERROR_FILE"
  fi

  ERR_TMP="$(mktemp "${ERROR_FILE}.XXXXXX" 2>/dev/null)"
  if [ -n "$ERR_TMP" ]; then
    jq --arg tool "$TOOL_NAME" \
       --arg msg "$ERROR_MSG" \
       --arg ts "$TIMESTAMP" \
       '.errors += [{"tool": $tool, "message": $msg, "timestamp": $ts}] |
        .errors = (.errors | .[-20:])' \
       "$ERROR_FILE" > "$ERR_TMP" 2>/dev/null && mv "$ERR_TMP" "$ERROR_FILE"
    rm -f "$ERR_TMP" 2>/dev/null
  fi
fi

exit 0
