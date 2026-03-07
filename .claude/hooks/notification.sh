#!/bin/bash
# Hook: Notification — Desktop Alert on Permission/Idle Events
# Sends desktop notifications when Claude needs user input.
# Exit 0 = allow (notification only, never block)

INPUT_JSON="$(cat)"
NOTIFICATION_TYPE=""

if command -v jq >/dev/null 2>&1; then
  NOTIFICATION_TYPE="$(printf '%s' "$INPUT_JSON" | jq -r '.type // empty' 2>/dev/null)"
fi

if [ -z "$NOTIFICATION_TYPE" ]; then
  exit 0
fi

# --- Send desktop notification ---
TITLE="Claude Code"
MESSAGE=""

case "$NOTIFICATION_TYPE" in
  permission_prompt)
    MESSAGE="Awaiting permission approval"
    ;;
  idle_prompt)
    MESSAGE="Ready for next command"
    ;;
  auth_success)
    MESSAGE="Authentication completed"
    ;;
  elicitation_dialog)
    MESSAGE="Clarification needed"
    ;;
  *)
    exit 0
    ;;
esac

# Sanitize variables before use in command strings (prevent injection)
SAFE_MESSAGE="${MESSAGE//\"/\\\"}"
SAFE_MESSAGE_PS="${MESSAGE//\'/\'\'}"
SAFE_TITLE="${TITLE//\"/\\\"}"
SAFE_TITLE_PS="${TITLE//\'/\'\'}"

# Try multiple notification methods (cross-platform)
if command -v notify-send >/dev/null 2>&1; then
  notify-send "$TITLE" "$MESSAGE" --urgency=normal 2>/dev/null
elif command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification \"$SAFE_MESSAGE\" with title \"$SAFE_TITLE\"" 2>/dev/null
elif command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$SAFE_MESSAGE_PS','$SAFE_TITLE_PS')" 2>/dev/null
fi

exit 0
