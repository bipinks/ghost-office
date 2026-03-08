# CLAUDE.md — Autonomous AI Software Company

## Overview

Fully autonomous AI software company: 1 master orchestrator + 17 agents across 7 departments, 54 skills, 23 commands, 6 workflows, 12 hooks. Use `/set-domain` to switch domain knowledge (erp, ecommerce, saas, healthcare, fintech, education, cms).

## Structure

```
.claude/
├── agents/      — 18 agents (1 orchestrator + 17 departments)
├── commands/    — 23 slash commands
├── workflows/   — 6 workflow definitions
├── memory/      — 6 knowledge docs + 7 domain templates
├── skills/      — 54 domain knowledge packs
├── rules/       — 12 guidelines (7 categories)
├── hooks/       — 12 safety/audit/lifecycle hooks
├── tools/       — 4 tool references
└── settings.json
```

## Agent Routing

| Department | Agents | Tasks |
|------------|--------|-------|
| Product | product-manager, ui-ux-designer | Requirements, wireframes, design systems |
| Engineering | architecture, backend, frontend, database, prompt-engineer | System design, code, APIs, schemas, AI |
| Quality | qa-agent, security-agent | Tests, security audits, compliance |
| Operations | devops-engineer, monitoring, performance | CI/CD, deployments, observability |
| Marketing | content-strategist, social-media-manager | Content, SEO, campaigns |
| Support | support-agent, documentation-agent | Triage, docs, changelogs |
| IT | ms-it-admin | Microsoft 365 administration |

## Knowledge Base

Agents reference `.claude/memory/` before decisions:
- @.claude/memory/architecture.md — System architecture
- @.claude/memory/coding-standards.md — Laravel/PHP, Vue/TS conventions
- @.claude/memory/domain-knowledge.md — Active domain rules (set via `/set-domain`)
- @.claude/memory/deployment-standards.md — Deployment procedures
- @.claude/memory/devops-runbook.md — Server ops, CI/CD, backups
- @.claude/memory/performance-guidelines.md — Performance targets

## Key Commands

`/implement-feature`, `/fix-bug`, `/deploy-staging`, `/deploy-production`, `/analyze-project`, `/write-tests`, `/refactor-module`, `/monitor-system`, `/investigate-incident`, `/security-scan`, `/create-content`, `/social-media`, `/design-ui`, `/ai-prompt`, `/set-domain`, `/agent-status`

## Conventions

- Agents: frontmatter with name, description, tools, model, skills, permissionMode
- Skills: `SKILL.md` as entry point per skill directory
- Commands: `$ARGUMENTS` substitution
- Rules: `paths` frontmatter for file-pattern scoping
- Workflows: parallel + sequential execution phases

## Mandatory Rules (hook-enforced)

- NEVER store secrets, API keys, or passwords in code
- NEVER force-push to protected branches (main, master, develop, production, staging)
- NEVER run destructive infra commands without confirmation
- All database tables MUST include `branch_id` for multi-tenant isolation
- All migrations MUST include rollback/down methods
- Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
- When changing component counts, update docs: CLAUDE.md, AGENTS.md, README.md, BEGINNERS-GUIDE.md, docs/architecture_report.md

## Testing

- Validate structure: `node scripts/validate-structure.js`
- Run all tests: `npm test`

## References

- @AGENTS.md — Agent roster and orchestration
- @BEGINNERS-GUIDE.md — Onboarding guide
- @CONTRIBUTING.md — Contribution guidelines
