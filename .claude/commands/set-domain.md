---
name: set-domain
description: Set the project domain to load specialized domain knowledge (erp, ecommerce, saas, healthcare, fintech, education, cms)
argument-hint: "<domain: erp|ecommerce|saas|healthcare|fintech|education|cms>"
---

## Set Project Domain

Set the active domain knowledge pack for this project: **$ARGUMENTS**

### Available Domains

| Domain | Description |
|--------|-------------|
| `erp` | Enterprise Resource Planning — accounting, inventory, sales, HR, procurement |
| `ecommerce` | E-Commerce — catalog, cart, checkout, orders, payments, shipping |
| `saas` | SaaS Platform — subscriptions, multi-tenancy, billing, feature flags |
| `healthcare` | Healthcare / HealthTech — EHR, HIPAA compliance, clinical workflows, HL7 FHIR |
| `fintech` | Financial Technology — payments, ledger, KYC/AML, fraud detection |
| `education` | EdTech — courses, assessments, LMS, FERPA compliance |
| `cms` | Content Management — content authoring, SEO, headless API, localization |

### Steps

1. **Validate Domain**: Confirm `$ARGUMENTS` is one of: `erp`, `ecommerce`, `saas`, `healthcare`, `fintech`, `education`, `cms`
2. **Write Lock File**: Write the domain name to `.claude/memory/domain.lock`
3. **Copy Domain Knowledge**: Copy `.claude/memory/domains/$ARGUMENTS.md` content to `.claude/memory/domain-knowledge.md`
4. **Confirm**: Report the active domain and key knowledge areas loaded

### How Domain Detection Works

Domain detection is **fully autonomous** with three layers:

1. **Auto-detection (first session)**: When no `domain.lock` exists, the `session-start.sh` hook instructs Claude to read key project files (composer.json, package.json, README.md, etc.), understand the project's domain using AI comprehension, and run `/set-domain` automatically. This leverages Claude's contextual understanding — far more accurate than keyword matching.

2. **Cached (subsequent sessions)**: Once set, the domain is stored in `.claude/memory/domain.lock`. All future sessions read from cache — zero overhead.

3. **Manual override (`/set-domain`)**: Always works. Overrides auto-detection or switches domains instantly.

### Behavior

- The `domain.lock` file caches the active domain so detection only happens once
- The session-start hook reads `domain.lock` and references the correct domain knowledge
- Running `/set-domain` again with a different domain switches immediately
- The base `domain-knowledge.md` is overwritten with the selected domain template

### Example

```
/set-domain ecommerce
```

This will:
1. Write `ecommerce` to `.claude/memory/domain.lock`
2. Replace `.claude/memory/domain-knowledge.md` with e-commerce domain knowledge
3. All agents will now reference e-commerce business rules and patterns
