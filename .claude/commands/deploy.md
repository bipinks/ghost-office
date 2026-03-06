---
name: deploy
description: Deploy application to staging or production environment
argument-hint: "[environment] [strategy]"
disable-model-invocation: true
---

# /deploy — Application Deployment

Deploy $ARGUMENTS using the **deployment-manager** agent with the following process:

1. **Pre-flight checks**
   - Verify all CI/CD checks have passed
   - Confirm the target environment
   - Review recent changes in the deployment
   - Check for pending database migrations

2. **Choose deployment strategy**
   - Blue/Green for major releases
   - Canary for high-risk changes
   - Rolling for standard releases

3. **Execute deployment**
   - Run pre-deployment scripts
   - Deploy the new version
   - Run smoke tests
   - Monitor error rates and latency

4. **Post-deployment**
   - Verify health checks
   - Update deployment documentation
   - Notify stakeholders

## Usage
```
/deploy                          # Interactive deployment
/deploy "staging"                # Deploy to staging
/deploy "production canary 5%"   # Canary deploy at 5%
```
