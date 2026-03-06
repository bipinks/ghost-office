# Security — DevOps Rules

## Mandatory Checks
- [ ] No secrets in code, configs, or environment files
- [ ] All credentials stored in secrets manager
- [ ] Encryption at rest enabled for all storage
- [ ] Encryption in transit (TLS 1.2+) for all communication
- [ ] IAM follows least privilege principle
- [ ] No 0.0.0.0/0 ingress on sensitive ports
- [ ] MFA enabled for all admin accounts
- [ ] Audit logging enabled (CloudTrail, audit logs)

## Never Do
- ❌ Commit secrets, API keys, or passwords to Git
- ❌ Use root/admin credentials in applications
- ❌ Disable SSL/TLS verification
- ❌ Open SSH (22) or RDP (3389) to the internet
- ❌ Store credentials in environment variables in CI configs
- ❌ Use `latest` tag for base images (supply chain risk)
- ❌ Skip security scanning in CI/CD pipelines
- ❌ Run containers as root in production

## Always Do
- ✅ Scan for secrets before every commit (gitleaks, trufflehog)
- ✅ Rotate credentials on a regular schedule
- ✅ Use OIDC for CI/CD cloud authentication
- ✅ Enable vulnerability scanning for container images
- ✅ Apply security patches within 48 hours (critical) or 7 days (high)
- ✅ Use network segmentation (public, private, data subnets)
- ✅ Log all access to sensitive resources
