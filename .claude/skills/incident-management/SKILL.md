---
name: incident-management
description: Use when handling production incidents, conducting post-mortems, or designing incident response processes. Covers severity classification, incident commander role, communication protocols, root cause analysis, and post-mortem templates.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Incident Management

## Severity Classification

| Sev | Definition | Response | Examples |
|-----|-----------|----------|----------|
| SEV1 | Complete outage, data loss, security breach | < 5 min, page IC + lead + VP | Service down, DB corruption, active breach |
| SEV2 | Major feature degraded, partial outage | < 15 min, page IC + lead | Payment failing, login broken for subset |
| SEV3 | Minor degradation, workaround exists | < 1 hr, notify via chat | Slow reports, non-critical errors for one tenant |
| SEV4 | Cosmetic, no user impact | < 4 hr, ticket | Dashboard glitch, dev env instability |

Auto-escalate if not acknowledged within response time.

## Incident Commander (IC)

**Authority**: Roll back any deploy, page any engineer, escalate/downgrade severity, approve emergency changes, halt non-essential deploys during SEV1.

**Duties**: Own incident start-to-finish, coordinate responders, control communication cadence (SEV1: every 15min, SEV2: every 30min), declare resolution, schedule post-mortem.

## Response Process

1. **Detect**: Automated alert, user report, or engineer observation.
2. **Triage** (0-5min): Assign severity, designate IC, open `#inc-YYYYMMDD-desc` channel, update status page.
3. **Investigate** (5-30min): Check recent deploys/config changes, review logs/metrics, identify affected components, assign parallel tracks.
4. **Mitigate** (target 30min SEV1): Apply fastest fix, confirm via metrics, communicate status.
5. **Resolve**: Apply permanent fix, verify in staging then production, monitor 1-2hr for recurrence.
6. **Review** (within 48hr): Blameless post-mortem, document timeline/RCA/action items.

## Triage Checklist

```bash
curl -s https://app.example.com/api/health | jq .     # app health
docker compose ps && docker stats --no-stream           # container status
df -h && free -h                                        # disk/memory
git log --oneline -5 --format="%h %ai %s"              # recent deploys
docker compose logs --since 30m app 2>&1 | grep -ci "error\|exception\|fatal"  # error count
docker compose exec -T db psql -U postgres -c "SELECT pid, now()-query_start AS duration, query FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC LIMIT 5;"
```

Check: error rate vs baseline, p95/p99 latency, traffic anomalies, CPU/memory/disk saturation, queue depth.

## Mitigation Strategies (Speed Order)

| Strategy | Speed | Risk | When |
|----------|-------|------|------|
| Feature flag disable | Seconds | Very low | Bad feature rollout |
| Rollback deployment | 2-5 min | Low | Correlated with recent deploy |
| Traffic shifting | 1-2 min | Low | Canary/blue-green |
| Scale up/out | 3-10 min | Low | Capacity issue |
| Restart service | 1-2 min | Medium | Memory leak, hung process |
| Failover to secondary | 5-15 min | Medium | Primary infra failure |
| Hotfix deploy | 15-30 min | Higher | Rollback not possible |

## Communication Templates

```
[INVESTIGATING] Investigating <symptom>. Impact: <user-facing>. Started: <UTC>. Next update: <time>.
[IDENTIFIED] Root cause: <brief>. Working on fix. Next update: <time>.
[MONITORING] Fix applied. Monitoring stability. Next update: <time>.
[RESOLVED] Resolved. Duration: <X>h <Y>m. Root cause: <summary>. Post-mortem within 48hr.
```

## Root Cause Analysis

### 5 Whys
```
Problem: Users got 500 errors on invoice endpoint.
Why 1: Out-of-memory exception.
Why 2: Query loaded all line items into memory.
Why 3: No pagination, eager-loaded nested relations.
Why 4: Code review missed unbounded query.
Why 5: No static analysis rule for query size.
Root cause: Missing guardrails for query result size.
```

When 5 Whys diverge, use **Fishbone** categories: People, Process, Technology, Environment, Monitoring.

## Post-Mortem Template

```markdown
# Post-Mortem: <Title>
**Date/Severity/Duration/IC/Author**

## Summary: 2-3 sentences on what happened and user impact.
## Impact: Users affected, revenue impact, data impact, duration.
## Timeline (UTC): Alert -> Declared -> Identified -> Mitigated -> Resolved.
## Root Cause: Technical explanation + 5 Whys.
## Detection: How detected, time to detection, improvement opportunities.
## Response: What went well, what could improve.
## Action Items
| Priority | Action | Owner | Due | Status |
|----------|--------|-------|-----|--------|
| P0 | Prevent recurrence | name | date | Open |
| P1 | Improve detection | name | date | Open |
## Lessons Learned
```

## Incident Metrics

| Metric | Target |
|--------|--------|
| MTTD (detect) | < 5 min |
| MTTA (acknowledge) | < 5 min SEV1, < 15 min SEV2 |
| MTTR (resolve) | < 1 hr SEV1, < 4 hr SEV2 |
| MTBF | Increasing trend |

Track action item completion: target 90% within 30 days.

## On-Call

- 2-person rotation (primary + secondary), weekly, max 7 days consecutive.
- Escalation: 0min primary, 5min secondary, 10min lead, 15min manager.
- Every alert links to a runbook (what it means, diagnose, mitigate, escalate).
- Target < 5 actionable alerts per shift. Tune/delete noisy alerts.

## Proactive Prevention

- **Chaos engineering**: Inject failures in staging, gradually increase scope.
- **Game days**: Quarterly simulated incidents, rotate IC role.
- **Pre-mortems**: Before launch ask "what could go wrong at 10x scale?"
- Target 40%+ of reliability work as proactive (not incident-triggered).

## Blameless Culture

Focus on systems not people. Assume good intent. Discuss "the deploy" not "your deploy." Learning over punishment. Use language like "How can we improve detection?" not "Why didn't you catch this?"
