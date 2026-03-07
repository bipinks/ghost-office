<div align="center">

# Autonomous AI Software Company

### Drop a folder into any project. Get an entire engineering department.

**18 AI agents** across **7 departments** — from product and engineering to security, marketing, and IT — all coordinated by a master orchestrator. Powered by [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agents](https://img.shields.io/badge/agents-18-blue)](.claude/agents/)
[![Skills](https://img.shields.io/badge/skills-54-green)](.claude/skills/)
[![Commands](https://img.shields.io/badge/commands-22-orange)](.claude/commands/)
[![Domains](https://img.shields.io/badge/domains-7-purple)](.claude/memory/domains/)

</div>

---

## What This Does

You copy `.claude/` and `CLAUDE.md` into your project. Claude Code instantly becomes an **autonomous AI software company** — a master orchestrator breaks down your task, assigns it to specialized agents, runs quality gates, and delivers production-ready results.

```
You: /implement-feature "Add invoice PDF generation with email delivery"

Orchestrator assigns:
  → product-manager     writes requirements + acceptance criteria
  → architecture-agent  designs the solution
  → backend-engineer    implements API + PDF service
  → frontend-engineer   builds the UI
  → database-engineer   creates migrations (with branch_id)
  → qa-agent            writes tests (80%+ coverage)
  → security-agent      reviews for vulnerabilities
  → devops-engineer     updates CI/CD pipeline
  → documentation-agent writes API docs + changelog

Result: Complete feature — code, tests, docs, ready to deploy.
```

**No plugins. No install. Just markdown, JSON, and shell scripts.**

---

## Setup

### Option A: Use this repo directly

```bash
git clone https://github.com/bipinks/devops-agent-hub.git
cd devops-agent-hub && claude
```

### Option B: Add to your existing project

**Minimum (required):**
```bash
cp -r devops-agent-hub/.claude/ your-project/.claude/
cp devops-agent-hub/CLAUDE.md your-project/CLAUDE.md
```

**Full setup (recommended):**
```bash
# Core — agents, skills, commands, rules, hooks, settings
cp -r devops-agent-hub/.claude/ your-project/.claude/

# Project instructions — Claude Code reads this on every session
cp devops-agent-hub/CLAUDE.md your-project/CLAUDE.md

# MCP integrations — GitHub, AWS, MS365, Docker, K8s, etc.
cp devops-agent-hub/.mcp.json your-project/.mcp.json

# Agent reference — full roster and orchestration details
cp devops-agent-hub/AGENTS.md your-project/AGENTS.md

# Validation scripts — structure checks and test suite
cp -r devops-agent-hub/scripts/ your-project/scripts/
cp devops-agent-hub/package.json your-project/package.json

# Context modes — switch between dev, deploy, incident, review
cp -r devops-agent-hub/contexts/ your-project/contexts/
```

> **Important:** After copying, run `/set-domain <name>` to activate the right domain knowledge (erp, ecommerce, saas, healthcare, fintech, education, cms). Then edit `CLAUDE.md` to match your project's architecture, tech stack, and conventions.

### Then just ask:

```bash
cd your-project && claude

/implement-feature "Add user authentication with OAuth"
/fix-bug "Invoice totals wrong when tax-exempt"
/deploy-production
/security-scan
```

Agents, skills, commands, rules, and hooks all auto-discover from `.claude/`.

---

## The Team

```
                         ┌─────────────────────┐
                         │ master-orchestrator  │
                         │  Plans · Assigns ·   │
                         │  Tracks · Delivers   │
                         └─────────┬───────────┘
                                   │
        ┌──────────┬───────────┬───┴───┬───────────┬──────────┬────────┐
        │          │           │       │           │          │        │
   ┌────┴───┐ ┌───┴────┐ ┌───┴──┐ ┌──┴───┐ ┌────┴───┐ ┌───┴───┐ ┌──┴──┐
   │Product │ │Engineer│ │Quality│ │  Ops │ │Market- │ │Support│ │ IT  │
   │        │ │  -ing  │ │      │ │      │ │  ing   │ │       │ │     │
   └───┬────┘ └───┬────┘ └──┬───┘ └──┬───┘ └───┬────┘ └──┬────┘ └──┬──┘
       │          │          │        │          │         │         │
  ┌────┴────┐  ┌──┴───┐  ┌──┴──┐  ┌──┴───┐  ┌──┴──┐  ┌──┴──┐  ┌──┴──┐
  │product- │  │archi-│  │ qa- │  │devops│  │cont-│  │supp-│  │ms-it│
  │manager  │  │tect  │  │agent│  │engnr │  │ent  │  │ort  │  │admin│
  │         │  │      │  │     │  │      │  │strat│  │agent│  └─────┘
  │ui-ux-   │  │back- │  │sec- │  │moni- │  │     │  │     │
  │designer │  │end   │  │urity│  │toring│  │soc- │  │docs │
  └─────────┘  │      │  └─────┘  │      │  │ial  │  │agent│
               │front-│           │perf- │  └─────┘  └─────┘
               │end   │           │orm.  │
               │      │           └──────┘
               │data- │
               │base  │
               │      │
               │prompt│
               │engnr │
               └──────┘
```

<table>
<tr>
<td align="center"><b>Department</b></td>
<td align="center"><b>Agents</b></td>
<td align="center"><b>What They Do</b></td>
</tr>
<tr>
<td><b>Product</b></td>
<td>product-manager, ui-ux-designer</td>
<td>Requirements, user stories, wireframes, design systems</td>
</tr>
<tr>
<td><b>Engineering</b></td>
<td>architecture, backend, frontend, database, prompt-engineer</td>
<td>System design, APIs, UI, schemas, AI integration</td>
</tr>
<tr>
<td><b>Quality</b></td>
<td>qa-agent, security-agent</td>
<td>Tests, security audits, OWASP, compliance</td>
</tr>
<tr>
<td><b>Operations</b></td>
<td>devops-engineer, monitoring-agent, performance-agent</td>
<td>CI/CD, deployments, observability, optimization</td>
</tr>
<tr>
<td><b>Marketing</b></td>
<td>content-strategist, social-media-manager</td>
<td>Content strategy, SEO, campaigns, community</td>
</tr>
<tr>
<td><b>Support</b></td>
<td>support-agent, documentation-agent</td>
<td>Issue triage, API docs, user guides, changelogs</td>
</tr>
<tr>
<td><b>IT</b></td>
<td>ms-it-admin</td>
<td>Microsoft 365, Entra ID, Teams, Exchange</td>
</tr>
</table>

The **master-orchestrator** coordinates everything — it plans work, assigns agents, runs parallel streams, and enforces quality gates before delivery.

---

## What You Can Do

| Command | What Happens |
|---------|-------------|
| `/implement-feature "..."` | Full feature lifecycle: requirements → design → code → test → docs |
| `/fix-bug "..."` | Triage → investigate → fix → regression test → deploy |
| `/deploy-production` | Security scan → staging → approval gate → production deploy |
| `/investigate-incident "..."` | Structured triage → root cause → mitigation → post-mortem |
| `/security-scan` | OWASP + CIS audit, secret detection, dependency scan |
| `/analyze-project` | Architecture review, tech debt analysis, recommendations |
| `/write-tests` | Comprehensive test suite with 80%+ coverage target |
| `/refactor-module "..."` | Code quality improvements with safety net |
| `/create-content "..."` | Content strategy → copywriting → SEO optimization |
| `/design-ui "..."` | Wireframes → components → accessibility audit |
| `/ai-prompt "..."` | Prompt engineering → evaluation → integration |
| `/infra-plan "..."` | Cloud architecture design with Terraform |
| `/cicd-setup "..."` | CI/CD pipeline generation for any platform |
| `/cost-review` | Cloud spend analysis + optimization recommendations |

[See all 22 commands →](.claude/commands/)

---

## Built-In Safety

This isn't a toy — it has production-grade guardrails:

| Hook | What It Prevents |
|------|-----------------|
| **git-safety-check** | Blocks force-push to main/master/develop/production |
| **infra-safety-check** | Warns before `terraform destroy`, `kubectl delete`, `rm -rf` |
| **file-write-check** | Scans every file write for hardcoded secrets and API keys |
| **migration-check** | Enforces `branch_id` in all migrations (multi-tenant isolation) |
| **ms365-audit-log** | Logs all Microsoft 365 operations for compliance |
| **session-start** | Auto-injects project context on every session |
| **pre-compact** | Preserves critical context before auto-compaction |

Plus deny rules that block `DROP DATABASE`, `rm -rf /`, and force-push to protected branches.

---

## 54 Domain Skills

Agents don't just guess — they reference deep knowledge packs:

**Infrastructure**: AWS, Terraform, Kubernetes, Docker, Ansible, Nginx, Networking
**Backend**: Laravel, API Design, Authentication, Multi-tenancy, PostgreSQL, Redis
**Frontend**: Vue 3, TypeScript, Component Patterns, Accessibility
**Quality**: Testing Patterns, Security Hardening, Secrets Management, SSL/TLS
**Operations**: CI/CD, GitHub Actions, Monitoring, Log Management, Backup/DR
**AI/ML**: Prompt Design, LLM Integration, Conversational AI, AI Evaluation
**Marketing**: SEO, Content Strategy, Copywriting, Email Marketing, Paid Ads, Social Media
**Product**: Product Management, UX Research, Wireframing, Design Systems

Each skill contains real-world patterns, code examples, and decision frameworks.

---

## 6 Workflows

End-to-end processes that coordinate multiple agents:

| Workflow | Flow |
|----------|------|
| **Feature Development** | Requirements → Design → Implement (parallel) → Test → Review → Deploy |
| **Bug Fix** | Triage → Investigate → Fix → Regression Test → Deploy |
| **Release Process** | Code Freeze → QA → Security → Staging → Approval → Production |
| **Production Incident** | Detect → Triage → Investigate → Mitigate → Resolve → Post-mortem |
| **Client Deployment** | Requirements → Tenant Setup → Config → Data → Deploy → Verify |
| **Content Campaign** | Strategy → Create → SEO Optimize → Publish → Analyze |

---

## Architecture

```
your-project/
├── .claude/                 Auto-discovered by Claude Code
│   ├── agents/              18 autonomous agents (1 orchestrator + 17 specialists)
│   ├── commands/            22 slash commands for task execution
│   ├── workflows/           6 end-to-end workflow definitions
│   ├── memory/              6 knowledge base docs + 7 domain templates
│   ├── skills/              54 domain knowledge packs with real code examples
│   ├── rules/               12 always-follow guidelines across 7 categories
│   ├── hooks/               11 safety, audit, and lifecycle hook scripts
│   └── settings.json        Permissions, hooks, and autonomous operation config
│
├── CLAUDE.md                Project instructions — Claude reads this every session
├── AGENTS.md                Agent roster and orchestration reference
├── .mcp.json                MCP server connections (GitHub, AWS, MS365, etc.)
├── scripts/                 Validation utilities and test suite
├── contexts/                Dynamic context modes (dev, deploy, incident, review)
└── ... your project files
```

**What must be copied:** `.claude/` + `CLAUDE.md` (minimum). See [Setup](#setup) for the full list.

**No plugins. No dependencies. No build step.** Pure markdown, JSON, and shell scripts. Claude Code auto-discovers everything from `.claude/`.

---

## 7 Domain Templates

Switch domain knowledge instantly with `/set-domain <name>`:

| Domain | Command | What You Get |
|--------|---------|-------------|
| **ERP** | `/set-domain erp` | Accounting, inventory, sales, HR, procurement, manufacturing |
| **E-Commerce** | `/set-domain ecommerce` | Catalog, cart, checkout, orders, payments, shipping |
| **SaaS** | `/set-domain saas` | Subscriptions, billing, feature flags, onboarding |
| **Healthcare** | `/set-domain healthcare` | EHR, HIPAA compliance, HL7 FHIR, clinical workflows |
| **Fintech** | `/set-domain fintech` | Payments, ledger, KYC/AML, fraud detection, PCI DSS |
| **Education** | `/set-domain education` | Courses, assessments, LMS, FERPA/COPPA compliance |
| **CMS** | `/set-domain cms` | Content authoring, SEO, headless API, localization |

The active domain is cached in `domain.lock` — runs once, not every session. All agents automatically reference the active domain knowledge.

---

## MCP Integrations

Pre-configured connections to external services (enable what you need):

| Server | Purpose |
|--------|---------|
| GitHub | Repos, issues, PRs, Actions |
| AWS | EC2, S3, RDS, ECS, Lambda, IAM |
| Cloudflare | DNS, CDN, Workers, Pages |
| Vercel | Deployments, domains |
| Supabase | Database, auth, storage |
| Docker | Containers, images, volumes |
| Kubernetes | Pods, services, deployments |
| Microsoft 365 | Users, Teams, Exchange, SharePoint |
| Filesystem | Local file operations |

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- Node.js 18+ (for validation scripts)
- Relevant CLI tools as needed: `terraform`, `kubectl`, `docker`, `aws`, `gh`

---

## Learn More

- **[Beginner's Guide](BEGINNERS-GUIDE.md)** — New to DevOps? Start here
- **[Agent Reference](AGENTS.md)** — Full agent roster and orchestration details
- **[Architecture Report](docs/architecture_report.md)** — System design and transformation plan
- **[Contributing](CONTRIBUTING.md)** — How to add agents, skills, commands, and rules

---

## License

MIT License — see [LICENSE](LICENSE) for details.

Built by [Bipin Kareparambil](https://github.com/bipinks).
