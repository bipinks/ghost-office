---
name: investigate-incident
description: Investigate a production incident with structured triage and root cause analysis
argument-hint: "<incident description>"
---

## Investigate Incident

Investigate the following incident: $ARGUMENTS

### Agents Involved
- **monitoring-agent** — Triage, metrics, and timeline
- **devops-engineer** — Infrastructure investigation
- **backend-engineer** — Code-level investigation
- **database-engineer** — Data/query investigation
- **master-orchestrator** — Coordinate response

### Workflow

#### Phase 1: Triage (First 5 minutes)
1. **monitoring-agent**: Initial assessment
   - Classify severity: SEV1 (outage) / SEV2 (degraded) / SEV3 (minor)
   - Identify affected services and users
   - Determine start time of incident
   - Check for correlated alerts

2. **devops-engineer**: Recent changes check
   - Any deployments in the last 24 hours?
   - Infrastructure changes?
   - Configuration changes?
   - Third-party service issues?

#### Phase 2: Investigation (Parallel)
3. **monitoring-agent**: Metrics deep dive
   - Error logs around incident start time
   - Latency and traffic patterns
   - Resource utilization spikes
   - Upstream/downstream service health

4. **backend-engineer**: Code investigation
   - Trace error stack traces
   - Check for recent code changes in affected paths
   - Review error handling in affected services

5. **database-engineer**: Data investigation
   - Check for query timeouts or deadlocks
   - Review connection pool status
   - Check for data corruption or inconsistency

#### Phase 3: Mitigation
6. **devops-engineer**: Apply mitigation
   - Rollback if deployment-related
   - Scale up if capacity-related
   - Restart services if crash-related
   - Failover if hardware-related

#### Phase 4: Resolution
7. **monitoring-agent**: Post-incident
   - Confirm service recovery
   - Write incident timeline
   - Root cause analysis (5 Whys)
   - Generate post-mortem document
   - Define action items to prevent recurrence

### Output
Incident resolved (or mitigated) with timeline, root cause, and post-mortem with action items.
