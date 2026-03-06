# Testing — DevOps Rules

## Infrastructure Testing
- **Static analysis**: `terraform validate`, `tflint`, `checkov`, `trivy`
- **Unit tests**: Module-level tests with Terratest or pytest
- **Integration tests**: Deploy to ephemeral environment, run checks, destroy
- **Compliance tests**: CIS benchmark checks, policy-as-code (OPA, Sentinel)

## CI/CD Testing
- Run tests on every PR (no exceptions)
- Pin tool versions for reproducibility
- Use test environments that mirror production
- Clean up test resources after each run

## Coverage Requirements
- Infrastructure modules: 80%+ test coverage
- Ansible roles: Molecule tests for every role
- Docker images: Vulnerability scan + functionality tests
- Kubernetes manifests: Policy validation (kubeval, kube-score)
