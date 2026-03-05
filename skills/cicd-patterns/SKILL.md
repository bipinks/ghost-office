---
name: cicd-patterns
description: Use when designing CI/CD pipeline architecture. Covers stage ordering (lint→test→build→deploy), quality gates, artifact management, multi-environment promotion, canary/blue-green deployments, rollback strategies, and pipeline-as-code patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Grep"]
---

# CI/CD Patterns

## Pipeline Stages
```
┌──────┐   ┌──────┐   ┌───────┐   ┌──────────┐   ┌────────┐   ┌────────┐
│ Lint │──▶│ Test │──▶│ Build │──▶│ Security │──▶│  Stage │──▶│  Prod  │
└──────┘   └──────┘   └───────┘   └──────────┘   └────────┘   └────────┘
  Fast       Unit       Docker       SAST/DAST     Auto-deploy   Manual
 checks    + Integ     + Assets      + Deps scan    + Smoke     approval
```

## Quality Gates
```yaml
quality_gates:
  - name: test-coverage
    threshold: 80%
    action: block

  - name: security-vulnerabilities
    threshold: 0 critical, 0 high
    action: block

  - name: code-quality
    tools: [eslint, sonarqube]
    action: warn

  - name: performance
    threshold: p99 < 500ms
    action: warn
```

## Best Practices
1. **Fail fast** — Run cheapest checks first (lint, format, type-check)
2. **Immutable artifacts** — Build once, deploy to all environments
3. **Version everything** — Git SHA for tags, semver for releases
4. **Parallel stages** — Run independent jobs concurrently
5. **Cache aggressively** — Dependencies, Docker layers, build outputs
6. **Secret management** — Inject at runtime, never bake into artifacts
7. **Environment parity** — Dev/staging/production as similar as possible
8. **Rollback plan** — Every deployment must be reversible
9. **Observability** — Pipeline metrics: duration, success rate, failure reasons
10. **Documentation** — Pipeline architecture in README, troubleshooting guides
