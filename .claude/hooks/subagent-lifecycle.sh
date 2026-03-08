#!/bin/bash
# Hook: SubagentStart / SubagentStop — Subagent Lifecycle Tracking
# Logs when subagents are spawned and completed for orchestration visibility.
# Writes structured JSON status to .claude/status/agents.json for dashboard.
# Logs session history to .claude/status/history.json on completion.
# Sends desktop notification when all agents complete.
# Attempts to capture token usage from hook data (best-effort).
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

# Source file locking helper
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$HOOK_DIR/lib/filelock.sh" ]; then
  . "$HOOK_DIR/lib/filelock.sh"
fi

STATUS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/status"
mkdir -p "$STATUS_DIR" 2>/dev/null
STATUS_FILE="$STATUS_DIR/agents.json"
HISTORY_FILE="$STATUS_DIR/history.json"
ERRORS_DIR="$STATUS_DIR/errors"

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

# --- Best-effort token usage capture ---
# Claude Code may include usage data in future hook versions
TOTAL_TOKENS="$(printf '%s' "$INPUT_JSON" | jq -r '.total_tokens // .usage.total_tokens // .tool_response.total_tokens // 0' 2>/dev/null)" || TOTAL_TOKENS=0
INPUT_TOKENS="$(printf '%s' "$INPUT_JSON" | jq -r '.input_tokens // .usage.input_tokens // .tool_response.input_tokens // 0' 2>/dev/null)" || INPUT_TOKENS=0
OUTPUT_TOKENS="$(printf '%s' "$INPUT_JSON" | jq -r '.output_tokens // .usage.output_tokens // .tool_response.output_tokens // 0' 2>/dev/null)" || OUTPUT_TOKENS=0
TOOL_USES="$(printf '%s' "$INPUT_JSON" | jq -r '.tool_uses // .usage.tool_uses // .tool_response.tool_uses // 0' 2>/dev/null)" || TOOL_USES=0

case "$EVENT_TYPE" in
  SubagentStart)
    if type acquire_lock >/dev/null 2>&1; then acquire_lock "$STATUS_FILE"; fi
    jq --arg agent "$AGENT_NAME" \
       --arg ts "$TIMESTAMP" \
       --arg dept "$DEPARTMENT" \
       --arg sid "$SESSION_ID" \
       '.session_id = $sid |
        .updated_at = $ts |
        .agents[$agent] = {
          "status": "running",
          "started_at": $ts,
          "department": $dept,
          "error_count": 0
        }' "$STATUS_FILE" > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$STATUS_FILE"
    if type release_lock >/dev/null 2>&1; then release_lock "$STATUS_FILE"; fi
    ;;
  SubagentStop)
    if type acquire_lock >/dev/null 2>&1; then acquire_lock "$STATUS_FILE"; fi
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

    # Preserve error_count from running state
    EXISTING_ERRORS="$(jq -r --arg agent "$AGENT_NAME" '.agents[$agent].error_count // 0' "$STATUS_FILE" 2>/dev/null)" || EXISTING_ERRORS=0

    jq --arg agent "$AGENT_NAME" \
       --arg ts "$TIMESTAMP" \
       --arg dept "$DEPARTMENT" \
       --arg sid "$SESSION_ID" \
       --argjson dur "$DURATION" \
       --argjson errors "$EXISTING_ERRORS" \
       --argjson tokens "$TOTAL_TOKENS" \
       --argjson input_tok "$INPUT_TOKENS" \
       --argjson output_tok "$OUTPUT_TOKENS" \
       --argjson tools "$TOOL_USES" \
       '.session_id = $sid |
        .updated_at = $ts |
        .agents[$agent].status = "completed" |
        .agents[$agent].completed_at = $ts |
        .agents[$agent].duration_seconds = $dur |
        .agents[$agent].error_count = $errors |
        .agents[$agent].tokens = {
          "total": $tokens,
          "input": $input_tok,
          "output": $output_tok,
          "tool_uses": $tools
        } |
        .agents[$agent].department = (
          if .agents[$agent].department then .agents[$agent].department else $dept end
        )' "$STATUS_FILE" > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$STATUS_FILE"
    if type release_lock >/dev/null 2>&1; then release_lock "$STATUS_FILE"; fi

    # --- Session history: log completed agent to history ---
    if [ ! -f "$HISTORY_FILE" ] || ! jq empty "$HISTORY_FILE" 2>/dev/null; then
      printf '{"sessions":[]}' > "$HISTORY_FILE"
    fi

    HIST_TMP="$(mktemp "${HISTORY_FILE}.XXXXXX" 2>/dev/null)"
    if [ -n "$HIST_TMP" ]; then
      jq --arg sid "$SESSION_ID" \
         --arg agent "$AGENT_NAME" \
         --arg dept "$DEPARTMENT" \
         --arg ts "$TIMESTAMP" \
         --arg started "$STARTED_AT" \
         --argjson dur "$DURATION" \
         --argjson tokens "$TOTAL_TOKENS" \
         '
         # Find or create session entry
         (.sessions |= (
           if any(.session_id == $sid) then
             map(if .session_id == $sid then
               .agents += [{
                 "name": $agent,
                 "department": $dept,
                 "started_at": $started,
                 "completed_at": $ts,
                 "duration_seconds": $dur,
                 "tokens": $tokens
               }] |
               .updated_at = $ts |
               .total_duration = ([.agents[].duration_seconds] | add) |
               .total_tokens = ([.agents[].tokens] | add)
             else . end)
           else
             . + [{
               "session_id": $sid,
               "started_at": $started,
               "updated_at": $ts,
               "total_duration": $dur,
               "total_tokens": $tokens,
               "agents": [{
                 "name": $agent,
                 "department": $dept,
                 "started_at": $started,
                 "completed_at": $ts,
                 "duration_seconds": $dur,
                 "tokens": $tokens
               }]
             }]
           end
         )) |
         # Keep only last 50 sessions
         .sessions = (.sessions | .[-50:])
         ' "$HISTORY_FILE" > "$HIST_TMP" 2>/dev/null && mv "$HIST_TMP" "$HISTORY_FILE"
      rm -f "$HIST_TMP" 2>/dev/null
    fi

    # --- Notification: check if all agents are completed ---
    STILL_RUNNING="$(jq '[.agents | to_entries[] | select(.value.status == "running")] | length' "$STATUS_FILE" 2>/dev/null)" || STILL_RUNNING=1
    TOTAL_AGENTS="$(jq '[.agents | to_entries[]] | length' "$STATUS_FILE" 2>/dev/null)" || TOTAL_AGENTS=0

    if [ "$STILL_RUNNING" -eq 0 ] && [ "$TOTAL_AGENTS" -gt 0 ]; then
      COMPLETED_COUNT="$(jq '[.agents | to_entries[] | select(.value.status == "completed")] | length' "$STATUS_FILE" 2>/dev/null)" || COMPLETED_COUNT=0
      NOTIFY_MSG="All $COMPLETED_COUNT agents completed"

      # Send desktop notification (cross-platform)
      if command -v notify-send >/dev/null 2>&1; then
        notify-send "Agent Dashboard" "$NOTIFY_MSG" --urgency=normal 2>/dev/null
      elif command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$NOTIFY_MSG\" with title \"Agent Dashboard\"" 2>/dev/null
      fi
    fi
    ;;
esac

# Clean up temp file if mv failed
rm -f "$TMPFILE" 2>/dev/null

exit 0
