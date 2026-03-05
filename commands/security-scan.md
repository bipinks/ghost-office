---
name: security-scan
description: Run comprehensive security audit against CIS benchmarks and OWASP guidelines
argument-hint: "[target path or service]"
---

# /security-scan — Security Audit

Run security scan on $ARGUMENTS using the **security-auditor** agent:

1. Scan infrastructure code for vulnerabilities
2. Check IAM policies for least privilege violations
3. Verify encryption settings (at rest, in transit)
4. Audit container configurations
5. Check for secrets in code and configs
6. Generate security report with severity ratings

## Usage
```
/security-scan                           # Full audit
/security-scan "terraform/"              # Scan Terraform only
/security-scan "kubernetes/manifests/"   # Scan K8s manifests
```
