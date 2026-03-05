# CLAUDE.md — Example Project Configuration

## Project Overview
This is a [YOUR PROJECT NAME] running on [YOUR STACK].

## Architecture
- **Frontend**: React/Next.js on Vercel
- **Backend**: Node.js API on ECS Fargate
- **Database**: PostgreSQL on RDS
- **Cache**: Redis on ElastiCache
- **CI/CD**: GitHub Actions
- **Infrastructure**: Terraform

## Key Commands
```bash
# Development
npm run dev              # Start local dev server
npm test                 # Run tests
npm run lint             # Lint code

# Infrastructure
cd infrastructure/
terraform plan           # Review changes
terraform apply          # Apply changes (requires approval)

# Docker
docker compose up -d     # Start local stack
docker compose logs -f   # View logs

# Deployment
git push origin main     # Triggers CI/CD pipeline
```

## Environment Variables
See `.env.example` for required variables.
Never commit `.env` files — use the secrets manager.

## Team Contacts
- **On-call**: Check PagerDuty schedule
- **Infrastructure**: #infra-team Slack channel
- **Deploys**: #deployments Slack channel
