#!/bin/bash
# Agent Dashboard — Live terminal UI for monitoring agent progress
# Usage: ./scripts/agent-dashboard.sh [--no-color] [--once]
#
# Reads .claude/status/agents.json and .claude/status/todos/*.json
# to display real-time agent status with task progress.

set -euo pipefail

# --- Configuration ---
REFRESH_INTERVAL=1
STATUS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/status"
AGENTS_FILE="$STATUS_DIR/agents.json"
TODOS_DIR="$STATUS_DIR/todos"
STALE_THRESHOLD=3600  # 1 hour in seconds

# --- Color codes ---
USE_COLOR=true
for arg in "$@"; do
  case "$arg" in
    --no-color) USE_COLOR=false ;;
    --once) RUN_ONCE=true ;;
  esac
done

if [ "$USE_COLOR" = true ]; then
  RESET="\033[0m"
  BOLD="\033[1m"
  DIM="\033[2m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  RED="\033[31m"
  CYAN="\033[36m"
  MAGENTA="\033[35m"
  WHITE="\033[37m"
  BG_BLUE="\033[44m"
  BG_BLACK="\033[40m"
else
  RESET="" BOLD="" DIM="" GREEN="" YELLOW="" RED="" CYAN="" MAGENTA="" WHITE="" BG_BLUE="" BG_BLACK=""
fi

# --- Dependency check ---
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required. Install with: apt-get install jq / brew install jq"
  exit 1
fi

# --- Terminal cleanup on exit ---
cleanup() {
  printf '\033[?25h'  # show cursor
  stty echo 2>/dev/null
  printf '\n'
  exit 0
}
trap cleanup INT TERM EXIT

# --- Helper functions ---
format_duration() {
  local seconds=$1
  if [ "$seconds" -lt 60 ]; then
    printf '%ds' "$seconds"
  elif [ "$seconds" -lt 3600 ]; then
    printf '%dm %ds' $((seconds / 60)) $((seconds % 60))
  else
    printf '%dh %dm' $((seconds / 3600)) $(((seconds % 3600) / 60))
  fi
}

progress_bar() {
  local completed=$1 total=$2 width=${3:-8}
  if [ "$total" -eq 0 ]; then
    printf '%*s' "$width" ''
    return
  fi
  local filled=$(( (completed * width) / total ))
  local empty=$(( width - filled ))
  printf '%s' "${GREEN}"
  for ((i=0; i<filled; i++)); do printf '%s' "█"; done
  printf '%s' "${DIM}"
  for ((i=0; i<empty; i++)); do printf '%s' "░"; done
  printf '%s' "${RESET}"
}

# Department display order
DEPARTMENTS=("Product" "Engineering" "Quality" "Operations" "Marketing" "Support" "IT" "Orchestrator" "Other")

# --- View state ---
VIEW_MODE="overview"  # overview or detail
DETAIL_AGENT=""
AGENT_INDEX_MAP=()

# --- Render overview ---
render_overview() {
  local now_epoch
  now_epoch="$(date -u +%s 2>/dev/null)" || now_epoch=0
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  # Parse agents.json
  if [ ! -f "$AGENTS_FILE" ] || ! jq empty "$AGENTS_FILE" 2>/dev/null; then
    printf '\033[2J\033[H'  # clear screen
    printf '%s' "${BOLD}${BG_BLUE}${WHITE}"
    printf '  %-56s\n' "AGENT DASHBOARD"
    printf '  %-56s\n' "$current_time"
    printf '%s\n' "${RESET}"
    printf '\n'
    printf '  %s\n' "${DIM}No active session. Waiting for agents...${RESET}"
    printf '\n'
    printf '  %s\n' "The dashboard auto-refreshes every ${REFRESH_INTERVAL}s."
    printf '  %s\n' "Start a multi-agent task (e.g., /implement-feature) to see activity."
    printf '\n'
    printf '  %s\n' "${DIM}[q] quit${RESET}"
    return
  fi

  local session_id
  session_id="$(jq -r '.session_id // "unknown"' "$AGENTS_FILE" 2>/dev/null)"
  local short_session="${session_id:0:12}"

  # Collect active/completed counts
  local active_count completed_count total_count earliest_start
  active_count="$(jq '[.agents | to_entries[] | select(.value.status == "running")] | length' "$AGENTS_FILE" 2>/dev/null)" || active_count=0
  completed_count="$(jq '[.agents | to_entries[] | select(.value.status == "completed")] | length' "$AGENTS_FILE" 2>/dev/null)" || completed_count=0
  total_count="$(jq '[.agents | to_entries[]] | length' "$AGENTS_FILE" 2>/dev/null)" || total_count=0
  earliest_start="$(jq -r '[.agents[].started_at] | sort | first // empty' "$AGENTS_FILE" 2>/dev/null)"

  local session_duration="--"
  if [ -n "$earliest_start" ]; then
    local start_epoch
    start_epoch="$(date -d "$earliest_start" +%s 2>/dev/null)" || start_epoch=0
    if [ "$start_epoch" -gt 0 ] && [ "$now_epoch" -gt 0 ]; then
      session_duration="$(format_duration $((now_epoch - start_epoch)))"
    fi
  fi

  # Clear and render
  printf '\033[2J\033[H'

  # Header
  printf "${BOLD}${BG_BLUE}${WHITE}%-60s${RESET}\n" "  AGENT DASHBOARD                          $current_time"
  printf "${BG_BLUE}${WHITE}%-60s${RESET}\n" "  Session: $short_session                    Refresh: ${REFRESH_INTERVAL}s"
  printf '%s\n' "$(printf '─%.0s' {1..60})"

  # Build agent index for keyboard navigation
  AGENT_INDEX_MAP=()
  local idx=0

  for dept in "${DEPARTMENTS[@]}"; do
    # Get agents in this department
    local agents_in_dept
    agents_in_dept="$(jq -r --arg d "$dept" '
      [.agents | to_entries[] | select(.value.department == $d) | .key] | .[]
    ' "$AGENTS_FILE" 2>/dev/null)"

    if [ -z "$agents_in_dept" ]; then
      continue
    fi

    printf '\n'
    printf '  %s%s%s\n' "${BOLD}${MAGENTA}" "$dept" "${RESET}"

    while IFS= read -r agent; do
      [ -z "$agent" ] && continue
      idx=$((idx + 1))
      AGENT_INDEX_MAP+=("$agent")

      local status started_at
      status="$(jq -r --arg a "$agent" '.agents[$a].status // "unknown"' "$AGENTS_FILE" 2>/dev/null)"
      started_at="$(jq -r --arg a "$agent" '.agents[$a].started_at // empty' "$AGENTS_FILE" 2>/dev/null)"

      # Duration
      local duration_str=""
      if [ "$status" = "running" ] && [ -n "$started_at" ]; then
        local s_epoch
        s_epoch="$(date -d "$started_at" +%s 2>/dev/null)" || s_epoch=0
        if [ "$s_epoch" -gt 0 ] && [ "$now_epoch" -gt 0 ]; then
          local dur=$((now_epoch - s_epoch))
          duration_str="$(format_duration $dur)"
          # Stale warning
          if [ "$dur" -gt "$STALE_THRESHOLD" ]; then
            duration_str="${RED}${duration_str} STALE${RESET}"
          fi
        fi
      elif [ "$status" = "completed" ]; then
        local dur_s
        dur_s="$(jq -r --arg a "$agent" '.agents[$a].duration_seconds // 0' "$AGENTS_FILE" 2>/dev/null)" || dur_s=0
        duration_str="$(format_duration "$dur_s")"
      fi

      # Status indicator
      local indicator label
      case "$status" in
        running)
          indicator="${YELLOW}${BOLD}●${RESET}"
          label="${YELLOW}RUNNING${RESET}"
          ;;
        completed)
          indicator="${GREEN}✓${RESET}"
          label="${GREEN}DONE${RESET}"
          ;;
        *)
          indicator="${DIM}○${RESET}"
          label="${DIM}IDLE${RESET}"
          ;;
      esac

      # Todo progress (inline mini bar)
      local todo_progress=""
      local todo_file="$TODOS_DIR/${agent}.json"
      if [ -f "$todo_file" ] && jq empty "$todo_file" 2>/dev/null; then
        local t_completed t_total
        t_completed="$(jq '.progress.completed // 0' "$todo_file" 2>/dev/null)" || t_completed=0
        t_total="$(jq '.progress.total // 0' "$todo_file" 2>/dev/null)" || t_total=0
        if [ "$t_total" -gt 0 ]; then
          todo_progress=" $(progress_bar "$t_completed" "$t_total" 6) ${t_completed}/${t_total}"
        fi
      fi

      printf "  ${DIM}[%d]${RESET} %b %-22s %b  %-8s%b\n" \
        "$idx" "$indicator" "$agent" "$label" "$duration_str" "$todo_progress"

    done <<< "$agents_in_dept"
  done

  # Footer
  printf '\n%s\n' "$(printf '─%.0s' {1..60})"
  printf "  Active: ${YELLOW}%d${RESET}  │  Completed: ${GREEN}%d${RESET}  │  Session: %s\n" \
    "$active_count" "$completed_count" "$session_duration"
  printf '%s\n' "$(printf '─%.0s' {1..60})"
  printf "  ${DIM}[1-%d] detail view  │  [r] reset  │  [q] quit${RESET}\n" "$idx"
}

# --- Render detail view ---
render_detail() {
  local agent="$1"
  local now_epoch
  now_epoch="$(date -u +%s 2>/dev/null)" || now_epoch=0
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  printf '\033[2J\033[H'

  # Get agent info
  local status department started_at duration_str=""
  status="$(jq -r --arg a "$agent" '.agents[$a].status // "unknown"' "$AGENTS_FILE" 2>/dev/null)"
  department="$(jq -r --arg a "$agent" '.agents[$a].department // "Unknown"' "$AGENTS_FILE" 2>/dev/null)"
  started_at="$(jq -r --arg a "$agent" '.agents[$a].started_at // empty' "$AGENTS_FILE" 2>/dev/null)"

  if [ "$status" = "running" ] && [ -n "$started_at" ]; then
    local s_epoch
    s_epoch="$(date -d "$started_at" +%s 2>/dev/null)" || s_epoch=0
    if [ "$s_epoch" -gt 0 ] && [ "$now_epoch" -gt 0 ]; then
      duration_str="$(format_duration $((now_epoch - s_epoch)))"
    fi
  elif [ "$status" = "completed" ]; then
    local dur_s
    dur_s="$(jq -r --arg a "$agent" '.agents[$a].duration_seconds // 0' "$AGENTS_FILE" 2>/dev/null)" || dur_s=0
    duration_str="$(format_duration "$dur_s")"
  fi

  local status_display
  case "$status" in
    running) status_display="${YELLOW}${BOLD}RUNNING${RESET}" ;;
    completed) status_display="${GREEN}DONE${RESET}" ;;
    *) status_display="${DIM}IDLE${RESET}" ;;
  esac

  # Header
  printf "${BOLD}${BG_BLUE}${WHITE}%-60s${RESET}\n" "  AGENT DETAIL: $agent"
  printf "${BG_BLUE}${WHITE}%-60s${RESET}\n" "  Department: $department                   $current_time"
  printf '%s\n' "$(printf '─%.0s' {1..60})"
  printf '\n'
  printf "  Status: %b" "$status_display"
  if [ -n "$duration_str" ]; then
    printf " (%s)" "$duration_str"
  fi
  printf '\n\n'

  # Tasks
  local todo_file="$TODOS_DIR/${agent}.json"
  if [ -f "$todo_file" ] && jq empty "$todo_file" 2>/dev/null; then
    local t_completed t_in_progress t_pending t_total
    t_completed="$(jq '.progress.completed // 0' "$todo_file" 2>/dev/null)" || t_completed=0
    t_in_progress="$(jq '.progress.in_progress // 0' "$todo_file" 2>/dev/null)" || t_in_progress=0
    t_pending="$(jq '.progress.pending // 0' "$todo_file" 2>/dev/null)" || t_pending=0
    t_total="$(jq '.progress.total // 0' "$todo_file" 2>/dev/null)" || t_total=0

    printf '  %s%sTasks:%s\n' "${BOLD}" "${WHITE}" "${RESET}"

    # Read each todo
    jq -r '.todos[] | "\(.status)\t\(.content)"' "$todo_file" 2>/dev/null | while IFS=$'\t' read -r t_status t_content; do
      case "$t_status" in
        completed)   printf '  %s✓ %s%s\n' "${GREEN}" "$t_content" "${RESET}" ;;
        in_progress) printf '  %s● %s%s\n' "${YELLOW}${BOLD}" "$t_content" "${RESET}" ;;
        pending)     printf '  %s○ %s%s\n' "${DIM}" "$t_content" "${RESET}" ;;
      esac
    done

    printf '\n'

    # Progress bar
    if [ "$t_total" -gt 0 ]; then
      local pct=$(( (t_completed * 100) / t_total ))
      printf '  Progress: '
      progress_bar "$t_completed" "$t_total" 16
      printf ' %d/%d (%d%%)\n' "$t_completed" "$t_total" "$pct"
    fi
  else
    printf '  %sNo task data available for this agent.%s\n' "${DIM}" "${RESET}"
    printf '  %sTasks appear when the agent uses TodoWrite.%s\n' "${DIM}" "${RESET}"
  fi

  printf '\n%s\n' "$(printf '─%.0s' {1..60})"
  printf "  ${DIM}[b] back to overview  │  [q] quit${RESET}\n"
}

# --- Main loop ---
printf '\033[?25l'  # hide cursor

while true; do
  case "$VIEW_MODE" in
    overview)
      render_overview
      ;;
    detail)
      render_detail "$DETAIL_AGENT"
      ;;
  esac

  # Check for --once flag
  if [ "${RUN_ONCE:-false}" = "true" ]; then
    break
  fi

  # Non-blocking key read (1 second timeout)
  if read -rsn1 -t "$REFRESH_INTERVAL" key 2>/dev/null; then
    case "$key" in
      q|Q)
        break
        ;;
      b|B)
        if [ "$VIEW_MODE" = "detail" ]; then
          VIEW_MODE="overview"
        fi
        ;;
      r|R)
        # Reset: remove status files
        rm -f "$AGENTS_FILE" "$TODOS_DIR"/*.json 2>/dev/null
        VIEW_MODE="overview"
        ;;
      [1-9])
        if [ "$VIEW_MODE" = "overview" ]; then
          local_idx=$((key - 1))
          if [ "$local_idx" -lt "${#AGENT_INDEX_MAP[@]}" ]; then
            DETAIL_AGENT="${AGENT_INDEX_MAP[$local_idx]}"
            VIEW_MODE="detail"
          fi
        fi
        ;;
    esac
  fi
done
