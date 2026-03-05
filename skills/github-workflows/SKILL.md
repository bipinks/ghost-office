---
name: github-workflows
description: Use when creating or modifying GitHub Actions CI/CD pipelines. Covers reusable workflows, matrix builds, OIDC authentication for cloud deploys, caching strategies, and deployment automation with environment protection rules.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# GitHub Workflows — CI/CD Patterns

## Core Concepts

### Workflow Structure
```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

permissions:
  contents: read
  id-token: write  # For OIDC

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  test:
    needs: lint
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: build-output
      - name: Deploy to production
        run: echo "Deploy steps here"
```

### Reusable Workflows
```yaml
# .github/workflows/reusable-docker.yml
name: Reusable Docker Build
on:
  workflow_call:
    inputs:
      image-name:
        required: true
        type: string
      dockerfile:
        required: false
        type: string
        default: 'Dockerfile'
    secrets:
      registry-token:
        required: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.registry-token }}
      - uses: docker/build-push-action@v5
        with:
          context: .
          file: ${{ inputs.dockerfile }}
          push: true
          tags: ghcr.io/${{ github.repository }}/${{ inputs.image-name }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### OIDC Authentication (No Long-Lived Credentials)
```yaml
jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
          aws-region: us-east-1
```

## Best Practices
1. **Pin action versions** — Use SHA hashes for third-party actions
2. **Cache dependencies** — Use `actions/cache` or built-in caching
3. **Use OIDC** — Avoid long-lived credentials in secrets
4. **Matrix builds** — Test across multiple versions and platforms
5. **Environment protection** — Require approval for production deploys
6. **Reusable workflows** — DRY principle for common patterns
7. **Concurrency** — Cancel redundant runs with `concurrency` key
8. **Artifacts** — Upload build outputs for downstream jobs

## Common Patterns
- **Branch protection**: Require CI checks before merge
- **Auto-merge**: Merge dependabot PRs automatically after CI passes
- **Release automation**: Tag and create releases on main branch
- **Scheduled jobs**: Dependency updates, security scans, cleanup
- **PR labeling**: Automatic labels based on changed files
