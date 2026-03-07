---
name: product-management
description: Use when defining features, writing user stories, prioritizing work, or creating acceptance criteria. Covers requirements gathering, user story mapping, prioritization frameworks, sprint planning, and stakeholder communication.
user-invocable: false
allowed-tools: ["Read", "Write", "Grep", "Glob"]
---

# Product Management — Requirements & Feature Delivery

## 1. Requirements Gathering

### Stakeholder Interview Template

Before writing any requirement, gather context with structured interviews:

```
STAKEHOLDER INTERVIEW
=====================
Interviewer:        [PM name]
Stakeholder:        [Name, role, department]
Date:               [YYYY-MM-DD]

1. What problem are you trying to solve?
2. Who experiences this problem? How often?
3. What is the current workaround?
4. What does success look like? How would you measure it?
5. Are there compliance or regulatory requirements?
6. Which branches or departments are affected?
7. What is the urgency? Is there a deadline?
8. Are there dependencies on other systems or teams?
```

### Problem Statement Format

```
PROBLEM:    [Specific, observable problem]
WHO:        [Affected user roles and branches]
IMPACT:     [Quantified business impact — time lost, revenue at risk, error rate]
FREQUENCY:  [How often it occurs — daily, per transaction, monthly]
EVIDENCE:   [Support tickets, user feedback, analytics data]
```

### Jobs-to-Be-Done Framework

```
When [situation/trigger],
I want to [motivation/action],
So I can [expected outcome/benefit].

Constraints:
- Must work within [time/budget/regulatory] limits
- Must integrate with [existing system/workflow]
- Must not break [existing functionality]
```

## 2. User Story Format

### Standard Template

```
As a [role] in [branch/department],
I want to [specific action or capability],
So that [measurable business value or outcome].
```

### Rules for Good User Stories (INVEST)

- **I**ndependent: No hidden coupling to other stories
- **N**egotiable: Details can be discussed, not locked in stone
- **V**aluable: Delivers value to a user or the business
- **E**stimable: Team can estimate the effort required
- **S**mall: Completable within a single sprint
- **T**estable: Has clear pass/fail acceptance criteria

### Story Sizes

| Size | Points | Description | Example |
|------|--------|-------------|---------|
| XS | 1 | Config change, label update | Change invoice prefix format |
| S | 2 | Single field or simple logic | Add discount percentage to invoice line |
| M | 3-5 | New screen or workflow step | Create purchase request approval screen |
| L | 8 | Multi-screen feature | Customer aging report with drill-down |
| XL | 13+ | Split required — too large | Full procurement module |

## 3. Acceptance Criteria

### Given/When/Then Format

```
Acceptance Criteria:
- [ ] Given [precondition/context],
      When [action performed by user],
      Then [observable and testable result].
```

### Standard Criteria for Every Feature

Every data-modifying feature must include these baseline criteria:

```
Multi-Tenant Isolation:
- [ ] Given a user in Branch A, when they query data, then only Branch A records are returned
- [ ] Given a user in Branch A, when they attempt to access a Branch B record by ID, then a 403 is returned

Audit Trail:
- [ ] Given any create/update/delete, when the operation completes, then an audit log entry records user, timestamp, table, record ID, old values, and new values

Permissions:
- [ ] Given a user without the required permission, when they attempt the action, then a 403 is returned
- [ ] Given a user with read-only permission, when they attempt to write, then a 403 is returned

Validation:
- [ ] Given invalid input, when the form is submitted, then field-level error messages are displayed
- [ ] Given missing required fields, when the form is submitted, then the submission is blocked
```

### Non-Functional Acceptance Criteria

```
Performance:
- [ ] List endpoint responds in < 300ms at p95 with 1000+ records
- [ ] Form submission completes in < 500ms at p95

Security:
- [ ] All inputs are validated and sanitized server-side
- [ ] No sensitive data exposed in API responses to unauthorized roles

Accessibility:
- [ ] All form fields have labels; keyboard navigation works end-to-end
```

## 4. User Story Mapping

### Hierarchy

```
ACTIVITY (Epic)          — e.g., "Manage Sales Orders"
  |
  +-- TASK (Feature)     — e.g., "Create Sales Order"
  |     |
  |     +-- STORY        — e.g., "Add line items to sales order"
  |     +-- STORY        — e.g., "Apply discount to sales order"
  |     +-- STORY        — e.g., "Submit sales order for approval"
  |
  +-- TASK (Feature)     — e.g., "Track Sales Order Status"
        |
        +-- STORY        — e.g., "View sales order timeline"
        +-- STORY        — e.g., "Receive notification on status change"
```

### MVP Slicing

Slice horizontally across the map to define releases:

```
Release 1 (MVP):     Create SO  |  View SO list  |  Basic invoice
Release 2 (Core):    Edit SO    |  SO approval   |  Partial payment
Release 3 (Advanced): SO report  |  Bulk actions  |  Credit notes
```

**MVP criteria**: The minimum set of stories that lets a user complete the core workflow end-to-end, even if details are manual or limited.

## 5. Prioritization Frameworks

### RICE Scoring (Primary)

```
Score = (Reach x Impact x Confidence) / Effort

Reach:       Number of users or branches affected per quarter
Impact:      0.25 (minimal), 0.5 (low), 1 (medium), 2 (high), 3 (massive)
Confidence:  100% (high), 80% (medium), 50% (low)
Effort:      Person-weeks of engineering work
```

| Feature | Reach | Impact | Confidence | Effort | RICE Score |
|---------|-------|--------|------------|--------|------------|
| Invoice PDF export | 200 | 2 | 90% | 2 | 180 |
| Multi-currency | 50 | 3 | 70% | 6 | 17.5 |
| Dashboard widgets | 200 | 1 | 80% | 4 | 40 |

### MoSCoW (Release Scoping)

- **Must have**: System fails without it. Regulatory requirement. Core workflow blocker.
- **Should have**: Important but has a workaround. Significant user value.
- **Could have**: Nice to have. Improves experience. Low risk to defer.
- **Won't have (this time)**: Explicitly out of scope for this release.

### ICE Scoring (Quick Triage)

```
Score = Impact x Confidence x Ease
Scale: 1-10 for each factor
```

### Kano Model (User Satisfaction)

| Category | Description | Example |
|----------|-------------|---------|
| Basic | Expected, absence causes dissatisfaction | Login, data saving, print |
| Performance | More is better, linear satisfaction | Speed, report filters, search |
| Delighter | Unexpected, creates strong satisfaction | Auto-suggestions, smart defaults |

## 6. Feature Specification Template

```markdown
# Feature: [Feature Name]

## Problem
[What problem does this solve? Who is affected? What is the business cost of not solving it?]

## Solution
[High-level description of the proposed solution in 2-3 paragraphs.]

## Scope
- Create/update/delete [entity]
- [Specific workflow or screen]
- [Integration with module X]

## Out of Scope
- [Explicitly excluded functionality]
- [Deferred to future release]

## User Stories
[List user stories with acceptance criteria per section 2 and 3 above.]

## Data Model
| Entity | Key Fields | Relationships |
|--------|------------|---------------|
| [Name] | [Fields]   | belongs_to, has_many |

## API Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/v1/resource | List with pagination | Bearer |
| POST   | /api/v1/resource | Create new | Bearer |

## UI/UX
- Screen 1: [Description, key interactions]
- Screen 2: [Description, key interactions]
- User flow: [Step-by-step path through the feature]

## Permissions
| Role | Create | Read | Update | Delete | Approve |
|------|--------|------|--------|--------|---------|
| Admin | Y | Y | Y | Y | Y |
| Manager | Y | Y | Y | N | Y |
| User | Y | Own | Own | N | N |

## Edge Cases
- [What if the user has no branch assigned?]
- [What if the referenced record is soft-deleted?]
- [What if concurrent edits occur?]
- [What if the amount exceeds approval threshold?]

## Success Metrics
- [Metric 1: e.g., 90% of invoices created in < 2 minutes]
- [Metric 2: e.g., Support tickets for this workflow drop by 50%]

## Dependencies
- [Module or feature that must exist first]
- [External service or API]

## Testing Plan
- Unit tests for service layer logic
- Integration tests for API endpoints
- E2E test for the primary user flow
- Multi-tenant isolation test
```

## 7. Sprint Planning

### Estimation Guidelines

Use modified Fibonacci: 1, 2, 3, 5, 8, 13. Stories over 8 should be split.

```
ESTIMATION CHECKLIST
====================
- [ ] Backend service logic complexity
- [ ] Database migration or schema change
- [ ] API endpoint(s) to build or modify
- [ ] Frontend screen(s) or component(s)
- [ ] Validation rules and error handling
- [ ] Permission/policy definitions
- [ ] Audit trail integration
- [ ] Multi-branch data scoping
- [ ] Unit and integration tests
- [ ] Documentation updates
```

### Velocity Tracking

```
Sprint Velocity = Sum of completed story points

Planned capacity = Average velocity of last 3 sprints x 0.8 (buffer)
```

### Sprint Commitment Template

```
Sprint [N] — [Start Date] to [End Date]
Capacity: [X] story points
Committed:
  - [Story 1] (3 pts) — [Assigned agent]
  - [Story 2] (5 pts) — [Assigned agent]
  - [Story 3] (2 pts) — [Assigned agent]
Total: [Y] points
Buffer: [Z] points remaining for unplanned work
```

## 8. Wireframing and Mockups

### Fidelity Progression

```
Phase 1 — Text Wireframe (requirements phase):
  +----------------------------------+
  | Invoice List                     |
  | [Search] [Filter: Status] [+New] |
  | # | Date | Customer | Amount | St|
  | 1 | ...  | ...      | ...    | ..|
  | Pagination: < 1 2 3 >           |
  +----------------------------------+

Phase 2 — Component Spec (design phase):
  - DataTable component with sortable columns
  - FilterBar with status dropdown, date range picker
  - ActionButton for create, linked to InvoiceForm

Phase 3 — Interactive Prototype (validation phase):
  - Clickable prototype for stakeholder review
  - User flow walkthrough with real sample data
```

### User Flow Diagram (Text Format)

```
[User opens Invoice List]
    |
    +---> [Clicks "+ New Invoice"]
    |         |
    |         +---> [Invoice Form: select customer, add line items]
    |         |         |
    |         |         +---> [Clicks "Save as Draft"] ---> [Returns to list, status: Draft]
    |         |         +---> [Clicks "Submit"]        ---> [Triggers approval flow]
    |
    +---> [Clicks existing invoice row]
              |
              +---> [Invoice Detail: view, edit, print, void]
```

## 9. Technical Requirements

### Non-Functional Requirements Checklist

```
PERFORMANCE
- API response time targets (see performance-guidelines.md)
- Maximum concurrent users per branch
- Report generation time limits
- File upload size limits

SECURITY
- Authentication method (Sanctum Bearer token)
- Authorization model (RBAC via Policies)
- Data encryption requirements (AES-256 at rest, TLS in transit)
- Input validation and sanitization

SCALABILITY
- Expected data volume per branch per year
- Peak usage patterns (month-end closing, payroll runs)
- Horizontal scaling requirements

RELIABILITY
- Uptime target (99.9%)
- Data backup and recovery requirements
- Graceful degradation for external service failures

COMPLIANCE
- Regulatory requirements (tax, labor law, financial reporting)
- Data retention policies
- Audit trail completeness
```

## 10. Release Planning

### Feature Flag Strategy

```
Feature flags for phased rollout:
- FEATURE_INVOICE_PDF=true       (per-branch toggle)
- FEATURE_MULTI_CURRENCY=false   (global toggle)
- FEATURE_NEW_DASHBOARD=beta     (percentage rollout)
```

### Rollout Phases

```
Phase 1 — Internal Testing:   Dev team uses feature in staging
Phase 2 — Beta (1 branch):    Single branch with close support
Phase 3 — Limited GA:         3-5 branches, monitor for issues
Phase 4 — General Availability: All branches, feature flag removed
```

### GA Criteria Checklist

```
- [ ] All acceptance criteria verified by QA
- [ ] Performance targets met under load
- [ ] Security review passed
- [ ] Documentation complete (user guide, API docs, changelog)
- [ ] Rollback plan documented and tested
- [ ] Support team briefed on new feature
- [ ] No P0 or P1 bugs open
- [ ] Monitoring and alerting configured
```

## 11. Feedback Loops

### Quantitative Signals

```
- Feature adoption rate (% of users using the feature within 30 days)
- Task completion rate (% of users who finish the workflow)
- Error rate (validation failures, API errors per feature)
- Time-on-task (how long the workflow takes)
- Support ticket volume related to the feature
```

### Qualitative Signals

```
USER INTERVIEW TEMPLATE (Post-Launch)
=====================================
1. How often do you use [feature]?
2. What do you like most about it?
3. What is frustrating or confusing?
4. What is missing that you expected?
5. On a scale of 1-10, how likely are you to recommend it?
```

### Feedback-to-Action Mapping

| Signal | Threshold | Action |
|--------|-----------|--------|
| Adoption < 30% after 30 days | Low | Investigate usability; schedule interviews |
| Error rate > 5% | Medium | File bug; review validation rules |
| NPS < 6 | High | Prioritize improvement sprint |
| Support tickets > 10/week | Medium | Identify top issues; create fixes |

## 12. Communication Templates

### PRD Header

```
PRODUCT REQUIREMENTS DOCUMENT
==============================
Title:          [Feature Name]
Author:         [PM Name]
Status:         [Draft | In Review | Approved | In Development | Shipped]
Created:        [YYYY-MM-DD]
Last Updated:   [YYYY-MM-DD]
Target Release: [Version or Sprint]
Stakeholders:   [List of stakeholders]
Reviewers:      [List of reviewers]
```

### Release Notes Template

```
RELEASE NOTES — v[X.Y.Z] ([YYYY-MM-DD])
=========================================

NEW FEATURES
- [Feature]: [One-sentence description]. [Link to docs].

IMPROVEMENTS
- [Module]: [What changed and why].

BUG FIXES
- [Module]: Fixed [description of bug]. (#ticket)

BREAKING CHANGES
- [Description of breaking change and migration steps].

KNOWN ISSUES
- [Description and workaround].
```

### Stakeholder Update Template

```
WEEKLY UPDATE — [Date]
======================
Completed This Week:
- [Story/feature completed and status]

In Progress:
- [Story/feature in development, % complete, blockers]

Planned Next Week:
- [Upcoming stories and assignments]

Risks and Blockers:
- [Risk description, impact, mitigation plan]

Metrics:
- Velocity: [X] points completed / [Y] planned
- Bug count: [N] open ([M] critical)
```

## 13. ERP-Specific Patterns

### Module Requirement Checklist

Every ERP module spec must address:

```
- [ ] Multi-branch data isolation (branch_id on all tables)
- [ ] Document numbering scheme (prefix, branch code, sequence)
- [ ] Approval workflow (thresholds, roles, rejection handling)
- [ ] Accounting integration (journal entries generated automatically)
- [ ] Reporting requirements (list report, summary report, export formats)
- [ ] Period locking (respect financial year locks)
- [ ] Inter-branch operations (transfers, consolidated views)
- [ ] Notification triggers (approval needed, overdue, low stock)
- [ ] Print/PDF output (company letterhead, configurable template)
- [ ] Audit trail (all creates, updates, deletes logged with before/after)
```

### Multi-Branch Considerations

```
BRANCH ISOLATION RULES
======================
1. Every database table with business data MUST have branch_id
2. Global scopes auto-filter queries to the user's current branch
3. Admin users can switch branches; the scope follows the active branch
4. Cross-branch reports require explicit company-level permission
5. Inter-branch transfers create records in BOTH branches with a shared reference
6. Document number sequences are independent per branch
```

### Common ERP Workflows

```
PROCURE-TO-PAY
  Purchase Request -> Approval -> Purchase Order -> Goods Receipt -> Vendor Bill -> Payment

ORDER-TO-CASH
  Quotation -> Sales Order -> Delivery Note -> Invoice -> Payment -> Receipt

RECORD-TO-REPORT
  Journal Entry -> Ledger Posting -> Trial Balance -> Financial Statements -> Period Close

HIRE-TO-RETIRE
  Job Requisition -> Hiring -> Onboarding -> Active Employment -> Leave/Attendance -> Payroll -> Exit
```

### Compliance Requirements by Module

| Module | Compliance Area | Requirement |
|--------|----------------|-------------|
| Accounting | Financial regulations | Double-entry enforced; period locking; audit trail |
| HR/Payroll | Labor law | Statutory deductions; leave entitlements; pay slips |
| Inventory | Tax/customs | Stock valuation method consistency; batch traceability |
| Sales | Tax compliance | Tax calculation per jurisdiction; tax reports |
| Procurement | Internal controls | Segregation of duties; approval thresholds; 3-way match |
