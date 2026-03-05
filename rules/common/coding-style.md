# Coding Style — DevOps

## File Organization
- One responsibility per file
- Group related configurations together
- Use consistent naming: `kebab-case` for files, `snake_case` for variables
- Keep files under 300 lines — split into modules when larger

## Naming Conventions
- **Resources**: `{project}-{environment}-{resource-type}` (e.g., `myapp-production-vpc`)
- **Variables**: Descriptive names with units (e.g., `max_retry_count`, `timeout_seconds`)
- **Tags**: Consistent taxonomy across all resources

## Documentation
- Every module/role/playbook has a README
- Inline comments for non-obvious logic
- Architecture Decision Records (ADRs) for significant choices
- Runbooks for operational procedures

## Code Quality
- Lint all configuration files (terraform fmt, yamllint, shellcheck)
- Validate before applying (terraform validate, kubeval)
- Use pre-commit hooks for formatting checks
- Review all changes via pull requests
