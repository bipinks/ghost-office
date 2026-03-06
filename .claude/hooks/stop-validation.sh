#!/bin/bash
# Hook: Stop — Post-Response Validation
# Runs after Claude finishes a response to log completion and check state.
# Exit 0 = allow (validation only, never block)

INPUT_JSON="$(cat)"
SESSION_ID=""

if command -v jq >/dev/null 2>&1; then
  SESSION_ID="$(printf '%s' "$INPUT_JSON" | jq -r '.session_id // "unknown"' 2>/dev/null)"
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# --- Check for uncommitted sensitive files ---
if command -v git >/dev/null 2>&1; then
  STAGED_SECRETS=""
  STAGED_SECRETS="$(git -C "$PROJECT_DIR" diff --cached --name-only 2>/dev/null | grep -iE '\.(env|pem|key|crt|tfvars|credentials)$' || true)"

  if [ -n "$STAGED_SECRETS" ]; then
    echo "⚠️  [Hook] Sensitive files are staged for commit:" >&2
    echo "$STAGED_SECRETS" | while read -r f; do echo "  - $f" >&2; done
    echo "Review before committing!" >&2
  fi
fi

# --- Log completion ---
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "[$TIMESTAMP] session=$SESSION_ID event=response_complete" >> "$LOG_DIR/session-activity.log" 2>/dev/null

exit 0
