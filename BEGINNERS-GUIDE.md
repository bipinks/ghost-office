# 🎓 Beginner's Guide to DevOps Agent Hub

Welcome! If you're new to DevOps and wondering what this project does and how to use it — this guide is for you.

---

## What Is This Project?

**DevOps Agent Hub** is a toolkit that makes Claude Code incredibly good at DevOps tasks. Think of it as a "brain upgrade" for your AI assistant — it teaches the AI about infrastructure, deployments, servers, and cloud services so it can actually help you do DevOps work.

### Simple Analogy
Imagine you hired 18 expert engineers across 7 departments — from product management and engineering to marketing, security, and IT. This project puts all their knowledge into your AI assistant so you can just ask it to do things and it knows how.

---

## How Does It Work?

The project has **6 main parts**:

```
┌─────────────────────────────────────────────────────┐
│                  YOU (the user)                     │
│         "Set up CI/CD for my Node.js app"           │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│              COMMANDS (23 shortcuts)                │
│   /cicd-setup, /deploy-staging, /fix-bug, etc.      │
│   → These are quick shortcuts you type              │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│               AGENTS (18 experts)                   │
│   The AI "experts" that handle the actual work      │
│   backend-engineer, devops-engineer, qa-agent, etc. │
└──────────────────────┬──────────────────────────────┘
                       │ uses knowledge from
                       ▼
┌─────────────────────────────────────────────────────┐
│           SKILLS (54 knowledge packs)               │
│   Step-by-step guides with real code examples       │
│   Terraform, Docker, AWS, Laravel, Vue, MS365, etc. │
└─────────────────────────────────────────────────────┘
```

Plus:
- **Rules** — Guidelines the AI always follows (like "never commit passwords")
- **Hooks** — Automatic safety checks (like warning before destructive operations)

---

## Getting Started (Step by Step)

### Step 1: Understand What You Have

Open the project folder in your editor. You'll see:

```
devops-agent-hub/
├── .claude/
│   ├── agents/    ← 18 AI "expert" definitions
│   ├── commands/  ← 22 shortcut commands
│   ├── skills/    ← 54 knowledge guides with code examples
│   ├── rules/     ← Safety and best practice rules
│   └── settings.json ← Automatic safety hooks
├── .mcp.json      ← External service connections
├── contexts/      ← Mode switching (dev/deploy/incident)
├── examples/      ← Sample configs for real projects
└── scripts/       ← Helper utilities
```

### Step 2: Start Claude Code

Everything auto-discovers from `.claude/` — no install or copy step needed:

```bash
cd devops-agent-hub
claude
```

To use in your own project, copy the core files into your project root:

```bash
# Required — agents, skills, commands, rules, hooks, and project instructions
cp -r devops-agent-hub/.claude/ your-project/.claude/
cp devops-agent-hub/CLAUDE.md your-project/CLAUDE.md

# Recommended — MCP integrations and agent reference
cp devops-agent-hub/.mcp.json your-project/.mcp.json
cp devops-agent-hub/AGENTS.md your-project/AGENTS.md
```

> **Tip:** After copying, run `/set-domain <name>` to activate your domain (erp, ecommerce, saas, healthcare, fintech, education, cms). Then edit `CLAUDE.md` to match your project's tech stack and architecture.

### Step 3: Start Using Commands

Slash commands are immediately available. Here are the most useful ones to start with:

---

## 🎯 Common Tasks (What You'll Actually Do)

### Task 1: Set Up a GitHub Repository with CI/CD

**What you type:**
```
/github-setup "new repo for my Node.js API with CI/CD"
```

**What happens:** The AI will generate configuration files for you:
1. Generate `.github/workflows/` CI/CD pipeline files (lint → test → build → deploy)
2. Suggest branch protection rules to configure
3. Generate dependabot configuration
4. Create PR and issue templates
5. You then review and commit these files to your repository

---

### Task 2: Deploy a Laravel App via Forge

**What you type:**
```
/forge-deploy "new site myapp.com on production server"
```

**What happens:** The AI will:
1. Guide you through creating a site on Laravel Forge
2. Generate the deployment script
3. Set up SSL with Let's Encrypt
4. Configure queue workers
5. Set up auto-deploy on git push

**Prerequisites:** You need a [Laravel Forge](https://forge.laravel.com) account and API token.

---

### Task 3: Provision Microsoft 365 Users

**What you type:**
```
/ms365-provision "create user john@company.com with E3 license"
```

**What happens:** The AI will:
1. Generate the Microsoft Graph API call or PowerShell script
2. Assign the correct license
3. Configure Teams membership
4. Set up security policies (MFA)

**Prerequisites:** You need Microsoft 365 admin access and a Graph API token.

---

### Task 4: Set Up Docker for Your App

**What you type:**
```
/docker-build "create Dockerfile for a Node.js app"
```

**What happens:** The AI will:
1. Create an optimized multi-stage Dockerfile
2. Create a docker-compose.yml with database and cache
3. Add a .dockerignore file
4. Set up health checks
5. Ensure security (non-root user, specific image tags)

---

### Task 5: Plan Cloud Infrastructure

**What you type:**
```
/infra-plan "Three-tier web app on AWS with a database and Redis cache"
```

**What happens:** The AI will:
1. Design the VPC layout (subnets, security groups)
2. Choose appropriate AWS services
3. Generate Terraform code
4. Estimate monthly costs
5. Document architecture decisions

---

### Task 6: Run a Security Audit

**What you type:**
```
/security-scan
```

**What happens:** The AI will:
1. Scan all infrastructure code for vulnerabilities
2. Check for hardcoded secrets
3. Verify encryption settings
4. Review IAM permissions
5. Generate a report with fixes

---

### Task 7: Handle a Production Incident

**What you type:**
```
/investigate-incident "API is returning 500 errors"
```

**What happens:** The AI will:
1. Help you triage the severity
2. Guide you through checking logs and metrics
3. Suggest mitigation steps
4. Help with root cause analysis
5. Generate a post-mortem document

---

## 📚 Learning Path (Recommended Order)

If you're brand new to DevOps, here's a suggested learning order:

### Week 1-2: Basics
1. **Read** `.claude/skills/docker-patterns/SKILL.md` — Learn Docker basics
2. **Try** `/docker-build` — Create your first Dockerfile
3. **Read** `.claude/skills/github-workflows/SKILL.md` — Learn CI/CD basics
4. **Try** `/github-setup` — Set up your first pipeline

### Week 3-4: Cloud & Infrastructure
1. **Read** `.claude/skills/aws-patterns/SKILL.md` — Understand cloud services
2. **Read** `.claude/skills/terraform-patterns/SKILL.md` — Learn Infrastructure-as-Code
3. **Try** `/infra-plan` — Design your first architecture

### Week 5-6: Deployment & Operations
1. **Read** `.claude/skills/ansible-patterns/SKILL.md` — Server provisioning and config management
2. **Read** `.claude/skills/nginx-patterns/SKILL.md` — Web server configuration
3. **Read** `.claude/skills/monitoring-patterns/SKILL.md` — Learn observability
4. **Try** `/monitor-setup` — Set up monitoring

### Week 7-8: Security & Advanced
1. **Read** `.claude/rules/common/security.md` — Security fundamentals
2. **Try** `/security-scan` — Audit your infrastructure
3. **Read** `.claude/skills/kubernetes-patterns/SKILL.md` — Container orchestration
4. **Try** `/k8s-deploy` — Deploy to Kubernetes

---

## 🔑 Key Concepts Explained

### What is Infrastructure-as-Code (IaC)?
Instead of clicking buttons in cloud consoles, you write code (usually Terraform) that describes your servers, databases, and networks. The tool then creates everything automatically and consistently.

### What is CI/CD?
**CI (Continuous Integration):** Automatically test every code change.
**CD (Continuous Deployment):** Automatically deploy tested code to servers.

### What is an Agent?
An "agent" in this project is a set of instructions that tells the AI assistant how to behave for a specific task. For example, the `security-auditor` agent knows exactly what security checks to run.

### What is a Skill?
A "skill" is a knowledge pack — a document full of best practices, code examples, and step-by-step instructions for a specific technology (like Terraform or Docker).

### What is a Hook?
A "hook" is an automatic check that runs when certain actions happen. For example, if you try to run `terraform destroy`, a hook will warn you to double-check.

---

## 💡 Tips for Beginners

1. **Start small** — Don't try to learn everything at once. Pick one area (e.g., Docker) and master it.
2. **Read the skills** — The `.claude/skills/*/SKILL.md` files are goldmines of practical knowledge with real code examples.
3. **Use commands freely** — The slash commands are safe to experiment with. They generate code/configs for you to review.
4. **Check the examples** — The `examples/` folder has complete CLAUDE.md configs for real-world projects you can copy.
5. **Follow the rules** — The `.claude/rules/` files contain critical best practices. Read `.claude/rules/common/security.md` first.
6. **Don't fear mistakes, but be cautious** — Many IaC resources can be recreated, but **data is not reversible**. Deleting a database destroys its data permanently. Always work in dev/staging environments first, and never run destructive commands (like `terraform destroy`) on production without a backup.

---

## ❓ FAQ

**Q: Do I need all these tools installed?**
No! Install only what you need. Start with `git` and `docker`. Add `terraform`, `kubectl`, etc. as you progress.

**Q: Is this only for AWS?**
No. While AWS examples are most detailed, the patterns apply to Azure, GCP, and DigitalOcean too. The skills cover multi-cloud approaches.

**Q: Can I use this for my personal projects?**
Absolutely! It's great for setting up CI/CD for personal repos, deploying side projects, or learning DevOps concepts.

**Q: What if I break something?**
The hooks and safety checks are designed to prevent mistakes. The `infra-safety-check` hook warns you before destructive operations. Always work in a dev/staging environment first.

**Q: Where do I get API tokens for Forge/MS365/AWS?**
- **Laravel Forge**: Dashboard → API Tokens
- **Microsoft 365**: Azure Portal → App Registrations
- **AWS**: IAM Console → Security Credentials
- **GitHub**: Settings → Developer Settings → Personal Access Tokens
