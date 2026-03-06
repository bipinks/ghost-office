# Production Incident Workflow

## Overview
Structured incident response workflow from detection to post-mortem.

## Trigger
- Alert fires from monitoring
- User reports production issue
- Error rate spike detected
- Command: `/investigate-incident`

## Severity Levels

| Level | Description | Response Time | Example |
|-------|-------------|---------------|---------|
| SEV1 | Complete outage, data at risk | Immediate | All API endpoints returning 500 |
| SEV2 | Degraded service, workaround exists | 15 minutes | Slow responses, intermittent errors |
| SEV3 | Minor issue, limited impact | 1 hour | Single tenant affected, cosmetic |

## Workflow Diagram
```
[Detect]──→[Triage]──→[Investigate]──→[Mitigate]──→[Resolve]──→[Post-Mortem]
    │          │          ┌──┴──┐          │           │             │
  Alert    Monitoring   DevOps  Backend   DevOps     All          Monitoring
           Agent        Eng     Eng       Engineer   Agents        Agent
```

## Phases

### Phase 1: Detection & Triage (First 5 minutes)
**Agent**: monitoring-agent
**Actions**:
1. Identify affected services
2. Classify severity (SEV1/SEV2/SEV3)
3. Determine user impact (branches, users, features affected)
4. Check for recent deployments or changes
5. Establish incident timeline (when did it start?)
**Output**: Incident classification and initial assessment

### Phase 2: Investigation (Parallel — next 10 minutes)
**Agents**: Run in parallel based on incident type

#### Track A: Infrastructure (devops-engineer)
- Check server/container health
- Review resource utilization (CPU, memory, disk)
- Check network connectivity
- Review recent infrastructure changes
- Check external service dependencies

#### Track B: Application (backend-engineer)
- Review application error logs
- Trace failing requests
- Check for recent code deployments
- Review database connection status
- Check queue/job processing

#### Track C: Data (database-engineer)
- Check for query timeouts or deadlocks
- Review connection pool exhaustion
- Check for data corruption
- Review replication lag
- Check disk space on database servers

**Output**: Root cause identified or narrowed down

### Phase 3: Mitigation (Immediate)
**Agent**: devops-engineer
**Actions** (based on root cause):

| Root Cause | Mitigation |
|------------|------------|
| Bad deployment | Rollback to previous version |
| Resource exhaustion | Scale up/out immediately |
| Database overload | Kill long-running queries, increase connections |
| External service down | Enable fallback/circuit breaker |
| Traffic spike | Enable rate limiting, scale out |
| Data corruption | Switch to read replica, halt writes |

**Output**: Service restored or impact reduced

### Phase 4: Resolution
**Agent**: Relevant engineer based on root cause
**Actions**:
1. Implement permanent fix
2. Write regression test
3. Deploy fix through staging → production
4. Verify fix in production
5. Confirm metrics return to baseline
**Output**: Root cause fixed and deployed

### Phase 5: Post-Mortem (Within 48 hours)
**Agent**: monitoring-agent
**Actions**:
1. Write incident timeline
2. Perform root cause analysis (5 Whys method)
3. Document:
   - What happened
   - What we did
   - What worked well
   - What didn't work well
   - What we'll change
4. Create action items with owners and deadlines
5. Share with team (blameless)
**Output**: Post-mortem document with action items

## Communication Template

### During Incident
```
[SEV{X}] {Service} - {Impact Description}
Status: Investigating | Mitigating | Resolved
Impact: {who is affected, how}
Start: {timestamp}
Last update: {timestamp}
Next update in: {X} minutes
```

### Resolution
```
[RESOLVED] {Service} - {What happened}
Duration: {start} to {end} ({total time})
Impact: {branches/users affected}
Root cause: {brief description}
Post-mortem: {link or scheduled date}
```

## Error Handling

- If mitigation fails → escalate to next severity level
- If root cause unclear after 30 min → engage all investigation tracks
- If data loss suspected → immediately notify user, engage database-engineer
