---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/terraform/**"
---

# Terraform Rules

## State Management
- Always use remote state with encryption and locking
- Separate state files per environment and component
- Never manually edit state files — use `terraform state` commands
- Enable state file versioning

## Module Design
- Every module must have: variables.tf, outputs.tf, main.tf, README.md
- Add validation rules to all input variables
- Use `description` for all variables and outputs
- Pin provider versions with `~>` constraints
- Keep modules small and focused (single responsibility)

## Operations
- Always run `terraform plan` before `terraform apply`
- Never use `-auto-approve` in production
- Review plan output in pull requests
- Use `terraform fmt` for consistent formatting
- Run `tflint` and `checkov` in CI
- Import existing resources before managing them
- Tag ALL resources with standard taxonomy
