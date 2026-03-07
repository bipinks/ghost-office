# DevOps Runbook — Platform Operations

## Server Management

### SSH Access
```bash
# Production
ssh deploy@prod.example.com

# Staging
ssh deploy@staging.example.com

# Use SSH config for convenience (~/.ssh/config)
Host prod
    HostName prod.example.com
    User deploy
    IdentityFile ~/.ssh/deploy_key
```

### Service Management
```bash
# Check all services
docker compose ps

# Restart a specific service
docker compose restart app

# View logs (last 100 lines, follow)
docker compose logs --tail=100 -f app

# Enter a container shell
docker compose exec app bash

# Run artisan command
docker compose exec -T app php artisan <command>
```

## Backup Procedures

### Database Backup (Automated — daily)
```bash
# Manual backup
docker compose exec -T db pg_dump -U postgres erp_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
docker compose exec -T db psql -U postgres erp_production < backup_20260306.sql
```

### File Backup
```bash
# Backup uploaded files
tar -czf files_backup_$(date +%Y%m%d).tar.gz storage/app/public/

# Sync to S3
aws s3 sync storage/app/public/ s3://backup-bucket/files/
```

### Backup Schedule
| What | Frequency | Retention | Location |
|------|-----------|-----------|----------|
| Database (full) | Daily 2:00 AM | 30 days | S3 + local |
| Database (WAL) | Continuous | 7 days | S3 |
| File uploads | Daily 3:00 AM | 90 days | S3 |
| Configuration | On change | 365 days | Git |

### Backup Verification
- Test restore monthly on a separate instance
- Verify data integrity after restore
- Document restore time (target: < 30 minutes)

## CI/CD Pipeline

### GitHub Actions Workflow
```
Push to feature/* → Lint → Test → Build Docker image
Push to develop    → Lint → Test → Build → Deploy to staging
Push to main       → Lint → Test → Build → Deploy to production (manual gate)
```

### Pipeline Secrets
Stored in GitHub Actions secrets:
- `DEPLOY_SSH_KEY` — SSH private key for deployment
- `DOCKER_REGISTRY_TOKEN` — Container registry auth
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` — AWS credentials
- `SLACK_WEBHOOK` — Deployment notifications

## Monitoring

### Health Checks
```bash
# Application health
curl -s https://app.example.com/api/health | jq .

# Database connectivity
docker compose exec -T app php artisan db:monitor

# Queue health
docker compose exec -T app php artisan queue:monitor

# Disk space
df -h

# Memory usage
free -h

# Docker resource usage
docker stats --no-stream
```

### Log Locations
```
# Application logs
docker compose logs app

# Nginx logs
/var/log/nginx/access.log
/var/log/nginx/error.log

# System logs
journalctl -u docker --since "1 hour ago"
```

### Alert Channels
- **P0/P1**: PagerDuty or phone call
- **P2**: Slack #alerts channel
- **P3**: Email notification

## Common Troubleshooting

### Application Not Responding
1. Check container status: `docker compose ps`
2. Check container logs: `docker compose logs --tail=50 app`
3. Check disk space: `df -h`
4. Check memory: `free -h`
5. Restart container: `docker compose restart app`

### Database Connection Issues
1. Check DB container: `docker compose ps db`
2. Check connections: `docker compose exec -T db psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"`
3. Check max connections: default 100, increase if needed
4. Restart DB (last resort): `docker compose restart db`

### Queue/Job Failures
1. Check worker status: `docker compose ps worker`
2. Check failed jobs: `docker compose exec -T app php artisan queue:failed`
3. Retry failed jobs: `docker compose exec -T app php artisan queue:retry all`
4. Restart worker: `docker compose restart worker`

### High CPU/Memory
1. Identify the process: `docker stats --no-stream`
2. Check for runaway queries: `docker compose exec -T db psql -U postgres -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC LIMIT 5;"`
3. Kill long-running queries if needed
4. Scale up if sustained high usage

### SSL Certificate Issues
1. Check expiry: `echo | openssl s_client -connect app.example.com:443 2>/dev/null | openssl x509 -noout -dates`
2. Renew: `certbot renew`
3. Reload Nginx: `nginx -s reload`

## Security Operations

### Credential Rotation
- Database passwords: Rotate quarterly
- API keys: Rotate on personnel change
- SSH keys: Rotate annually
- SSL certificates: Auto-renewed via certbot

### Security Updates
```bash
# Update system packages
apt update && apt upgrade -y

# Update Docker images
docker compose pull
docker compose up -d

# Check for vulnerabilities
trivy image app:latest
```

## Disaster Recovery

### RTO/RPO Targets
- **RTO** (Recovery Time Objective): 1 hour
- **RPO** (Recovery Point Objective): 1 hour (continuous WAL archiving)

### Recovery Steps
1. Provision new server (Terraform or manual)
2. Restore database from latest backup
3. Deploy latest application version
4. Update DNS to point to new server
5. Verify all services healthy
6. Notify stakeholders
