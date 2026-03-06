#!/bin/bash
# Hook: PostToolUse (Write|Edit) — File Write Safety Check
# Scans written files for secrets, Dockerfile issues, and YAML lint.
# Exit 0 = allow (with warnings on stderr)

INPUT_JSON="$(cat)"
FILE=""

if command -v jq >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT_JSON" | jq -r '.tool_response.filePath // .tool_response.file_path // .tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
fi

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  exit 0
fi

# --- Secret detection ---
if grep -qiE '(password|secret|api[_-]?key|access[_-]?key|private[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]{8,}' "$FILE" 2>/dev/null; then
  echo '🔐 [Hook] Potential secret detected in file!' >&2
  echo 'Please use a secrets manager instead of hardcoding credentials.' >&2
fi

# --- Dockerfile best practices ---
if echo "$FILE" | grep -qE 'Dockerfile'; then
  if grep -q 'FROM.*:latest' "$FILE" 2>/dev/null; then
    echo '⚠️  [Hook] Dockerfile uses :latest tag. Pin to a specific version.' >&2
  fi
  if ! grep -q '^USER ' "$FILE" 2>/dev/null; then
    echo '⚠️  [Hook] Dockerfile does not set USER. Add a non-root user.' >&2
  fi
  if ! grep -q 'HEALTHCHECK' "$FILE" 2>/dev/null; then
    echo 'ℹ️  [Hook] Consider adding a HEALTHCHECK instruction.' >&2
  fi
fi

# --- YAML lint ---
if echo "$FILE" | grep -qE '\.(ya?ml)$'; then
  if command -v yamllint >/dev/null 2>&1; then
    yamllint -d relaxed "$FILE" 2>&1 | head -5
  fi
fi

exit 0
