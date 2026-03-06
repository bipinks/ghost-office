# Bug Fix Workflow

## Overview
Structured workflow for investigating, fixing, and verifying bugs with regression testing.

## Trigger
- User reports a bug
- Monitoring detects an error spike
- QA finds an issue during testing
- Command: `/fix-bug`

## Workflow Diagram
```
[Report]──→[Triage]──→[Investigate]──→[Fix]──→[Test]──→[Deploy]
    │          │            │            │        │         │
  User     Support      Engineer     Engineer    QA     DevOps
           Agent                                Agent   Engineer
```

## Phases

### Phase 1: Triage (Sequential)
**Agent**: support-agent
**Actions**:
1. Parse bug report (module, branch, user role, steps to reproduce)
2. Classify severity:
   - **P0**: System down, data loss → Immediate response
   - **P1**: Major feature broken → 4 hour SLA
   - **P2**: Minor feature issue → 24 hour SLA
   - **P3**: Cosmetic/enhancement → Backlog
3. Reproduce the bug
4. Gather logs and error context
5. Identify affected branches/tenants
**Output**: Triage report with severity, reproduction steps, and initial findings
**Escalation**: P0/P1 → master-orchestrator immediately

### Phase 2: Investigation (Sequential)
**Agent**: backend-engineer or frontend-engineer (based on bug location)
**Support**: database-engineer (if data-related)
**Actions**:
1. Trace the code path from reproduction steps
2. Identify root cause
3. Check if this is a regression (find introducing commit)
4. Assess blast radius (which other features might be affected)
5. Determine fix approach
**Output**: Root cause analysis with proposed fix

### Phase 3: Fix (Sequential)
**Agent**: backend-engineer or frontend-engineer
**Actions**:
1. Implement the fix (minimal, focused change)
2. Ensure multi-tenant safety
3. Add inline comments explaining the fix if non-obvious
**Output**: Code fix committed

### Phase 4: Testing (Sequential)
**Agent**: qa-agent
**Actions**:
1. Write regression test that reproduces the original bug
2. Verify the fix makes the test pass
3. Run full test suite to check for side effects
4. Test across multiple tenants/branches
5. If auth/data related → security-agent quick review
**Output**: All tests passing, regression test added
**Gate**: Tests must pass before deployment

### Phase 5: Deployment (Sequential)
**Agent**: devops-engineer
**Actions**:
1. Deploy fix to staging
2. Verify fix on staging
3. For P0/P1: Deploy to production with user approval
4. For P2/P3: Include in next regular release
5. Monitor post-deploy
**Output**: Fix deployed and verified

## Error Handling

| Error | Recovery |
|-------|----------|
| Cannot reproduce | Ask user for more details, check specific branch |
| Fix causes new test failures | Revise approach, ensure backward compatibility |
| Fix works on staging but not production | Check data differences, deploy hotfix |

## P0 Fast Track
For P0 incidents, skip to Phase 3 with a hotfix:
1. Apply minimal fix to stop the bleeding
2. Deploy immediately with user approval
3. Then go back and do proper investigation, testing, and root cause analysis
