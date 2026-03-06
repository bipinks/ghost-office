# DevOps Agent Hub

> Claude Code native DevOps toolkit with 10 specialized agents, 21 domain skills, 16 slash commands, path-scoped rules, and infrastructure safety hooks for cloud operations, CI/CD, and reliable deployments.

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
│   ├── agents/                      # Specialized DevOps subagents
│   │   ├── infra-planner.md         # Infrastructure planning and design
│   │   ├── cicd-architect.md        # CI/CD pipeline architecture
│   │   ├── cloud-reviewer.md        # Cloud infrastructure code review
│   │   ├── security-auditor.md      # CIS benchmarks, OWASP for infra
│   │   ├── incident-responder.md    # Incident triage and resolution
│   │   ├── cost-optimizer.md        # Cloud cost analysis
│   │   ├── deployment-manager.md    # Blue/green, canary deployments
│   │   ├── monitoring-analyst.md    # Observability and alerting
│   │   ├── database-ops.md          # Database operations
│   │   └── container-reviewer.md    # Docker/K8s review
│   ├── commands/                    # Slash commands
│   │   ├── deploy.md                # /deploy
│   │   ├── infra-plan.md            # /infra-plan
│   │   ├── security-scan.md         # /security-scan
│   │   ├── cost-review.md           # /cost-review
│   │   ├── cicd-setup.md            # /cicd-setup
│   │   ├── docker-build.md          # /docker-build
│   │   ├── k8s-deploy.md            # /k8s-deploy
│   │   ├── server-provision.md      # /server-provision
│   │   ├── forge-deploy.md          # /forge-deploy
│   │   ├── ms365-provision.md       # /ms365-provision
│   │   ├── incident-response.md     # /incident-response
│   │   ├── backup.md                # /backup
│   │   ├── monitor-setup.md         # /monitor-setup
│   │   ├── db-migrate.md            # /db-migrate
│   │   ├── ssl-setup.md             # /ssl-setup
│   │   └── github-setup.md          # /github-setup
│   ├── skills/                      # Domain knowledge packs
│   │   ├── terraform-patterns/      # Terraform IaC best practices
│   │   ├── kubernetes-patterns/     # K8s deployment patterns
│   │   ├── docker-patterns/         # Dockerfile and Compose patterns
│   │   ├── aws-patterns/            # AWS service patterns
│   │   ├── github-workflows/        # GitHub Actions CI/CD patterns
│   │   ├── ansible-patterns/        # Ansible roles and playbooks
│   │   ├── monitoring-patterns/     # Prometheus, Grafana, Datadog
│   │   ├── laravel-forge/           # Forge site provisioning
│   │   ├── ms365-admin/             # Microsoft 365 administration
│   │   ├── nginx-patterns/          # Nginx configuration
│   │   ├── ssl-tls-management/      # Certificate management
│   │   ├── secrets-management/      # Vault, Secrets Manager
│   │   ├── backup-disaster-recovery/# Backup and DR strategies
│   │   ├── networking-patterns/     # VPC, DNS, CDN, load balancing
│   │   ├── security-hardening/      # Server hardening, CIS benchmarks
│   │   ├── log-management/          # ELK, CloudWatch, structured logs
│   │   ├── database-ops/            # PostgreSQL, MySQL, Redis ops
│   │   ├── serverless-patterns/     # Lambda, Cloud Functions
│   │   ├── gitops-patterns/         # ArgoCD, Flux workflows
│   │   ├── cicd-patterns/           # Pipeline design patterns
│   │   └── cloud-cost-optimization/ # FinOps and cost analysis
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
| Design infrastructure | `/infra-plan` | infra-planner |
| Build CI/CD pipeline | `/cicd-setup` | cicd-architect |
| Review Terraform code | *(use cloud-reviewer agent)* | cloud-reviewer |
| Security audit | `/security-scan` | security-auditor |
| Handle incident | `/incident-response` | incident-responder |
| Optimize cloud costs | `/cost-review` | cost-optimizer |
| Deploy application | `/deploy` | deployment-manager |
| Set up monitoring | `/monitor-setup` | monitoring-analyst |
| Database migration | `/db-migrate` | database-ops |
| Review Dockerfiles | `/docker-build` | container-reviewer |

---

## Common Workflows

**Setting up a new project:**
```bash
/infra-plan "Three-tier web app on AWS"
/cicd-setup "GitHub Actions with Docker and ECS"
/monitor-setup "Prometheus + Grafana for ECS services"
```

**Deploying to production:**
```bash
/security-scan
/cost-review
/deploy
```

**Incident response:**
```bash
/incident-response "High CPU on production web servers"
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
