---
name: deploy-production
description: Deploy to production with full safety checks and approval gates
argument-hint: "[version tag or commit hash]"
---

## Deploy to Production

Deploy to production: $ARGUMENTS

**WARNING: This deploys to production. Requires explicit user approval.**

### Agents Involved
- **devops-engineer** — Orchestrate deployment
- **qa-agent** — Verify staging tests passed
- **security-agent** — Final security check
- **monitoring-agent** — Post-deployment monitoring
- **master-orchestrator** — Coordinate and report

### Workflow

#### Phase 1: Pre-Deployment Gates (All must pass)
1. **qa-agent**: Verify readiness
   - [ ] All tests passing on the exact commit
   - [ ] Staging deployment verified and stable
   - [ ] No P0/P1 bugs outstanding
   - [ ] Database migrations tested on staging

2. **security-agent**: Final security check
   - [ ] No critical vulnerabilities in dependencies
   - [ ] No hardcoded secrets in deployment
   - [ ] SSL certificates valid and not expiring soon

3. **devops-engineer**: Infrastructure check
   - [ ] Production environment healthy
   - [ ] Sufficient resources (disk, memory, connections)
   - [ ] Backup completed before deployment
   - [ ] Rollback plan documented

#### Phase 2: Approval Gate
4. **REQUIRE USER APPROVAL** before proceeding
   - Show: changes to deploy (commit log since last deploy)
   - Show: migration list
   - Show: rollback plan
   - Wait for explicit "approved" from user

#### Phase 3: Deploy
5. **devops-engineer**: Execute production deployment
   - Enable maintenance mode (if needed)
   - Run database migrations
   - Deploy application code
   - Clear all caches
   - Disable maintenance mode
   - Verify health checks pass

#### Phase 4: Post-Deployment
6. **monitoring-agent**: Active monitoring
   - Watch error rates for 15 minutes
   - Compare latency against baseline
   - Verify all health endpoints
   - Check background job processing

7. **master-orchestrator**: Deployment report
   - Deployment summary
   - Changes included
   - Health status
   - Rollback instructions

### Rollback Procedure
If issues detected within 30 minutes:
1. Re-enable maintenance mode
2. Rollback to previous version
3. Reverse migrations (if safe)
4. Clear caches and restart
5. Verify health
6. Notify stakeholders

### Output
Production deployment completed (or rolled back) with full monitoring report.
