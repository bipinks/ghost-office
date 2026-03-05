# Rules — Structure Overview

Rules are always-follow guidelines that inform agent behavior. They are organized by domain and installed globally.

## Installation

```bash
# Install all rules
cp -r rules/ ~/.claude/rules/

# Or install selectively
cp -r rules/common/ ~/.claude/rules/common/
cp -r rules/terraform/ ~/.claude/rules/terraform/
cp -r rules/kubernetes/ ~/.claude/rules/kubernetes/
```

## Structure

```
rules/
├── common/           # Universal DevOps principles (always install)
│   ├── coding-style.md
│   ├── git-workflow.md
│   ├── security.md
│   ├── testing.md
│   └── performance.md
├── terraform/        # Terraform-specific rules
│   └── best-practices.md
├── kubernetes/       # Kubernetes-specific rules
│   └── best-practices.md
├── docker/           # Docker-specific rules
│   └── best-practices.md
├── cicd/             # CI/CD-specific rules
│   └── best-practices.md
├── cloud/            # Cloud-specific rules
│   └── best-practices.md
└── security/         # Security-specific rules
    └── best-practices.md
```

## Key Principle
Common rules apply to **all** DevOps work. Domain-specific rules add specialized guidance for particular tools and technologies.
