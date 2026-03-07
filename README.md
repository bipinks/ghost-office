# DevOps Agent Hub

> Fully autonomous AI-driven software company powered by Claude Code — 18 specialized agents (7 departments), 54 domain skills, 21 slash commands, 6 workflows, 11 hooks, and a persistent knowledge base for end-to-end product development, operations, and support.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Quick Start

### Option 1: Clone and Use Directly

```bash
# Clone the repo
git clone https://github.com/bipinks/devops-agent-hub.git
cd devops-agent-hub

# Start Claude Code — agents, commands, skills, rules, and hooks auto-discover
claude
```

### Option 2: Copy into Your Project

```bash
# Copy .claude/ directory into your project
cp -r devops-agent-hub/.claude/ your-project/.claude/

# Copy MCP config (optional — only servers you need)
cp devops-agent-hub/.mcp.json your-project/.mcp.json
```

### Start Using

```bash
/infra-plan "Design a VPC with public and private subnets"
/cicd-setup "Create GitHub Actions for a Node.js app with Docker deploy"
/forge-deploy "Provision a new site on Forge with SSL"
/security-scan
/cost-review
/deploy
```

---

## Project Structure

```
devops-agent-hub/
├── .claude/
│   ├── agents/                      # 18 autonomous agents (7 departments)
│   │   ├── master-orchestrator.md   # Central coordinator of all agents
│   │   ├── product-manager.md       # Requirements, specs, priorities
│   │   ├── ui-ux-designer.md        # Visual design, wireframes, accessibility
│   │   ├── architecture-agent.md    # System design, tech decisions
│   │   ├── backend-engineer.md      # Server-side code, APIs, logic
│   │   ├── frontend-engineer.md     # UI/UX implementation, client-side code
│   │   ├── database-engineer.md     # Schema, queries, migrations
│   │   ├── prompt-engineer.md       # AI prompts, LLM integration
│   │   ├── qa-agent.md              # Testing, quality assurance
│   │   ├── security-agent.md        # Security audits, vulnerabilities
│   │   ├── devops-engineer.md       # CI/CD, infrastructure, deployments
│   │   ├── monitoring-agent.md      # Observability, alerting, incidents
│   │   ├── performance-agent.md     # Optimization, profiling, cost
│   │   ├── content-strategist.md    # Content, SEO, email marketing
│   │   ├── social-media-manager.md  # Social media, ads, community
│   │   ├── support-agent.md         # User issues, triage, client admin
│   │   ├── documentation-agent.md   # Tech docs, API docs, guides
│   │   └── ms-it-admin.md           # Microsoft 365 administration
│   ├── commands/                    # 21 slash commands
│   │   ├── implement-feature.md     # /implement-feature
│   │   ├── fix-bug.md               # /fix-bug
│   │   ├── deploy-staging.md        # /deploy-staging
│   │   ├── deploy-production.md     # /deploy-production
│   │   ├── analyze-project.md       # /analyze-project
│   │   ├── write-tests.md           # /write-tests
│   │   ├── refactor-module.md       # /refactor-module
│   │   ├── security-scan.md         # /security-scan
│   │   ├── monitor-system.md        # /monitor-system
│   │   ├── investigate-incident.md  # /investigate-incident
│   │   ├── infra-plan.md            # /infra-plan
│   │   ├── cicd-setup.md            # /cicd-setup
│   │   ├── docker-build.md          # /docker-build
│   │   ├── github-setup.md          # /github-setup
│   │   ├── monitor-setup.md         # /monitor-setup
│   │   ├── cost-review.md           # /cost-review
│   │   ├── acodax-deploy.md         # /acodax-deploy
│   │   ├── create-content.md        # /create-content
│   │   ├── social-media.md          # /social-media
│   │   ├── design-ui.md             # /design-ui
│   │   └── ai-prompt.md             # /ai-prompt
│   ├── skills/                      # 54 domain knowledge packs
│   │   ├── terraform-patterns/      # Terraform IaC best practices
│   │   ├── kubernetes-patterns/     # K8s deployment patterns
│   │   ├── docker-patterns/         # Dockerfile and Compose patterns
│   │   ├── aws-patterns/            # AWS service patterns
│   │   ├── github-workflows/        # GitHub Actions CI/CD patterns
│   │   ├── laravel-patterns/        # Laravel application patterns
│   │   ├── vue-patterns/            # Vue 3 frontend patterns
│   │   ├── typescript-patterns/     # TypeScript patterns
│   │   ├── postgresql-patterns/     # PostgreSQL optimization
│   │   ├── redis-patterns/          # Redis caching and queues
│   │   ├── api-design/              # REST API design patterns
│   │   ├── testing-patterns/        # Test architecture
│   │   ├── performance-optimization/# Profiling and optimization
│   │   ├── multi-tenancy-patterns/  # Multi-tenant isolation
│   │   ├── authentication-patterns/ # Auth and RBAC
│   │   └── ... (54 total)           # See .claude/skills/ for full list
│   ├── rules/                       # Always-follow guidelines
│   │   ├── common/                  # Universal DevOps principles
│   │   ├── terraform/               # Terraform-specific rules
│   │   ├── kubernetes/              # K8s-specific rules
│   │   ├── docker/                  # Docker-specific rules
│   │   ├── cicd/                    # CI/CD-specific rules
│   │   ├── cloud/                   # Cloud-specific rules
│   │   └── security/                # Security-specific rules
│   ├── settings.json                # Infrastructure safety hooks
│   └── settings.local.json          # Personal overrides (gitignored)
├── .mcp.json                        # MCP servers (GitHub, AWS, Cloudflare, etc.)
├── CLAUDE.md                        # Project instructions
├── AGENTS.md                        # Agent reference and orchestration guide
├── contexts/                        # Dynamic context modes
├── examples/                        # Example CLAUDE.md configs
├── scripts/                         # Utility scripts
└── README.md
```

---

## Which Agent Should I Use?

| Task | Command | Agent |
|------|---------|-------|
| Implement a feature | `/implement-feature` | master-orchestrator → all agents |
| Fix a bug | `/fix-bug` | support-agent → engineer → qa-agent |
| Design infrastructure | `/infra-plan` | architecture-agent |
| Build CI/CD pipeline | `/cicd-setup` | devops-engineer |
| Security audit | `/security-scan` | security-agent |
| Handle incident | `/investigate-incident` | monitoring-agent |
| Optimize costs | `/cost-review` | performance-agent |
| Deploy to staging | `/deploy-staging` | devops-engineer |
| Deploy to production | `/deploy-production` | devops-engineer (approval gate) |
| Set up monitoring | `/monitor-setup` | monitoring-agent |
| Write tests | `/write-tests` | qa-agent |
| Analyze project | `/analyze-project` | architecture-agent |
| Create content | `/create-content` | content-strategist |
| Social media campaign | `/social-media` | social-media-manager |
| Design UI/UX | `/design-ui` | ui-ux-designer |
| AI prompt engineering | `/ai-prompt` | prompt-engineer |

---

## Common Workflows

**Implement a new feature:**
```bash
/implement-feature "Add invoice PDF generation with email delivery"
```

**Setting up a new project:**
```bash
/analyze-project
/infra-plan "Three-tier web app on AWS"
/cicd-setup "GitHub Actions with Docker and ECS"
/monitor-setup "Prometheus + Grafana for ECS services"
```

**Deploying to production:**
```bash
/security-scan
/deploy-staging
/deploy-production
```

**Incident response:**
```bash
/investigate-incident "High CPU on production web servers"
```

---

## MCP Servers

Configured in `.mcp.json` — enable only what you need:

| Server | Purpose |
|--------|---------|
| GitHub | Repos, issues, PRs, Actions |
| AWS | EC2, S3, RDS, ECS, Lambda, IAM |
| Cloudflare | DNS, CDN, Workers, Pages |
| Vercel | Deployments, domains |
| Supabase | Database, auth, storage |
| Docker | Containers, images, volumes |
| Kubernetes | Pods, services, deployments |

Set required environment variables for each server (API tokens, etc.).

---

## Safety

- Infrastructure safety hooks run automatically via `.claude/settings.json`
- Destructive operations (`terraform apply/destroy`, `kubectl delete`) trigger warnings
- Secret detection runs on every file write/edit
- Dockerfile best practices checked automatically
- All rules auto-load from `.claude/rules/` based on file patterns

---

## Requirements

- Claude Code CLI
- Node.js 18+ (for scripts)
- Relevant CLI tools as needed: `terraform`, `kubectl`, `docker`, `aws`, `gh`

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
