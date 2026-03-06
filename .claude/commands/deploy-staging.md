---
name: deploy-staging
description: Deploy the current branch to the staging environment
argument-hint: "[branch name, defaults to current branch]"
---

## Deploy to Staging

Deploy to the staging environment: $ARGUMENTS

### Agents Involved
- **devops-engineer** — Orchestrate deployment
- **qa-agent** — Pre-deployment test verification
- **monitoring-agent** — Post-deployment health check

### Workflow

#### Phase 1: Pre-Deployment Checks
1. **qa-agent**: Verify test suite
   - All tests passing on the branch
   - No known P0/P1 bugs outstanding
   - Test coverage meets minimum threshold

2. **devops-engineer**: Pre-flight check
   - Verify staging environment is healthy
   - Check for pending migrations
   - Confirm no conflicting deployments in progress
   - Note current deployed commit (for rollback)

#### Phase 2: Deploy
3. **devops-engineer**: Execute deployment
   - Pull latest code on staging server
   - Run database migrations
   - Build and deploy application
   - Clear caches (application, config, route)
   - Restart services

#### Phase 3: Post-Deployment
4. **monitoring-agent**: Health verification
   - Check service health endpoints
   - Verify no error spike in logs
   - Confirm key features accessible
   - Monitor for 5 minutes post-deploy

5. **devops-engineer**: Report
   - Previous commit hash
   - Deployed commit hash
   - Migration status
   - Service health status
   - Rollback instructions if needed

### Rollback
If issues are detected:
```bash
# Rollback to previous commit
git checkout <previous-commit>
# Reverse migrations if applicable
php artisan migrate:rollback
# Restart services
docker compose restart
```

### Output
Staging deployment completed with health verification report.
