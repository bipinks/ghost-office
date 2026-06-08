<div align="center">
<img src="assets/logo.svg" alt="Ghost Office" width="80" height="80">

# Beginner's Guide
</div>

A practical introduction to Ghost Office — what it is, how it works, and how to start using it.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Commands Reference](#commands-reference)
- [Agents and Departments](#agents-and-departments)
- [Common Workflows](#common-workflows)
- [Live Dashboard](#live-dashboard)
- [Domain Configuration](#domain-configuration)
- [Skills and Knowledge Packs](#skills-and-knowledge-packs)
- [Safety and Guardrails](#safety-and-guardrails)
- [Key Concepts](#key-concepts)
- [Learning Path](#learning-path)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Overview

Ghost Office is a drop-in configuration layer for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that transforms it into an autonomous AI software company. It provides **19 specialized agents** across **7 departments**, coordinated by a master orchestrator that breaks down tasks, delegates to the right agents, runs quality gates, and delivers production-ready results.

Think of it as hiring an entire engineering department — product managers, architects, backend/frontend engineers, QA, security, DevOps, and more — all available through your terminal.

**What it includes:**

| Component | Count | Purpose |
|-----------|-------|---------|
| Agents | 19 | Specialized AI experts across 7 departments |
| Skills | 54 | Domain knowledge packs with real code examples |
| Commands | 25 | Slash commands for common operations |
| Workflows | 6 | Multi-phase orchestrated processes |
| Rules | 12 | Enforced guidelines across 7 categories |
| Hooks | 13 | Automated safety checks and lifecycle events |
| Domains | 7 | Switchable domain knowledge (ERP, SaaS, etc.) |

**No plugins. No installation. Just markdown, JSON, and shell scripts.**

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      YOU (the user)                      │
│       "Add invoice PDF generation with email delivery"   │
└─────────────────────────┬────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│                  SLASH COMMANDS (24)                      │
│  /implement-feature  /fix-bug  /deploy-staging  etc.     │
└─────────────────────────┬────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│              MASTER ORCHESTRATOR                         │
│    Plans → Assigns → Tracks → Quality gates → Delivers  │
└─────────────────────────┬────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌────────────────┐ ┌────────────┐ ┌──────────────┐
│  AGENTS (18)   │ │ RULES (12) │ │  HOOKS (13)  │
│  Specialized   │ │ Enforced   │ │  Automated   │
│  AI experts    │ │ guidelines │ │  safety nets │
└───────┬────────┘ └────────────┘ └──────────────┘
        │ references
        ▼
┌──────────────────────────────────────────────────────────┐
│                 SKILLS (54) + MEMORY (6)                  │
│  Best practices, code patterns, domain knowledge         │
│  Terraform, Docker, AWS, Laravel, Vue, K8s, and more     │
└──────────────────────────────────────────────────────────┘
```

---

## Prerequisites

- **Required:** [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- **Required:** `git` (version control)
- **Optional:** `docker` (for containerized dashboard and deployments)
- **Optional:** `node` (for running validation tests — `npm test`)
- **Optional:** Cloud CLI tools as needed (`aws`, `terraform`, `kubectl`, `gh`)

No other installation or build step is required. Claude Code auto-discovers everything from the `.claude/` directory.

---

## Quick Start

### Option 1: Use directly

```bash
git clone https://github.com/bipinks/ghost-office.git
cd ghost-office
claude
```

### Option 2: Add to your existing project

```bash
# Required — agents, skills, commands, rules, hooks, and project instructions
cp -r ghost-office/.claude/ your-project/.claude/
cp ghost-office/CLAUDE.md your-project/CLAUDE.md

# Recommended — MCP integrations and agent reference
cp ghost-office/.mcp.json your-project/.mcp.json
cp ghost-office/AGENTS.md your-project/AGENTS.md
```

Then activate your domain:

```bash
cd your-project
claude
# Inside Claude Code:
/set-domain saas    # or: erp, ecommerce, healthcare, fintech, education, cms
```

Edit `CLAUDE.md` to match your project's tech stack, architecture, and conventions.

---

## Project Structure

```
ghost-office/
├── .claude/
│   ├── agents/       # 19 agent definitions (1 orchestrator + 18 specialists)
│   ├── commands/     # 25 slash commands
│   ├── workflows/    # 6 workflow definitions
│   ├── memory/       # 6 knowledge docs + 7 domain templates
│   │   └── domains/  #   erp, ecommerce, saas, healthcare, fintech, education, cms
│   ├── skills/       # 54 domain knowledge packs with code examples
│   ├── rules/        # 12 guidelines across 7 categories
│   │   ├── common/   #   coding-style, git-workflow, security, testing, performance
│   │   ├── cicd/     #   CI/CD best practices
│   │   ├── cloud/    #   Cloud infrastructure rules
│   │   ├── docker/   #   Container best practices
│   │   ├── kubernetes/ # K8s deployment rules
│   │   ├── security/ #   Security hardening rules
│   │   └── terraform/ #  IaC best practices
│   ├── hooks/        # 13 safety and lifecycle hooks
│   ├── status/       # Runtime: agent status, todos, errors, session history
│   ├── tools/        # 4 tool references
│   └── settings.json # Permissions and hook configuration
├── scripts/
│   ├── agent-dashboard.sh  # Live TUI and web dashboard
│   ├── web/                # Web dashboard (HTML + Python server + Docker)
│   ├── tests/              # Test suites
│   └── validate-structure.js # Structure validator
├── contexts/         # Mode switching (dev, deploy, incident, review)
├── examples/         # Sample CLAUDE.md configs for real projects
├── docs/             # Architecture reports and data models
├── CLAUDE.md         # Project instructions (the brain)
├── AGENTS.md         # Agent roster and orchestration rules
├── docker-compose.yml # Dashboard containerization
└── .mcp.json         # MCP server connections (MS365, filesystem)
```

---

## Commands Reference

All 25 slash commands, grouped by function:

### Development

| Command | Description |
|---------|-------------|
| `/implement-feature` | End-to-end feature implementation with agent coordination |
| `/fix-bug` | Investigate, fix, and verify a bug with regression tests |
| `/refactor-module` | Refactor for improved quality, performance, or architecture |
| `/write-tests` | Write comprehensive tests for a module or feature |
| `/analyze-project` | Analyze project structure, dependencies, and health |

### Deployment and Infrastructure

| Command | Description |
|---------|-------------|
| `/deploy-staging` | Deploy current branch to staging |
| `/deploy-production` | Deploy to production with safety checks and approval |
| `/docker-build` | Build, optimize, and scan Docker images |
| `/cicd-setup` | Generate CI/CD pipeline configuration |
| `/github-setup` | Set up GitHub repo with branch protection and workflows |
| `/infra-plan` | Plan and design cloud infrastructure architecture |
| `/cost-review` | Analyze cloud spending and recommend optimizations |
| `/ansible` | Run Ansible playbooks, deployments, diagnostics, inventory management |
| `/forge-site` | Create a new Laravel Forge site end-to-end (site, repo, DB, .env, deploy, DNS, SSL) |

### Operations

| Command | Description |
|---------|-------------|
| `/monitor-setup` | Set up monitoring, alerting, and dashboards |
| `/monitor-system` | Check system health, review metrics, identify issues |
| `/investigate-incident` | Structured incident triage and root cause analysis |
| `/security-scan` | Security audit against CIS benchmarks and OWASP |

### Content and Design

| Command | Description |
|---------|-------------|
| `/create-content` | Content strategy, calendars, copywriting, SEO |
| `/social-media` | Social campaigns, posts, analytics, community |
| `/design-ui` | Wireframes, components, accessibility, design systems |
| `/ai-prompt` | Prompt design, AI feature integration, LLM testing |

### System

| Command | Description |
|---------|-------------|
| `/agent-status` | Show status of all agents in the current session |
| `/set-domain` | Switch domain knowledge (erp, ecommerce, saas, etc.) |

### Usage

Commands accept a quoted argument describing what you need:

```
/implement-feature "Add invoice PDF generation with email delivery"
/fix-bug "Tax calculation returns wrong amount for exempt items"
/deploy-staging
/security-scan
/set-domain healthcare
```

---

## Agents and Departments

The orchestrator automatically routes your task to the right agents. You do not need to invoke agents manually.

| Department | Agents | Handles |
|------------|--------|---------|
| **Product** | product-manager, ui-ux-designer | Requirements, user stories, wireframes, design systems |
| **Engineering** | architecture-agent, backend-engineer, frontend-engineer, database-engineer, prompt-engineer | System design, APIs, UI, schemas, migrations, AI features |
| **Quality** | qa-agent, security-agent | Test writing, security audits, compliance checks |
| **Operations** | devops-engineer, laravel-forge-agent, monitoring-agent, performance-agent | CI/CD, Forge, deployments, observability, optimization |
| **Marketing** | content-strategist, social-media-manager | Content planning, SEO, campaigns, community |
| **Support** | support-agent, documentation-agent | Bug triage, docs, changelogs, ADRs |
| **IT** | ms-it-admin | Microsoft 365, Entra ID, Teams, Exchange |

### Auto-Routing

The master orchestrator routes tasks automatically:

- **Feature request** → product-manager → architecture-agent → engineers → qa-agent
- **Bug report** → support-agent → relevant engineer → qa-agent
- **Deployment** → devops-engineer → monitoring-agent
- **Laravel Forge** → laravel-forge-agent
- **Ansible/config management** → devops-engineer
- **Security issue** → security-agent (immediate priority)
- **Incident** → monitoring-agent → devops-engineer → engineers

Independent tasks (e.g., backend + frontend after design) execute in parallel.

---

## Common Workflows

### Implement a Feature

```
/implement-feature "Add customer aging report with 30/60/90 day breakdowns"
```

The orchestrator coordinates a full development cycle:

1. **Requirements** — product-manager writes user stories and acceptance criteria
2. **Design** — architecture-agent designs the solution, ui-ux-designer creates wireframes
3. **Implementation** — backend-engineer builds the API, frontend-engineer builds the UI, database-engineer writes migrations
4. **Testing** — qa-agent writes tests (80%+ coverage target)
5. **Review** — security-agent audits for vulnerabilities
6. **Delivery** — documentation-agent updates docs, devops-engineer prepares deployment

### Fix a Bug

```
/fix-bug "Invoice total doesn't include tax for multi-currency orders"
```

1. **Triage** — Identify severity and affected scope
2. **Investigate** — Trace root cause through code and data
3. **Fix** — Implement the correction
4. **Test** — Add regression test to prevent recurrence
5. **Deploy** — Ship the fix through staging → production

### Deploy to Production

```
/deploy-staging
# Verify on staging, then:
/deploy-production
```

Full safety gates: tests must pass, security scan clean, database backup taken, rollback plan documented.

### Run a Security Audit

```
/security-scan
```

Scans for: hardcoded secrets, encryption gaps, IAM over-permissions, OWASP vulnerabilities, CIS benchmark violations. Generates a report with prioritized fixes.

### Handle a Production Incident

```
/investigate-incident "API returning 500 errors on /api/v1/invoices"
```

Structured process: severity triage → log/metric analysis → mitigation → root cause analysis → post-mortem document.

### Plan Infrastructure

```
/infra-plan "Three-tier web app on AWS with PostgreSQL and Redis"
```

Produces: VPC layout, service selection, Terraform code, cost estimates, and architecture decision records.

---

## Live Dashboard

Monitor agent progress in real time from a second terminal.

### Terminal Dashboard

```bash
./scripts/agent-dashboard.sh                # Live overview (1s refresh)
./scripts/agent-dashboard.sh --sessions     # List all sessions, pick one
./scripts/agent-dashboard.sh --session <id> # Jump to a specific session
./scripts/agent-dashboard.sh --history      # Browse past sessions
./scripts/agent-dashboard.sh --analytics    # Per-agent performance stats
./scripts/agent-dashboard.sh --export       # Save snapshot as markdown
```

**Keyboard shortcuts:** number keys for agent detail, `[h]` history, `[s]` stats, `[l]` session list, `[m]` messages, `[c]` send command, `[q]` quit.

### Web Dashboard

```bash
./scripts/agent-dashboard.sh --web          # Web UI on http://localhost:8686
./scripts/agent-dashboard.sh --web-docker   # Containerized via Docker Compose
docker compose up dashboard                 # Alternative: run container directly
```

The web dashboard includes a session selector dropdown, agent detail panels, an interactive chat interface for messaging agents, and a cross-session analytics view at `/analytics.html`.

### Agent Messaging

Send instructions or questions to agents while they work:

- **Terminal:** Press `[m]` to view messages, `[c]` to send a command
- **Web:** Click an agent to open the chat panel, or use the Commands tab

Messages are delivered asynchronously via hooks. Agents acknowledge and respond automatically.

### Quick Status Check

Inside Claude Code, type `/agent-status` for a snapshot of all agent progress without leaving the session.

---

## Domain Configuration

The workspace ships with 7 domain templates. Each domain loads specialized business rules, entity definitions, and workflow patterns into the agents' knowledge base.

| Domain | Use Case |
|--------|----------|
| `erp` | Accounting, inventory, sales, HR, procurement, manufacturing |
| `ecommerce` | Products, carts, orders, payments, shipping, reviews |
| `saas` | Subscriptions, tenants, billing, usage tracking, onboarding |
| `healthcare` | Patients, appointments, records, prescriptions, compliance |
| `fintech` | Accounts, transactions, KYC, compliance, risk scoring |
| `education` | Courses, students, grades, enrollment, LMS |
| `cms` | Content types, publishing, taxonomies, media, SEO |

### Switching Domains

```
/set-domain fintech
```

This updates `.claude/memory/domain-knowledge.md` with the selected domain's rules and entities. All agents reference this file before making decisions.

---

## Skills and Knowledge Packs

Skills are comprehensive reference documents that agents use for domain expertise. Each skill lives in `.claude/skills/<name>/SKILL.md` and contains best practices, code patterns, and step-by-step instructions.

### By Category

**Infrastructure and Cloud:**
ansible-patterns, aws-patterns, terraform-patterns, kubernetes-patterns, docker-patterns, networking-patterns, nginx-patterns

**CI/CD and Operations:**
cicd-patterns, github-workflows, monitoring-patterns, log-management, incident-management, backup-disaster-recovery, laravel-forge

**Security:**
security-hardening, secrets-management, ssl-tls-management

**Backend Development:**
laravel-patterns, api-design, authentication-patterns, multi-tenancy-patterns, postgresql-patterns, redis-patterns, database-ops

**Frontend Development:**
vue-patterns, frontend-patterns, typescript-patterns, design-systems, accessibility-patterns, wireframing-prototyping

**AI and LLM:**
prompt-design, llm-integration, conversational-ai, ai-evaluation

**Content and Marketing:**
content-strategy, copywriting-patterns, seo-optimization, email-marketing, social-media-strategy, analytics-reporting, paid-advertising, community-management

**Product and UX:**
product-management, ux-research

**Testing and Quality:**
testing-patterns, qa-testing-strategy, performance-optimization, cloud-cost-optimization

**Documentation:**
documentation-standards

**Microsoft 365:**
ms365-admin, entra-id-admin, exchange-online-admin, intune-device-mgmt

You can read any skill directly for self-study:

```bash
cat .claude/skills/docker-patterns/SKILL.md
cat .claude/skills/terraform-patterns/SKILL.md
```

---

## Safety and Guardrails

### Hooks (Automated Checks)

| Hook | Trigger | Purpose |
|------|---------|---------|
| `infra-safety-check` | Destructive infra commands | Warns before `terraform destroy`, `kubectl delete`, etc. |
| `git-safety-check` | Git operations | Blocks force-push to protected branches |
| `file-write-check` | File creation | Prevents writing secrets or sensitive data |
| `migration-check` | Database migrations | Ensures rollback methods exist |
| `ms365-audit-log` | Microsoft 365 operations | Logs all admin actions |
| `message-check` | Agent tool calls | Delivers dashboard messages to agents |
| `session-start` | Session initialization | Sets up workspace context |
| `subagent-lifecycle` | Agent spawn/complete | Tracks agent status for dashboard |
| `todo-tracker` | Todo updates | Syncs progress to dashboard |
| `tool-failure` | Tool errors | Logs failures for debugging |
| `notification` | Key events | Sends alerts on completions/errors |
| `pre-compact` | Context compression | Saves state before memory trim |
| `stop-validation` | Session end | Validates final state |

### Enforced Rules

These rules are always active and cannot be bypassed:

- **Never** commit secrets, API keys, or passwords to code
- **Never** force-push to protected branches (main, master, develop, production, staging)
- **Never** run destructive infrastructure commands without confirmation
- **Always** include `branch_id` on database tables for multi-tenant isolation
- **Always** include rollback/down methods in database migrations
- **Always** use conventional commits (`feat:`, `fix:`, `docs:`, `chore:`)

---

## Key Concepts

### Infrastructure-as-Code (IaC)

Instead of manually configuring servers through cloud consoles, you describe infrastructure in code (Terraform, CloudFormation, etc.). The tool provisions everything automatically, consistently, and repeatably. Changes are version-controlled and peer-reviewed like application code.

### CI/CD (Continuous Integration / Continuous Deployment)

**CI** automatically tests every code change on push. **CD** automatically deploys tested code through environments (staging → production). The pipeline catches bugs before they reach users.

### Multi-Tenancy

A single application instance serves multiple customers (tenants). Each tenant's data is isolated using a `branch_id` column on every table. Queries are automatically scoped so Tenant A never sees Tenant B's data.

### Agent

An agent is a specialized instruction set that tells Claude Code how to behave for a specific role. The `security-agent` knows how to run security audits. The `backend-engineer` knows Laravel patterns and API design. Agents reference shared knowledge (memory + skills) for consistency.

### Skill

A skill is a knowledge pack — a structured document containing best practices, code patterns, and step-by-step guides for a specific technology. For example, `terraform-patterns` covers module design, state management, and CI/CD integration.

### Hook

A hook is a shell script that runs automatically when certain events occur. The `infra-safety-check` hook intercepts destructive commands and requires confirmation. The `git-safety-check` hook prevents force-pushes to protected branches.

### Workflow

A workflow is a multi-phase process definition. The `feature-development` workflow runs: Requirements → Design → Implementation → Testing → Review → Deploy. The orchestrator follows these phases and assigns agents accordingly.

---

## Learning Path

A suggested progression for teams new to DevOps and this toolkit.

### Phase 1: Foundations (Week 1-2)

| Step | Action | Skill |
|------|--------|-------|
| 1 | Learn containerization basics | `.claude/skills/docker-patterns/SKILL.md` |
| 2 | Build your first Dockerfile | `/docker-build "Dockerfile for a Node.js API"` |
| 3 | Understand CI/CD pipelines | `.claude/skills/github-workflows/SKILL.md` |
| 4 | Set up your first pipeline | `/github-setup "CI/CD for my project"` |
| 5 | Read the security rules | `.claude/rules/common/security.md` |

### Phase 2: Cloud and Infrastructure (Week 3-4)

| Step | Action | Skill |
|------|--------|-------|
| 1 | Understand cloud services | `.claude/skills/aws-patterns/SKILL.md` |
| 2 | Learn Infrastructure-as-Code | `.claude/skills/terraform-patterns/SKILL.md` |
| 3 | Design your first architecture | `/infra-plan "Web app on AWS with database"` |
| 4 | Understand networking | `.claude/skills/networking-patterns/SKILL.md` |

### Phase 3: Deployment and Operations (Week 5-6)

| Step | Action | Skill |
|------|--------|-------|
| 1 | Learn server configuration | `.claude/skills/ansible-patterns/SKILL.md` |
| 2 | Configure web servers | `.claude/skills/nginx-patterns/SKILL.md` |
| 3 | Set up observability | `.claude/skills/monitoring-patterns/SKILL.md` |
| 4 | Build monitoring dashboards | `/monitor-setup` |

### Phase 4: Security and Scale (Week 7-8)

| Step | Action | Skill |
|------|--------|-------|
| 1 | Harden your infrastructure | `.claude/skills/security-hardening/SKILL.md` |
| 2 | Run a security audit | `/security-scan` |
| 3 | Learn container orchestration | `.claude/skills/kubernetes-patterns/SKILL.md` |
| 4 | Manage secrets properly | `.claude/skills/secrets-management/SKILL.md` |

---

## Troubleshooting

### Commands not recognized

Ensure you are running Claude Code from a directory containing the `.claude/` folder:

```bash
ls .claude/commands/    # Should list 24 .md files
```

### Agents not spawning

Check that `.claude/settings.json` exists and has proper hook configuration. Run the structure validator:

```bash
npm test
```

### Dashboard shows no data

Agent status files are written to `.claude/status/`. If empty, the session hasn't started agent work yet. Try running a command like `/implement-feature` first.

### Dashboard web server won't start

```bash
# Check if port 8686 is in use
lsof -i :8686

# Use Docker instead
docker compose up dashboard
```

### Tests failing

```bash
npm test                           # Run all tests (14 suites)
node scripts/validate-structure.js # Validate project structure
```

---

## FAQ

**Do I need all the cloud tools installed?**
No. Install only what your project needs. Start with `git` and `docker`. Add `terraform`, `kubectl`, `aws`, etc. as your needs grow.

**Does this only work with AWS?**
No. While AWS skills are the most detailed, the patterns apply to Azure, GCP, and DigitalOcean. Skills cover multi-cloud approaches.

**Can I use this for personal projects?**
Yes. It works well for setting up CI/CD on personal repos, deploying side projects, and learning DevOps through guided practice.

**What prevents mistakes?**
13 hooks run automatically to catch common errors: blocking force-pushes to protected branches, warning before destructive infrastructure commands, checking for committed secrets, and validating database migrations have rollback methods.

**How do I add a new agent, skill, or command?**
See [CONTRIBUTING.md](CONTRIBUTING.md) for step-by-step instructions on adding components. Each follows a frontmatter-based markdown format.

**Where do I configure API tokens and credentials?**
- **AWS:** IAM Console → Security Credentials, or `aws configure`
- **GitHub:** Settings → Developer Settings → Personal Access Tokens
- **Microsoft 365:** Azure Portal → App Registrations → Client Secret
- **Docker Hub:** Account Settings → Security → Access Tokens

Never commit credentials to code. Use environment variables or a secrets manager.

**How do I validate that everything is set up correctly?**
```bash
npm test    # Runs 14 test suites with 1100+ checks
```

**Where can I find example configurations?**
The `examples/` directory contains complete `CLAUDE.md` templates for real-world projects:
- `examples/CLAUDE.md` — General-purpose template
- `examples/aws-terraform-CLAUDE.md` — AWS + Terraform infrastructure project
- `examples/k8s-microservices-CLAUDE.md` — Kubernetes microservices
- `examples/laravel-forge-CLAUDE.md` — Laravel + Forge deployment

---

## Next Steps

- Read [CLAUDE.md](CLAUDE.md) for the full project reference
- Read [AGENTS.md](AGENTS.md) for detailed agent routing and orchestration rules
- Read [CONTRIBUTING.md](CONTRIBUTING.md) to add your own agents, skills, or commands
- Explore `.claude/skills/` to browse all 53 knowledge packs
- Try `/analyze-project` on your own codebase to see the agents in action
