# Architecture Report — Autonomous AI Software Company

**Updated**: 2026-03-08

## Overview

Claude Code native workspace — markdown agents, skills, commands, rules, and hooks that extend Claude Code into an autonomous AI software company. No runtime dependencies beyond Node.js 18+ for validation scripts.

**Stack**: Markdown, JSON, Shell scripts, JavaScript/ESM | **CI**: GitHub Actions | **MCP**: GitHub, AWS, Cloudflare, Vercel, Supabase, MS365, Docker, Kubernetes, Filesystem

## Structure

```
.claude/
├── agents/      — 18 agents (1 orchestrator + 17 specialists)
├── commands/    — 23 slash commands
├── workflows/   — 6 workflow definitions
├── memory/      — 6 knowledge docs + 7 domain templates
├── skills/      — 53 domain knowledge packs
├── rules/       — 12 guidelines (7 categories)
├── hooks/       — 13 safety/audit/lifecycle hooks
├── status/      — Runtime: agent status, todos, errors, session history
├── tools/       — 4 tool reference documents
└── settings.json
```

## Agents (18)

| Dept | Agents |
|------|--------|
| Product | product-manager, ui-ux-designer |
| Engineering | architecture-agent, backend-engineer, frontend-engineer, database-engineer, prompt-engineer |
| Quality | qa-agent, security-agent |
| Operations | devops-engineer, monitoring-agent, performance-agent |
| Marketing | content-strategist, social-media-manager |
| Support | support-agent, documentation-agent |
| IT | ms-it-admin |

## Skills (53)

**Cloud/Infra**: aws, terraform, networking, ansible, nginx | **Container**: docker, kubernetes | **CI/CD**: cicd-patterns, github-workflows | **Security**: security-hardening, secrets-management, ssl-tls | **Monitoring**: monitoring-patterns, log-management | **Database**: database-ops, postgresql, redis | **Backend**: laravel, api-design, authentication, multi-tenancy | **Frontend**: vue, typescript, frontend-patterns, accessibility, design-systems | **Testing**: testing-patterns, qa-testing-strategy | **Performance**: performance-optimization, cloud-cost-optimization | **AI/ML**: prompt-design, llm-integration, conversational-ai, ai-evaluation | **Marketing**: seo, content-strategy, copywriting, email-marketing, paid-advertising, social-media-strategy, analytics-reporting, community-management | **Product**: product-management, ux-research, wireframing-prototyping | **Docs**: documentation-standards | **Backup**: backup-disaster-recovery | **MS365**: ms365-admin, entra-id, exchange-online, intune

## Hooks (13)

| Hook | Event | Purpose |
|------|-------|---------|
| session-start.sh | SessionStart | Project context + domain injection |
| pre-compact.sh | PreCompact | Context preservation |
| infra-safety-check.sh | PreToolUse (Bash) | Destructive command warnings |
| git-safety-check.sh | PreToolUse (Bash) | Force-push blocking |
| file-write-check.sh | PostToolUse (Write/Edit) | Secret scanning |
| migration-check.sh | PostToolUse (Write/Edit) | branch_id enforcement |
| ms365-audit-log.sh | PreToolUse (MS365) | Audit logging |
| todo-tracker.sh | PostToolUse (TodoWrite) | Per-agent task progress tracking |
| subagent-lifecycle.sh | SubagentStart/Stop | Agent tracking + session history |
| message-check.sh | PostToolUse | Dashboard↔agent messaging delivery |
| notification.sh | Notification | Desktop alerts |
| stop-validation.sh | Stop | Staged secrets check |
| tool-failure.sh | PostToolUseFailure | Failure diagnostics + error tracking |

## Dashboard & Analytics

### Terminal Dashboard
- `./scripts/agent-dashboard.sh` — Live TUI with overview, detail, errors, workflow, history, analytics views
- Multi-session support: `--sessions`, `--session <id>`, `--history`, `--analytics`, `--export`
- Interactive messaging: `[m]` messages, `[c]` send command to agents

### Web Dashboard (`:8686`)
- `scripts/web/dashboard.html` — Real-time agent monitoring with session selector
- `scripts/web/analytics.html` — Cross-session analytics with Chart.js charts
- `scripts/web/server.py` — Python HTTP server with JSON sync + SQLite analytics backend
- `scripts/web/Dockerfile` + `docker-compose.yml` — Containerized deployment via Docker Compose

### SQLite Analytics Backend
- Auto-created `data/dashboard.db` on first web server run
- Tables: `sessions`, `agent_runs`, `errors`, `messages`
- JSON → SQLite sync on each request (idempotent upsert)
- WAL journal mode for concurrent read/write
- Auto-prune: retains last 200 sessions

### Analytics API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/analytics/summary` | Total sessions, agents, errors, tokens, avg duration |
| `GET /api/analytics/agent-performance` | Per-agent: avg duration, error rate, usage count |
| `GET /api/analytics/department-performance` | Per-department aggregates |
| `GET /api/analytics/session-trends` | Last 50 sessions: duration, agent count, errors, tokens |
| `GET /api/analytics/workflow-bottlenecks` | Average time per workflow phase by department |
| `GET /api/analytics/error-breakdown` | Errors by tool and by agent |
| `GET /api/analytics/token-usage` | Token usage trends per session |
| `GET /api/analytics/message-stats` | Message volume, types, response times |

### Analytics Charts
Session duration trend (line), agent performance (bar), department breakdown (doughnut), error rate (bar), token usage (stacked area), workflow bottlenecks (horizontal bar), top error-prone tools (bar), message activity (line).

## Permissions

- **Allow**: Read-only tools auto-approved (Read, Glob, Grep, TodoWrite, Agent, WebSearch, MS365 list/get)
- **Deny**: rm -rf /, terraform destroy, kubectl delete namespace, DROP DATABASE/TABLE, force-push to protected branches
