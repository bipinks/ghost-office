#!/bin/bash
# Hook: SessionStart — Project Context Injection
# Injects critical project context at session start, resume, and compact events.
# Includes domain detection via domain.lock for lazy, cached domain knowledge loading.
# Exit 0 = allow (context injection only)

INPUT_JSON="$(cat)"
EVENT_TYPE=""

if command -v jq >/dev/null 2>&1; then
  EVENT_TYPE="$(printf '%s' "$INPUT_JSON" | jq -r '.type // "startup"' 2>/dev/null)"
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# --- Detect git state (single command check) ---
BRANCH=""
RECENT_CHANGES=""
UNCOMMITTED=""
if command -v git >/dev/null 2>&1; then
  BRANCH="$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  RECENT_CHANGES="$(git -C "$PROJECT_DIR" log --oneline -5 2>/dev/null)"
  UNCOMMITTED="$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | head -10)"
fi

# --- Detect active domain (cached in domain.lock) ---
DOMAIN_LOCK="$PROJECT_DIR/.claude/memory/domain.lock"
ACTIVE_DOMAIN=""
DOMAIN_STATUS=""

if [ -f "$DOMAIN_LOCK" ]; then
  ACTIVE_DOMAIN="$(cat "$DOMAIN_LOCK" 2>/dev/null | tr -d '[:space:]')"
  DOMAIN_STATUS="$ACTIVE_DOMAIN (cached — use /set-domain to change)"
else
  DOMAIN_STATUS="not set — use /set-domain <domain> to activate"
fi

# --- Output context summary ---
cat <<EOF

=== AI Software Company — Workspace Context ===
Project: Autonomous AI Software Company (Claude Code native)
Type: AI-driven software company — multi-tenant, multi-branch capable
Session Event: ${EVENT_TYPE:-startup}
Branch: ${BRANCH:-unknown}
Domain: ${DOMAIN_STATUS}

Key References:
- Architecture: .claude/memory/architecture.md
- Coding Standards: .claude/memory/coding-standards.md
- Domain Knowledge: .claude/memory/domain-knowledge.md
- Deployment: .claude/memory/deployment-standards.md

Active Hooks: infra-safety, git-safety, file-write-check, migration-check, ms365-audit
Quality Gates: Tests required, security review, multi-tenant isolation

CRITICAL RULES:
- All database tables MUST include branch_id for multi-tenant isolation
- NEVER commit secrets, API keys, or passwords
- NEVER force-push to protected branches (main, master, develop, production, staging)
- All migrations MUST have rollback methods
- Use conventional commits: feat:, fix:, docs:, chore:

EOF

if [ -n "$RECENT_CHANGES" ]; then
  echo "Recent Commits:"
  echo "$RECENT_CHANGES"
  echo ""
fi

if [ -n "$UNCOMMITTED" ]; then
  echo "Uncommitted Changes:"
  echo "$UNCOMMITTED"
  echo ""
fi

exit 0
