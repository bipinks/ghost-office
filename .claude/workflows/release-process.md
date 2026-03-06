# Release Process Workflow

## Overview
Structured release workflow from code freeze to production deployment with quality gates.

## Trigger
- Scheduled release cycle
- Hotfix for critical production issue
- Command: `/deploy-production`

## Workflow Diagram
```
[Code Freeze]──→[QA Pass]──→[Security Review]──→[Staging]──→[Approval]──→[Production]──→[Monitor]
      │              │              │                │            │              │            │
   DevOps           QA          Security          DevOps       User          DevOps      Monitoring
   Engineer        Agent          Agent           Engineer                   Engineer      Agent
```

## Phases

### Phase 1: Release Preparation
**Agent**: devops-engineer
**Actions**:
1. Create release branch from develop
2. Bump version number
3. Generate changelog from commits since last release
4. Freeze feature development (bugfixes only)
**Output**: Release branch created with version bump

### Phase 2: Quality Assurance
**Agent**: qa-agent
**Actions**:
1. Run full test suite on release branch
2. Execute regression test suite
3. Run multi-tenant isolation tests
4. Verify all acceptance criteria for included features
5. Test database migrations (up and down)
6. Check test coverage meets thresholds
**Output**: QA report with pass/fail status
**Gate**: All tests must pass

### Phase 3: Security Review
**Agent**: security-agent
**Actions**:
1. Scan dependencies for known vulnerabilities
2. Run static analysis for security issues
3. Check for hardcoded secrets
4. Verify no sensitive data in logs
5. Review new API endpoints for auth/authz
**Output**: Security clearance report
**Gate**: No critical or high vulnerabilities

### Phase 4: Staging Deployment
**Agent**: devops-engineer
**Actions**:
1. Deploy release branch to staging
2. Run database migrations
3. Execute smoke tests
4. Verify all services healthy
5. Performance baseline check
**Output**: Staging deployment verified

### Phase 5: User Acceptance
**Agent**: master-orchestrator
**Actions**:
1. Present release summary to user:
   - Features included
   - Bug fixes included
   - Breaking changes (if any)
   - Migration details
   - Rollback plan
2. **WAIT FOR USER APPROVAL**
**Gate**: Explicit user approval required

### Phase 6: Production Deployment
**Agent**: devops-engineer
**Actions**:
1. Create database backup
2. Enable maintenance mode (if needed for migrations)
3. Deploy to production
4. Run database migrations
5. Clear all caches
6. Disable maintenance mode
7. Verify health checks
**Output**: Production deployment completed

### Phase 7: Post-Release Monitoring
**Agent**: monitoring-agent
**Actions**:
1. Monitor error rates for 30 minutes
2. Compare latency against baseline
3. Verify background job processing
4. Check all health endpoints
5. Confirm no regression in key metrics
**Output**: Post-release health report

### Phase 8: Release Finalization
**Agent**: devops-engineer + documentation-agent
**Actions**:
1. Merge release branch to main
2. Tag release with version number
3. Merge back to develop
4. Publish release notes
5. Update documentation
**Output**: Release finalized and documented

## Rollback Procedure

If issues detected during Phase 7:
1. **monitoring-agent**: Detect and classify issue severity
2. **devops-engineer**: Execute rollback
   - Revert to previous deployment
   - Rollback migrations (if safe)
   - Restore from backup (if data affected)
3. **monitoring-agent**: Verify rollback successful
4. **master-orchestrator**: Notify user, create incident for investigation

## Hotfix Process (Abbreviated)

For critical production issues:
1. Branch from main (not develop)
2. Minimal fix + regression test
3. Security quick scan
4. Deploy to staging → verify → deploy to production
5. Merge hotfix to both main and develop
