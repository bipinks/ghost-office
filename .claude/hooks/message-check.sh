#!/bin/bash
# Hook: PostToolUse (TodoWrite|Agent|Bash) — Dashboard Message Delivery
# Checks for pending messages from the dashboard user and notifies the agent
# via stderr so the agent can read and process them. Exit 0 = allow (never block).

INPUT_JSON="$(cat)"

# Require jq
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

STATUS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/status"
MESSAGES_DIR="$STATUS_DIR/messages"
AGENTS_FILE="$STATUS_DIR/agents.json"

# No messages directory = nothing to check
if [ ! -d "$MESSAGES_DIR" ]; then
  exit 0
fi

# Find the currently running agent (most recently started)
AGENT_NAME=""
if [ -f "$AGENTS_FILE" ] && jq empty "$AGENTS_FILE" 2>/dev/null; then
  AGENT_NAME="$(jq -r '
    [.agents | to_entries[] | select(.value.status == "running")]
    | sort_by(.value.started_at) | last | .key // empty
  ' "$AGENTS_FILE" 2>/dev/null)"
fi

# If no running agent, skip
if [ -z "$AGENT_NAME" ]; then
  exit 0
fi

MSG_FILE="$MESSAGES_DIR/${AGENT_NAME}.json"

# No message file for this agent = nothing to deliver
if [ ! -f "$MSG_FILE" ] || ! jq empty "$MSG_FILE" 2>/dev/null; then
  exit 0
fi

# Count pending messages
PENDING_COUNT="$(jq '[.messages[] | select(.status == "pending")] | length' "$MSG_FILE" 2>/dev/null)" || PENDING_COUNT=0

if [ "$PENDING_COUNT" -eq 0 ]; then
  exit 0
fi

# Get preview of pending messages (first 3)
PREVIEWS="$(jq -r '
  [.messages[] | select(.status == "pending")] | .[0:3][] |
  "  [\(.type)] \(.content[0:100])"
' "$MSG_FILE" 2>/dev/null)"

# Notify agent via stderr (visible in agent conversation as [Hook] output)
echo "" >&2
echo "===== DASHBOARD MESSAGE =====" >&2
echo "You have ${PENDING_COUNT} pending message(s) from the dashboard user." >&2
echo "Messages:" >&2
echo "$PREVIEWS" >&2
echo "" >&2
echo "Action required: Read .claude/status/messages/${AGENT_NAME}.json" >&2
echo "Process each pending message, then update its status to \"acknowledged\"" >&2
echo "and write your response in the \"response\" field." >&2
echo "==============================" >&2
echo "" >&2

# Mark messages as delivered
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
TMPFILE="$(mktemp "${MSG_FILE}.XXXXXX" 2>/dev/null)" || exit 0

jq --arg ts "$TIMESTAMP" '
  .messages |= ([.[] | if .status == "pending" then
    .status = "delivered" | .delivered_at = $ts
  else . end] | .[-100:])
' "$MSG_FILE" > "$TMPFILE" 2>/dev/null && mv "$TMPFILE" "$MSG_FILE"

# Clean up on failure
rm -f "$TMPFILE" 2>/dev/null

exit 0
