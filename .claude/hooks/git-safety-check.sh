#!/bin/bash
# Hook: PreToolUse (Bash) — Git Safety Check
# Blocks force-push and hard reset on protected branches (main, develop, master).
# Exit 0 = allow (with warnings on stderr)
# Exit 2 = block the command

INPUT_JSON="$(cat)"
CMD=""

if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT_JSON" | jq -r '.tool_input.command // empty' 2>/dev/null)"
fi

if [ -z "$CMD" ]; then
  exit 0
fi

PROTECTED_BRANCHES="main|master|develop|production|staging"

# --- Block force push to protected branches ---
if echo "$CMD" | grep -qE 'git push.*--force|git push.*-f'; then
  if echo "$CMD" | grep -qE "($PROTECTED_BRANCHES)"; then
    echo "❌ [Hook] BLOCKED: Force push to a protected branch is not allowed." >&2
    echo "Protected branches: main, master, develop, production, staging" >&2
    echo "Use a feature branch and create a pull request instead." >&2
    exit 2
  fi
  echo '⚠️  [Hook] Force push detected. Verify you are pushing to the correct branch.' >&2
fi

# --- Block hard reset on protected branches ---
if echo "$CMD" | grep -qE 'git reset --hard'; then
  CURRENT_BRANCH=""
  if command -v git >/dev/null 2>&1; then
    CURRENT_BRANCH="$(git branch --show-current 2>/dev/null)"
  fi
  if echo "$CURRENT_BRANCH" | grep -qE "^($PROTECTED_BRANCHES)$"; then
    echo "❌ [Hook] BLOCKED: git reset --hard on protected branch '$CURRENT_BRANCH'." >&2
    echo "This would destroy commit history. Use git revert instead." >&2
    exit 2
  fi
  echo '⚠️  [Hook] git reset --hard detected. Uncommitted changes will be lost.' >&2
fi

# --- Warn on direct push to protected branches ---
if echo "$CMD" | grep -qE '^git push'; then
  if echo "$CMD" | grep -qE "origin\s+($PROTECTED_BRANCHES)(\s|$)"; then
    echo '⚠️  [Hook] Pushing directly to a protected branch.' >&2
    echo 'Consider using a feature branch and pull request workflow.' >&2
  fi
fi

# --- Warn on branch deletion ---
if echo "$CMD" | grep -qE 'git branch.*-[dD]|git push.*--delete|git push.*:'; then
  echo '⚠️  [Hook] Branch deletion detected. Verify this is intentional.' >&2
fi

exit 0
