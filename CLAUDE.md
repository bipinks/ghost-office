# CLAUDE.md — Autonomous AI Software Company

## Project Overview

A **fully autonomous AI-driven software company** powered by Claude Code. The system operates as an entire engineering and operations department with a master orchestrator coordinating 13 specialized agents across product management, engineering, QA, security, DevOps, and support. ERP development is a core specialty, with built-in domain knowledge for enterprise resource planning systems.

## Architecture

All components live under `.claude/` for native auto-discovery:

```
.claude/
├── agents/         — 14 autonomous agents (1 orchestrator + 12 departments + 1 specialist)
├── commands/       — 17 slash commands for task execution
├── workflows/      — 5 end-to-end workflow definitions
├── memory/         — 6 knowledge base documents (persistent context)
├── tools/          — 4 tool reference documents
├── skills/         — 26 domain knowledge packs
├── rules/          — 11 always-follow guidelines (7 categories)
├── hooks/          — 11 safety, audit, and lifecycle hook scripts
└── settings.json   — Hooks, permissions, and autonomous operation settings
```

## Agent Team

### Master Orchestrator
The central coordinator — assigns tasks, manages workflows, tracks progress, and ensures quality standards.

### Department Agents
| Agent | Role |
|-------|------|
| architecture-agent | System design, tech decisions, infrastructure planning |
| product-manager | Requirements, user stories, feature specs, prioritization |
| backend-engineer | Server-side code, APIs, business logic (Laravel/Django) |
| frontend-engineer | UI/UX, components, responsive design (Vue/React) |
| database-engineer | Schema design, migrations, query optimization, backups |
| qa-agent | Test strategy, test writing, bug verification, quality gates |
| security-agent | Security audits, OWASP, CIS benchmarks, compliance |
| devops-engineer | CI/CD, Docker, Kubernetes, infrastructure automation, SSH deployments |
| monitoring-agent | Observability, alerting, incident response, post-mortems |
| performance-agent | Optimization, load testing, cost analysis, caching |
| support-agent | User issue triage, client operations, Acodax administration |
| documentation-agent | API docs, user guides, ADRs, changelog |
| ms-it-admin | Microsoft 365 & Entra ID administration |

## Workflows

| Workflow | Trigger | Key Agents |
|----------|---------|------------|
| feature-development | `/implement-feature` | All agents, parallel phases |
| bug-fix | `/fix-bug` | Support → Engineer → QA |
| release-process | `/deploy-production` | QA → Security → DevOps |
| production-incident | `/investigate-incident` | Monitoring → DevOps → Engineers |
| client-deployment | New client setup | Support → Backend → DevOps |

## Knowledge Base

Agents reference `.claude/memory/` for persistent context:
- @.claude/memory/architecture.md — System architecture overview
- @.claude/memory/coding-standards.md — Coding conventions (Laravel/PHP, Vue/TS)
- @.claude/memory/domain-knowledge.md — Domain expertise and business rules (ERP specialty)
- @.claude/memory/deployment-standards.md — Staging/production deployment procedures
- @.claude/memory/devops-runbook.md — Server management, CI/CD, backups
- @.claude/memory/performance-guidelines.md — Optimization targets and rules

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
| `session-start.sh` | SessionStart | Injects project context on session start/resume/compact |
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
