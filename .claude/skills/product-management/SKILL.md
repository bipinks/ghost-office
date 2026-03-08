---
name: product-management
description: Use when defining features, writing user stories, prioritizing work, or creating acceptance criteria. Covers requirements gathering, user story mapping, prioritization frameworks, sprint planning, and stakeholder communication.
user-invocable: false
allowed-tools: ["Read", "Write", "Grep", "Glob"]
---

# Product Management -- Requirements & Feature Delivery

## Requirements Gathering

### Problem Statement
```
PROBLEM:    [Specific, observable problem]
WHO:        [Affected user roles and branches]
IMPACT:     [Quantified -- time lost, revenue at risk, error rate]
FREQUENCY:  [Daily, per transaction, monthly]
EVIDENCE:   [Support tickets, analytics, user feedback]
```

### Jobs-to-Be-Done
```
When [situation/trigger],
I want to [motivation/action],
So I can [expected outcome].
Constraints: [time/budget/regulatory limits, integrations, must not break X]
```

## User Stories (INVEST)

```
As a [role] in [branch/department],
I want to [specific action],
So that [measurable business value].
```

**I**ndependent, **N**egotiable, **V**aluable, **E**stimable, **S**mall (fits a sprint), **T**estable.

| Size | Points | Description |
|------|--------|-------------|
| XS | 1 | Config change, label update |
| S | 2 | Single field or simple logic |
| M | 3-5 | New screen or workflow step |
| L | 8 | Multi-screen feature |
| XL | 13+ | Must be split |

## Acceptance Criteria

### Given/When/Then
```
- [ ] Given [precondition], When [action], Then [testable result].
```

### Mandatory Baseline (every data-modifying feature)
```
Multi-Tenant: User sees only own branch data; cross-branch access returns 403.
Audit Trail:  Every CUD logs user, timestamp, table, record ID, old/new values.
Permissions:  Users without required permission get 403; read-only users cannot write.
Validation:   Invalid input shows field-level errors; missing required fields blocks submit.
Performance:  List < 300ms p95; form submit < 500ms p95.
Security:     All inputs validated server-side; no sensitive data leaked to unauthorized roles.
```

## User Story Mapping

```
ACTIVITY (Epic)       -- "Manage Sales Orders"
  TASK (Feature)      -- "Create Sales Order"
    STORY             -- "Add line items", "Apply discount", "Submit for approval"
  TASK (Feature)      -- "Track Sales Order Status"
    STORY             -- "View timeline", "Receive notification on change"
```

**MVP Slicing**: Slice horizontally. MVP = minimum stories for end-to-end core workflow.

## Prioritization Frameworks

### RICE (Primary)
```
Score = (Reach x Impact x Confidence) / Effort
Reach: users/branches per quarter | Impact: 0.25-3 scale | Confidence: 50-100% | Effort: person-weeks
```

### MoSCoW (Release Scoping)
- **Must**: System fails without it. Regulatory. Core blocker.
- **Should**: Important, has workaround.
- **Could**: Nice to have, low risk to defer.
- **Won't**: Explicitly out of scope this release.

### Kano Model
| Category | Description |
|----------|-------------|
| Basic | Expected; absence causes dissatisfaction (login, save, print) |
| Performance | More is better, linear satisfaction (speed, filters, search) |
| Delighter | Unexpected, strong satisfaction (auto-suggestions, smart defaults) |

## Feature Specification Template

```markdown
# Feature: [Name]
## Problem: [What, who, business cost of not solving]
## Scope / Out of Scope
## User Stories (with acceptance criteria)
## Data Model: Entity | Key Fields | Relationships
## API Endpoints: Method | Endpoint | Description | Auth
## UI/UX: Screens, key interactions, user flow
## Permissions: Role x CRUD matrix
## Edge Cases
## Success Metrics
## Dependencies
## Testing Plan: Unit, integration, E2E, multi-tenant isolation
```

## Sprint Planning

Fibonacci estimation: 1, 2, 3, 5, 8, 13. Split stories > 8 points.
Planned capacity = avg velocity (last 3 sprints) x 0.8 buffer.

## Release Planning

### Feature Flags
```
FEATURE_INVOICE_PDF=true       (per-branch)
FEATURE_MULTI_CURRENCY=false   (global)
FEATURE_NEW_DASHBOARD=beta     (percentage rollout)
```

### Rollout Phases
1. Internal testing (staging)
2. Beta (1 branch, close support)
3. Limited GA (3-5 branches, monitor)
4. General Availability (all branches, flag removed)

### GA Checklist
- [ ] All acceptance criteria verified
- [ ] Performance targets met under load
- [ ] Security review passed
- [ ] Docs complete (user guide, API, changelog)
- [ ] Rollback plan tested
- [ ] Support team briefed
- [ ] No P0/P1 bugs open

## Communication Templates

### Release Notes
```
RELEASE NOTES -- v[X.Y.Z] ([YYYY-MM-DD])
NEW FEATURES: [Feature]: [One-sentence description]. [Link].
IMPROVEMENTS: [Module]: [What changed and why].
BUG FIXES: [Module]: Fixed [description]. (#ticket)
BREAKING CHANGES: [Description + migration steps].
```

## ERP-Specific Patterns

### Module Requirement Checklist
- [ ] branch_id on all tables
- [ ] Document numbering (prefix, branch code, sequence)
- [ ] Approval workflow (thresholds, roles)
- [ ] Accounting integration (auto journal entries)
- [ ] Reports (list, summary, export)
- [ ] Period locking
- [ ] Notification triggers
- [ ] Print/PDF output
- [ ] Audit trail

### Common Workflows
```
Procure-to-Pay:   PR -> Approval -> PO -> Receipt -> Bill -> Payment
Order-to-Cash:    Quotation -> SO -> Delivery -> Invoice -> Payment
Record-to-Report: Journal -> Ledger -> Trial Balance -> Statements -> Period Close
Hire-to-Retire:   Requisition -> Hiring -> Onboarding -> Employment -> Payroll -> Exit
```
