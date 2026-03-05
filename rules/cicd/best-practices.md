---
paths:
  - "**/.github/workflows/**"
  - "**/.gitlab-ci.yml"
  - "**/Jenkinsfile"
  - "**/bitbucket-pipelines.yml"
  - "**/.circleci/**"
---

# CI/CD Rules

## Pipeline Reliability
- Pin all tool and action versions
- Cache dependencies for speed
- Fail fast — cheapest checks first
- Use matrix builds for multi-version testing

## Security
- Use OIDC for cloud auth (no long-lived keys)
- Store secrets in CI vault, never in pipeline configs
- Scan dependencies for vulnerabilities
- Enable SAST/DAST in pipeline

## Deployment
- Build once, deploy to all environments (immutable artifacts)
- Manual approval gate for production
- Include rollback procedures
- Monitor for 30 minutes after deploy
- Never deploy on Fridays (unless critical hotfix)
