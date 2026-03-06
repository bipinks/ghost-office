---
name: infra-plan
description: Plan and design cloud infrastructure architecture
argument-hint: "[project or workload description]"
---

# /infra-plan — Infrastructure Planning

Plan infrastructure for $ARGUMENTS using the **infra-planner** agent:

1. Gather requirements (application type, traffic, compliance)
2. Design multi-tier architecture (network → compute → data → security)
3. Generate Terraform/IaC code
4. Produce cost estimate
5. Document architecture decisions (ADRs)

## Usage
```
/infra-plan "Three-tier web app on AWS with RDS and ElastiCache"
/infra-plan "Microservices on ECS Fargate with service mesh"
/infra-plan "Static site with CloudFront and S3"
```
