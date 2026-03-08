---
name: ux-research
description: Use when conducting user research, usability analysis, or validating design decisions. Covers user personas, journey mapping, usability heuristics, A/B testing, feedback analysis, and research methodologies.
user-invocable: false
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob"]
---

# UX Research -- Validating Design Decisions with Evidence

## 1. User Persona Template

```markdown
## Persona: [Name]
**Role**: [Job title]  |  **Experience**: [Novice/Intermediate/Expert]  |  **Tech Comfort**: [Low/Med/High]
**Uses system**: [Daily/Weekly/Monthly]  |  **Device**: [Desktop/Tablet/Mobile]

### Goals
1. [Primary goal]  2. [Secondary goal]  3. [Tertiary goal]

### Pain Points
1. [Frustration]  2. [Inefficiency]  3. [Missing capability]

### Scenarios
- **Happy path**: [Typical successful workflow]
- **Edge case**: [Unusual but important scenario]
- **Failure recovery**: [What happens when things go wrong]
```

**Example**: Sarah (Accounts Manager) -- Processes 30-50 invoices/day, prefers keyboard shortcuts, pain points: multi-screen switching, slow reports, poor search. Ahmed (Warehouse Supervisor) -- Uses tablet, needs large touch targets, simple forms, high contrast.

## 2. Journey Mapping

```markdown
## Journey Map: [Task Name]
**Persona**: [Name]  |  **Goal**: [Outcome]  |  **Duration**: [Time]  |  **Trigger**: [Event]

| Stage | Action | Thinking | Feeling | Pain Points | Opportunities |
|-------|--------|----------|---------|-------------|---------------|
| 1. Navigate | | | | | |
| 2. Fill form | | | | | |
| 3. Review | | | | | |
| 4. Complete | | | | | |
```

Map the emotional journey (1-5 scale) alongside actions. Identify the lowest-satisfaction moments as design priorities.

## 3. Nielsen's 10 Heuristics (Enterprise UI)

| # | Heuristic | Good Example | Bad Example |
|---|-----------|-------------|-------------|
| 1 | **Visibility of status** | Loading spinner: "Generating report..." | Form submits with no indicator |
| 2 | **Match real world** | "Invoice", "Due Date" | "Sales Document Type A", database column names |
| 3 | **User control** | Undo after delete, cancel with unsaved warning | Permanent deletion without confirmation |
| 4 | **Consistency** | Same icon/position for edit across modules | Save button left in one form, right in another |
| 5 | **Error prevention** | Disable submit until valid, date picker constraints | Free-text date field, no validation until submit |
| 6 | **Recognition > recall** | Recent customers in selector, breadcrumbs | Must remember customer codes |
| 7 | **Flexibility** | Keyboard shortcuts, bulk actions, saved filters | Every action requires multiple menu clicks |
| 8 | **Minimalist design** | Progressive disclosure, summary cards | 20+ KPIs visible at once, 30-field single-page form |
| 9 | **Error recovery** | "Invoice date cannot be in the future. Select today or earlier." | "Error 422" |
| 10 | **Help** | Tooltip: "Days from invoice date until payment is due" | No help text anywhere |

### Evaluation Template
Rate each heuristic 0-4 (0=no problem, 4=catastrophe). Score >= 3 must fix before release.

## 4. A/B Testing

### Hypothesis Template
```
IF we [change/add/remove] [specific element],
THEN [metric] will [increase/decrease] by [amount],
BECAUSE [reasoning based on research/data].
```

### Test Spec
- **Primary metric**: Task completion time / conversion rate / error rate
- **Guardrail metrics**: Must not decrease (e.g., completion rate)
- **Sample size**: Calculate via power analysis. Min detectable effect: 10%
- **Confidence level**: 95% (p < 0.05)
- **Duration**: Minimum 7 days to account for day-of-week effects
- **Segmentation**: By role, branch size, experience level

### Result Template
| Metric | Control | Treatment | Difference | p-value | Significant? |
|--------|---------|-----------|------------|---------|-------------|
| [metric] | [val] | [val] | [+/-X%] | [val] | Yes/No |

**Decision**: Ship / Iterate / Abandon -- [Reasoning]

## 5. Feedback Analysis

### Classification
| Category | Subcategory | Example |
|----------|------------|---------|
| Bug | Functionality/Display | "Save button broken on Firefox" |
| Feature Request | New/Enhancement | "Export invoices to QuickBooks" |
| Usability | Navigation/Clarity | "Cannot find tax settings" |
| Performance | Speed/Responsiveness | "Report takes over a minute" |

### Prioritization Matrix
```
              High Frequency
    Quick Wins (P2) | Must Do (P0/P1)
  Low Impact -------|------- High Impact
    Deprioritize (P3)| Strategic (P2)
              Low Frequency
```

## 6. Usability Testing Script

```markdown
### Introduction (2 min)
"We are testing the [feature], not you. Think aloud as you work."

### Tasks (15-20 min)
**Task 1: [Name]**
Scenario: "[Realistic description]"
Success criteria: [What constitutes completion]
Observe: Found starting point? Understood labels? Errors? Time: ___

### Post-Task (5 min)
1. Ease rating 1-7 (Single Ease Question)
2. Most confusing part?
3. What would you change?

### SUS Questionnaire (3 min)
10 alternating positive/negative statements rated 1-5.
Score: (odd items: score-1, even items: 5-score) * 2.5 = 0-100.
80-100=Excellent, 68-79=Good, 50-67=Needs improvement, <50=Unacceptable.
```

## 7. Task Success Metrics

| Metric | Definition | Target |
|--------|-----------|--------|
| Task completion rate | % who complete | >90% |
| Time on task | Avg completion time | Varies |
| Error rate | % with at least one error | <10% |
| Learnability | Improvement attempt 1 to 3 | >30% faster |
| SEQ (post-task) | Ease rating 1-7 | >5.5 |

## 8. Information Architecture

### Card Sorting
Use open sort to discover natural groupings. Report similarity matrix (e.g., Invoice+Credit Note+Payment grouped by 85% of participants).

### Tree Testing
Validate navigation structure. Measure success rate, directness, and time per task. If success <70%, restructure that path.

## 9. Analytics-Driven UX

| Metric | Insight |
|--------|---------|
| Bounce rate per page | Pages that confuse users |
| Funnel drop-off | Where users abandon workflows |
| Search queries | What users cannot find via navigation |
| Session recordings | Actual behavior patterns |
| Click heatmaps | Where users click and miss |

### Funnel Template
| Step | Users | Drop-off % |
|------|-------|-----------|
| 1. Open form | 1,000 | -- |
| 2. Fill fields | 920 | 8% |
| 3. Submit | 780 | 15% |
**Biggest drop-off**: Investigate which fields cause abandonment.

### Monthly UX Scorecard
| Metric | Target |
|--------|--------|
| Task completion rate | >90% |
| Avg SUS score | >75 |
| Support tickets (UX) | <20 |
| Feature adoption (new) | >40% |
| Form error rate | <5% |
