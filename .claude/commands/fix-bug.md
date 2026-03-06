---
name: fix-bug
description: Investigate, fix, and verify a bug with regression testing
argument-hint: "<bug description or ticket reference>"
---

## Fix Bug

Investigate and fix the following bug: $ARGUMENTS

### Agents Involved
- **support-agent** — Triage and reproduce
- **backend-engineer** or **frontend-engineer** — Fix
- **qa-agent** — Verify fix and add regression test
- **database-engineer** — If data-related

### Workflow

#### Phase 1: Investigation
1. **support-agent**: Triage and reproduce
   - Identify affected module and branch
   - Reproduce the issue
   - Classify severity (P0-P3)
   - Gather logs and error context

2. **Relevant engineer**: Root cause analysis
   - Trace the code path
   - Identify the root cause
   - Assess impact (which branches/users affected)
   - Check if this is a regression (worked before)

#### Phase 2: Fix
3. **Relevant engineer**: Implement fix
   - Fix the root cause (not just the symptom)
   - Ensure multi-tenant safety
   - Keep the fix minimal and focused

4. **qa-agent**: Write regression test
   - Test that reproduces the original bug
   - Verify the fix makes the test pass
   - Check for side effects

#### Phase 3: Verify
5. **qa-agent**: Full verification
   - Run full test suite
   - Verify fix across multiple tenants
   - Confirm no regressions

6. **security-agent**: Quick security check (if auth/data related)

### Output
Bug fixed with regression test, verified across tenants, ready for deployment.
