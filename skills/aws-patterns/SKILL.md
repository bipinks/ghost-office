---
name: aws-patterns
description: Use when designing or implementing AWS infrastructure. Covers EC2, ECS/Fargate, Lambda, S3, RDS, IAM policies, VPC networking, CloudFormation, and cost-optimized architecture patterns across compute, storage, and networking.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# AWS Patterns

## VPC Architecture
```hcl
# Terraform — Production VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0"

  name = "${var.project}-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "production"
  enable_dns_hostnames   = true
  enable_dns_support     = true

  tags = local.common_tags
}
```

## ECS Fargate Service
```yaml
# Task Definition
{
  "family": "web-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskRole",
  "containerDefinitions": [{
    "name": "web-app",
    "image": "ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/web-app:latest",
    "portMappings": [{"containerPort": 8080}],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/web-app",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "secrets": [{
      "name": "DATABASE_URL",
      "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:db-url"
    }],
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:8080/healthz || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3
    }
  }]
}
```

## IAM Best Practices
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

## Lambda Function Pattern
```python
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """Lambda handler with structured logging and error handling."""
    logger.info("Processing event", extra={"event": json.dumps(event)})

    try:
        # Process event
        result = process(event)
        return {
            "statusCode": 200,
            "body": json.dumps(result)
        }
    except ValueError as e:
        logger.warning(f"Validation error: {e}")
        return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        return {"statusCode": 500, "body": json.dumps({"error": "Internal server error"})}
```

## Best Practices
1. **IAM least privilege** — Scope permissions to specific resources and actions
2. **Encryption** — Enable at rest (KMS) and in transit (TLS) everywhere
3. **VPC endpoints** — Use for S3, DynamoDB, ECR to avoid NAT costs
4. **Tagging** — Mandatory tags: Environment, Project, Owner, CostCenter, ManagedBy
5. **Multi-AZ** — Deploy across 3 AZs for production workloads
6. **CloudTrail** — Enable in all regions for audit logging
7. **Config** — Use AWS Config rules for compliance monitoring
8. **GuardDuty** — Enable for threat detection
9. **Budgets** — Set billing alerts and anomaly detection
10. **SSO** — Use AWS SSO with Identity Center, not IAM users
