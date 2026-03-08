<div align="center">

# Autonomous AI Software Company

### Drop a folder into any project. Get an entire engineering department.

**18 AI agents** across **7 departments** — product, engineering, quality, operations, marketing, support, and IT — all coordinated by a master orchestrator. Powered by [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agents](https://img.shields.io/badge/agents-18-blue)](.claude/agents/)
[![Skills](https://img.shields.io/badge/skills-54-green)](.claude/skills/)
[![Commands](https://img.shields.io/badge/commands-23-orange)](.claude/commands/)
[![Domains](https://img.shields.io/badge/domains-7-purple)](.claude/memory/domains/)

</div>

---

## What This Does

Copy `.claude/` and `CLAUDE.md` into your project. Claude Code instantly becomes an **autonomous AI software company** — a master orchestrator breaks down your task, assigns it to specialized agents, runs quality gates, and delivers production-ready results.

```
You: /implement-feature "Add invoice PDF generation with email delivery"

Orchestrator assigns:
  → product-manager     requirements + acceptance criteria
  → architecture-agent  solution design
  → backend-engineer    API + PDF service
  → frontend-engineer   UI components
  → database-engineer   migrations (with branch_id)
  → qa-agent            tests (80%+ coverage)
  → security-agent      vulnerability review
  → devops-engineer     CI/CD pipeline
  → documentation-agent API docs + changelog

Result: Complete feature — code, tests, docs, ready to deploy.
```

**No plugins. No install. Just markdown, JSON, and shell scripts.**

---

## Setup

### Use directly
```bash
git clone https://github.com/bipinks/devops-agent-hub.git
cd devops-agent-hub && claude
```

### Add to your project

**Minimum:**
```bash
cp -r devops-agent-hub/.claude/ your-project/.claude/
cp devops-agent-hub/CLAUDE.md your-project/CLAUDE.md
```

**Full setup:**
```bash
cp -r devops-agent-hub/.claude/ your-project/.claude/
cp devops-agent-hub/CLAUDE.md your-project/CLAUDE.md
cp devops-agent-hub/AGENTS.md your-project/AGENTS.md
cp devops-agent-hub/.mcp.json your-project/.mcp.json      # MCP integrations
cp -r devops-agent-hub/scripts/ your-project/scripts/      # Validation
cp -r devops-agent-hub/contexts/ your-project/contexts/    # Context modes
```

Then activate your domain: `/set-domain <name>` (erp, ecommerce, saas, healthcare, fintech, education, cms) and edit `CLAUDE.md` to match your project.

---

## The Team

<table>
<tr><td align="center"><b>Department</b></td><td align="center"><b>Agents</b></td><td align="center"><b>What They Do</b></td></tr>
<tr><td><b>Product</b></td><td>product-manager, ui-ux-designer</td><td>Requirements, user stories, wireframes, design systems</td></tr>
<tr><td><b>Engineering</b></td><td>architecture, backend, frontend, database, prompt-engineer</td><td>System design, APIs, UI, schemas, AI integration</td></tr>
<tr><td><b>Quality</b></td><td>qa-agent, security-agent</td><td>Tests, security audits, OWASP, compliance</td></tr>
<tr><td><b>Operations</b></td><td>devops-engineer, monitoring-agent, performance-agent</td><td>CI/CD, deployments, observability, optimization</td></tr>
<tr><td><b>Marketing</b></td><td>content-strategist, social-media-manager</td><td>Content strategy, SEO, campaigns, community</td></tr>
<tr><td><b>Support</b></td><td>support-agent, documentation-agent</td><td>Issue triage, API docs, user guides, changelogs</td></tr>
<tr><td><b>IT</b></td><td>ms-it-admin</td><td>Microsoft 365, Entra ID, Teams, Exchange</td></tr>
</table>

The **master-orchestrator** coordinates everything — plans work, assigns agents, runs parallel streams, and enforces quality gates.

---

## Commands

| Command | What Happens |
|---------|-------------|
| `/implement-feature "..."` | Full lifecycle: requirements → design → code → test → docs |
| `/fix-bug "..."` | Triage → investigate → fix → regression test → deploy |
| `/deploy-production` | Security scan → staging → approval → production |
| `/investigate-incident "..."` | Triage → root cause → mitigation → post-mortem |
| `/security-scan` | OWASP + CIS audit, secret detection, dependency scan |
| `/analyze-project` | Architecture review, tech debt, recommendations |
| `/write-tests` | Test suite with 80%+ coverage target |
| `/create-content "..."` | Content strategy → copywriting → SEO |
| `/design-ui "..."` | Wireframes → components → accessibility audit |
| `/ai-prompt "..."` | Prompt engineering → evaluation → integration |
| `/infra-plan "..."` | Cloud architecture with Terraform |
| `/set-domain <name>` | Switch domain knowledge |

| `/agent-status` | Live agent progress and task tracking |

[All 23 commands →](.claude/commands/)

---

## Agent Dashboard

Monitor agent progress in real-time with an interactive terminal or web dashboard.

**Terminal dashboard** (run from a second terminal):
```bash
./scripts/agent-dashboard.sh              # Live interactive dashboard
./scripts/agent-dashboard.sh --history    # View past sessions
./scripts/agent-dashboard.sh --analytics  # Agent performance stats
./scripts/agent-dashboard.sh --export     # Export status as markdown
./scripts/agent-dashboard.sh --web        # Launch web dashboard on :8686
```

**In-session**: Use `/agent-status` to check progress without leaving Claude Code.

**Features**:
- Department-grouped agent overview with live duration timers
- Per-agent task progress (from TodoWrite) with progress bars
- Workflow phase inference (Requirements → Design → Implementation → Testing → Security → Deploy)
- Error tracking per agent with detailed error log view
- Session history (last 50 sessions) with agent performance analytics
- Desktop notifications when all agents complete
- Web dashboard with dark theme, auto-refresh, and interactive detail panels
- Markdown export for sharing in PRs or Slack

---

## Safety Hooks

| Hook | What It Prevents |
|------|-----------------|
| **git-safety-check** | Blocks force-push to main/master/develop/production |
| **infra-safety-check** | Warns before `terraform destroy`, `kubectl delete`, `rm -rf` |
| **file-write-check** | Scans every write for hardcoded secrets and API keys |
| **migration-check** | Enforces `branch_id` in all migrations (multi-tenant) |
| **ms365-audit-log** | Logs all Microsoft 365 operations for compliance |
| **todo-tracker** | Captures per-agent task progress for the dashboard |
| **tool-failure** | Logs tool failures, tracks errors per agent |
| **subagent-lifecycle** | Tracks agent start/stop, session history, notifications |
| **session-start** | Auto-injects project context on every session |
| **pre-compact** | Preserves critical context before auto-compaction |

Plus deny rules blocking `DROP DATABASE`, `rm -rf /`, and force-push to protected branches.

---

## 54 Skills

Agents reference deep knowledge packs — not guessing, applying proven patterns:

**Infrastructure**: AWS, Terraform, Kubernetes, Docker, Ansible, Nginx, Networking
**Backend**: Laravel, API Design, Authentication, Multi-tenancy, PostgreSQL, Redis
**Frontend**: Vue 3, TypeScript, Component Patterns, Accessibility, Design Systems
**Quality**: Testing, Security Hardening, Secrets Management, SSL/TLS
**Operations**: CI/CD, GitHub Actions, Monitoring, Log Management, Backup/DR
**AI/ML**: Prompt Design, LLM Integration, Conversational AI, AI Evaluation
**Marketing**: SEO, Content Strategy, Copywriting, Email Marketing, Paid Ads, Social Media, Analytics
**Product**: Product Management, UX Research, Wireframing

---

## 6 Workflows

| Workflow | Flow |
|----------|------|
| **Feature Development** | Requirements → Design → Implement (parallel) → Test → Review → Deploy |
| **Bug Fix** | Triage → Investigate → Fix → Regression Test → Deploy |
| **Release Process** | Freeze → QA → Security → Staging → Approval → Production |
| **Production Incident** | Detect → Triage → Investigate → Mitigate → Resolve → Post-mortem |
| **Client Deployment** | Requirements → Tenant → Config → Data → Deploy → Verify |
| **Content Campaign** | Strategy → Create → SEO Optimize → Publish → Analyze |

---

## 7 Domain Templates

Switch domain knowledge with `/set-domain <name>`:

| Domain | What You Get |
|--------|-------------|
| **ERP** | Accounting, inventory, sales, HR, procurement, manufacturing |
| **E-Commerce** | Catalog, cart, checkout, orders, payments, shipping |
| **SaaS** | Subscriptions, billing, feature flags, onboarding |
| **Healthcare** | EHR, HIPAA compliance, HL7 FHIR, clinical workflows |
| **Fintech** | Payments, ledger, KYC/AML, fraud detection, PCI DSS |
| **Education** | Courses, assessments, LMS, FERPA/COPPA compliance |
| **CMS** | Content authoring, SEO, headless API, localization |

---

## Architecture

```
your-project/
├── .claude/                 Auto-discovered by Claude Code
│   ├── agents/              18 agents (1 orchestrator + 17 specialists)
│   ├── commands/            23 slash commands
│   ├── workflows/           6 workflow definitions
│   ├── memory/              6 knowledge docs + 7 domain templates
│   ├── skills/              54 domain knowledge packs
│   ├── rules/               12 guidelines (7 categories)
│   ├── hooks/               12 safety/audit/lifecycle hooks
│   ├── status/              Runtime: agent status, todos, errors, history
│   └── settings.json        Permissions, hooks, autonomous config
├── scripts/
│   ├── agent-dashboard.sh   Terminal dashboard (live + history + analytics)
│   └── web/dashboard.html   Web dashboard (dark theme, auto-refresh)
├── CLAUDE.md                Project instructions (loaded every session)
├── AGENTS.md                Agent roster and orchestration
└── .mcp.json                MCP connections (GitHub, AWS, MS365, etc.)
```

**No plugins. No dependencies. No build step.** Pure markdown, JSON, and shell scripts.

---

## MCP Integrations

Pre-configured connections (enable what you need): GitHub, AWS, Cloudflare, Vercel, Supabase, Docker, Kubernetes, Microsoft 365, Filesystem.

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Node.js 18+ (for validation scripts)
- CLI tools as needed: `terraform`, `kubectl`, `docker`, `aws`, `gh`

---

## Learn More

- **[Beginner's Guide](BEGINNERS-GUIDE.md)** — New to DevOps? Start here
- **[Agent Reference](AGENTS.md)** — Full roster and orchestration details
- **[Architecture Report](docs/architecture_report.md)** — System overview
- **[Contributing](CONTRIBUTING.md)** — How to add agents, skills, commands, and rules

---

## License

MIT License — see [LICENSE](LICENSE) for details.

Built by [Bipin Kareparambil](https://github.com/bipinks).
