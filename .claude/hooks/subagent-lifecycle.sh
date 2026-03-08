#!/bin/bash
# Hook: SubagentStart / SubagentStop — Subagent Lifecycle Tracking
# Logs when subagents are spawned and completed for orchestration visibility.
# Writes structured JSON status to .claude/status/agents.json for dashboard.
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
mkdir -p -m 0700 "$LOG_DIR" 2>/dev/null

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

# --- JSON status for agent dashboard ---
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

STATUS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/status"
mkdir -p "$STATUS_DIR" 2>/dev/null
STATUS_FILE="$STATUS_DIR/agents.json"

# Department lookup
get_department() {
  case "$1" in
    product-manager|ui-ux-designer) echo "Product" ;;
    architecture-agent|backend-engineer|frontend-engineer|database-engineer|prompt-engineer) echo "Engineering" ;;
    qa-agent|security-agent) echo "Quality" ;;
    devops-engineer|monitoring-agent|performance-agent) echo "Operations" ;;
    content-strategist|social-media-manager) echo "Marketing" ;;
    support-agent|documentation-agent) echo "Support" ;;
    ms-it-admin) echo "IT" ;;
    master-orchestrator) echo "Orchestrator" ;;
    *) echo "Other" ;;
  esac
}

DEPARTMENT="$(get_department "$AGENT_NAME")"

# Initialize status file if missing or invalid
if [ ! -f "$STATUS_FILE" ] || ! jq empty "$STATUS_FILE" 2>/dev/null; then
  printf '{"session_id":"%s","updated_at":"%s","agents":{}}' "$SESSION_ID" "$TIMESTAMP" > "$STATUS_FILE"
fi

TMPFILE="$(mktemp "${STATUS_FILE}.XXXXXX" 2>/dev/null)" || exit 0

case "$EVENT_TYPE" in
  SubagentStart)
    jq --arg agent "$AGENT_NAME" \
       --arg ts "$TIMESTAMP" \
       --arg dept "$DEPARTMENT" \
       --arg sid "$SESSION_ID" \
       '.session_id = $sid |
        .updated_at = $ts |
        .agents[$agent] = {
          "status": "running",
          "started_at": $ts,
          "department": $dept
        }' "$STATUS_FILE" > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$STATUS_FILE"
    ;;
  SubagentStop)
    # Compute duration if started_at exists
    STARTED_AT="$(jq -r --arg agent "$AGENT_NAME" '.agents[$agent].started_at // empty' "$STATUS_FILE" 2>/dev/null)"
    DURATION=0
    if [ -n "$STARTED_AT" ] && command -v date >/dev/null 2>&1; then
      START_EPOCH="$(date -d "$STARTED_AT" +%s 2>/dev/null)" || START_EPOCH=0
      NOW_EPOCH="$(date -u +%s 2>/dev/null)" || NOW_EPOCH=0
      if [ "$START_EPOCH" -gt 0 ] 2>/dev/null && [ "$NOW_EPOCH" -gt 0 ] 2>/dev/null; then
        DURATION=$(( NOW_EPOCH - START_EPOCH ))
      fi
    fi

    jq --arg agent "$AGENT_NAME" \
       --arg ts "$TIMESTAMP" \
       --arg dept "$DEPARTMENT" \
       --arg sid "$SESSION_ID" \
       --argjson dur "$DURATION" \
       '.session_id = $sid |
        .updated_at = $ts |
        .agents[$agent].status = "completed" |
        .agents[$agent].completed_at = $ts |
        .agents[$agent].duration_seconds = $dur |
        .agents[$agent].department = (
          if .agents[$agent].department then .agents[$agent].department else $dept end
        )' "$STATUS_FILE" > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$STATUS_FILE"
    ;;
esac

# Clean up temp file if mv failed
rm -f "$TMPFILE" 2>/dev/null

exit 0
