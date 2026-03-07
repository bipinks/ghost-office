---
name: incident-management
description: Use when handling production incidents, conducting post-mortems, or designing incident response processes. Covers severity classification, incident commander role, communication protocols, root cause analysis, and post-mortem templates.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Incident Management

Comprehensive guide for detecting, responding to, and learning from production incidents. This skill covers the full incident lifecycle from detection through post-mortem, with emphasis on blameless culture and continuous improvement.

---

## 1. Severity Classification

| Severity | Definition | Response Time | Escalation | Examples |
|----------|-----------|---------------|------------|----------|
| **SEV1** | Complete outage, data loss risk, or security breach affecting all users | < 5 min | Page on-call + engineering lead + VP immediately | Service fully down, database corruption, active breach |
| **SEV2** | Major feature degraded, significant user impact, or partial outage | < 15 min | Page on-call + team lead | Payment processing failing, login broken for subset of users |
| **SEV3** | Minor feature degraded, limited user impact, workaround available | < 1 hour | Notify on-call via chat | Report generation slow, non-critical API errors for single tenant |
| **SEV4** | Cosmetic issue, no user-facing impact, internal tooling degraded | < 4 hours | Create ticket, fix in next sprint | Dashboard rendering glitch, dev environment instability |

### Escalation Paths
```
SEV1: On-Call Engineer -> Team Lead -> Engineering Manager -> VP Engineering -> CTO
SEV2: On-Call Engineer -> Team Lead -> Engineering Manager
SEV3: On-Call Engineer -> Team Lead
SEV4: On-Call Engineer (self-managed)
```

### Auto-Escalation Rules
- If SEV1 is not acknowledged within 5 minutes, auto-page the next level.
- If SEV2 is not acknowledged within 15 minutes, auto-page team lead.
- If any severity is not mitigated within its target MTTR, escalate one level.

---

## 2. Incident Commander (IC) Role

### Responsibilities
- **Own the incident** from declaration to resolution.
- **Coordinate responders** and assign investigation tracks.
- **Make decisions** on mitigation strategies (rollback, failover, hotfix).
- **Control communication** cadence to stakeholders.
- **Declare resolution** and schedule the post-mortem.

### Decision Authority
The IC has authority to:
- Roll back any deployment without additional approval.
- Page any engineer regardless of team or timezone.
- Escalate severity up or down based on new information.
- Approve emergency changes that bypass normal review.
- Halt non-essential deployments company-wide during SEV1.

### Communication Duties
- Post initial status update within 5 minutes of declaration.
- Provide updates every 15 minutes for SEV1, every 30 minutes for SEV2.
- Coordinate a final "all clear" message when resolved.
- Ensure the post-mortem is scheduled before closing the incident.

---

## 3. Incident Response Process

### Phase 1: Detection
- Automated alert fires (Prometheus, CloudWatch, Datadog, custom monitors).
- User report via support channel.
- Engineer observation during routine work.
- Synthetic monitoring (health checks, uptime probes) detects failure.

### Phase 2: Triage (first 5 minutes)
- Assign severity based on user impact and blast radius.
- Designate an Incident Commander.
- Open a dedicated incident channel (e.g., `#inc-YYYYMMDD-short-desc`).
- Begin initial status page update.

### Phase 3: Investigate (5-30 minutes)
- Check recent deployments and config changes.
- Review error logs and metrics dashboards.
- Identify the affected component(s) and scope of impact.
- Form hypotheses and assign parallel investigation tracks.

### Phase 4: Mitigate (target: 30 minutes for SEV1)
- Apply the fastest available mitigation (rollback, feature flag, scaling).
- Confirm mitigation is effective via metrics.
- Communicate status to stakeholders.

### Phase 5: Resolve
- Identify and apply the permanent fix.
- Verify the fix in staging, then production.
- Monitor for recurrence over the next 1-2 hours.
- Close the incident channel with summary.

### Phase 6: Review (within 48 hours)
- Schedule and conduct a blameless post-mortem.
- Document timeline, root cause, and action items.
- Track action items to completion.

---

## 4. Communication Protocols

### Status Page Update Template
```
[INVESTIGATING] We are investigating reports of <symptom>.
  Impact: <user-facing impact description>
  Started: <timestamp UTC>
  Next update: <time>

[IDENTIFIED] The root cause has been identified as <brief cause>.
  We are working on a fix. Services remain <degraded/unavailable>.
  Next update: <time>

[MONITORING] A fix has been applied. We are monitoring for stability.
  Services are <restored/partially restored>.
  Next update: <time>

[RESOLVED] This incident has been resolved.
  Duration: <X hours Y minutes>
  Root cause: <one-line summary>
  A full post-mortem will be published within 48 hours.
```

### Internal Stakeholder Notification
```
INCIDENT DECLARED: SEV<N> - <title>
Impact: <what users are experiencing>
Started: <timestamp>
Current status: <investigating/identified/mitigating>
IC: <name>
Channel: #inc-<id>
Next update in: <N> minutes
```

### Customer Communication Cadence
| Severity | Initial Update | Follow-up Cadence | Resolution Notice |
|----------|---------------|-------------------|-------------------|
| SEV1 | Within 5 min | Every 15 min | Immediately + post-mortem link |
| SEV2 | Within 15 min | Every 30 min | Within 1 hour of resolution |
| SEV3 | Within 1 hour | Every 2 hours | End of business day |
| SEV4 | No external notice | N/A | N/A |

---

## 5. War Room Procedures

### Roles
| Role | Responsibility |
|------|---------------|
| **Incident Commander (IC)** | Coordinates response, makes decisions, controls communication |
| **Scribe** | Documents timeline, decisions, and actions in real time |
| **Communications Lead** | Manages status page, stakeholder updates, customer messaging |
| **Subject Matter Experts (SMEs)** | Investigate specific systems (database, networking, application) |

### Parallel Investigation Tracks
Assign SMEs to investigate independently and report back every 10 minutes:

- **Track 1: Recent Changes** -- Review deployments, config changes, feature flags toggled in the last 24 hours.
- **Track 2: Infrastructure** -- Check CPU, memory, disk, network, DNS, load balancers.
- **Track 3: Application** -- Review error logs, exception patterns, request traces.
- **Track 4: Dependencies** -- Check third-party service status pages, API health, DNS resolution.

### War Room Rules
- Keep the channel focused: use threads for side discussions.
- State facts, not speculation. Prefix hypotheses with "HYPOTHESIS:".
- The IC makes final decisions. Disagree and commit.
- No blame. Focus on "what happened" not "who caused it."

---

## 6. Triage Checklist

Run through this checklist within the first 5 minutes of an incident.

### System Health
```bash
# Application health check
curl -s https://app.example.com/api/health | jq .

# Container status
docker compose ps

# Resource utilization
docker stats --no-stream

# Disk space
df -h

# Memory
free -h

# CPU load
uptime
```

### Recent Changes
```bash
# Last 5 deployments
git log --oneline -5 --format="%h %ai %s"

# Recent config changes
git log --oneline --since="24 hours ago" -- "*.env*" "*.yml" "*.yaml" "*.json"

# Feature flags changed recently (application-specific)
# Check your feature flag service dashboard
```

### Log Patterns
```bash
# Error spike in last 30 minutes
docker compose logs --since 30m app 2>&1 | grep -ci "error\|exception\|fatal"

# Top error messages
docker compose logs --since 30m app 2>&1 | grep -i "error\|exception" | sort | uniq -c | sort -rn | head -10

# Slow queries (PostgreSQL)
docker compose exec -T db psql -U postgres -c \
  "SELECT pid, now() - query_start AS duration, query
   FROM pg_stat_activity
   WHERE state != 'idle' ORDER BY duration DESC LIMIT 5;"
```

### Metrics Anomalies
- Error rate: Is 5xx rate above baseline?
- Latency: Are p95/p99 latencies elevated?
- Traffic: Unusual traffic spike or drop?
- Saturation: CPU, memory, disk, or connection pool exhaustion?
- Queue depth: Are background job queues backing up?

---

## 7. Common Investigation Patterns

### Database Issues
| Symptom | Investigation | Likely Cause |
|---------|--------------|--------------|
| Connection timeouts | Check `pg_stat_activity` count vs `max_connections` | Connection pool exhaustion |
| Slow queries | Run `EXPLAIN ANALYZE` on suspect queries | Missing index, table bloat |
| Replication lag | Check `pg_stat_replication` | Write-heavy workload, network issues |
| Lock contention | Check `pg_locks` for blocked queries | Long-running transactions, DDL locks |

### Memory Leaks
- Monitor RSS over time: gradual increase without release indicates a leak.
- Check for unclosed connections, unbounded caches, or event listener accumulation.
- Use heap dumps or profiling tools to identify the leaking objects.
- Restart the service as immediate mitigation; deploy a fix for resolution.

### Traffic Spikes
- Check if traffic is legitimate (marketing campaign, viral event) or malicious (DDoS).
- Review request patterns: single IP, single endpoint, or distributed.
- Apply rate limiting or WAF rules for malicious traffic.
- Scale horizontally for legitimate traffic spikes.

### Dependency Failures
- Check third-party status pages (AWS, Stripe, Twilio, etc.).
- Implement circuit breakers to prevent cascade failures.
- Fall back to cached data or degraded functionality where possible.
- Set aggressive timeouts on external calls (5s default, 15s max).

---

## 8. Mitigation Strategies

Apply in order of speed and safety:

| Strategy | Speed | Risk | When to Use |
|----------|-------|------|-------------|
| **Feature flag disable** | Seconds | Very low | Bad feature rollout, isolated to a flag |
| **Rollback deployment** | 2-5 min | Low | Issue correlated with recent deploy |
| **Traffic shifting** | 1-2 min | Low | Canary or blue/green, shift away from bad version |
| **Scale up/out** | 3-10 min | Low | Capacity-related issues, traffic spike |
| **Restart service** | 1-2 min | Medium | Memory leak, hung process, transient state |
| **Failover to secondary** | 5-15 min | Medium | Primary infrastructure failure |
| **Hotfix deploy** | 15-30 min | Higher | When rollback is not possible, fix is small and clear |
| **DNS redirect** | 5-30 min | Medium | Full region or provider failure, redirect to backup |

### Rollback Procedure
```bash
# 1. Identify the last known good commit
git log --oneline -5

# 2. Deploy the previous version
git checkout <previous-commit-hash>
docker compose build --no-cache app
docker compose up -d app

# 3. Rollback migrations if needed
docker compose exec -T app php artisan migrate:rollback --step=N

# 4. Verify health
curl -s http://localhost/api/health | jq .
docker compose logs --tail=20 app
```

---

## 9. Root Cause Analysis (RCA)

### 5 Whys Method
Start with the symptom and ask "Why?" iteratively:

```
Problem: Users received 500 errors on the invoice endpoint.

Why 1: The application threw an out-of-memory exception.
Why 2: The invoice query loaded all line items into memory at once.
Why 3: The query lacked pagination and eager-loaded nested relations.
Why 4: The code review did not catch the unbounded query.
Why 5: There is no automated test or linter rule for unbounded queries.

Root cause: Missing guardrails for query result size.
Action: Add query result size limits and a static analysis rule.
```

### Fishbone Diagram Categories
When the 5 Whys do not converge, explore contributing factors across categories:

- **People**: Training gaps, unclear ownership, handoff failures.
- **Process**: Missing runbooks, inadequate review, no pre-deploy checks.
- **Technology**: Software bugs, infrastructure limits, dependency failures.
- **Environment**: Network issues, cloud provider outage, DNS problems.
- **Monitoring**: Missing alerts, alert fatigue, insufficient dashboards.

### Fault Tree Analysis
For complex incidents with multiple contributing causes, build a fault tree:
1. Place the top-level failure at the root.
2. Decompose into contributing factors using AND/OR gates.
3. Identify the minimal cut sets (smallest combination of failures that cause the incident).
4. Prioritize fixes for the most common or impactful cut sets.

---

## 10. Post-Mortem Template

```markdown
# Post-Mortem: <Incident Title>

**Date**: YYYY-MM-DD
**Severity**: SEV<N>
**Duration**: X hours Y minutes
**Incident Commander**: <name>
**Author**: <name>

## Summary
<2-3 sentence description of what happened and the user impact.>

## Impact
- **Users affected**: <number or percentage>
- **Revenue impact**: <estimated if applicable>
- **Data impact**: <any data loss or corruption>
- **Duration of impact**: <from first user impact to full resolution>

## Timeline (all times UTC)
| Time | Event |
|------|-------|
| HH:MM | Alert fired / Issue reported |
| HH:MM | Incident declared, IC assigned |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied |
| HH:MM | Full resolution confirmed |

## Root Cause
<Detailed technical explanation of what caused the incident.
Include the 5 Whys analysis or fault tree.>

## Detection
- How was the incident detected? (alert, user report, engineer observation)
- How long from start of impact to detection?
- Could detection have been faster? How?

## Response
- What went well in the response?
- What could have been better?

## Action Items
| Priority | Action | Owner | Due Date | Status |
|----------|--------|-------|----------|--------|
| P0 | <fix to prevent recurrence> | <name> | YYYY-MM-DD | Open |
| P1 | <improve detection> | <name> | YYYY-MM-DD | Open |
| P2 | <process improvement> | <name> | YYYY-MM-DD | Open |

## Lessons Learned
- What did we learn that we did not know before?
- What assumptions were proven wrong?
- What should we share with other teams?
```

---

## 11. Blameless Culture

### Principles
- **Focus on systems, not people.** Humans make errors; systems should prevent errors from reaching production.
- **Assume good intent.** Every engineer was making the best decision they could with the information available.
- **Separate the person from the action.** Discuss "the deploy" not "your deploy."
- **Psychological safety is non-negotiable.** People who feel safe report issues faster and share more during post-mortems.
- **Learning over punishment.** The goal is to make the system more resilient, not to assign blame.

### Language Guide
| Avoid | Use Instead |
|-------|-------------|
| "Who broke this?" | "What change triggered this behavior?" |
| "You should have tested this." | "How can we improve our test coverage for this scenario?" |
| "This was a careless mistake." | "What guardrails can we add to prevent this class of error?" |
| "Why didn't you catch this?" | "How can we improve detection for this type of issue?" |

---

## 12. Incident Metrics

### Key Metrics
| Metric | Definition | Target |
|--------|-----------|--------|
| **MTTD** (Mean Time to Detect) | Time from incident start to first alert/detection | < 5 min |
| **MTTA** (Mean Time to Acknowledge) | Time from alert to first human response | < 5 min (SEV1), < 15 min (SEV2) |
| **MTTR** (Mean Time to Resolve) | Time from detection to full resolution | < 1 hr (SEV1), < 4 hr (SEV2) |
| **MTBF** (Mean Time Between Failures) | Time between incidents for a given service | Increasing trend |

### Tracking and Reporting
- Log every incident in a shared tracker (spreadsheet, Jira, PagerDuty).
- Review incident metrics monthly with engineering leadership.
- Track action item completion rate (target: 90% within 30 days).
- Monitor incident frequency trends per service and per severity.

---

## 13. On-Call Best Practices

### Rotation Design
- Minimum 2-person rotation (primary + secondary).
- Rotation cadence: weekly, with handoff on a low-traffic day (e.g., Tuesday).
- Maximum on-call duration: 7 consecutive days.
- Compensate on-call with time off or additional pay.

### Escalation Policy
```
0 min:  Alert fires -> Page primary on-call
5 min:  No acknowledgment -> Page secondary on-call
10 min: No acknowledgment -> Page team lead
15 min: No acknowledgment -> Page engineering manager
```

### Runbook Requirements
Every alert must link to a runbook containing:
- What the alert means and why it matters.
- Steps to diagnose the issue.
- Steps to mitigate or resolve the issue.
- When and how to escalate.

### Alert Fatigue Prevention
- Review alert volume weekly. Target: fewer than 5 actionable alerts per on-call shift.
- Delete or tune alerts that fire but require no action.
- Consolidate related alerts into a single notification.
- Use severity-based routing: only page for critical; notify via chat for warnings.
- Never silence an alert without filing a ticket to address the root cause.

---

## 14. Proactive Incident Prevention

### Chaos Engineering
- Start small: inject latency or errors into non-critical services in staging.
- Gradually increase scope: test failover, kill instances, simulate dependency failures.
- Always have a rollback plan for chaos experiments.
- Document findings and fix weaknesses before they cause real incidents.

### Game Days
- Simulate a realistic incident scenario quarterly.
- Practice the full response process: detection, triage, communication, mitigation.
- Rotate who plays IC so everyone gains experience.
- Debrief after each game day and update runbooks.

### Pre-Mortems
Before launching a new feature or making a major change, ask:
- "What could go wrong?"
- "What would cause this to fail at 10x scale?"
- "What single point of failure exists?"
- "What happens if this external dependency goes down?"
- Document risks and add mitigations before launch.

### Continuous Improvement Cycle
```
Incidents -> Post-Mortems -> Action Items -> System Improvements
    ^                                              |
    |______________________________________________|
                    Fewer Incidents
```

Track the ratio of proactive improvements to reactive fixes. Target: at least 40% of reliability work should be proactive (not triggered by an incident).
