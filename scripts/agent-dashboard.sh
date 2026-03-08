#!/bin/bash
# Agent Dashboard — Live terminal UI for monitoring agent progress
#
# Usage:
#   ./scripts/agent-dashboard.sh              # Interactive live dashboard
#   ./scripts/agent-dashboard.sh --once       # Print once and exit
#   ./scripts/agent-dashboard.sh --no-color   # Disable colors
#   ./scripts/agent-dashboard.sh --history    # Show session history
#   ./scripts/agent-dashboard.sh --analytics  # Show agent performance analytics
#   ./scripts/agent-dashboard.sh --export     # Export current status as markdown
#   ./scripts/agent-dashboard.sh --web        # Launch web dashboard (opens browser)
#
# Interactive keys:
#   [1-9] = agent detail  [b] = back  [h] = history  [s] = stats
#   [e] = errors  [w] = workflow  [m] = messages  [c] = command
#   [r] = reset  [q] = quit

set -euo pipefail

# --- Configuration ---
REFRESH_INTERVAL=1
STATUS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/status"
AGENTS_FILE="$STATUS_DIR/agents.json"
TODOS_DIR="$STATUS_DIR/todos"
ERRORS_DIR="$STATUS_DIR/errors"
MESSAGES_DIR="$STATUS_DIR/messages"
HISTORY_FILE="$STATUS_DIR/history.json"
STALE_THRESHOLD=3600  # 1 hour
WEB_DIR="$(dirname "$0")/web"
WIDTH=64

# --- Parse arguments ---
USE_COLOR=true
RUN_ONCE=false
MODE=""
for arg in "$@"; do
  case "$arg" in
    --no-color) USE_COLOR=false ;;
    --once)     RUN_ONCE=true ;;
    --history)  MODE="history" ;;
    --analytics) MODE="analytics" ;;
    --export)   MODE="export" ;;
    --web)      MODE="web" ;;
  esac
done

# --- Color codes ---
if [ "$USE_COLOR" = true ]; then
  RESET="\033[0m"; BOLD="\033[1m"; DIM="\033[2m"
  GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"
  CYAN="\033[36m"; MAGENTA="\033[35m"; WHITE="\033[37m"
  BG_BLUE="\033[44m"; BG_RED="\033[41m"
else
  RESET="" BOLD="" DIM="" GREEN="" YELLOW="" RED=""
  CYAN="" MAGENTA="" WHITE="" BG_BLUE="" BG_RED=""
fi

# --- Dependency check ---
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required. Install with: apt-get install jq / brew install jq"
  exit 1
fi

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
  for ((i=0; i<filled; i++)); do printf '█'; done
  printf '%s' "${DIM}"
  for ((i=0; i<empty; i++)); do printf '░'; done
  printf '%s' "${RESET}"
}

separator() {
  printf '%s\n' "$(printf '─%.0s' $(seq 1 "$WIDTH"))"
}

# --- Department display order ---
DEPARTMENTS=("Orchestrator" "Product" "Engineering" "Quality" "Operations" "Marketing" "Support" "IT" "Other")

# --- Workflow phase inference ---
# Maps active agent patterns to workflow phases
infer_workflow_phase() {
  if [ ! -f "$AGENTS_FILE" ] || ! jq empty "$AGENTS_FILE" 2>/dev/null; then
    echo ""
    return
  fi

  local running completed
  running="$(jq -r '[.agents | to_entries[] | select(.value.status == "running") | .key] | join(",")' "$AGENTS_FILE" 2>/dev/null)"
  completed="$(jq -r '[.agents | to_entries[] | select(.value.status == "completed") | .key] | join(",")' "$AGENTS_FILE" 2>/dev/null)"

  # Infer phase from agent patterns
  if echo "$running" | grep -q "product-manager"; then
    echo "Phase 1: Requirements"
  elif echo "$running" | grep -q "architecture-agent"; then
    if echo "$completed" | grep -q "product-manager"; then
      echo "Phase 2: Design"
    else
      echo "Phase 2: Design"
    fi
  elif echo "$running" | grep -qE "backend-engineer|frontend-engineer|database-engineer"; then
    echo "Phase 3: Implementation"
  elif echo "$running" | grep -q "qa-agent"; then
    echo "Phase 4: Testing"
  elif echo "$running" | grep -q "security-agent"; then
    echo "Phase 5: Security Review"
  elif echo "$running" | grep -qE "devops-engineer|documentation-agent"; then
    echo "Phase 6: Deploy & Docs"
  elif echo "$running" | grep -q "master-orchestrator"; then
    echo "Orchestrating..."
  else
    local total_agents
    total_agents="$(jq '[.agents | to_entries[]] | length' "$AGENTS_FILE" 2>/dev/null)" || total_agents=0
    local done_count
    done_count="$(jq '[.agents | to_entries[] | select(.value.status == "completed")] | length' "$AGENTS_FILE" 2>/dev/null)" || done_count=0
    if [ "$total_agents" -gt 0 ] && [ "$done_count" -eq "$total_agents" ]; then
      echo "All Complete"
    elif [ "$total_agents" -gt 0 ]; then
      echo "In Progress"
    else
      echo ""
    fi
  fi
}

# --- Get agent error count ---
get_error_count() {
  local agent="$1"
  if [ -f "$AGENTS_FILE" ] && jq empty "$AGENTS_FILE" 2>/dev/null; then
    jq -r --arg a "$agent" '.agents[$a].error_count // 0' "$AGENTS_FILE" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

# --- Get agent token info ---
get_token_info() {
  local agent="$1"
  if [ -f "$AGENTS_FILE" ] && jq empty "$AGENTS_FILE" 2>/dev/null; then
    jq -r --arg a "$agent" '.agents[$a].tokens.total // 0' "$AGENTS_FILE" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

# --- View state ---
VIEW_MODE="overview"
DETAIL_AGENT=""
AGENT_INDEX_MAP=()

# ====================================================================
# MODE: --export (print markdown and exit)
# ====================================================================
handle_export() {
  echo "# Agent Dashboard Export"
  echo ""
  echo "**Generated**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  echo ""

  if [ ! -f "$AGENTS_FILE" ] || ! jq empty "$AGENTS_FILE" 2>/dev/null; then
    echo "No active session data."
    exit 0
  fi

  local session_id
  session_id="$(jq -r '.session_id // "unknown"' "$AGENTS_FILE" 2>/dev/null)"
  echo "**Session**: \`$session_id\`"

  local phase
  phase="$(infer_workflow_phase)"
  [ -n "$phase" ] && echo "**Workflow**: $phase"
  echo ""

  echo "## Agent Status"
  echo ""
  echo "| Agent | Department | Status | Duration | Tasks | Errors |"
  echo "|-------|-----------|--------|----------|-------|--------|"

  jq -r '.agents | to_entries[] | "\(.key)\t\(.value.department // "?")\t\(.value.status)\t\(.value.duration_seconds // 0)\t\(.value.error_count // 0)"' \
    "$AGENTS_FILE" 2>/dev/null | while IFS=$'\t' read -r name dept status dur errs; do
    local dur_str
    if [ "$status" = "completed" ] && [ "$dur" -gt 0 ]; then
      dur_str="$(format_duration "$dur")"
    elif [ "$status" = "running" ]; then
      dur_str="running..."
    else
      dur_str="--"
    fi

    # Todo progress
    local todo_str="--"
    local todo_file="$TODOS_DIR/${name}.json"
    if [ -f "$todo_file" ] && jq empty "$todo_file" 2>/dev/null; then
      local tc tt
      tc="$(jq '.progress.completed // 0' "$todo_file" 2>/dev/null)" || tc=0
      tt="$(jq '.progress.total // 0' "$todo_file" 2>/dev/null)" || tt=0
      [ "$tt" -gt 0 ] && todo_str="${tc}/${tt}"
    fi

    local err_str="$errs"
    [ "$errs" -gt 0 ] && err_str="**$errs**"

    echo "| $name | $dept | $status | $dur_str | $todo_str | $err_str |"
  done

  echo ""

  # Errors section
  if [ -d "$ERRORS_DIR" ]; then
    local has_errors=false
    for ef in "$ERRORS_DIR"/*.json; do
      [ -f "$ef" ] || continue
      local ecount
      ecount="$(jq '.errors | length' "$ef" 2>/dev/null)" || ecount=0
      if [ "$ecount" -gt 0 ]; then
        has_errors=true
        break
      fi
    done
    if [ "$has_errors" = true ]; then
      echo "## Errors"
      echo ""
      for ef in "$ERRORS_DIR"/*.json; do
        [ -f "$ef" ] || continue
        local agent_name
        agent_name="$(jq -r '.agent // "unknown"' "$ef" 2>/dev/null)"
        jq -r '.errors[] | "- **\(.tool)** (\(.timestamp)): \(.message)"' "$ef" 2>/dev/null | while read -r line; do
          echo "  $agent_name: $line"
        done
      done
      echo ""
    fi
  fi

  echo "---"
  echo "*Exported by agent-dashboard.sh*"
  exit 0
}

# ====================================================================
# MODE: --history (show session history and exit)
# ====================================================================
handle_history() {
  if [ ! -f "$HISTORY_FILE" ] || ! jq empty "$HISTORY_FILE" 2>/dev/null; then
    echo "No session history found."
    echo "History is recorded when agents complete during orchestrated sessions."
    exit 0
  fi

  local session_count
  session_count="$(jq '.sessions | length' "$HISTORY_FILE" 2>/dev/null)" || session_count=0

  printf "${BOLD}Session History${RESET} (%d sessions)\n\n" "$session_count"
  separator

  jq -r '.sessions | reverse | .[] |
    "SESSION:\(.session_id)\tSTARTED:\(.started_at // "?")\tDURATION:\(.total_duration // 0)\tTOKENS:\(.total_tokens // 0)\tAGENTS:\(.agents | length)"
  ' "$HISTORY_FILE" 2>/dev/null | head -20 | while IFS=$'\t' read -r sid started dur tokens agents; do
    local session_id="${sid#SESSION:}"
    local short_sid="${session_id:0:16}"
    local start_time="${started#STARTED:}"
    local total_dur="${dur#DURATION:}"
    local total_tok="${tokens#TOKENS:}"
    local agent_count="${agents#AGENTS:}"

    local dur_str="$(format_duration "$total_dur")"
    local tok_str="N/A"
    [ "$total_tok" -gt 0 ] && tok_str="$total_tok"

    printf "\n  ${BOLD}%s${RESET}  %s\n" "$short_sid" "$start_time"
    printf "  Agents: ${CYAN}%s${RESET}  Duration: ${YELLOW}%s${RESET}  Tokens: %s\n" \
      "$agent_count" "$dur_str" "$tok_str"

    # List agents in this session
    jq -r --arg sid "$session_id" '
      .sessions[] | select(.session_id == $sid) | .agents[] |
      "    \(.department)/\(.name) — \(.duration_seconds)s"
    ' "$HISTORY_FILE" 2>/dev/null | while read -r agent_line; do
      printf "  ${DIM}%s${RESET}\n" "$agent_line"
    done
  done

  printf '\n'
  separator
  printf "  ${DIM}Showing last 20 sessions (max 50 stored)${RESET}\n"
  exit 0
}

# ====================================================================
# MODE: --analytics (show agent performance stats and exit)
# ====================================================================
handle_analytics() {
  if [ ! -f "$HISTORY_FILE" ] || ! jq empty "$HISTORY_FILE" 2>/dev/null; then
    echo "No session history for analytics. Run some multi-agent tasks first."
    exit 0
  fi

  printf "${BOLD}Agent Performance Analytics${RESET}\n\n"
  separator

  # Per-agent stats: avg duration, total runs, total errors
  printf "\n  ${BOLD}%-24s %6s %8s %8s %8s${RESET}\n" "Agent" "Runs" "Avg" "Min" "Max"
  separator

  jq -r '
    [.sessions[].agents[]] | group_by(.name) | .[] |
    {
      name: .[0].name,
      department: .[0].department,
      runs: length,
      avg_dur: ([.[].duration_seconds] | add / length | floor),
      min_dur: ([.[].duration_seconds] | min),
      max_dur: ([.[].duration_seconds] | max),
      total_tokens: ([.[].tokens // 0] | add)
    } | "\(.name)\t\(.department)\t\(.runs)\t\(.avg_dur)\t\(.min_dur)\t\(.max_dur)\t\(.total_tokens)"
  ' "$HISTORY_FILE" 2>/dev/null | sort | while IFS=$'\t' read -r name dept runs avg mn mx tokens; do
    local avg_str="$(format_duration "$avg")"
    local min_str="$(format_duration "$mn")"
    local max_str="$(format_duration "$mx")"
    printf "  %-24s %6s %8s %8s %8s\n" "$name" "$runs" "$avg_str" "$min_str" "$max_str"
  done

  printf '\n'
  separator

  # Department summary
  printf "\n  ${BOLD}Department Summary${RESET}\n\n"
  printf "  ${BOLD}%-16s %6s %10s${RESET}\n" "Department" "Runs" "Avg Time"
  separator

  jq -r '
    [.sessions[].agents[]] | group_by(.department) | .[] |
    {
      dept: .[0].department,
      runs: length,
      avg_dur: ([.[].duration_seconds] | add / length | floor)
    } | "\(.dept)\t\(.runs)\t\(.avg_dur)"
  ' "$HISTORY_FILE" 2>/dev/null | sort | while IFS=$'\t' read -r dept runs avg; do
    local avg_str="$(format_duration "$avg")"
    printf "  %-16s %6s %10s\n" "$dept" "$runs" "$avg_str"
  done

  # Session trends
  printf '\n'
  separator
  printf "\n  ${BOLD}Session Trends (last 10)${RESET}\n\n"

  jq -r '
    .sessions | reverse | .[0:10] | reverse | .[] |
    "\(.started_at // "?")\t\(.agents | length)\t\(.total_duration // 0)"
  ' "$HISTORY_FILE" 2>/dev/null | while IFS=$'\t' read -r started agents dur; do
    local dur_str="$(format_duration "$dur")"
    printf "  %s  agents=%-3s  duration=%s\n" "${started:0:16}" "$agents" "$dur_str"
  done

  printf '\n'
  exit 0
}

# ====================================================================
# MODE: --web (launch web dashboard)
# ====================================================================
handle_web() {
  local html_file="$WEB_DIR/dashboard.html"
  if [ ! -f "$html_file" ]; then
    echo "Error: Web dashboard not found at $html_file"
    echo "Expected: scripts/web/dashboard.html"
    exit 1
  fi

  # Copy status files to web dir for serving
  mkdir -p "$WEB_DIR/data" 2>/dev/null
  [ -f "$AGENTS_FILE" ] && cp "$AGENTS_FILE" "$WEB_DIR/data/agents.json" 2>/dev/null
  [ -f "$HISTORY_FILE" ] && cp "$HISTORY_FILE" "$WEB_DIR/data/history.json" 2>/dev/null
  if [ -d "$ERRORS_DIR" ]; then
    mkdir -p "$WEB_DIR/data/errors" 2>/dev/null
    cp "$ERRORS_DIR"/*.json "$WEB_DIR/data/errors/" 2>/dev/null || true
  fi
  if [ -d "$TODOS_DIR" ]; then
    mkdir -p "$WEB_DIR/data/todos" 2>/dev/null
    cp "$TODOS_DIR"/*.json "$WEB_DIR/data/todos/" 2>/dev/null || true
  fi

  local port=8686
  local server_py="$WEB_DIR/server.py"
  echo "Starting web dashboard on http://localhost:$port"
  echo "Press Ctrl+C to stop."

  # Use custom server.py (supports message API) or fall back to static server
  if command -v python3 >/dev/null 2>&1; then
    if [ -f "$server_py" ]; then
      python3 "$server_py" "$port"
    else
      cd "$WEB_DIR" && python3 -m http.server "$port"
    fi
  elif command -v python >/dev/null 2>&1; then
    if [ -f "$server_py" ]; then
      python "$server_py" "$port"
    else
      cd "$WEB_DIR" && python -m http.server "$port"
    fi
  else
    echo "Error: Python is required for the web dashboard."
    echo "Install Python 3 or open $html_file directly in a browser."
    exit 1
  fi
  exit 0
}

# --- Handle non-interactive modes ---
case "$MODE" in
  export)    handle_export ;;
  history)   handle_history ;;
  analytics) handle_analytics ;;
  web)       handle_web ;;
esac

# ====================================================================
# INTERACTIVE DASHBOARD
# ====================================================================

# --- Terminal cleanup on exit ---
cleanup() {
  printf '\033[?25h'
  stty echo 2>/dev/null
  printf '\n'
  exit 0
}
trap cleanup INT TERM EXIT

# --- Render overview ---
render_overview() {
  local now_epoch
  now_epoch="$(date -u +%s 2>/dev/null)" || now_epoch=0
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  if [ ! -f "$AGENTS_FILE" ] || ! jq empty "$AGENTS_FILE" 2>/dev/null; then
    printf '\033[2J\033[H'
    printf "${BOLD}${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  AGENT DASHBOARD                          $current_time"
    printf "${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  No active session"
    separator
    printf '\n'
    printf '  %sNo active session. Waiting for agents...%s\n' "${DIM}" "${RESET}"
    printf '  %sStart a multi-agent task to see activity.%s\n' "${DIM}" "${RESET}"
    printf '\n'
    printf '  %s[h] history  [s] analytics  [q] quit%s\n' "${DIM}" "${RESET}"
    return
  fi

  local session_id short_session
  session_id="$(jq -r '.session_id // "unknown"' "$AGENTS_FILE" 2>/dev/null)"
  short_session="${session_id:0:12}"

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

  # Workflow phase
  local phase
  phase="$(infer_workflow_phase)"

  printf '\033[2J\033[H'

  # Header
  printf "${BOLD}${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  AGENT DASHBOARD                          $current_time"
  printf "${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  Session: $short_session                    Refresh: ${REFRESH_INTERVAL}s"
  if [ -n "$phase" ]; then
    printf "${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  Workflow: $phase"
  fi
  separator

  # Build agent index
  AGENT_INDEX_MAP=()
  local idx=0

  for dept in "${DEPARTMENTS[@]}"; do
    local agents_in_dept
    agents_in_dept="$(jq -r --arg d "$dept" '
      [.agents | to_entries[] | select(.value.department == $d) | .key] | .[]
    ' "$AGENTS_FILE" 2>/dev/null)"

    [ -z "$agents_in_dept" ] && continue

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
        running)   indicator="${YELLOW}${BOLD}●${RESET}"; label="${YELLOW}RUNNING${RESET}" ;;
        completed) indicator="${GREEN}✓${RESET}"; label="${GREEN}DONE${RESET}" ;;
        *)         indicator="${DIM}○${RESET}"; label="${DIM}IDLE${RESET}" ;;
      esac

      # Error indicator
      local err_count
      err_count="$(get_error_count "$agent")"
      local err_indicator=""
      if [ "$err_count" -gt 0 ] 2>/dev/null; then
        err_indicator=" ${RED}✗${err_count}${RESET}"
      fi

      # Todo progress
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

      printf "  ${DIM}[%d]${RESET} %b %-20s %b  %-8s%b%b\n" \
        "$idx" "$indicator" "$agent" "$label" "$duration_str" "$todo_progress" "$err_indicator"

    done <<< "$agents_in_dept"
  done

  # Footer
  printf '\n'
  separator
  printf "  Active: ${YELLOW}%d${RESET}  Completed: ${GREEN}%d${RESET}  Session: %s\n" \
    "$active_count" "$completed_count" "$session_duration"

  # Token usage (best-effort)
  local total_tokens
  total_tokens="$(jq '[.agents[].tokens.total // 0] | add // 0' "$AGENTS_FILE" 2>/dev/null)" || total_tokens=0
  if [ "$total_tokens" -gt 0 ] 2>/dev/null; then
    printf "  Tokens: ${CYAN}%s${RESET}\n" "$total_tokens"
  fi

  separator
  printf "  ${DIM}[1-%d] detail  [h] history  [s] stats  [e] errors  [w] workflow${RESET}\n" "$idx"
  printf "  ${DIM}[m] messages  [c] command  [q] quit${RESET}\n"
}

# --- Render detail view ---
render_detail() {
  local agent="$1"
  local now_epoch
  now_epoch="$(date -u +%s 2>/dev/null)" || now_epoch=0
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  printf '\033[2J\033[H'

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
    running)   status_display="${YELLOW}${BOLD}RUNNING${RESET}" ;;
    completed) status_display="${GREEN}DONE${RESET}" ;;
    *)         status_display="${DIM}IDLE${RESET}" ;;
  esac

  # Header
  printf "${BOLD}${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  AGENT DETAIL: $agent"
  printf "${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  Department: $department                   $current_time"
  separator
  printf '\n'
  printf "  Status: %b" "$status_display"
  [ -n "$duration_str" ] && printf " (%s)" "$duration_str"
  printf '\n'

  # Error count
  local err_count
  err_count="$(get_error_count "$agent")"
  if [ "$err_count" -gt 0 ] 2>/dev/null; then
    printf "  Errors: ${RED}%s${RESET}\n" "$err_count"
  fi

  # Tokens
  local tokens
  tokens="$(get_token_info "$agent")"
  if [ "$tokens" -gt 0 ] 2>/dev/null; then
    printf "  Tokens: ${CYAN}%s${RESET}\n" "$tokens"
  fi
  printf '\n'

  # Tasks
  local todo_file="$TODOS_DIR/${agent}.json"
  if [ -f "$todo_file" ] && jq empty "$todo_file" 2>/dev/null; then
    local t_completed t_in_progress t_pending t_total
    t_completed="$(jq '.progress.completed // 0' "$todo_file" 2>/dev/null)" || t_completed=0
    t_in_progress="$(jq '.progress.in_progress // 0' "$todo_file" 2>/dev/null)" || t_in_progress=0
    t_pending="$(jq '.progress.pending // 0' "$todo_file" 2>/dev/null)" || t_pending=0
    t_total="$(jq '.progress.total // 0' "$todo_file" 2>/dev/null)" || t_total=0

    printf '  %s%sTasks:%s\n' "${BOLD}" "${WHITE}" "${RESET}"

    jq -r '.todos[] | "\(.status)\t\(.content)"' "$todo_file" 2>/dev/null | while IFS=$'\t' read -r t_status t_content; do
      case "$t_status" in
        completed)   printf '  %s✓ %s%s\n' "${GREEN}" "$t_content" "${RESET}" ;;
        in_progress) printf '  %s● %s%s\n' "${YELLOW}${BOLD}" "$t_content" "${RESET}" ;;
        pending)     printf '  %s○ %s%s\n' "${DIM}" "$t_content" "${RESET}" ;;
      esac
    done

    printf '\n'
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

  # Recent errors
  local error_file="$ERRORS_DIR/${agent}.json"
  if [ -f "$error_file" ] && jq empty "$error_file" 2>/dev/null; then
    local ecount
    ecount="$(jq '.errors | length' "$error_file" 2>/dev/null)" || ecount=0
    if [ "$ecount" -gt 0 ]; then
      printf '\n'
      printf '  %s%sRecent Errors:%s\n' "${BOLD}" "${RED}" "${RESET}"
      jq -r '.errors | reverse | .[0:5][] | "\(.timestamp)\t\(.tool)\t\(.message)"' "$error_file" 2>/dev/null | \
        while IFS=$'\t' read -r ts tool msg; do
          local short_msg="${msg:0:50}"
          printf '  %s%s %s: %s%s\n' "${RED}" "${ts:11:8}" "$tool" "$short_msg" "${RESET}"
        done
    fi
  fi

  printf '\n'
  separator
  printf "  ${DIM}[b] back  │  [c] command  │  [e] errors  │  [q] quit${RESET}\n"
}

# --- Render errors view ---
render_errors() {
  local now_epoch
  now_epoch="$(date -u +%s 2>/dev/null)" || now_epoch=0
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  printf '\033[2J\033[H'
  printf "${BOLD}${BG_RED}${WHITE}%-${WIDTH}s${RESET}\n" "  ERROR LOG                                $current_time"
  separator

  if [ ! -d "$ERRORS_DIR" ]; then
    printf '\n  %sNo errors recorded.%s\n' "${DIM}" "${RESET}"
    printf '\n'
    separator
    printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
    return
  fi

  local has_errors=false
  for ef in "$ERRORS_DIR"/*.json; do
    [ -f "$ef" ] || continue
    if ! jq empty "$ef" 2>/dev/null; then continue; fi

    local agent_name
    agent_name="$(jq -r '.agent // "unknown"' "$ef" 2>/dev/null)"
    local ecount
    ecount="$(jq '.errors | length' "$ef" 2>/dev/null)" || ecount=0
    [ "$ecount" -eq 0 ] && continue

    has_errors=true
    printf '\n  %s%s%s (%d errors)\n' "${BOLD}${RED}" "$agent_name" "${RESET}" "$ecount"

    jq -r '.errors | reverse | .[0:5][] | "\(.timestamp)\t\(.tool)\t\(.message)"' "$ef" 2>/dev/null | \
      while IFS=$'\t' read -r ts tool msg; do
        local short_msg="${msg:0:60}"
        printf '    %s%s %s%s: %s\n' "${DIM}" "${ts:0:19}" "${RESET}${YELLOW}" "$tool" "${RESET}$short_msg"
      done
  done

  if [ "$has_errors" = false ]; then
    printf '\n  %sNo errors recorded. Clean run!%s\n' "${GREEN}" "${RESET}"
  fi

  printf '\n'
  separator
  printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
}

# --- Render workflow view ---
render_workflow() {
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  printf '\033[2J\033[H'
  printf "${BOLD}${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  WORKFLOW PHASES                          $current_time"
  separator

  if [ ! -f "$AGENTS_FILE" ] || ! jq empty "$AGENTS_FILE" 2>/dev/null; then
    printf '\n  %sNo active session.%s\n' "${DIM}" "${RESET}"
    printf '\n'
    separator
    printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
    return
  fi

  local phase
  phase="$(infer_workflow_phase)"

  # Define standard phases
  local -a phases=("Requirements" "Design" "Implementation" "Testing" "Security Review" "Deploy & Docs")
  local -a phase_agents=(
    "product-manager"
    "architecture-agent"
    "backend-engineer,frontend-engineer,database-engineer,prompt-engineer"
    "qa-agent"
    "security-agent"
    "devops-engineer,documentation-agent"
  )

  printf '\n'
  for i in "${!phases[@]}"; do
    local p="${phases[$i]}"
    local p_agents="${phase_agents[$i]}"
    local phase_num=$((i + 1))

    # Check status of agents in this phase
    local phase_status="pending"
    local any_running=false any_completed=false
    IFS=',' read -ra agent_list <<< "$p_agents"
    for pa in "${agent_list[@]}"; do
      local ast
      ast="$(jq -r --arg a "$pa" '.agents[$a].status // "none"' "$AGENTS_FILE" 2>/dev/null)"
      [ "$ast" = "running" ] && any_running=true
      [ "$ast" = "completed" ] && any_completed=true
    done

    if [ "$any_running" = true ]; then
      phase_status="running"
    elif [ "$any_completed" = true ]; then
      phase_status="completed"
    fi

    local icon color
    case "$phase_status" in
      completed) icon="✓"; color="${GREEN}" ;;
      running)   icon="●"; color="${YELLOW}${BOLD}" ;;
      pending)   icon="○"; color="${DIM}" ;;
    esac

    printf "  %b%s Phase %d: %s%s\n" "$color" "$icon" "$phase_num" "$p" "${RESET}"

    # Show agents under this phase
    for pa in "${agent_list[@]}"; do
      local ast
      ast="$(jq -r --arg a "$pa" '.agents[$a].status // "none"' "$AGENTS_FILE" 2>/dev/null)"
      if [ "$ast" != "none" ]; then
        local sub_icon
        case "$ast" in
          completed) sub_icon="${GREEN}✓${RESET}" ;;
          running)   sub_icon="${YELLOW}●${RESET}" ;;
          *)         sub_icon="${DIM}○${RESET}" ;;
        esac
        printf "      %b %s\n" "$sub_icon" "$pa"
      fi
    done
    printf '\n'
  done

  if [ -n "$phase" ]; then
    printf "  ${BOLD}Current: %s${RESET}\n" "$phase"
  fi

  printf '\n'
  separator
  printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
}

# --- Render history view (interactive) ---
render_history_interactive() {
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  printf '\033[2J\033[H'
  printf "${BOLD}${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  SESSION HISTORY                          $current_time"
  separator

  if [ ! -f "$HISTORY_FILE" ] || ! jq empty "$HISTORY_FILE" 2>/dev/null; then
    printf '\n  %sNo session history found.%s\n' "${DIM}" "${RESET}"
    printf '\n'
    separator
    printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
    return
  fi

  local session_count
  session_count="$(jq '.sessions | length' "$HISTORY_FILE" 2>/dev/null)" || session_count=0

  printf '\n  %s%d sessions recorded%s\n\n' "${DIM}" "$session_count" "${RESET}"

  jq -r '.sessions | reverse | .[0:10][] |
    "\(.session_id)\t\(.started_at // "?")\t\(.total_duration // 0)\t\(.agents | length)"
  ' "$HISTORY_FILE" 2>/dev/null | while IFS=$'\t' read -r sid started dur agents; do
    local short_sid="${sid:0:12}"
    local dur_str="$(format_duration "$dur")"
    printf "  ${CYAN}%s${RESET}  %s  agents=${YELLOW}%s${RESET}  dur=${GREEN}%s${RESET}\n" \
      "$short_sid" "${started:0:16}" "$agents" "$dur_str"
  done

  printf '\n'
  separator
  printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
}

# --- Render stats view (interactive) ---
render_stats_interactive() {
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  printf '\033[2J\033[H'
  printf "${BOLD}${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  AGENT ANALYTICS                          $current_time"
  separator

  if [ ! -f "$HISTORY_FILE" ] || ! jq empty "$HISTORY_FILE" 2>/dev/null; then
    printf '\n  %sNo history data for analytics.%s\n' "${DIM}" "${RESET}"
    printf '\n'
    separator
    printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
    return
  fi

  printf '\n  %s%-22s %5s %7s%s\n' "${BOLD}" "Agent" "Runs" "Avg" "${RESET}"
  separator

  jq -r '
    [.sessions[].agents[]] | group_by(.name) | .[] |
    "\(.[0].name)\t\(length)\t([.[].duration_seconds] | add / length | floor)"
  ' "$HISTORY_FILE" 2>/dev/null | sort | while IFS=$'\t' read -r name runs avg; do
    local avg_str="$(format_duration "$avg")"
    printf '  %-22s %5s %7s\n' "$name" "$runs" "$avg_str"
  done

  printf '\n'
  separator
  printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
}

# --- Render messages view ---
render_messages() {
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  printf '\033[2J\033[H'
  printf "${BOLD}${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  AGENT MESSAGES                           $current_time"
  separator

  if [ ! -d "$MESSAGES_DIR" ]; then
    printf '\n  %sNo messages directory found.%s\n' "${DIM}" "${RESET}"
    printf '\n'
    separator
    printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
    return
  fi

  local found=0
  for msg_file in "$MESSAGES_DIR"/*.json; do
    [ -f "$msg_file" ] || continue
    jq empty "$msg_file" 2>/dev/null || continue
    local agent_name
    agent_name="$(jq -r '.agent // "unknown"' "$msg_file" 2>/dev/null)"
    local total pending delivered acked
    total="$(jq '[.messages | length] | add // 0' "$msg_file" 2>/dev/null)" || total=0
    pending="$(jq '[.messages[] | select(.status == "pending")] | length' "$msg_file" 2>/dev/null)" || pending=0
    delivered="$(jq '[.messages[] | select(.status == "delivered")] | length' "$msg_file" 2>/dev/null)" || delivered=0
    acked="$(jq '[.messages[] | select(.status == "acknowledged")] | length' "$msg_file" 2>/dev/null)" || acked=0

    if [ "$total" -gt 0 ]; then
      found=1
      printf '\n  %s%s%s  total:%d' "${BOLD}" "$agent_name" "${RESET}" "$total"
      [ "$pending" -gt 0 ] && printf "  ${YELLOW}pending:%d${RESET}" "$pending"
      [ "$delivered" -gt 0 ] && printf "  ${CYAN}delivered:%d${RESET}" "$delivered"
      [ "$acked" -gt 0 ] && printf "  ${GREEN}acked:%d${RESET}" "$acked"
      printf '\n'

      # Show last 3 messages
      jq -r '.messages | reverse | .[0:3][] | "\(.status)\t\(.type)\t\(.from)\t\(.content[0:60])"' "$msg_file" 2>/dev/null | \
        while IFS=$'\t' read -r status mtype mfrom mcontent; do
          local color="$DIM"
          case "$status" in
            pending)      color="$YELLOW" ;;
            delivered)    color="$CYAN" ;;
            acknowledged) color="$GREEN" ;;
          esac
          printf '    %s[%s] %s → %s%s\n' "$color" "$mtype" "$mfrom" "$mcontent" "${RESET}"
        done
    fi
  done

  if [ "$found" -eq 0 ]; then
    printf '\n  %sNo messages yet. Use [c] to send a command.%s\n' "${DIM}" "${RESET}"
  fi

  printf '\n'
  separator
  printf "  ${DIM}[b] back  │  [c] command  │  [q] quit${RESET}\n"
}

# --- Write message to agent's message file ---
write_message_file() {
  local agent="$1" msg_type="$2" content="$3"
  mkdir -p "$MESSAGES_DIR" 2>/dev/null

  local msg_file="$MESSAGES_DIR/${agent}.json"
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local msg_id="msg_$(date +%s)_$(( $(date +%N 2>/dev/null || echo 0) / 1000000 % 1000 ))"

  local new_msg
  new_msg="$(cat <<MSGEOF
{
  "id": "$msg_id",
  "type": "$msg_type",
  "from": "user",
  "content": "$content",
  "priority": "normal",
  "status": "pending",
  "created_at": "$now",
  "delivered_at": null,
  "acknowledged_at": null,
  "response": null
}
MSGEOF
)"

  if [ -f "$msg_file" ] && jq empty "$msg_file" 2>/dev/null; then
    local tmp
    tmp="$(mktemp "${msg_file}.XXXXXX" 2>/dev/null)" || return 1
    jq --argjson msg "$new_msg" '.messages += [$msg]' "$msg_file" > "$tmp" 2>/dev/null && mv "$tmp" "$msg_file"
    rm -f "$tmp" 2>/dev/null
  else
    printf '{"agent":"%s","messages":[%s]}' "$agent" "$new_msg" | jq '.' > "$msg_file" 2>/dev/null
  fi
}

# --- Send message (interactive command mode) ---
send_message() {
  local target="$1"  # agent name or "master-orchestrator"

  printf '\033[2J\033[H'
  printf "${BOLD}${BG_BLUE}${WHITE}%-${WIDTH}s${RESET}\n" "  SEND COMMAND TO: $target"
  separator

  printf '\n  Message types: instruction, question, priority, note\n'
  if [ "$target" = "master-orchestrator" ]; then
    printf '  Orchestrator: reprioritize, pause-workflow, resume-workflow\n'
  fi
  printf '\n'

  # Show cursor for input
  printf '\033[?25h'

  printf '  Type [default=instruction]: '
  local msg_type=""
  read -r msg_type </dev/tty 2>/dev/null || msg_type=""
  msg_type="${msg_type:-instruction}"

  printf '  Message: '
  local content=""
  read -r content </dev/tty 2>/dev/null || content=""

  # Hide cursor again
  printf '\033[?25l'

  if [ -z "$content" ]; then
    printf '\n  %sCancelled (empty message).%s\n' "${YELLOW}" "${RESET}"
    sleep 1
    return
  fi

  # Escape quotes in content for JSON safety
  content="$(printf '%s' "$content" | sed 's/\\/\\\\/g; s/"/\\"/g')"

  if command -v jq >/dev/null 2>&1; then
    write_message_file "$target" "$msg_type" "$content"
    printf '\n  %s✓ Message sent to %s%s\n' "${GREEN}" "$target" "${RESET}"
  else
    printf '\n  %sError: jq is required for messaging.%s\n' "${RED}" "${RESET}"
  fi
  sleep 1
}

# --- Main loop ---
printf '\033[?25l'  # hide cursor

while true; do
  case "$VIEW_MODE" in
    overview)  render_overview ;;
    detail)    render_detail "$DETAIL_AGENT" ;;
    errors)    render_errors ;;
    workflow)  render_workflow ;;
    history)   render_history_interactive ;;
    stats)     render_stats_interactive ;;
    messages)  render_messages ;;
  esac

  if [ "$RUN_ONCE" = "true" ]; then
    break
  fi

  if read -rsn1 -t "$REFRESH_INTERVAL" key 2>/dev/null; then
    case "$key" in
      q|Q) break ;;
      b|B)
        if [ "$VIEW_MODE" != "overview" ]; then
          VIEW_MODE="overview"
        fi
        ;;
      h|H) VIEW_MODE="history" ;;
      s|S) VIEW_MODE="stats" ;;
      e|E) VIEW_MODE="errors" ;;
      w|W) VIEW_MODE="workflow" ;;
      m|M) VIEW_MODE="messages" ;;
      c|C)
        if [ "$VIEW_MODE" = "detail" ] && [ -n "$DETAIL_AGENT" ]; then
          send_message "$DETAIL_AGENT"
        else
          send_message "master-orchestrator"
        fi
        ;;
      r|R)
        if [ "$VIEW_MODE" = "overview" ]; then
          rm -f "$AGENTS_FILE" "$TODOS_DIR"/*.json "$ERRORS_DIR"/*.json 2>/dev/null
        fi
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
