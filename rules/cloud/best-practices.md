---
paths:
  - "**/*.tf"
  - "**/cloudformation/**"
  - "**/cdk/**"
  - "**/pulumi/**"
---

# Cloud Rules

## IAM
- Least privilege for all roles and policies
- Use SSO/Identity Center, not IAM users
- Enable MFA for all human access
- Scope permissions to specific resources (no wildcard `*`)
- Rotate credentials regularly

## Networking
- Use private subnets for application and data tiers
- VPC endpoints for service access (reduce NAT costs)
- Enable VPC flow logs
- Use security groups as primary network control

## Cost
- Tag ALL resources (Environment, Project, Owner, CostCenter)
- Set billing alerts at 50%, 80%, 100%
- Review costs monthly
- Delete unused resources promptly
- Use reserved capacity for steady-state workloads

## Compliance
- Enable CloudTrail/audit logging in all regions
- Use AWS Config / Azure Policy for compliance rules
- Enable GuardDuty / Security Center for threat detection
- Apply organizational SCPs for guardrails
