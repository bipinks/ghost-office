# Deployment Standards — Platform Deployment

## Environments

| Environment | Purpose | Deployment | Approval |
|-------------|---------|------------|----------|
| Local | Development | Manual | None |
| Staging | Pre-production testing | Auto on merge to develop | None |
| Production | Live client access | Manual trigger | User approval required |

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing on the branch
- [ ] Code reviewed and approved
- [ ] Database migrations tested (up and down)
- [ ] No P0/P1 bugs in the release
- [ ] Security scan passed
- [ ] Changelog updated
- [ ] Rollback plan documented

### During Deployment
- [ ] Current commit hash noted (for rollback)
- [ ] Database backup taken
- [ ] Maintenance mode enabled (if needed for migrations)
- [ ] Code deployed
- [ ] Migrations run
- [ ] Caches cleared (application, config, route, view)
- [ ] Queue workers restarted
- [ ] Scheduler verified
- [ ] Maintenance mode disabled

### Post-Deployment
- [ ] Health check endpoints responding
- [ ] No error spike in logs (check for 15 minutes)
- [ ] Key features manually verified
- [ ] Background jobs processing
- [ ] Email notifications working
- [ ] Deployment logged in changelog

## Deployment Methods

### Method 1: Docker Compose (Primary)
```bash
# SSH to server
ssh deploy@server

# Pre-flight check
cd /app && git log --oneline -1 && docker compose ps

# Deploy
git pull origin main &&
docker compose build --no-cache app &&
docker compose exec -T app php artisan migrate --force &&
docker compose exec -T app php artisan config:cache &&
docker compose exec -T app php artisan route:cache &&
docker compose exec -T app php artisan view:cache &&
docker compose restart app worker scheduler &&
sleep 5 &&
docker compose ps &&
docker compose logs --tail=20 app
```

### Method 2: Laravel Forge
- Auto-deploy on push to main branch
- Deployment script configured in Forge dashboard
- Zero-downtime deployment with Envoyer integration
- SSL managed by Forge (Let's Encrypt)

### Method 3: Kubernetes
- Helm chart deployment with rolling update strategy
- Health check probes for readiness and liveness
- HPA for auto-scaling based on CPU/request metrics
- ConfigMaps for environment-specific settings

## Rollback Procedure

### Quick Rollback (< 5 minutes)
```bash
# 1. Get previous commit
git log --oneline -5

# 2. Rollback code
git checkout <previous-commit-hash>

# 3. Rollback migrations (if safe)
docker compose exec -T app php artisan migrate:rollback --step=N

# 4. Rebuild and restart
docker compose restart app worker scheduler

# 5. Verify
docker compose ps && curl -s http://localhost/health
```

### Full Rollback (with data)
1. Stop the application
2. Restore database from pre-deployment backup
3. Deploy previous version
4. Verify data integrity
5. Notify affected users

## Database Migration Rules

1. **Always reversible** — `down()` must undo `up()` completely
2. **Non-destructive** — Never drop columns/tables in production directly
3. **Additive first** — Add new columns as nullable, backfill, then enforce constraints
4. **Test on copy** — Run migrations against a copy of production data
5. **One migration per change** — Don't bundle unrelated changes
6. **Backup before migration** — Automated backup triggered pre-migration

## Zero-Downtime Deployment

For critical deployments:
1. Deploy new version alongside old version
2. Run migrations that are backward-compatible
3. Switch traffic to new version
4. Monitor for 15 minutes
5. Remove old version

## Environment Variables

Never commit `.env` files. Required variables:
```
APP_ENV=production
APP_KEY=base64:...
DB_HOST=
DB_DATABASE=
DB_USERNAME=
DB_PASSWORD=
REDIS_HOST=
MAIL_HOST=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=
AWS_BUCKET=
```

Store in: AWS Secrets Manager, Laravel Forge environment, or `.env` on server (never in git).
