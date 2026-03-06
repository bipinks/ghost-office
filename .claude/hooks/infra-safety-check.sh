#!/bin/bash
# Hook: PreToolUse (Bash) — Infrastructure Safety Check
# Warns on destructive infrastructure and application operations.
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

# --- Destructive infrastructure operations ---
if echo "$CMD" | grep -qE 'terraform (apply|destroy)|kubectl delete|aws .* delete'; then
  echo '⚠️  [Hook] Destructive infrastructure operation detected!' >&2
  echo 'Please verify:' >&2
  echo '  1. You are targeting the correct environment' >&2
  echo '  2. A terraform plan has been reviewed' >&2
  echo '  3. Rollback procedures are documented' >&2
  echo '  4. Team has been notified' >&2
fi

# --- Terraform apply safety ---
if echo "$CMD" | grep -qE 'terraform apply'; then
  if echo "$CMD" | grep -qE '\-auto-approve'; then
    echo '⚠️  [Hook] Using -auto-approve detected! This skips the review step.' >&2
    echo 'This should NEVER be used in production.' >&2
  else
    echo 'ℹ️  [Hook] Remember to review the plan output carefully before confirming.' >&2
  fi
fi

# --- Destructive application operations ---
if echo "$CMD" | grep -qE 'php artisan migrate.*--force|docker compose.*down|rm -rf|DROP TABLE|DROP DATABASE'; then
  echo '⚠️  [Hook] Potentially destructive operation detected!' >&2
  echo 'Verify: correct environment, backup exists, rollback plan ready.' >&2
fi

exit 0
