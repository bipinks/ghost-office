#!/bin/bash
# Hook: PreCompact — Preserve Critical Context
# Outputs critical task context before auto-compaction to prevent context loss.
# Exit 0 = allow compaction (context output preserved in summary)

INPUT_JSON="$(cat)"
COMPACT_TYPE=""

if command -v jq >/dev/null 2>&1; then
  COMPACT_TYPE="$(printf '%s' "$INPUT_JSON" | jq -r '.type // "auto"' 2>/dev/null)"
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# --- Capture current state (single git check) ---
BRANCH=""
UNCOMMITTED_COUNT=0
HAS_GIT=false
if command -v git >/dev/null 2>&1; then
  HAS_GIT=true
  BRANCH="$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  UNCOMMITTED_COUNT="$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l)"
fi

# --- Output critical context for preservation ---
cat <<EOF

=== Pre-Compaction Context Snapshot ===
Compact Type: ${COMPACT_TYPE:-auto}
Branch: ${BRANCH:-unknown}
Uncommitted Files: ${UNCOMMITTED_COUNT}

IMPORTANT — Preserve These After Compaction:
1. Current working branch: ${BRANCH:-unknown}
2. Uncommitted changes count: ${UNCOMMITTED_COUNT}
3. Project type: AI Software Company (multi-tenant, multi-branch capable)
4. All database tables require branch_id column
5. Protected branches: main, master, develop, production, staging
6. Hooks active: infra-safety, git-safety, file-write-check, migration-check, ms365-audit
7. Quality gates: tests, security review, multi-tenant isolation required

EOF

# --- List modified files if any ---
if [ "$UNCOMMITTED_COUNT" -gt 0 ]; then
  echo "Modified Files (preserve awareness):"
  git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | head -20
  echo ""
fi

# --- Recent commits for continuity ---
if $HAS_GIT; then
  echo "Recent Work (last 3 commits):"
  git -C "$PROJECT_DIR" log --oneline -3 2>/dev/null
  echo ""
fi

exit 0
