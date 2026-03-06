---
name: github-setup
description: Set up GitHub repository with branch protection, workflows, and team access
argument-hint: "[repo name or organization]"
---

# /github-setup — GitHub Repository Setup

Set up GitHub repository for $ARGUMENTS using the **cicd-architect** agent with the **github-workflows** skill:

1. Create repository with proper settings
2. Configure branch protection rules
3. Set up GitHub Actions workflows (CI/CD)
4. Configure team access and CODEOWNERS
5. Set up dependabot and security scanning
6. Create issue and PR templates

## Usage
```
/github-setup "new repo for Node.js API with CI/CD"
/github-setup "add branch protection to main"
/github-setup "configure dependabot for npm and Docker"
```
