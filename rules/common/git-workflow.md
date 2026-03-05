# Git Workflow — DevOps

## Commit Format
Use conventional commits:
```
feat: add ECS service module
fix: correct security group ingress rule
docs: update deployment runbook
chore: update terraform provider versions
refactor: simplify VPC module variables
ci: add terraform plan to PR checks
```

## Branch Strategy
- `main` — Production-ready, protected, requires PR review
- `develop` — Integration branch for staging
- `feat/*` — Feature branches from develop
- `fix/*` — Bug fix branches
- `hotfix/*` — Emergency production fixes from main

## PR Process
1. Create feature branch from develop
2. Make changes with descriptive commits
3. Push and create PR with description
4. Require at least 1 reviewer approval
5. All CI checks must pass
6. Squash merge to keep history clean

## Protected Branches
- Require pull request reviews (minimum 1)
- Require status checks to pass
- Require signed commits for production
- No force pushes to main or develop
- Require linear history

## Infrastructure-Specific
- Always include `terraform plan` output in PR
- Tag infrastructure releases with semver
- Never commit secrets — use `.gitignore` for `.env`, `*.tfvars`, `*.pem`
