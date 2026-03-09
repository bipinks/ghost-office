#!/bin/bash
# Hook: SubagentStart / SubagentStop — Subagent Lifecycle Tracking
# Writes per-agent JSON files to .claude/status/agents/ for lock-free concurrency.
# A lightweight assembler merges them into agents.json after each write.
# Logs session history to .claude/status/history.json on completion.
# Sends desktop notification when all agents complete.
# Exit 0 = allow (log only, never block)

INPUT_JSON="$(cat)"
AGENT_NAME=""
SESSION_ID=""
EVENT_TYPE=""

if command -v jq >/dev/null 2>&1; then
  AGENT_NAME="$(printf '%s' "$INPUT_JSON" | jq -r '.agent_type // .agent_name // .tool_input.subagent_type // empty' 2>/dev/null)"
  SESSION_ID="$(printf '%s' "$INPUT_JSON" | jq -r '.session_id // "unknown"' 2>/dev/null)"
  EVENT_TYPE="$(printf '%s' "$INPUT_JSON" | jq -r '.hook_event_name // empty' 2>/dev/null)"
fi

# Fallback to env var if JSON field not available
EVENT_TYPE="${EVENT_TYPE:-${HOOK_EVENT:-unknown}}"

if [ -z "$AGENT_NAME" ]; then
  exit 0
fi

# --- Source file locking helper ---
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$HOOK_DIR/lib/filelock.sh" ]; then
  . "$HOOK_DIR/lib/filelock.sh"
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
AGENTS_DIR="$STATUS_DIR/agents"
mkdir -p "$AGENTS_DIR" 2>/dev/null
STATUS_FILE="$STATUS_DIR/agents.json"
HISTORY_FILE="$STATUS_DIR/history.json"

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

# --- Per-agent file (atomic write, no locking needed) ---
AGENT_FILE="$AGENTS_DIR/${AGENT_NAME}.json"

# Best-effort token usage capture
TOTAL_TOKENS="$(printf '%s' "$INPUT_JSON" | jq -r '.total_tokens // .usage.total_tokens // 0' 2>/dev/null)" || TOTAL_TOKENS=0
INPUT_TOKENS="$(printf '%s' "$INPUT_JSON" | jq -r '.input_tokens // .usage.input_tokens // 0' 2>/dev/null)" || INPUT_TOKENS=0
OUTPUT_TOKENS="$(printf '%s' "$INPUT_JSON" | jq -r '.output_tokens // .usage.output_tokens // 0' 2>/dev/null)" || OUTPUT_TOKENS=0
TOOL_USES="$(printf '%s' "$INPUT_JSON" | jq -r '.tool_uses // .usage.tool_uses // 0' 2>/dev/null)" || TOOL_USES=0

case "$EVENT_TYPE" in
  SubagentStart)
    # Write per-agent file atomically (write to temp, then mv)
    TMPFILE="$(mktemp "$AGENT_FILE.XXXXXX" 2>/dev/null)" || exit 0
    cat > "$TMPFILE" <<AGENTJSON
{
  "status": "running",
  "started_at": "$TIMESTAMP",
  "department": "$DEPARTMENT",
  "error_count": 0
}
AGENTJSON
    mv "$TMPFILE" "$AGENT_FILE" 2>/dev/null
    ;;
  SubagentStop)
    # Read started_at from existing agent file
    STARTED_AT=""
    if [ -f "$AGENT_FILE" ]; then
      STARTED_AT="$(jq -r '.started_at // empty' "$AGENT_FILE" 2>/dev/null)"
      EXISTING_ERRORS="$(jq -r '.error_count // 0' "$AGENT_FILE" 2>/dev/null)" || EXISTING_ERRORS=0
    fi

    # Compute duration
    DURATION=0
    if [ -n "$STARTED_AT" ] && command -v date >/dev/null 2>&1; then
      START_EPOCH="$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%SZ" "$STARTED_AT" +%s 2>/dev/null)" || \
      START_EPOCH="$(date -d "$STARTED_AT" +%s 2>/dev/null)" || START_EPOCH=0
      NOW_EPOCH="$(date -u +%s 2>/dev/null)" || NOW_EPOCH=0
      if [ "$START_EPOCH" -gt 0 ] 2>/dev/null && [ "$NOW_EPOCH" -gt 0 ] 2>/dev/null; then
        DURATION=$(( NOW_EPOCH - START_EPOCH ))
      fi
    fi

    # Write completed agent file atomically
    TMPFILE="$(mktemp "$AGENT_FILE.XXXXXX" 2>/dev/null)" || exit 0
    cat > "$TMPFILE" <<AGENTJSON
{
  "status": "completed",
  "started_at": "${STARTED_AT:-$TIMESTAMP}",
  "completed_at": "$TIMESTAMP",
  "department": "$DEPARTMENT",
  "error_count": ${EXISTING_ERRORS:-0},
  "duration_seconds": $DURATION,
  "tokens": {
    "total": $TOTAL_TOKENS,
    "input": $INPUT_TOKENS,
    "output": $OUTPUT_TOKENS,
    "tool_uses": $TOOL_USES
  }
}
AGENTJSON
    mv "$TMPFILE" "$AGENT_FILE" 2>/dev/null

    # --- Session history (best-effort, non-critical) ---
    if [ ! -f "$HISTORY_FILE" ] || ! jq empty "$HISTORY_FILE" 2>/dev/null; then
      printf '{"sessions":[]}' > "$HISTORY_FILE"
    fi
    HIST_TMP="$(mktemp "${HISTORY_FILE}.XXXXXX" 2>/dev/null)"
    if [ -n "$HIST_TMP" ]; then
      jq --arg sid "$SESSION_ID" \
         --arg agent "$AGENT_NAME" \
         --arg dept "$DEPARTMENT" \
         --arg ts "$TIMESTAMP" \
         --arg started "${STARTED_AT:-$TIMESTAMP}" \
         --argjson dur "$DURATION" \
         --argjson tokens "$TOTAL_TOKENS" \
         '(.sessions |= (
           if any(.session_id == $sid) then
             map(if .session_id == $sid then
               .agents += [{"name": $agent, "department": $dept, "started_at": $started, "completed_at": $ts, "duration_seconds": $dur, "tokens": $tokens}] |
               .updated_at = $ts |
               .total_duration = ([.agents[].duration_seconds] | add) |
               .total_tokens = ([.agents[].tokens] | add)
             else . end)
           else
             . + [{"session_id": $sid, "started_at": $started, "updated_at": $ts, "total_duration": $dur, "total_tokens": $tokens,
               "agents": [{"name": $agent, "department": $dept, "started_at": $started, "completed_at": $ts, "duration_seconds": $dur, "tokens": $tokens}]}]
           end
         )) | .sessions = (.sessions | .[-50:])' "$HISTORY_FILE" > "$HIST_TMP" 2>/dev/null && mv "$HIST_TMP" "$HISTORY_FILE"
      rm -f "$HIST_TMP" 2>/dev/null
    fi
    ;;
esac

# --- Assemble agents.json from per-agent files (with lock for concurrent safety) ---
if type acquire_lock >/dev/null 2>&1; then acquire_lock "$STATUS_FILE"; fi
ASSEMBLED='{"session_id":"'"$SESSION_ID"'","updated_at":"'"$TIMESTAMP"'","agents":{}}'
for agent_file in "$AGENTS_DIR"/*.json; do
  [ -f "$agent_file" ] || continue
  agent_basename="$(basename "$agent_file" .json)"
  agent_data="$(cat "$agent_file" 2>/dev/null)" || continue
  ASSEMBLED="$(printf '%s' "$ASSEMBLED" | jq --arg name "$agent_basename" --argjson data "$agent_data" '.agents[$name] = $data' 2>/dev/null)" || continue
done
ASSEMBLE_TMP="$(mktemp "${STATUS_FILE}.XXXXXX" 2>/dev/null)"
if [ -n "$ASSEMBLE_TMP" ]; then
  printf '%s' "$ASSEMBLED" > "$ASSEMBLE_TMP" && mv "$ASSEMBLE_TMP" "$STATUS_FILE" 2>/dev/null
  rm -f "$ASSEMBLE_TMP" 2>/dev/null
fi
if type release_lock >/dev/null 2>&1; then release_lock "$STATUS_FILE"; fi

# --- Notification: check if all agents are completed ---
if [ "$EVENT_TYPE" = "SubagentStop" ]; then
  STILL_RUNNING=0
  TOTAL_AGENTS=0
  for agent_file in "$AGENTS_DIR"/*.json; do
    [ -f "$agent_file" ] || continue
    TOTAL_AGENTS=$((TOTAL_AGENTS + 1))
    status="$(jq -r '.status' "$agent_file" 2>/dev/null)"
    [ "$status" = "running" ] && STILL_RUNNING=$((STILL_RUNNING + 1))
  done

  if [ "$STILL_RUNNING" -eq 0 ] && [ "$TOTAL_AGENTS" -gt 0 ]; then
    NOTIFY_MSG="All $TOTAL_AGENTS agents completed"
    if command -v osascript >/dev/null 2>&1; then
      osascript -e "display notification \"$NOTIFY_MSG\" with title \"Agent Dashboard\"" 2>/dev/null
    elif command -v notify-send >/dev/null 2>&1; then
      notify-send "Agent Dashboard" "$NOTIFY_MSG" --urgency=normal 2>/dev/null
    fi
  fi
fi

exit 0
