# Autonomous AI Software Company — Agent Instructions

A **fully autonomous AI-driven software company** with 14 specialized agents, 26 skills, 17 commands, 5 workflows, 11 hooks, and a persistent knowledge base for end-to-end product development, operations, and support.

## Core Principles
1. **Agent-First** — Delegate to specialized agents for domain tasks
2. **Autonomous Operation** — Agents self-coordinate via the master orchestrator
3. **Quality Gates** — Tests, security review, and approval before deployment
4. **Knowledge-Driven** — All agents reference `.claude/memory/` for consistency
5. **Parallel Execution** — Independent tasks run simultaneously for efficiency
6. **Audit Everything** — Log all actions, decisions, and changes
7. **Security-First** — Never compromise on security; validate all changes

## Agent Roster

### Master Orchestrator
| Agent | Purpose | When Active |
|-------|---------|-------------|
| master-orchestrator | Central coordinator of all agents | Every task — plans, assigns, tracks, delivers |

### Department Agents
| Agent | Purpose | When to Use |
|-------|---------|-------------|
| architecture-agent | System design, tech decisions | New features, refactors, architecture reviews |
| product-manager | Requirements, specs, priorities | Feature planning, user stories, acceptance criteria |
| backend-engineer | Server-side code, APIs, logic | Backend features, API endpoints, integrations |
| frontend-engineer | UI/UX, client-side code | Frontend features, UI bugs, responsive design |
| database-engineer | Schema, queries, migrations | DB changes, migrations, query optimization |
| qa-agent | Testing, quality assurance | Test writing, bug verification, regression testing |
| security-agent | Security audits, vulnerabilities | Security reviews, pen testing, compliance |
| devops-engineer | CI/CD, infrastructure, SSH deployments | Pipeline setup, server config, deployments, SSH deploys |
| monitoring-agent | Observability, alerting, incidents | Monitoring setup, incident triage, RCA |
| performance-agent | Optimization, profiling, cost | Performance issues, optimization, cost analysis |
| support-agent | User issues, triage, client admin | Bug reports, client setup, Acodax user/role management |
| documentation-agent | Tech docs, API docs, guides | Documentation, changelogs, ADRs |
| ms-it-admin | Microsoft 365 administration | User provisioning, licensing, Teams, Exchange |

## Agent Orchestration

### Automatic Assignment
The master-orchestrator automatically routes tasks:
- Feature requests → product-manager → architecture-agent → engineers → qa-agent
- Bug reports → support-agent → relevant engineer → qa-agent
- Deployments → devops-engineer → monitoring-agent
- Security concerns → security-agent (immediate priority)
- Incidents → monitoring-agent → devops-engineer → engineers
- Documentation → documentation-agent
- Performance issues → performance-agent
- Microsoft 365 tasks → ms-it-admin
- Acodax admin → support-agent
- SSH deployments → devops-engineer

### Parallel Execution
Launch multiple agents simultaneously for independent tasks:
- Backend + frontend implementation (after design phase)
- Security review + architecture review (post-implementation)
- Documentation + deployment preparation
- Multiple investigation tracks during incidents

## Workflows

| Workflow | File | Phases |
|----------|------|--------|
| Feature Development | `.claude/workflows/feature-development.md` | Requirements → Design → Implement → Test → Review → Deploy |
| Bug Fix | `.claude/workflows/bug-fix.md` | Triage → Investigate → Fix → Test → Deploy |
| Release Process | `.claude/workflows/release-process.md` | Freeze → QA → Security → Staging → Approval → Production |
| Production Incident | `.claude/workflows/production-incident.md` | Detect → Triage → Investigate → Mitigate → Resolve → Post-mortem |
| Client Deployment | `.claude/workflows/client-deployment.md` | Requirements → Tenant → Config → Data → Deploy → Verify |

## Knowledge Base

All agents reference `.claude/memory/` before making decisions:
| Document | Contents |
|----------|----------|
| `architecture.md` | System architecture, module structure, API design |
| `coding-standards.md` | Laravel/PHP, Vue/TS conventions, git workflow |
| `domain-knowledge.md` | Domain expertise, business rules, multi-branch operations (ERP specialty) |
| `deployment-standards.md` | Environment setup, deployment checklists, rollback |
| `devops-runbook.md` | Server management, backups, CI/CD, troubleshooting |
| `performance-guidelines.md` | Performance targets, optimization rules, caching |

## Security Guidelines
**Before ANY change:**
- No hardcoded secrets (API keys, passwords, tokens, certificates)
- IAM follows least privilege principle
- Encryption at rest enabled for all storage
- Encryption in transit (TLS 1.2+) for all communication
- Multi-tenant data isolation verified
- Audit logging for all data changes
- Container images scanned for vulnerabilities

**If security issue found:** STOP → use security-agent → fix CRITICAL issues → rotate exposed credentials → review for similar issues.

## Coding Style
Reference `.claude/memory/coding-standards.md` for full details:
- **PHP/Laravel**: PSR-12, thin controllers, service layer for business logic
- **TypeScript/Vue**: Composition API, type-safe props, component-based architecture
- **Database**: snake_case, branch_id for multi-tenant tables, soft deletes, audit columns
- **API**: RESTful, versioned, consistent response envelope
- **Git**: Conventional commits, feature branches, squash merge

## Quality Requirements
Every deliverable must meet:
- [ ] Code follows coding standards
- [ ] Tests written and passing (80%+ coverage)
- [ ] Security review passed
- [ ] Multi-tenant isolation verified
- [ ] Documentation updated
- [ ] Database migrations reversible
- [ ] No breaking changes to existing APIs

## Project Structure
```
.claude/
  agents/         — 14 autonomous agents
  commands/       — 17 slash commands
  workflows/      — 5 workflow definitions
  memory/         — 6 knowledge base documents
  tools/          — 4 tool reference documents
  skills/         — 26 domain knowledge packs
  rules/          — 11 guidelines (7 categories)
  hooks/          — 11 safety, audit, and lifecycle hook scripts
  settings.json   — Hooks, permissions, and autonomous settings
.mcp.json         — MCP server configurations (GitHub, AWS, MS365, etc.)
scripts/          — Node.js utilities (ms365, acodax, validation)
contexts/         — 4 dynamic context modes
examples/         — CLAUDE.md templates for real projects
docs/             — Architecture reports and documentation
```

## Success Metrics
- All changes go through agent-coordinated quality gates
- No security vulnerabilities in deployed code
- Zero secrets exposed in code or logs
- Tests passing with 80%+ coverage
- Multi-tenant data isolation verified for multi-tenant features
- Deployment rollback available within 5 minutes
- Mean Time To Recovery (MTTR) under 30 minutes for SEV1
- Every feature has documentation and changelog entry
