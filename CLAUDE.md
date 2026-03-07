# CLAUDE.md — Autonomous AI Software Company

## Project Overview

A **fully autonomous AI-driven software company** powered by Claude Code. The system operates as an entire engineering and operations department with a master orchestrator coordinating 17 specialized agents across 7 departments: product, engineering, quality, operations, marketing, support, and IT. Ships with 7 switchable domain knowledge packs (ERP, E-Commerce, SaaS, Healthcare, Fintech, Education, CMS) — use `/set-domain` to activate.

## Architecture

All components live under `.claude/` for native auto-discovery:

```
.claude/
├── agents/         — 18 autonomous agents (1 orchestrator + 17 departments)
├── commands/       — 22 slash commands for task execution
├── workflows/      — 6 end-to-end workflow definitions
├── memory/         — 6 knowledge base documents + 7 domain templates (persistent context)
├── tools/          — 4 tool reference documents
├── skills/         — 54 domain knowledge packs
├── rules/          — 12 always-follow guidelines (7 categories)
├── hooks/          — 11 safety, audit, and lifecycle hook scripts
└── settings.json   — Hooks, permissions, and autonomous operation settings
```

## Agent Team

### Master Orchestrator
The central coordinator — assigns tasks, manages workflows, tracks progress, and ensures quality standards.

### Department Agents
| Agent | Department | Role |
|-------|------------|------|
| product-manager | Product | Requirements, user stories, feature specs, prioritization |
| ui-ux-designer | Product | Visual design, wireframes, design systems, accessibility |
| architecture-agent | Engineering | System design, tech decisions, infrastructure planning |
| backend-engineer | Engineering | Server-side code, APIs, business logic (Laravel/Django) |
| frontend-engineer | Engineering | UI/UX implementation, components, responsive design (Vue/React) |
| database-engineer | Engineering | Schema design, migrations, query optimization, backups |
| prompt-engineer | Engineering | AI prompt design, LLM integration, conversational AI |
| qa-agent | Quality | Test strategy, test writing, bug verification, quality gates |
| security-agent | Quality | Security audits, OWASP, CIS benchmarks, compliance |
| devops-engineer | Operations | CI/CD, Docker, Kubernetes, infrastructure automation, SSH deployments |
| monitoring-agent | Operations | Observability, alerting, incident response, post-mortems |
| performance-agent | Operations | Optimization, load testing, cost analysis, caching |
| content-strategist | Marketing | Content planning, copywriting, SEO, email marketing |
| social-media-manager | Marketing | Social media strategy, community, paid advertising |
| support-agent | Support | User issue triage, client operations, Acodax administration |
| documentation-agent | Support | API docs, user guides, ADRs, changelog |
| ms-it-admin | IT | Microsoft 365 & Entra ID administration |

## Workflows

| Workflow | Trigger | Key Agents |
|----------|---------|------------|
| feature-development | `/implement-feature` | All agents, parallel phases |
| bug-fix | `/fix-bug` | Support → Engineer → QA |
| release-process | `/deploy-production` | QA → Security → DevOps |
| production-incident | `/investigate-incident` | Monitoring → DevOps → Engineers |
| client-deployment | New client setup | Support → Backend → DevOps |
| content-campaign | `/create-content` | Content-strategist → SEO → Social |

## Knowledge Base

Agents reference `.claude/memory/` for persistent context:
- @.claude/memory/architecture.md — System architecture overview
- @.claude/memory/coding-standards.md — Coding conventions (Laravel/PHP, Vue/TS)
- @.claude/memory/domain-knowledge.md — Active domain expertise and business rules
- @.claude/memory/deployment-standards.md — Staging/production deployment procedures
- @.claude/memory/devops-runbook.md — Server management, CI/CD, backups
- @.claude/memory/performance-guidelines.md — Optimization targets and rules

### Domain Templates (`.claude/memory/domains/`)
Switchable domain knowledge packs — use `/set-domain <name>` to activate:
| Domain | File | Specialty |
|--------|------|-----------|
| ERP | `erp.md` | Accounting, inventory, sales, HR, procurement, manufacturing |
| E-Commerce | `ecommerce.md` | Catalog, cart, checkout, orders, payments, shipping |
| SaaS | `saas.md` | Subscriptions, multi-tenancy, billing, feature flags |
| Healthcare | `healthcare.md` | EHR, HIPAA compliance, clinical workflows, HL7 FHIR |
| Fintech | `fintech.md` | Payments, ledger, KYC/AML, fraud detection, PCI DSS |
| Education | `education.md` | Courses, assessments, LMS, FERPA/COPPA compliance |
| CMS | `cms.md` | Content authoring, SEO, headless API, localization |

The active domain is cached in `.claude/memory/domain.lock` — detection runs once, not every session.

## Key Commands

| Command | Purpose |
|---------|---------|
| `/implement-feature` | End-to-end feature development |
| `/fix-bug` | Bug investigation and fix |
| `/deploy-staging` | Deploy to staging |
| `/deploy-production` | Deploy to production (approval gate) |
| `/analyze-project` | Full project analysis |
| `/write-tests` | Write comprehensive tests |
| `/refactor-module` | Module refactoring |
| `/monitor-system` | System health check |
| `/investigate-incident` | Incident response |
| `/security-scan` | Security audit |
| `/create-content` | Content strategy and creation |
| `/social-media` | Social media campaigns |
| `/design-ui` | UI/UX design and wireframes |
| `/ai-prompt` | AI prompt engineering |
| `/set-domain` | Switch domain knowledge (erp, ecommerce, saas, healthcare, fintech, education, cms) |

## References

- Agent roster: @AGENTS.md
- Architecture report: @docs/architecture_report.md
- Beginner guide: @BEGINNERS-GUIDE.md
- Contribution guide: @CONTRIBUTING.md

## Key Conventions

- Agents use frontmatter: name, description, tools, disallowedTools, model, maxTurns, skills, permissionMode, isolation
- Skills directories contain a `SKILL.md` as the main instruction
- Commands use `$ARGUMENTS` substitution
- Rules use `paths` frontmatter for file-pattern scoping
- Workflows define parallel and sequential execution phases
- Memory files are the persistent knowledge base for all agents

IMPORTANT: The following rules are enforced by hooks and MUST be followed:
- NEVER store secrets, API keys, or passwords in code — use a secrets manager
- NEVER force-push to protected branches (main, master, develop, production, staging)
- NEVER run destructive infrastructure commands without explicit confirmation
- All database tables MUST include `branch_id` for multi-tenant data isolation
- All migrations MUST include rollback/down methods
- Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
- When adding/removing agents, skills, commands, workflows, or hooks, ALWAYS update documentation counts in `CLAUDE.md`, `AGENTS.md`, `README.md`, `BEGINNERS-GUIDE.md`, and `docs/architecture_report.md` (see `.claude/rules/common/documentation-sync.md`)

## Autonomous Operation

The workspace enables Claude Code to:
- Break down tasks and assign to specialized agents
- Execute parallel work streams for independent subtasks (with worktree isolation)
- Run quality gates (tests, security review) before deployment
- Manage full feature lifecycle across any domain (requirements → deploy)
- Handle incidents with structured triage and resolution
- Maintain audit trails for all operations (MS365 audit logging)
- Reference the knowledge base for consistent decision-making
- Auto-inject project context on session start/resume (SessionStart hook)
- Preserve critical context before compaction (PreCompact hook)
- Auto-approve read-only tools via permissions (allowedTools)
- Block destructive commands via deny rules

## Testing

- Validate JSON: `node -e "JSON.parse(require('fs').readFileSync('FILE','utf8'))"`
- Check structure: `node scripts/validate-structure.js`
- Verify agents: `ls .claude/agents/`
- Verify commands: `ls .claude/commands/`
- Verify workflows: `ls .claude/workflows/`
- Verify memory: `ls .claude/memory/`
- Run all tests: `npm test`

## Hooks

11 hook scripts in `.claude/hooks/` enforce safety, compliance, and observability:

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Injects project context + active domain on session start/resume/compact |
| `pre-compact.sh` | PreCompact | Preserves critical context before auto-compaction |
| `infra-safety-check.sh` | PreToolUse (Bash) | Warns on destructive infrastructure commands |
| `git-safety-check.sh` | PreToolUse (Bash) | Blocks force-push to protected branches |
| `file-write-check.sh` | PostToolUse (Write/Edit) | Scans for secrets, Dockerfile issues, YAML lint |
| `migration-check.sh` | PostToolUse (Write/Edit) | Enforces branch_id in new migrations |
| `ms365-audit-log.sh` | PreToolUse (MS365) | Logs all MS365 operations for audit |
| `subagent-lifecycle.sh` | SubagentStart/Stop | Tracks subagent spawn and completion |
| `notification.sh` | Notification | Desktop alerts when Claude needs input |
| `stop-validation.sh` | Stop | Post-response validation (staged secrets check) |
| `tool-failure.sh` | PostToolUseFailure | Logs tool failures with diagnostic hints |

## Important

- This is a Claude Code native project — no plugin install required
- All content is markdown, JSON, and shell scripts
- Components auto-discover from `.claude/` at session start
- The master-orchestrator coordinates all agent activity
- Existing skills, rules, hooks, scripts, and MCP integrations are preserved
