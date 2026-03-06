#!/bin/bash
# Hook: PostToolUse (Write|Edit) — Migration Multi-Tenant Check
# Verifies that new database migration files include branch_id for multi-tenant isolation.
# Exit 0 = allow (with warnings on stderr)

INPUT_JSON="$(cat)"
FILE=""

if command -v jq >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT_JSON" | jq -r '.tool_response.filePath // .tool_response.file_path // .tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
fi

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  exit 0
fi

# --- Only check migration files ---
# Matches Laravel (database/migrations/*.php) and Django (*/migrations/*.py)
if ! echo "$FILE" | grep -qE '(database/migrations/.*\.php|/migrations/.*\.py)'; then
  exit 0
fi

# --- Check for table creation without branch_id ---
# Laravel: Schema::create or $table->
if echo "$FILE" | grep -qE '\.php$'; then
  if grep -qE 'Schema::create' "$FILE" 2>/dev/null; then
    if ! grep -qE 'branch_id|branches' "$FILE" 2>/dev/null; then
      echo '⚠️  [Hook] New migration creates a table without branch_id column!' >&2
      echo 'Multi-tenant tables MUST include branch_id for data isolation.' >&2
      echo 'Add: $table->foreignId("branch_id")->constrained();' >&2
    fi
  fi
fi

# Django: CreateModel or migrations.CreateModel
if echo "$FILE" | grep -qE '\.py$'; then
  if grep -qE 'CreateModel|create_model' "$FILE" 2>/dev/null; then
    if ! grep -qE 'branch_id|branch' "$FILE" 2>/dev/null; then
      echo '⚠️  [Hook] New Django migration creates a model without branch_id field!' >&2
      echo 'Multi-tenant models MUST include branch_id for data isolation.' >&2
      echo 'Add: branch = models.ForeignKey("branches.Branch", on_delete=models.CASCADE)' >&2
    fi
  fi
fi

# --- Check for missing down/rollback migration ---
if echo "$FILE" | grep -qE '\.php$'; then
  if grep -qE 'function up' "$FILE" 2>/dev/null; then
    if ! grep -qE 'function down' "$FILE" 2>/dev/null; then
      echo '⚠️  [Hook] Migration is missing a down() method for rollback.' >&2
    fi
  fi
fi

exit 0
