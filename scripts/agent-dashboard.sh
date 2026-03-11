#!/bin/bash
# Agent Dashboard — Live terminal UI for monitoring agent progress
#
# Usage:
#   ./scripts/agent-dashboard.sh                    # Interactive live dashboard
#   ./scripts/agent-dashboard.sh --session <id>     # Open specific session by ID
#   ./scripts/agent-dashboard.sh --sessions         # Show session list and pick one
#   ./scripts/agent-dashboard.sh --once             # Print once and exit
#   ./scripts/agent-dashboard.sh --no-color         # Disable colors
#   ./scripts/agent-dashboard.sh --history          # Show session history
#   ./scripts/agent-dashboard.sh --analytics        # Show agent performance analytics
#   ./scripts/agent-dashboard.sh --export           # Export current status as markdown
#   ./scripts/agent-dashboard.sh --web              # Launch web dashboard (opens browser)
#   ./scripts/agent-dashboard.sh --web-docker       # Launch web dashboard via Docker Compose
#
# Interactive keys:
#   [1-9] = agent detail  [b] = back  [h] = history  [s] = stats
#   [e] = errors  [w] = workflow  [m] = messages  [c] = command
#   [l] = session list  [r] = reset  [q] = quit

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
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEB_DIR="$SCRIPT_DIR/web"

# --- Adaptive terminal width ---
get_term_width() {
  local w
  w=$(tput cols 2>/dev/null || echo 80)
  [ "$w" -lt 60 ] && w=60
  [ "$w" -gt 200 ] && w=200
  echo "$w"
}
WIDTH=$(get_term_width)

# --- Parse arguments ---
USE_COLOR=true
RUN_ONCE=false
MODE=""
TARGET_SESSION=""
SKIP_NEXT=false
args=("$@")
for i in "${!args[@]}"; do
  if [ "$SKIP_NEXT" = true ]; then
    SKIP_NEXT=false
    continue
  fi
  case "${args[$i]}" in
    --no-color)  USE_COLOR=false ;;
    --once)      RUN_ONCE=true ;;
    --history)   MODE="history" ;;
    --analytics) MODE="analytics" ;;
    --export)    MODE="export" ;;
    --web)       MODE="web" ;;
    --web-docker) MODE="web-docker" ;;
    --sessions)  MODE="sessions" ;;
    --session)
      if [ -n "${args[$((i+1))]:-}" ]; then
        TARGET_SESSION="${args[$((i+1))]}"
        SKIP_NEXT=true
      else
        echo "Error: --session requires a session ID argument"
        echo "Usage: $0 --session <session-id>"
        exit 1
      fi
      ;;
  esac
done

# --- Color codes ---
if [ "$USE_COLOR" = true ]; then
  RESET="\033[0m"; BOLD="\033[1m"; DIM="\033[2m"
  GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"
  CYAN="\033[36m"; MAGENTA="\033[35m"; WHITE="\033[37m"
  BLUE="\033[34m"
  BG_BLUE="\033[44m"; BG_RED="\033[41m"
  BRIGHT_GREEN="\033[92m"; BRIGHT_YELLOW="\033[93m"; BRIGHT_RED="\033[91m"
  BRIGHT_CYAN="\033[96m"; BRIGHT_MAGENTA="\033[95m"
else
  RESET="" BOLD="" DIM="" GREEN="" YELLOW="" RED=""
  CYAN="" MAGENTA="" WHITE="" BLUE=""
  BG_BLUE="" BG_RED=""
  BRIGHT_GREEN="" BRIGHT_YELLOW="" BRIGHT_RED=""
  BRIGHT_CYAN="" BRIGHT_MAGENTA=""
fi

# --- Dependency check ---
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required. Install with: apt-get install jq / brew install jq"
  exit 1
fi

# --- Session management ---
VIEWING_HISTORY_SESSION=false

resolve_session_target() {
  if [ -z "$TARGET_SESSION" ]; then
    return
  fi

  if [ -f "$AGENTS_FILE" ] && jq empty "$AGENTS_FILE" 2>/dev/null; then
    local current_sid
    current_sid="$(jq -r '.session_id // ""' "$AGENTS_FILE" 2>/dev/null)"
    if [ -n "$current_sid" ]; then
      if [ "$current_sid" = "$TARGET_SESSION" ] || \
         [[ "$current_sid" == "$TARGET_SESSION"* ]]; then
        return
      fi
    fi
  fi

  if [ -f "$HISTORY_FILE" ] && jq empty "$HISTORY_FILE" 2>/dev/null; then
    local match
    match="$(jq -r --arg sid "$TARGET_SESSION" '
      .sessions[] | select(.session_id == $sid or (.session_id | startswith($sid))) |
      .session_id
    ' "$HISTORY_FILE" 2>/dev/null | head -1)"

    if [ -n "$match" ]; then
      TARGET_SESSION="$match"
      VIEWING_HISTORY_SESSION=true
      return
    fi
  fi

  echo "Error: Session '$TARGET_SESSION' not found in active session or history."
  echo ""
  echo "Available sessions:"
  if [ -f "$AGENTS_FILE" ] && jq empty "$AGENTS_FILE" 2>/dev/null; then
    local active_sid
    active_sid="$(jq -r '.session_id // ""' "$AGENTS_FILE" 2>/dev/null)"
    [ -n "$active_sid" ] && echo "  [active] $active_sid"
  fi
  if [ -f "$HISTORY_FILE" ] && jq empty "$HISTORY_FILE" 2>/dev/null; then
    jq -r '.sessions | reverse | .[0:10][] | "  [history] \(.session_id)  (\(.started_at // "?"))"' \
      "$HISTORY_FILE" 2>/dev/null
  fi
  exit 1
}

count_sessions() {
  local count=0
  if [ -f "$AGENTS_FILE" ] && jq empty "$AGENTS_FILE" 2>/dev/null; then
    local has_agents
    has_agents="$(jq '[.agents | to_entries[]] | length' "$AGENTS_FILE" 2>/dev/null)" || has_agents=0
    [ "$has_agents" -gt 0 ] && count=$((count + 1))
  fi
  if [ -f "$HISTORY_FILE" ] && jq empty "$HISTORY_FILE" 2>/dev/null; then
    local hist_count
    hist_count="$(jq '.sessions | length' "$HISTORY_FILE" 2>/dev/null)" || hist_count=0
    count=$((count + hist_count))
  fi
  echo "$count"
}

build_history_agents_file() {
  local session_id="$1"
  local tmp_file="$STATUS_DIR/.history_view.json"

  jq --arg sid "$session_id" '
    .sessions[] | select(.session_id == $sid) |
    {
      session_id: .session_id,
      started_at: .started_at,
      agents: (
        [.agents[] | {key: .name, value: {
          status: "completed",
          department: .department,
          started_at: .started_at,
          duration_seconds: .duration_seconds,
          tokens: {total: (.tokens // 0)},
          error_count: (.errors // 0)
        }}] | from_entries
      )
    }
  ' "$HISTORY_FILE" > "$tmp_file" 2>/dev/null

  echo "$tmp_file"
}

resolve_session_target

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
  printf '%b' "${BRIGHT_GREEN}"
  for ((i=0; i<filled; i++)); do printf '▓'; done
  printf '%b' "${DIM}"
  for ((i=0; i<empty; i++)); do printf '░'; done
  printf '%b' "${RESET}"
}

# --- Box drawing helpers ---
draw_box_top() {
  local w=${1:-$WIDTH}
  printf '┌'; printf '─%.0s' $(seq 1 $((w - 2))); printf '┐\n'
}

draw_box_bottom() {
  local w=${1:-$WIDTH}
  printf '└'; printf '─%.0s' $(seq 1 $((w - 2))); printf '┘\n'
}

draw_box_separator() {
  local w=${1:-$WIDTH}
  printf '├'; printf '─%.0s' $(seq 1 $((w - 2))); printf '┤\n'
}

draw_box_line() {
  local content="$1" w=${2:-$WIDTH}
  local plain_content
  plain_content="$(printf '%b' "$content" | sed 's/\x1b\[[0-9;]*m//g')"
  local len=${#plain_content}
  local padding=$((w - 4 - len))
  [ "$padding" -lt 0 ] && padding=0
  printf '│ %b%*s │\n' "$content" "$padding" ""
}

separator() {
  printf '%b' "${DIM}"
  printf '─%.0s' $(seq 1 "$WIDTH")
  printf '%b\n' "${RESET}"
}

# --- Differential update helpers ---
RENDER_COUNT=0
LAST_VIEW=""
declare -A PREV_VALUES 2>/dev/null || true

move_to() { printf '\033[%d;%dH' "$1" "$2"; }
clear_eol() { printf '\033[K'; }

write_at() {
  local row=$1 col=$2
  shift 2
  move_to "$row" "$col"
  printf '%b' "$@"
  clear_eol
}

needs_full_redraw() {
  if [ "$RENDER_COUNT" -eq 0 ] || [ "$LAST_VIEW" != "$VIEW_MODE" ]; then
    return 0  # true
  fi
  # Also redraw on terminal resize
  local current_width
  current_width=$(get_term_width)
  if [ "$current_width" != "$WIDTH" ]; then
    WIDTH=$current_width
    return 0
  fi
  return 1  # false
}

# --- Department display order ---
DEPARTMENTS=("Orchestrator" "Product" "Engineering" "Quality" "Operations" "Marketing" "Support" "IT" "Other")

# --- Workflow phase inference ---
infer_workflow_phase() {
  if [ ! -f "$AGENTS_FILE" ] || ! jq empty "$AGENTS_FILE" 2>/dev/null; then
    echo ""
    return
  fi

  local running completed
  running="$(jq -r '[.agents | to_entries[] | select(.value.status == "running") | .key] | join(",")' "$AGENTS_FILE" 2>/dev/null)"
  completed="$(jq -r '[.agents | to_entries[] | select(.value.status == "completed") | .key] | join(",")' "$AGENTS_FILE" 2>/dev/null)"

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
SESSION_LIST_INDEX_MAP=()

if [ "$VIEWING_HISTORY_SESSION" = true ]; then
  AGENTS_FILE="$(build_history_agents_file "$TARGET_SESSION")"
fi

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

  local project_root
  project_root="$(cd "$SCRIPT_DIR/.." && pwd)"
  if [ -f "$project_root/docker-compose.yml" ] && command -v docker >/dev/null 2>&1; then
    echo "Tip: use --web-docker for containerized mode (docker compose)"
  fi

  echo "Starting web dashboard on http://localhost:$port"
  echo "Press Ctrl+C to stop."

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

# ====================================================================
# MODE: --web-docker (launch web dashboard via Docker Compose)
# ====================================================================
handle_web_docker() {
  local project_root
  project_root="$(cd "$SCRIPT_DIR/.." && pwd)"
  local compose_file="$project_root/docker-compose.yml"

  if [ ! -f "$compose_file" ]; then
    echo "Error: docker-compose.yml not found at $project_root"
    exit 1
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is not installed. Use --web for bare-metal mode."
    exit 1
  fi

  echo "Starting containerized web dashboard..."
  cd "$project_root"
  docker compose up -d dashboard
  echo "Web dashboard running at http://localhost:${DASHBOARD_PORT:-8686}"
  echo "Press Ctrl+C to stop following logs. Container keeps running."
  echo "Stop with: docker compose down"
  docker compose logs -f dashboard
  exit 0
}

# ====================================================================
# MODE: --sessions (show session list and exit)
# ====================================================================
handle_sessions_list() {
  printf "${BOLD}Available Sessions${RESET}\n\n"
  separator

  local idx=0

  if [ -f "$AGENTS_FILE" ] && jq empty "$AGENTS_FILE" 2>/dev/null; then
    local active_sid active_count
    active_sid="$(jq -r '.session_id // "unknown"' "$AGENTS_FILE" 2>/dev/null)"
    active_count="$(jq '[.agents | to_entries[]] | length' "$AGENTS_FILE" 2>/dev/null)" || active_count=0
    if [ "$active_count" -gt 0 ]; then
      local running_count completed_count
      running_count="$(jq '[.agents | to_entries[] | select(.value.status == "running")] | length' "$AGENTS_FILE" 2>/dev/null)" || running_count=0
      completed_count="$(jq '[.agents | to_entries[] | select(.value.status == "completed")] | length' "$AGENTS_FILE" 2>/dev/null)" || completed_count=0

      local phase
      phase="$(infer_workflow_phase)"

      idx=$((idx + 1))
      printf '\n'
      printf "  ${BOLD}${GREEN}[%d] %s${RESET}  ${GREEN}● ACTIVE${RESET}\n" "$idx" "${active_sid:0:20}"
      printf "      Agents: ${CYAN}%d${RESET}  Running: ${YELLOW}%d${RESET}  Done: ${GREEN}%d${RESET}\n" \
        "$active_count" "$running_count" "$completed_count"
      [ -n "$phase" ] && printf "      %s\n" "$phase"
    fi
  fi

  if [ -f "$HISTORY_FILE" ] && jq empty "$HISTORY_FILE" 2>/dev/null; then
    jq -r '.sessions | reverse | .[0:9][] |
      "\(.session_id)\t\(.started_at // "?")\t\(.total_duration // 0)\t\(.agents | length)"
    ' "$HISTORY_FILE" 2>/dev/null | while IFS=$'\t' read -r sid started dur agents; do
      idx=$((idx + 1))
      local short_sid="${sid:0:20}"
      local dur_str="$(format_duration "$dur")"
      printf '\n'
      printf "  ${DIM}[%d] %s${RESET}\n" "$idx" "$short_sid"
      printf "      ${DIM}%s  agents:%s  duration:%s${RESET}\n" \
        "${started:0:16}" "$agents" "$dur_str"
    done
  fi

  if [ "$idx" -eq 0 ]; then
    printf '\n  %sNo sessions found.%s\n' "${DIM}" "${RESET}"
  fi

  printf '\n'
  separator
  printf "  ${DIM}Use: $0 --session <id> to open a specific session${RESET}\n"
  exit 0
}

# --- Handle non-interactive modes ---
case "$MODE" in
  export)    handle_export ;;
  history)   handle_history ;;
  analytics) handle_analytics ;;
  web)        handle_web ;;
  web-docker) handle_web_docker ;;
  sessions)   handle_sessions_list ;;
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
    if needs_full_redraw; then
      printf '\033[2J\033[H'
      draw_box_top
      draw_box_line "${BOLD}◆ Ghost Office — Agent Dashboard${RESET}"
      draw_box_line "${DIM}No active session${RESET}"
      draw_box_bottom
      printf '\n'
      printf '  %sWaiting for agents to start...%s\n' "${DIM}" "${RESET}"
      printf '  %sStart a multi-agent task to see activity.%s\n' "${DIM}" "${RESET}"
      printf '\n'
      separator
      printf "  ${DIM}[h] history  [s] analytics  [l] sessions  [q] quit${RESET}\n"
    else
      write_at 2 3 "${DIM}No active session                        ${RESET}"
    fi
    return
  fi

  local session_id short_session
  session_id="$(jq -r '.session_id // "unknown"' "$AGENTS_FILE" 2>/dev/null)"
  short_session="${session_id:0:16}"

  local active_count completed_count total_count error_count earliest_start
  active_count="$(jq '[.agents | to_entries[] | select(.value.status == "running")] | length' "$AGENTS_FILE" 2>/dev/null)" || active_count=0
  completed_count="$(jq '[.agents | to_entries[] | select(.value.status == "completed")] | length' "$AGENTS_FILE" 2>/dev/null)" || completed_count=0
  total_count="$(jq '[.agents | to_entries[]] | length' "$AGENTS_FILE" 2>/dev/null)" || total_count=0
  error_count="$(jq '[.agents | to_entries[] | select(.value.error_count > 0)] | length' "$AGENTS_FILE" 2>/dev/null)" || error_count=0
  earliest_start="$(jq -r '[.agents[].started_at] | sort | first // empty' "$AGENTS_FILE" 2>/dev/null)"

  local session_duration="--"
  if [ -n "$earliest_start" ]; then
    local start_epoch
    start_epoch="$(date -d "$earliest_start" +%s 2>/dev/null)" || start_epoch=0
    if [ "$start_epoch" -gt 0 ] && [ "$now_epoch" -gt 0 ]; then
      session_duration="$(format_duration $((now_epoch - start_epoch)))"
    fi
  fi

  local phase
  phase="$(infer_workflow_phase)"

  if needs_full_redraw; then
    printf '\033[2J\033[H'

    # Header box
    draw_box_top
    if [ "$VIEWING_HISTORY_SESSION" = true ]; then
      draw_box_line "${BOLD}${RED}◆ Ghost Office — HISTORY${RESET}                          ${DIM}$current_time${RESET}"
    else
      draw_box_line "${BOLD}◆ Ghost Office — Agent Dashboard${RESET}              ${DIM}$current_time${RESET}"
    fi
    draw_box_line "${DIM}Session:${RESET} $short_session   ${DIM}│${RESET}   ${DIM}Uptime:${RESET} $session_duration"
    if [ -n "$phase" ]; then
      draw_box_line "${BRIGHT_CYAN}▶ $phase${RESET}"
    fi
    draw_box_bottom

    # Summary bar
    printf '\n'
    printf "  ${BOLD}Total:${RESET} ${BRIGHT_CYAN}%d${RESET}    ${BRIGHT_YELLOW}● Active: %d${RESET}    ${BRIGHT_GREEN}✓ Done: %d${RESET}    ${BRIGHT_RED}✗ Errors: %d${RESET}\n" \
      "$total_count" "$active_count" "$completed_count" "$error_count"
    printf '\n'

    # Agent list
    AGENT_INDEX_MAP=()
    local idx=0

    for dept in "${DEPARTMENTS[@]}"; do
      local agents_in_dept
      agents_in_dept="$(jq -r --arg d "$dept" '
        [.agents | to_entries[] | select(.value.department == $d) | .key] | .[]
      ' "$AGENTS_FILE" 2>/dev/null)"

      [ -z "$agents_in_dept" ] && continue

      printf '  %s%s── %s %s%s\n' "${BOLD}" "${MAGENTA}" "$dept" "$(printf '─%.0s' $(seq 1 $((WIDTH - ${#dept} - 8))))" "${RESET}"

      while IFS= read -r agent; do
        [ -z "$agent" ] && continue
        idx=$((idx + 1))
        AGENT_INDEX_MAP+=("$agent")

        local status started_at
        status="$(jq -r --arg a "$agent" '.agents[$a].status // "unknown"' "$AGENTS_FILE" 2>/dev/null)"
        started_at="$(jq -r --arg a "$agent" '.agents[$a].started_at // empty' "$AGENTS_FILE" 2>/dev/null)"

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

        local indicator label
        case "$status" in
          running)   indicator="${BRIGHT_YELLOW}●${RESET}"; label="${BRIGHT_YELLOW}ACTIVE${RESET}" ;;
          completed) indicator="${BRIGHT_GREEN}✓${RESET}"; label="${BRIGHT_GREEN}DONE  ${RESET}" ;;
          *)         indicator="${DIM}○${RESET}"; label="${DIM}IDLE  ${RESET}" ;;
        esac

        local err_count
        err_count="$(get_error_count "$agent")"
        local err_indicator=""
        if [ "$err_count" -gt 0 ] 2>/dev/null; then
          err_indicator=" ${BRIGHT_RED}✗${err_count}${RESET}"
        fi

        local todo_progress=""
        local todo_file="$TODOS_DIR/${agent}.json"
        if [ -f "$todo_file" ] && jq empty "$todo_file" 2>/dev/null; then
          local t_completed t_total
          t_completed="$(jq '.progress.completed // 0' "$todo_file" 2>/dev/null)" || t_completed=0
          t_total="$(jq '.progress.total // 0' "$todo_file" 2>/dev/null)" || t_total=0
          if [ "$t_total" -gt 0 ]; then
            todo_progress=" $(progress_bar "$t_completed" "$t_total" 8) ${DIM}${t_completed}/${t_total}${RESET}"
          fi
        fi

        printf "  ${DIM}[%d]${RESET} %b %-22s %b  %-8s%b%b\n" \
          "$idx" "$indicator" "$agent" "$label" "$duration_str" "$todo_progress" "$err_indicator"

      done <<< "$agents_in_dept"
      printf '\n'
    done

    # Token usage
    local total_tokens
    total_tokens="$(jq '[.agents[].tokens.total // 0] | add // 0' "$AGENTS_FILE" 2>/dev/null)" || total_tokens=0

    separator
    printf "  Session: ${CYAN}%s${RESET}" "$session_duration"
    if [ "$total_tokens" -gt 0 ] 2>/dev/null; then
      printf "  │  Tokens: ${CYAN}%s${RESET}" "$total_tokens"
    fi
    printf '\n'
    separator
    printf "  ${DIM}[1-%d] detail  [l] sessions  [h] history  [s] stats  [e] errors${RESET}\n" "$idx"
    printf "  ${DIM}[w] workflow  [m] messages  [c] command  [q] quit${RESET}\n"
  else
    # --- Differential update: only update changing values ---
    # Update time
    write_at 2 "$((WIDTH - 13))" "${DIM}$current_time${RESET}"

    # Update session duration
    write_at 3 3 "${DIM}Session:${RESET} $short_session   ${DIM}│${RESET}   ${DIM}Uptime:${RESET} $session_duration"

    # Update phase
    if [ -n "$phase" ]; then
      write_at 4 3 "${BRIGHT_CYAN}▶ $phase${RESET}"
    fi

    # Update summary bar (row 7)
    write_at 7 3 "${BOLD}Total:${RESET} ${BRIGHT_CYAN}${total_count}${RESET}    ${BRIGHT_YELLOW}● Active: ${active_count}${RESET}    ${BRIGHT_GREEN}✓ Done: ${completed_count}${RESET}    ${BRIGHT_RED}✗ Errors: ${error_count}${RESET}"

    # Update agent rows - find each agent's row and update duration/progress
    local row=9
    for dept in "${DEPARTMENTS[@]}"; do
      local agents_in_dept
      agents_in_dept="$(jq -r --arg d "$dept" '
        [.agents | to_entries[] | select(.value.department == $d) | .key] | .[]
      ' "$AGENTS_FILE" 2>/dev/null)"

      [ -z "$agents_in_dept" ] && continue
      row=$((row + 1))  # department header

      while IFS= read -r agent; do
        [ -z "$agent" ] && continue

        local status started_at
        status="$(jq -r --arg a "$agent" '.agents[$a].status // "unknown"' "$AGENTS_FILE" 2>/dev/null)"
        started_at="$(jq -r --arg a "$agent" '.agents[$a].started_at // empty' "$AGENTS_FILE" 2>/dev/null)"

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

        local indicator label
        case "$status" in
          running)   indicator="${BRIGHT_YELLOW}●${RESET}"; label="${BRIGHT_YELLOW}ACTIVE${RESET}" ;;
          completed) indicator="${BRIGHT_GREEN}✓${RESET}"; label="${BRIGHT_GREEN}DONE  ${RESET}" ;;
          *)         indicator="${DIM}○${RESET}"; label="${DIM}IDLE  ${RESET}" ;;
        esac

        local err_count
        err_count="$(get_error_count "$agent")"
        local err_indicator=""
        if [ "$err_count" -gt 0 ] 2>/dev/null; then
          err_indicator=" ${BRIGHT_RED}✗${err_count}${RESET}"
        fi

        local todo_progress=""
        local todo_file="$TODOS_DIR/${agent}.json"
        if [ -f "$todo_file" ] && jq empty "$todo_file" 2>/dev/null; then
          local t_completed t_total
          t_completed="$(jq '.progress.completed // 0' "$todo_file" 2>/dev/null)" || t_completed=0
          t_total="$(jq '.progress.total // 0' "$todo_file" 2>/dev/null)" || t_total=0
          if [ "$t_total" -gt 0 ]; then
            todo_progress=" $(progress_bar "$t_completed" "$t_total" 8) ${DIM}${t_completed}/${t_total}${RESET}"
          fi
        fi

        # Update the status, duration, and progress inline
        write_at "$row" 35 "%b  %-8s%b%b" "$label" "$duration_str" "$todo_progress" "$err_indicator"

        row=$((row + 1))
      done <<< "$agents_in_dept"
      row=$((row + 1))  # blank line after department
    done
  fi
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

  local status_display status_icon
  case "$status" in
    running)   status_display="${BRIGHT_YELLOW}ACTIVE${RESET}"; status_icon="${BRIGHT_YELLOW}●${RESET}" ;;
    completed) status_display="${BRIGHT_GREEN}DONE${RESET}"; status_icon="${BRIGHT_GREEN}✓${RESET}" ;;
    *)         status_display="${DIM}IDLE${RESET}"; status_icon="${DIM}○${RESET}" ;;
  esac

  # Header box
  draw_box_top
  draw_box_line "${BOLD}${agent}${RESET}"
  draw_box_line "${DIM}Department:${RESET} $department   ${DIM}│${RESET}   $current_time"
  draw_box_bottom
  printf '\n'

  printf "  %b Status: %b" "$status_icon" "$status_display"
  [ -n "$duration_str" ] && printf "  ${DIM}(%s)${RESET}" "$duration_str"
  printf '\n'

  # Error count
  local err_count
  err_count="$(get_error_count "$agent")"
  if [ "$err_count" -gt 0 ] 2>/dev/null; then
    printf "  ${BRIGHT_RED}✗${RESET} Errors: ${BRIGHT_RED}%s${RESET}\n" "$err_count"
  fi

  # Tokens
  local tokens
  tokens="$(get_token_info "$agent")"
  if [ "$tokens" -gt 0 ] 2>/dev/null; then
    printf "  ${CYAN}⚡${RESET} Tokens: ${CYAN}%s${RESET}\n" "$tokens"
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

    draw_box_separator
    draw_box_line "${BOLD}Tasks${RESET}"
    draw_box_separator

    jq -r '.todos[] | "\(.status)\t\(.content)"' "$todo_file" 2>/dev/null | while IFS=$'\t' read -r t_status t_content; do
      case "$t_status" in
        completed)   printf '  %s✓ %s%s\n' "${BRIGHT_GREEN}" "$t_content" "${RESET}" ;;
        in_progress) printf '  %s▶ %s%s\n' "${BRIGHT_YELLOW}${BOLD}" "$t_content" "${RESET}" ;;
        pending)     printf '  %s○ %s%s\n' "${DIM}" "$t_content" "${RESET}" ;;
      esac
    done

    printf '\n'
    if [ "$t_total" -gt 0 ]; then
      local pct=$(( (t_completed * 100) / t_total ))
      printf '  Progress: '
      progress_bar "$t_completed" "$t_total" 20
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
      draw_box_separator
      draw_box_line "${BOLD}${RED}Errors${RESET}"
      draw_box_separator
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
  draw_box_top
  draw_box_line "${BOLD}${RED}⚠ Error Log${RESET}                                      ${DIM}$current_time${RESET}"
  draw_box_bottom

  if [ ! -d "$ERRORS_DIR" ]; then
    printf '\n  %s✓ No errors recorded.%s\n' "${BRIGHT_GREEN}" "${RESET}"
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
    printf '\n  %s%s●%s %s%s%s (%d errors)\n' "${BRIGHT_RED}" "" "${RESET}" "${BOLD}" "$agent_name" "${RESET}" "$ecount"

    jq -r '.errors | reverse | .[0:5][] | "\(.timestamp)\t\(.tool)\t\(.message)"' "$ef" 2>/dev/null | \
      while IFS=$'\t' read -r ts tool msg; do
        local short_msg="${msg:0:60}"
        printf '    %s%s %s%s: %s\n' "${DIM}" "${ts:0:19}" "${RESET}${YELLOW}" "$tool" "${RESET}$short_msg"
      done
  done

  if [ "$has_errors" = false ]; then
    printf '\n  %s✓ No errors recorded. Clean run!%s\n' "${BRIGHT_GREEN}" "${RESET}"
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
  draw_box_top
  draw_box_line "${BOLD}⟳ Workflow Phases${RESET}                                    ${DIM}$current_time${RESET}"
  draw_box_bottom

  if [ ! -f "$AGENTS_FILE" ] || ! jq empty "$AGENTS_FILE" 2>/dev/null; then
    printf '\n  %sNo active session.%s\n' "${DIM}" "${RESET}"
    printf '\n'
    separator
    printf "  ${DIM}[b] back  │  [q] quit${RESET}\n"
    return
  fi

  local phase
  phase="$(infer_workflow_phase)"

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
      completed) icon="✓"; color="${BRIGHT_GREEN}" ;;
      running)   icon="▶"; color="${BRIGHT_YELLOW}${BOLD}" ;;
      pending)   icon="○"; color="${DIM}" ;;
    esac

    printf "  %b%s Phase %d: %s%s\n" "$color" "$icon" "$phase_num" "$p" "${RESET}"

    for pa in "${agent_list[@]}"; do
      local ast
      ast="$(jq -r --arg a "$pa" '.agents[$a].status // "none"' "$AGENTS_FILE" 2>/dev/null)"
      if [ "$ast" != "none" ]; then
        local sub_icon
        case "$ast" in
          completed) sub_icon="${BRIGHT_GREEN}✓${RESET}" ;;
          running)   sub_icon="${BRIGHT_YELLOW}●${RESET}" ;;
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
  draw_box_top
  draw_box_line "${BOLD}Session History${RESET}                                      ${DIM}$current_time${RESET}"
  draw_box_bottom

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
  draw_box_top
  draw_box_line "${BOLD}Agent Analytics${RESET}                                      ${DIM}$current_time${RESET}"
  draw_box_bottom

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

# --- Render session list view (interactive) ---
render_session_list() {
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"
  local now_epoch
  now_epoch="$(date -u +%s 2>/dev/null)" || now_epoch=0

  printf '\033[2J\033[H'
  draw_box_top
  draw_box_line "${BOLD}Session List${RESET}                                         ${DIM}$current_time${RESET}"
  draw_box_bottom

  SESSION_LIST_INDEX_MAP=()
  local idx=0

  local orig_agents="$STATUS_DIR/agents.json"
  if [ -f "$orig_agents" ] && jq empty "$orig_agents" 2>/dev/null; then
    local active_sid active_count
    active_sid="$(jq -r '.session_id // ""' "$orig_agents" 2>/dev/null)"
    active_count="$(jq '[.agents | to_entries[]] | length' "$orig_agents" 2>/dev/null)" || active_count=0
    if [ "$active_count" -gt 0 ] && [ -n "$active_sid" ]; then
      idx=$((idx + 1))
      SESSION_LIST_INDEX_MAP+=("active:$active_sid")

      local running_count completed_count
      running_count="$(jq '[.agents | to_entries[] | select(.value.status == "running")] | length' "$orig_agents" 2>/dev/null)" || running_count=0
      completed_count="$(jq '[.agents | to_entries[] | select(.value.status == "completed")] | length' "$orig_agents" 2>/dev/null)" || completed_count=0

      local earliest_start session_dur_str="--"
      earliest_start="$(jq -r '[.agents[].started_at] | sort | first // empty' "$orig_agents" 2>/dev/null)"
      if [ -n "$earliest_start" ]; then
        local s_epoch
        s_epoch="$(date -d "$earliest_start" +%s 2>/dev/null)" || s_epoch=0
        if [ "$s_epoch" -gt 0 ] && [ "$now_epoch" -gt 0 ]; then
          session_dur_str="$(format_duration $((now_epoch - s_epoch)))"
        fi
      fi

      local pbar
      pbar="$(progress_bar "$completed_count" "$active_count" 8)"

      printf '\n'
      printf "  ${BOLD}[%d]${RESET} ${BRIGHT_GREEN}●${RESET} ${BOLD}%-20s${RESET} %b ${GREEN}%d${RESET}/${CYAN}%d${RESET}\n" \
        "$idx" "${active_sid:0:20}" "$pbar" "$completed_count" "$active_count"
      printf "      Started %s ago · ${BRIGHT_YELLOW}%d running${RESET}\n" "$session_dur_str" "$running_count"
    fi
  fi

  if [ -f "$HISTORY_FILE" ] && jq empty "$HISTORY_FILE" 2>/dev/null; then
    while IFS=$'\t' read -r sid started dur agents; do
      [ -z "$sid" ] && continue
      idx=$((idx + 1))
      SESSION_LIST_INDEX_MAP+=("history:$sid")
      local dur_str="$(format_duration "$dur")"

      printf '\n'
      printf "  ${DIM}[%d]${RESET} ${DIM}○${RESET} %-20s ${DIM}%b done${RESET}\n" \
        "$idx" "${sid:0:20}" "$(progress_bar "$agents" "$agents" 8)"
      printf "      ${DIM}%s · %s agents · %s${RESET}\n" \
        "${started:0:16}" "$agents" "$dur_str"
    done < <(jq -r '.sessions | reverse | .[0:8][] |
      "\(.session_id)\t\(.started_at // "?")\t\(.total_duration // 0)\t\(.agents | length)"
    ' "$HISTORY_FILE" 2>/dev/null)
  fi

  if [ "$idx" -eq 0 ]; then
    printf '\n  %sNo sessions found. Start a multi-agent task to see activity.%s\n' "${DIM}" "${RESET}"
  fi

  printf '\n'
  separator
  printf "  ${DIM}[1-%d] select session  [h] history  [s] stats  [q] quit${RESET}\n" "$idx"
}

# --- Render messages view ---
render_messages() {
  local current_time
  current_time="$(date -u +"%H:%M:%S UTC")"

  printf '\033[2J\033[H'
  draw_box_top
  draw_box_line "${BOLD}✉ Agent Messages${RESET}                                     ${DIM}$current_time${RESET}"
  draw_box_bottom

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
      [ "$pending" -gt 0 ] && printf "  ${BRIGHT_YELLOW}pending:%d${RESET}" "$pending"
      [ "$delivered" -gt 0 ] && printf "  ${BRIGHT_CYAN}delivered:%d${RESET}" "$delivered"
      [ "$acked" -gt 0 ] && printf "  ${BRIGHT_GREEN}acked:%d${RESET}" "$acked"
      printf '\n'

      jq -r '.messages | reverse | .[0:3][] | "\(.status)\t\(.type)\t\(.from)\t\(.content[0:60])"' "$msg_file" 2>/dev/null | \
        while IFS=$'\t' read -r status mtype mfrom mcontent; do
          local color="$DIM"
          case "$status" in
            pending)      color="$BRIGHT_YELLOW" ;;
            delivered)    color="$BRIGHT_CYAN" ;;
            acknowledged) color="$BRIGHT_GREEN" ;;
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
  local target="$1"

  printf '\033[2J\033[H'
  draw_box_top
  draw_box_line "${BOLD}Send Command to: $target${RESET}"
  draw_box_bottom

  printf '\n  Message types: instruction, question, priority, note\n'
  if [ "$target" = "master-orchestrator" ]; then
    printf '  Orchestrator: reprioritize, pause-workflow, resume-workflow\n'
  fi
  printf '\n'

  printf '\033[?25h'

  printf '  Type [default=instruction]: '
  local msg_type=""
  read -r msg_type </dev/tty 2>/dev/null || msg_type=""
  msg_type="${msg_type:-instruction}"

  printf '  Message: '
  local content=""
  read -r content </dev/tty 2>/dev/null || content=""

  printf '\033[?25l'

  if [ -z "$content" ]; then
    printf '\n  %sCancelled (empty message).%s\n' "${YELLOW}" "${RESET}"
    sleep 1
    return
  fi

  content="$(printf '%s' "$content" | sed 's/\\/\\\\/g; s/"/\\"/g')"

  if command -v jq >/dev/null 2>&1; then
    write_message_file "$target" "$msg_type" "$content"
    printf '\n  %s✓ Message sent to %s%s\n' "${BRIGHT_GREEN}" "$target" "${RESET}"
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
    sessions)  render_session_list ;;
  esac

  RENDER_COUNT=$((RENDER_COUNT + 1))
  LAST_VIEW="$VIEW_MODE"

  if [ "$RUN_ONCE" = "true" ]; then
    break
  fi

  if read -rsn1 -t "$REFRESH_INTERVAL" key 2>/dev/null; then
    case "$key" in
      q|Q) break ;;
      b|B)
        if [ "$VIEW_MODE" = "overview" ] && [ "$VIEWING_HISTORY_SESSION" = true ]; then
          VIEW_MODE="sessions"
        elif [ "$VIEW_MODE" != "overview" ]; then
          VIEW_MODE="overview"
        fi
        ;;
      h|H) VIEW_MODE="history" ;;
      s|S) VIEW_MODE="stats" ;;
      e|E) VIEW_MODE="errors" ;;
      w|W) VIEW_MODE="workflow" ;;
      m|M) VIEW_MODE="messages" ;;
      l|L) VIEW_MODE="sessions" ;;
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
        if [ "$VIEW_MODE" = "sessions" ]; then
          local_idx=$((key - 1))
          if [ "$local_idx" -lt "${#SESSION_LIST_INDEX_MAP[@]}" ]; then
            local entry="${SESSION_LIST_INDEX_MAP[$local_idx]}"
            local entry_type="${entry%%:*}"
            local entry_sid="${entry#*:}"
            if [ "$entry_type" = "active" ]; then
              AGENTS_FILE="$STATUS_DIR/agents.json"
              VIEWING_HISTORY_SESSION=false
            else
              AGENTS_FILE="$(build_history_agents_file "$entry_sid")"
              VIEWING_HISTORY_SESSION=true
              TARGET_SESSION="$entry_sid"
            fi
            VIEW_MODE="overview"
          fi
        elif [ "$VIEW_MODE" = "overview" ]; then
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
