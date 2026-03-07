<div align="center">

# Autonomous AI Software Company

### Drop a folder into any project. Get an entire engineering department.

**18 AI agents** across **7 departments** — from product and engineering to security, marketing, and IT — all coordinated by a master orchestrator. Powered by [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Agents](https://img.shields.io/badge/agents-18-blue)](.claude/agents/)
[![Skills](https://img.shields.io/badge/skills-54-green)](.claude/skills/)
[![Commands](https://img.shields.io/badge/commands-21-orange)](.claude/commands/)

</div>

---

## What This Does

You copy `.claude/` into your project. Claude Code instantly becomes an **autonomous AI software company** — a master orchestrator breaks down your task, assigns it to specialized agents, runs quality gates, and delivers production-ready results.

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

## 30-Second Setup

```bash
# Option A: Use directly
git clone https://github.com/bipinks/devops-agent-hub.git
cd devops-agent-hub && claude

# Option B: Add to your existing project
cp -r devops-agent-hub/.claude/ your-project/.claude/
cd your-project && claude
```

Then just ask:

```bash
/implement-feature "Add user authentication with OAuth"
/fix-bug "Invoice totals wrong when tax-exempt"
/deploy-production
/security-scan
```

That's it. Agents, skills, commands, rules, and hooks all auto-discover.

---

## The Team

<table>
<tr>
<td align="center"><b>Department</b></td>
<td align="center"><b>Agents</b></td>
<td align="center"><b>What They Do</b></td>
</tr>
<tr>
<td>Product</td>
<td>product-manager, ui-ux-designer</td>
<td>Requirements, user stories, wireframes, design systems</td>
</tr>
<tr>
<td>Engineering</td>
<td>architecture, backend, frontend, database, prompt-engineer</td>
<td>System design, APIs, UI, schemas, AI integration</td>
</tr>
<tr>
<td>Quality</td>
<td>qa-agent, security-agent</td>
<td>Tests, security audits, OWASP, compliance</td>
</tr>
<tr>
<td>Operations</td>
<td>devops-engineer, monitoring-agent, performance-agent</td>
<td>CI/CD, deployments, observability, optimization</td>
</tr>
<tr>
<td>Marketing</td>
<td>content-strategist, social-media-manager</td>
<td>Content strategy, SEO, campaigns, community</td>
</tr>
<tr>
<td>Support</td>
<td>support-agent, documentation-agent</td>
<td>Issue triage, API docs, user guides, changelogs</td>
</tr>
<tr>
<td>IT</td>
<td>ms-it-admin</td>
<td>Microsoft 365, Entra ID, Teams, Exchange</td>
</tr>
</table>

All coordinated by the **master-orchestrator** — it plans work, assigns agents, runs parallel streams, and enforces quality gates.

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

[See all 21 commands →](.claude/commands/)

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

Everything lives in `.claude/` for native auto-discovery:

```
.claude/
├── agents/         18 autonomous agents (1 orchestrator + 17 specialists)
├── commands/       21 slash commands for task execution
├── workflows/      6 end-to-end workflow definitions
├── memory/         6 knowledge base docs (architecture, standards, domain)
├── skills/         54 domain knowledge packs with real code examples
├── rules/          12 always-follow guidelines across 7 categories
├── hooks/          11 safety, audit, and lifecycle hook scripts
└── settings.json   Permissions, hooks, and autonomous operation config
```

**No plugins. No dependencies. No build step.** Pure markdown, JSON, and shell scripts. Claude Code auto-discovers everything.

---

## ERP Specialty

The workspace includes deep ERP domain knowledge out of the box:

- **Accounting**: Double-entry bookkeeping, chart of accounts, bank reconciliation
- **Inventory**: FIFO/LIFO/weighted average, stock movements, batch tracking
- **Sales**: Quote → Order → Delivery → Invoice → Payment workflow
- **Procurement**: Three-way matching, approval workflows, vendor management
- **HR/Payroll**: Employee lifecycle, leave management, salary components
- **Multi-tenancy**: `branch_id` isolation enforced at every layer

Remove or replace `.claude/memory/domain-knowledge.md` to specialize for your domain.

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
