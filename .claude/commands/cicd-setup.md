---
name: cicd-setup
description: Generate CI/CD pipeline configuration for any platform
argument-hint: "[platform] [project type]"
---

# /cicd-setup — CI/CD Pipeline Generation

Set up CI/CD for $ARGUMENTS using the **devops-engineer** agent:

1. Analyze the project stack and structure
2. Choose the appropriate CI platform
3. Design pipeline stages (lint → test → build → security → deploy)
4. Generate pipeline configuration files
5. Document secret requirements and caching strategy

## Usage
```
/cicd-setup "GitHub Actions for Node.js with Docker"
/cicd-setup "GitLab CI for Python Django with PostgreSQL"
/cicd-setup "GitHub Actions for Terraform with plan/apply"
```
