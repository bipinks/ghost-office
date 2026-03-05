# DevOps Agent Hub

> Production-ready DevOps AI toolkit with specialized agents, skills, commands, and security guardrails for infrastructure, CI/CD, cloud operations, and reliable deployments.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

**Not just configs.** A complete DevOps automation system: 10 specialized agents, 21 domain skills, 16 slash commands, 7 rule categories, infrastructure safety hooks, and MCP configurations — evolved for real-world DevOps workflows.

Works with Claude Code, Codex, Cowork, and other AI agent harnesses.

---

## 🚀 Quick Start

### Step 1: Install the Plugin

```bash
# Add this repository as a local marketplace
claude plugin marketplace add /path/to/devops-agent-hub

# Install the plugin from that marketplace
claude plugin install devops-agent-hub@devops-agent-hub

# Or run the install script
curl -fsSL https://raw.githubusercontent.com/bipinks/devops-agent-hub/main/install.sh | bash
```

### Step 2: Install Rules (Required)

```bash
# Copy common rules to your global config
cp -r rules/common/ ~/.claude/rules/

# Add domain-specific rules as needed
cp -r rules/terraform/ ~/.claude/rules/
cp -r rules/kubernetes/ ~/.claude/rules/
cp -r rules/docker/ ~/.claude/rules/
```

### Step 3: Start Using

```bash
# Plan infrastructure
/infra-plan "Design a VPC with public and private subnets"

# Set up CI/CD
/cicd-setup "Create GitHub Actions for a Node.js app with Docker deploy"

# Deploy via Laravel Forge
/forge-deploy "Provision a new site on Forge with SSL"

# Provision Microsoft 365
/ms365-provision "Set up new user accounts with E3 licenses"

# Security scan
/security-scan

# Review cloud costs
/cost-review
```

### Step 4: Use with Codex

```bash
# Start Codex in this project
codex -C /path/to/devops-agent-hub

# Optional strict profile for sensitive infra actions
codex -C /path/to/devops-agent-hub -p devops_strict
```

Codex compatibility is preconfigured in `.codex/config.toml` and `.agents/skills`.

---

## 📦 What's Inside

```
devops-agent-hub/
├── .codex/                      # Codex project-local config and guide
│   ├── config.toml              # Codex model/sandbox/profile/MCP settings
│   └── README.md                # Codex usage notes
├── .agents/                     # Codex agent-system compatibility bridge
│   ├── skills -> ../skills      # Shared skill source for Codex + Claude
│   └── README.md                # Bridge documentation
├── .claude-plugin/              # Plugin and marketplace manifests
│   ├── plugin.json              # Plugin manifest (metadata + plugin integrations)
│   └── marketplace.json         # Marketplace catalog
├── agents/                      # Specialized DevOps subagents
│   ├── infra-planner.md         # Infrastructure planning and design
│   ├── cicd-architect.md        # CI/CD pipeline architecture
│   ├── cloud-reviewer.md        # Cloud infrastructure code review
│   ├── security-auditor.md      # CIS benchmarks, OWASP for infra
│   ├── incident-responder.md    # Incident triage and resolution
│   ├── cost-optimizer.md        # Cloud cost analysis
│   ├── deployment-manager.md    # Blue/green, canary deployments
│   ├── monitoring-analyst.md    # Observability and alerting
│   ├── database-ops.md          # Database operations
│   └── container-reviewer.md    # Docker/K8s review
├── skills/                      # DevOps domain knowledge packs
│   ├── github-workflows/        # GitHub Actions CI/CD patterns
│   ├── terraform-patterns/      # Terraform IaC best practices
│   ├── kubernetes-patterns/     # K8s deployment patterns
│   ├── docker-patterns/         # Dockerfile and Compose patterns
│   ├── ansible-patterns/        # Ansible roles and playbooks
│   ├── aws-patterns/            # AWS service patterns
│   ├── monitoring-patterns/     # Prometheus, Grafana, Datadog
│   ├── laravel-forge/           # Forge site provisioning
│   ├── ms365-admin/             # Microsoft 365 administration
│   ├── nginx-patterns/          # Nginx configuration
│   ├── ssl-tls-management/      # Certificate management
│   ├── secrets-management/      # Vault, Secrets Manager
│   ├── backup-disaster-recovery/# Backup and DR strategies
│   ├── networking-patterns/     # VPC, DNS, CDN, load balancing
│   ├── security-hardening/      # Server hardening, CIS benchmarks
│   ├── log-management/          # ELK, CloudWatch, structured logs
│   ├── database-ops/            # PostgreSQL, MySQL, Redis ops
│   ├── serverless-patterns/     # Lambda, Cloud Functions
│   ├── gitops-patterns/         # ArgoCD, Flux workflows
│   ├── cicd-patterns/           # Pipeline design patterns
│   └── cloud-cost-optimization/ # FinOps and cost analysis
├── commands/                    # Slash commands for quick execution
│   ├── deploy.md                # /deploy — Deploy application
│   ├── infra-plan.md            # /infra-plan — Plan infrastructure
│   ├── security-scan.md         # /security-scan — Security audit
│   ├── cost-review.md           # /cost-review — Cost analysis
│   ├── cicd-setup.md            # /cicd-setup — Pipeline generation
│   ├── docker-build.md          # /docker-build — Container build
│   ├── k8s-deploy.md            # /k8s-deploy — K8s deployment
│   ├── server-provision.md      # /server-provision — Provision servers
│   ├── forge-deploy.md          # /forge-deploy — Laravel Forge
│   ├── ms365-provision.md       # /ms365-provision — MS365 setup
│   ├── incident-response.md     # /incident-response — Triage
│   ├── backup.md                # /backup — Backup management
│   ├── monitor-setup.md         # /monitor-setup — Monitoring
│   ├── db-migrate.md            # /db-migrate — DB migration
│   ├── ssl-setup.md             # /ssl-setup — SSL/TLS setup
│   └── github-setup.md          # /github-setup — GitHub setup
├── rules/                       # Always-follow guidelines
│   ├── README.md                # Structure overview
│   ├── common/                  # Language-agnostic DevOps principles
│   ├── terraform/               # Terraform-specific rules
│   ├── kubernetes/              # K8s-specific rules
│   ├── docker/                  # Docker-specific rules
│   ├── cicd/                    # CI/CD-specific rules
│   ├── cloud/                   # Cloud-specific rules
│   └── security/                # Security-specific rules
├── hooks/                       # Trigger-based automations
│   ├── hooks.json               # Hook configurations
│   └── README.md                # Hook documentation
├── scripts/                     # Cross-platform utilities
│   ├── lib/
│   │   └── utils.js             # File, path, system utilities
│   └── hooks/
│       ├── session-start.js     # Load context on session start
│       ├── session-end.js       # Save state on session end
│       └── infra-safety-check.js# Infrastructure safety hooks
├── contexts/                    # Dynamic context injection
│   ├── dev.md                   # Development mode
│   ├── deploy.md                # Deployment mode
│   ├── incident.md              # Incident response mode
│   └── review.md                # Infrastructure review mode
├── examples/                    # Example configurations
│   ├── CLAUDE.md                # Generic project config
│   ├── aws-terraform-CLAUDE.md  # AWS + Terraform
│   ├── k8s-microservices-CLAUDE.md  # Kubernetes setup
│   └── laravel-forge-CLAUDE.md  # Laravel Forge setup
└── mcp-configs/                 # MCP server configurations
    └── mcp-servers.json         # GitHub, AWS, Azure, GCP, etc.
```

---

## 🎯 Key Concepts

### Agents
Specialized subagents handle delegated DevOps tasks with limited scope:

```markdown
---
name: security-auditor
description: Reviews infrastructure for security vulnerabilities
tools: ["Read", "Grep", "Glob", "Bash"]
model: opus
---
You are a senior DevOps security auditor...
```

### Skills
Skills are domain knowledge packs invoked by commands or agents:

```markdown
# Terraform Patterns
1. Use remote state with locking
2. Organize by modules and environments
3. Use variable validation with custom rules
4. Implement drift detection in CI
5. Tag all resources with standard taxonomy
```

### Commands
Slash commands for quick execution:

```bash
/infra-plan "Design HA architecture for a SaaS app"
/cicd-setup "GitHub Actions for Python with pytest + Docker"
/security-scan
/deploy
```

### Rules
Always-follow guidelines organized by domain:

```
rules/
  common/      # Universal DevOps principles
  terraform/   # Terraform-specific patterns
  kubernetes/  # K8s-specific patterns
  docker/      # Docker-specific patterns
  cicd/        # CI/CD-specific patterns
  cloud/       # Cloud-specific patterns
  security/    # Security-specific patterns
```

---

## 🗺️ Which Agent Should I Use?

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

### Common Workflows

**Setting up a new project:**
```bash
/infra-plan "Three-tier web app on AWS"
  → infra-planner designs VPC, subnets, security groups
/cicd-setup "GitHub Actions with Docker and ECS"
  → cicd-architect creates workflow files
/monitor-setup "Prometheus + Grafana for ECS services"
  → monitoring-analyst creates dashboards and alerts
```

**Deploying to production:**
```bash
/security-scan → security-auditor: CIS benchmark audit
/cost-review → cost-optimizer: pre-deploy cost estimate
/deploy → deployment-manager: blue/green deployment
```

**Incident response:**
```bash
/incident-response "High CPU on production web servers"
  → incident-responder: triage, root cause, runbook
```

---

## 📋 Requirements

- Claude Code CLI or compatible AI agent harness
- Node.js 18+ (for hooks and scripts)
- Relevant CLI tools for your stack:
  - `terraform`, `kubectl`, `docker`, `ansible` (as needed)
  - `aws`, `az`, `gcloud` CLI tools (as needed)
  - `forge` CLI (for Laravel Forge)
  - `gh` CLI (for GitHub operations)

---

## ⚠️ Important Notes

### Infrastructure Safety
- All destructive infrastructure operations require explicit confirmation
- Terraform `apply` and `destroy` operations trigger safety hooks
- Secret values are never logged or stored in plain text

### Customization
- Add project-specific rules to your project's `.claude/rules/` directory
- Override default skills by creating project-level skill files
- Customize hooks in `hooks/hooks.json`

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the existing patterns
4. Submit a PR with a clear description

### Ideas for Contributions
- Additional cloud provider skills (Oracle Cloud, IBM Cloud)
- More CI/CD platform support (CircleCI, Bitbucket Pipelines)
- Compliance frameworks (HIPAA, PCI-DSS, SOC2)
- Service mesh patterns (Istio, Linkerd)
- Edge computing patterns

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.
