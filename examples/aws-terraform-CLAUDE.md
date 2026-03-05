# CLAUDE.md — AWS + Terraform Project

## Project Overview
Production infrastructure on AWS managed with Terraform.

## Architecture
- **VPC**: Multi-AZ with public, private, and data subnets
- **Compute**: ECS Fargate for containerized services
- **Database**: Aurora PostgreSQL with read replicas
- **Cache**: ElastiCache Redis cluster
- **CDN**: CloudFront with S3 origin
- **DNS**: Route 53 with health checks
- **Monitoring**: CloudWatch + Datadog
- **CI/CD**: GitHub Actions with OIDC

## Infrastructure Structure
```
infrastructure/
├── modules/         # Reusable Terraform modules
├── environments/    # Per-environment configs (dev, staging, prod)
├── global/          # Shared resources (IAM, DNS)
└── scripts/         # Helper scripts
```

## Key Commands
```bash
cd infrastructure/environments/production
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## State
- S3 backend: `myorg-terraform-state`
- DynamoDB locking: `terraform-locks`
- KMS encryption: `alias/terraform-state`

## Tagging Standard
All resources must have: Environment, Project, Owner, CostCenter, ManagedBy
