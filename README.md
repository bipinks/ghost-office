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

When you run `/implement-feature`, up to 9 agents work in parallel. The dashboard shows you exactly what each one is doing — in real-time, from a second terminal.

```bash
./scripts/agent-dashboard.sh              # Live overview (1s refresh)
./scripts/agent-dashboard.sh --sessions   # List all sessions, pick one
./scripts/agent-dashboard.sh --session <id> # Jump to a specific session
./scripts/agent-dashboard.sh --history    # Browse past sessions
./scripts/agent-dashboard.sh --analytics  # Per-agent performance stats
./scripts/agent-dashboard.sh --export     # Save snapshot as markdown
./scripts/agent-dashboard.sh --web        # Web UI on http://localhost:8686
```

**Multi-session:** Press `[l]` in the dashboard to switch between active and historical sessions. The web dashboard has a session selector dropdown.

**Or stay in Claude Code:** type `/agent-status` for an instant status snapshot.

---

### Overview — all agents, live

```
╔══════════════════════════════════════════════════════════════════╗
║  AGENT DASHBOARD        Session: a3f9b2       12:34:56 UTC      ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Workflow: Requirements ──▶ Design ──▶ [Implementation] ──▶ ... ║
║                                                                  ║
║  ENGINEERING                                                     ║
║  [1] ● backend-engineer    RUNNING   4m 23s  ████████░░  3/5    ║
║  [2] ● frontend-engineer   RUNNING   3m 11s  ██████░░░░  2/4    ║
║  [3] ✓ architecture-agent  DONE      1m 47s  ██████████  4/4    ║
║      ○ database-engineer   IDLE                                  ║
║                                                                  ║
║  QUALITY                                                         ║
║      ○ qa-agent            IDLE                                  ║
║      ○ security-agent      IDLE                                  ║
║                                                                  ║
║  PRODUCT                                                         ║
║  [4] ✓ product-manager     DONE      2m 05s  ██████████  3/3    ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  Active: 2  │  Completed: 2  │  Idle: 3  │  Uptime: 6m 18s    ║
╚══════════════════════════════════════════════════════════════════╝
  [1-4] detail  [l] sessions  [h] history  [s] stats  [e] errors
  [w] workflow  [m] messages  [c] command  [q] quit
```

---

### Session list — `[l]` or `--sessions`

Switch between active and historical sessions:

```
╔══════════════════════════════════════════════════════════════════╗
║  SESSION LIST                                    12:34:56 UTC    ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [1] ● a3f9b2c8d1e4f5a7  ████████░░  2/4  (ACTIVE)            ║
║        Started 6m ago · 2 running                                ║
║                                                                  ║
║  [2] ○ 7c2d1e9a3b5f8c0d  ██████████  done                     ║
║        Mar 08 09:14 · 8 agents · 12m 44s                        ║
║                                                                  ║
║  [3] ○ f81a3c7e2b9d4f6a  ██████████  done                     ║
║        Mar 07 16:52 · 6 agents · 8m 30s                         ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
  [1-3] select session  [h] history  [s] stats  [q] quit
```

When viewing a historical session, the header turns red with a **HISTORY** badge:

```
╔══════════════════════════════════════════════════════════════════╗
║  AGENT DASHBOARD (HISTORY)                       12:34:56 UTC    ║
║  Session: 7c2d1e9a                                [l] live       ║
╠══════════════════════════════════════════════════════════════════╣
```

Press `[b]` to return to the session list, or `[l]` to switch sessions.

---

### Detail view — drill into any agent

Press a number key to see that agent's task list in real-time:

```
╔══════════════════════════════════════════════════════════════════╗
║  backend-engineer                     Engineering  ●  RUNNING   ║
║  Running for 4m 23s                                              ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Tasks:                                                          ║
║  ✓  Create migration for invoices table (branch_id scoped)      ║
║  ✓  Build InvoiceService with PDF generation                     ║
║  ●  Implement email delivery via Laravel Queue                   ║
║  ○  Add API resource transformer                                 ║
║  ○  Write unit tests for InvoiceService                          ║
║                                                                  ║
║  Progress: ████████████░░░░░░░░  2/5 tasks done (40%)           ║
║                                                                  ║
║  Errors: 0                                                       ║
╚══════════════════════════════════════════════════════════════════╝
  [b] back to overview  │  [q] quit
```

---

### Session history — `--history`

```
╔══════════════════════════════════════════════════════════════════╗
║  SESSION HISTORY                            Last 50 sessions     ║
╠═══════════╦══════════════════╦══════════╦═════════╦═════════════╣
║  Session  ║  Started         ║  Duration║  Agents ║  Status     ║
╠═══════════╬══════════════════╬══════════╬═════════╬═════════════╣
║  a3f9b2   ║  Mar 08  12:28   ║  6m 18s  ║    4    ║  running    ║
║  7c2d1e   ║  Mar 08  09:14   ║  12m 44s ║    8    ║  completed  ║
║  f81a3c   ║  Mar 07  16:52   ║  8m 30s  ║    6    ║  completed  ║
║  b4e29a   ║  Mar 07  11:07   ║  15m 02s ║    9    ║  completed  ║
╚═══════════╩══════════════════╩══════════╩═════════╩═════════════╝
  [b] back  │  [q] quit
```

Tip: Use `[l]` from the overview to open the interactive session list, or `--session <id>` to jump directly.

---

### Web dashboard — `--web`

Launch with `./scripts/agent-dashboard.sh --web` — opens `http://localhost:8686`. Auto-refreshes every 2 seconds. No server dependencies — reads the same local JSON status files the terminal dashboard uses.

```
┌──────────────────────────────────────────────────────────────────────────┐
│  ◉ ○ ○   Agent Dashboard                    http://localhost:8686       │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   Agent Dashboard                          [Current Session ▾]          │
│   Session: a3f9b2 · 12:34:56 UTC                                        │
│                                                                          │
│   ┌────────────┐   ┌────────────┐   ┌──────────────────┐   ┌─────────┐ │
│   │Requirements│──▶│   Design   │──▶│ ■ Implementation │──▶│ Testing │ │
│   │     ✓      │   │     ✓      │   │     active       │   │ pending │ │
│   └────────────┘   └────────────┘   └──────────────────┘   └─────────┘ │
│                                                                          │
│   ┌─ Engineering ────────────────────────────────────────────────────┐   │
│   │                                                                  │   │
│   │  ┌─────────────────────────┐  ┌─────────────────────────┐       │   │
│   │  │  backend-engineer    ●  │  │  frontend-engineer   ●  │       │   │
│   │  │  RUNNING · 4m 23s      │  │  RUNNING · 3m 11s       │       │   │
│   │  │  ██████████░░░░░  3/5  │  │  ████████░░░░░░░  2/4   │       │   │
│   │  │                        │  │                          │       │   │
│   │  │  ✓ Create migration    │  │  ✓ Invoice list page     │       │   │
│   │  │  ✓ Build service       │  │  ✓ Form components       │       │   │
│   │  │  ● PDF generation      │  │  ● PDF preview modal     │       │   │
│   │  │  ○ Email delivery      │  │  ○ Email trigger UI      │       │   │
│   │  │  ○ Unit tests          │  │                          │       │   │
│   │  └─────────────────────────┘  └─────────────────────────┘       │   │
│   │                                                                  │   │
│   │  ┌─────────────────────────┐  ┌─────────────────────────┐       │   │
│   │  │  architecture-agent  ✓  │  │  database-engineer   ○  │       │   │
│   │  │  DONE · 1m 47s         │  │  IDLE                    │       │   │
│   │  │  ██████████████████ 4/4 │  │  ░░░░░░░░░░░░░░░░░ 0/0 │       │   │
│   │  └─────────────────────────┘  └─────────────────────────┘       │   │
│   └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
│   ┌─ Product ────────────────────┐  ┌─ Quality ─────────────────────┐   │
│   │  ┌─────────────────────────┐ │  │  ┌────────────────────────┐   │   │
│   │  │  product-manager     ✓  │ │  │  │  qa-agent           ○  │   │   │
│   │  │  DONE · 2m 05s         │ │  │  │  IDLE                   │   │   │
│   │  │  ██████████████████ 3/3 │ │  │  │  ░░░░░░░░░░░░░░░░ 0/0 │   │   │
│   │  └─────────────────────────┘ │  │  └────────────────────────┘   │   │
│   └──────────────────────────────┘  │  ┌────────────────────────┐   │   │
│                                      │  │  security-agent     ○  │   │   │
│                                      │  │  IDLE                   │   │   │
│                                      │  └────────────────────────┘   │   │
│                                      └──────────────────────────────┘   │
│                                                                          │
│   ┌──────────────────────────────────────────────────────────────────┐   │
│   │  Active: 2  ·  Completed: 2  ·  Idle: 3  ·  Uptime: 6m 18s    │   │
│   └──────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

<details>
<summary>View HTML source of the web dashboard</summary>

```html
<!-- http://localhost:8686  —  auto-refresh every 2s, dark theme -->
<div class="dashboard dark">
  <header>
    Agent Dashboard
    <select id="session-selector">
      <option value="current">Current Session</option>
      <option>7c2d1e (8 agents, 12m 44s)</option>
    </select>
  </header>
  <div class="meta">Session: a3f9b2 · 12:34:56 UTC</div>

  <div class="workflow-bar">
    <span class="done">Requirements</span> ▶
    <span class="done">Design</span> ▶
    <span class="active">Implementation</span> ▶
    <span class="pending">Testing</span> ▶
    <span class="pending">Security</span> ▶
    <span class="pending">Deploy</span>
  </div>

  <div class="agent-grid">
    <div class="agent-card running">
      <div class="agent-name">backend-engineer</div>
      <div class="dept-badge">Engineering</div>
      <div class="progress-bar"><div class="fill" style="width:60%"></div></div>
      <div class="task-list">
        <div class="task done">✓ Create migration for invoices table</div>
        <div class="task done">✓ Build InvoiceService with PDF generation</div>
        <div class="task active">● Implement email delivery via Queue</div>
        <div class="task pending">○ Add API resource transformer</div>
        <div class="task pending">○ Write unit tests</div>
      </div>
      <div class="meta">3 / 5 tasks · 4m 23s</div>
    </div>
    <div class="agent-card running">
      <div class="agent-name">frontend-engineer</div>
      <div class="dept-badge">Engineering</div>
      <div class="progress-bar"><div class="fill" style="width:50%"></div></div>
      <div class="task-list">
        <div class="task done">✓ Invoice list page</div>
        <div class="task done">✓ Form components</div>
        <div class="task active">● PDF preview modal</div>
        <div class="task pending">○ Email trigger UI</div>
      </div>
      <div class="meta">2 / 4 tasks · 3m 11s</div>
    </div>
    <div class="agent-card done">
      <div class="agent-name">architecture-agent</div>
      <div class="dept-badge">Engineering</div>
      <div class="progress-bar"><div class="fill" style="width:100%"></div></div>
      <div class="meta">4 / 4 tasks · 1m 47s ✓</div>
    </div>
    <div class="agent-card done">
      <div class="agent-name">product-manager</div>
      <div class="dept-badge">Product</div>
      <div class="progress-bar"><div class="fill" style="width:100%"></div></div>
      <div class="meta">3 / 3 tasks · 2m 05s ✓</div>
    </div>
    <div class="agent-card idle">
      <div class="agent-name">qa-agent</div>
      <div class="dept-badge">Quality</div>
    </div>
    <div class="agent-card idle">
      <div class="agent-name">security-agent</div>
      <div class="dept-badge">Quality</div>
    </div>
  </div>

  <footer>Active: 2 · Completed: 2 · Idle: 3 · Uptime: 6m 18s</footer>
</div>
```

</details>

---

**How the dashboard works — no magic:**

| What you see | Where it comes from |
|---|---|
| Agent status + duration | `.claude/status/agents.json` (written by `subagent-lifecycle` hook) |
| Task progress bars | `.claude/status/todos/{agent}.json` (written by `todo-tracker` hook) |
| Workflow phase label | Inferred from which agents are currently active |
| Error indicators | `.claude/status/errors.json` (written by `tool-failure` hook) |
| Session history | `.claude/status/history/` — last 50 sessions, auto-pruned |
| Desktop notification | Fires via `notification` hook when all agents finish |

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
│   ├── hooks/               13 safety/audit/lifecycle hooks
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
