# Architecture Report — DevOps Agent Hub → Autonomous ERP Workspace

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
│   ├── agents/         — 14 specialized DevOps subagents
│   ├── commands/       — 18 slash commands
│   ├── skills/         — 27 domain knowledge packs
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

## 2. Existing Agents (14 total)

| Agent | Domain | Preserve? | Disposition |
|-------|--------|-----------|-------------|
| ms-it-admin | Microsoft 365 administration | **Yes** | Keep as-is, integrate with IT/admin functions |
| acodax-erp-office-admin | Acodax ERP user/role management | **Yes** | Keep as-is, core ERP admin agent |
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

## 3. Existing Skills (27 total)

Skills are retained as knowledge packs and referenced by new agents:

- **Cloud/Infra**: aws-patterns, terraform-patterns, networking-patterns, serverless-patterns
- **Container/K8s**: docker-patterns, kubernetes-patterns
- **CI/CD**: cicd-patterns, github-workflows, gitops-patterns
- **Security**: security-hardening, secrets-management, ssl-tls-management
- **Monitoring**: monitoring-patterns, log-management
- **Database**: database-ops
- **Web/Server**: nginx-patterns, ansible-patterns
- **Cost**: cloud-cost-optimization
- **Backup**: backup-disaster-recovery
- **MS365**: ms365-admin, entra-id-admin, exchange-online-admin, intune-device-mgmt
- **Acodax**: acodax-erp-office-admin, deploy-acodax-property
- **Files**: file-management
- **Forge**: laravel-forge (kept for deployment reference)

## 4. Existing Commands (18 total)

Commands retained where relevant, new ERP-focused commands added.

## 5. Existing Rules (7 categories)

All rules retained — they provide safety guardrails:
- `common/`: coding-style, git-workflow, performance, security, testing
- `cicd/`, `cloud/`, `docker/`, `kubernetes/`, `security/`, `terraform/`

## 6. Hooks & Safety

Current hooks (retained and extended):
- **PreToolUse (Bash)**: Warns on destructive infra operations (terraform apply/destroy, kubectl delete, aws delete)
- **PostToolUse (Write|Edit)**: Scans for hardcoded secrets, Dockerfile best practices, YAML lint

## 7. MCP Integrations (9 servers)

All retained — they provide external service access:
- GitHub, AWS, Cloudflare, Vercel, Supabase, MS365, Filesystem, Docker, Kubernetes

## 8. Transformation Plan

### New Structure
```
.claude/
├── agents/         — 13 new autonomous agents + master orchestrator + preserved agents
├── commands/       — 9 new ERP commands + preserved essential commands
├── workflows/      — 5 workflow definitions (NEW)
├── memory/         — 6 knowledge base documents (NEW)
├── tools/          — 4 tool reference documents (NEW)
├── skills/         — All 27 existing skills (preserved)
├── rules/          — All existing rules (preserved)
└── settings.json   — Enhanced for autonomous operation
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
