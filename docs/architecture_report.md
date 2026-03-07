# Architecture Report — DevOps Agent Hub → Autonomous AI Software Company

**Generated**: 2026-03-06
**Status**: Pre-transformation analysis

---

## 1. Current Repository Overview

### Project Type
Claude Code native DevOps toolkit — a collection of markdown-based agents, skills, commands, rules, and hooks that extend Claude Code with DevOps domain expertise.

### Technology Stack
- **Runtime**: Node.js >= 18.0.0
- **Configuration**: Markdown (agents, skills, commands, rules), JSON (settings, MCP)
- **Scripts**: JavaScript/ESM (`scripts/*.mjs`, `scripts/*.js`)
- **CI/CD**: GitHub Actions (`.github/workflows/ci-validate.yml`)
- **External Services (MCP)**: GitHub, AWS, Cloudflare, Vercel, Supabase, MS365, Docker, Kubernetes, Filesystem

### Directory Structure (Pre-Transformation)
```
devops-agent-hub/
├── .claude/
│   ├── agents/         — 18 specialized agents (7 departments)
│   ├── commands/       — 22 slash commands
│   ├── skills/         — 54 domain knowledge packs
│   ├── rules/          — 7 rule categories (common, cicd, cloud, docker, kubernetes, security, terraform)
│   └── settings.json   — Infrastructure safety hooks (PreToolUse, PostToolUse)
├── .github/workflows/  — CI validation pipeline
├── .mcp.json           — 9 MCP server configurations
├── contexts/           — 4 dynamic context modes (deploy, dev, incident, review)
├── examples/           — 4 CLAUDE.md templates for real projects
├── scripts/            — Node.js utilities (ms365.mjs, acodax.mjs, setup, validate, tests)
├── CLAUDE.md           — Project instructions
├── AGENTS.md           — Agent orchestration guide
├── BEGINNERS-GUIDE.md  — Onboarding documentation
├── CONTRIBUTING.md     — Contribution guidelines
├── package.json        — Project metadata and scripts
└── README.md           — Public documentation
```

## 2. Existing Agents (18 total)

| Agent | Domain | Preserve? | Disposition |
|-------|--------|-----------|-------------|
| ms-it-admin | Microsoft 365 administration | **Yes** | Keep as-is, integrate with IT/admin functions |
| acodax-erp-office-admin | Acodax ERP user/role management | **Yes** | Keep as-is, domain-specific admin agent |
| deployer | SSH-based project deployment | **Yes** | Keep, absorb into devops-engineer scope |
| security-auditor | CIS/OWASP security audits | Absorb | Merge into security-agent |
| cicd-architect | CI/CD pipeline design | Absorb | Merge into devops-engineer |
| cloud-reviewer | IaC code review | Absorb | Merge into architecture-agent |
| container-reviewer | Docker/K8s review | Absorb | Merge into devops-engineer |
| cost-optimizer | Cloud cost analysis | Absorb | Merge into performance-agent |
| database-ops | Database operations | Absorb | Merge into database-engineer |
| deployment-manager | Deployment orchestration | Absorb | Merge into devops-engineer |
| file-manager | Filesystem operations | Absorb | Merge into support-agent |
| incident-responder | Incident triage | Absorb | Merge into monitoring-agent |
| infra-planner | Infrastructure design | Absorb | Merge into architecture-agent |
| monitoring-analyst | Observability/SLOs | Absorb | Merge into monitoring-agent |

## 3. Skills (54 total)

Skills are retained as knowledge packs and referenced by new agents:

- **Cloud/Infra**: aws-patterns, terraform-patterns, networking-patterns
- **Container/K8s**: docker-patterns, kubernetes-patterns
- **CI/CD**: cicd-patterns, github-workflows
- **Security**: security-hardening, secrets-management, ssl-tls-management
- **Monitoring**: monitoring-patterns, log-management
- **Database**: database-ops, postgresql-patterns, redis-patterns
- **Web/Server**: nginx-patterns, ansible-patterns
- **Cost**: cloud-cost-optimization
- **Backend**: laravel-patterns, api-design, authentication-patterns, multi-tenancy-patterns
- **Frontend**: vue-patterns, typescript-patterns, frontend-patterns
- **Testing/QA**: testing-patterns, qa-testing-strategy
- **Performance**: performance-optimization
- **Product**: product-management
- **Incident**: incident-management
- **Documentation**: documentation-standards
- **Backup**: backup-disaster-recovery
- **MS365**: ms365-admin, entra-id-admin, exchange-online-admin, intune-device-mgmt
- **Acodax**: acodax-erp-office-admin, deploy-acodax-property

## 4. Existing Commands (21 total)

Commands retained where relevant, new ERP-focused commands added.

## 5. Existing Rules (7 categories)

All rules retained — they provide safety guardrails:
- `common/`: coding-style, git-workflow, performance, security, testing
- `cicd/`, `cloud/`, `docker/`, `kubernetes/`, `security/`, `terraform/`

## 6. Hooks & Safety (11 hooks)

All hooks externalized to `.claude/hooks/` scripts:
- **SessionStart (startup|resume|compact)**: `session-start.sh` — Injects ERP project context (branch, recent changes, critical rules)
- **PreToolUse (Bash)**: `infra-safety-check.sh` — Warns on destructive infra operations (terraform apply/destroy, kubectl delete, aws delete)
- **PreToolUse (Bash)**: `git-safety-check.sh` — Blocks force-push to protected branches (exit 2), warns on direct push
- **PreToolUse (mcp__ms365__)**: `ms365-audit-log.sh` — Logs all MS365 operations for compliance audit trail
- **PostToolUse (Write|Edit)**: `file-write-check.sh` — Scans for hardcoded secrets, Dockerfile best practices, YAML lint
- **PostToolUse (Write|Edit)**: `migration-check.sh` — Enforces branch_id in new migration files (multi-tenant)
- **PreCompact (auto|manual)**: `pre-compact.sh` — Preserves critical task context before auto-compaction

### Permissions Configuration
- **allowedTools**: Read-only tools auto-approved (Read, Glob, Grep, TodoWrite, Agent, WebSearch, MS365 list/get)
- **deny**: Destructive commands blocked (rm -rf /, terraform destroy, DROP DATABASE, force-push to protected branches)

## 7. MCP Integrations (9 servers)

All retained — they provide external service access:
- GitHub, AWS, Cloudflare, Vercel, Supabase, MS365, Filesystem, Docker, Kubernetes

## 8. Transformation Plan

### New Structure
```
.claude/
├── agents/         — 18 autonomous agents (1 orchestrator + 17 departments)
├── commands/       — 21 slash commands
├── workflows/      — 6 workflow definitions
├── memory/         — 6 knowledge base documents + 7 domain templates (NEW)
│   └── domains/    — Switchable domain packs (erp, ecommerce, saas, healthcare, fintech, education, cms)
├── tools/          — 4 tool reference documents (NEW)
├── skills/         — 54 domain knowledge packs
├── rules/          — All existing rules (preserved)
├── hooks/          — 11 hook scripts (session-start, pre-compact, infra-safety, git-safety, file-write, migration, ms365-audit, subagent-lifecycle, notification, stop-validation, tool-failure)
└── settings.json   — Enhanced with hooks, permissions (allowedTools/deny), and autonomous operation
```

### Preserved Unchanged
- All skills (`.claude/skills/`)
- All rules (`.claude/rules/`)
- All scripts (`scripts/`)
- MCP configuration (`.mcp.json`)
- CI/CD pipeline (`.github/workflows/`)
- Contexts (`contexts/`)
- Examples (`examples/`)

### Key Principle
No existing functionality breaks. New agents reference existing skills. Old agent knowledge is absorbed into new department-style agents.
