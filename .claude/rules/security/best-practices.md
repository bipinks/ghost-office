---
paths:
  - "**/*.tf"
  - "**/*.yaml"
  - "**/*.yml"
  - "**/Dockerfile*"
  - "**/.github/workflows/**"
---

# Security Rules

## CIS Benchmarks
- Follow CIS benchmarks for your cloud provider (AWS, Azure, GCP)
- Run automated CIS checks in CI (Prowler, ScoutSuite)
- Document exceptions with justification

## Secrets
- No plaintext secrets anywhere (code, configs, env files, logs)
- Use a secrets manager (Vault, AWS Secrets Manager)
- Rotate secrets on a schedule (30-90 days)
- Scan for leaked secrets with gitleaks/trufflehog

## Access Control
- Principle of least privilege everywhere
- Time-bounded access for elevated permissions
- Regular access reviews (quarterly minimum)
- Separate admin accounts from daily accounts

## Incident Response
- Document incident response procedures
- Test IR procedures quarterly
- Maintain on-call rotation
- Post-incident reviews for all SEV1/SEV2 incidents
- Blameless retrospectives focused on systems
