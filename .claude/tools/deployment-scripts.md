# Deployment Scripts Reference

## Overview
Reference for deployment automation scripts and tools used by the devops-engineer agent.

## Docker Compose Deployment

### Standard Deploy Script
```bash
#!/bin/bash
# deploy.sh — Standard deployment for Docker Compose ERP
set -euo pipefail

SERVER=$1
PROJECT_PATH=$2
SERVICE=${3:-app}

echo "=== Pre-flight check ==="
ssh deploy@$SERVER "cd $PROJECT_PATH && \
    echo 'Current commit:' && git log --oneline -1 && \
    echo 'Status:' && git status --short && \
    echo 'Containers:' && docker compose ps --format 'table {{.Name}}\t{{.Status}}'"

read -p "Proceed with deployment? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

echo "=== Deploying ==="
ssh deploy@$SERVER "cd $PROJECT_PATH && \
    git pull && \
    docker compose build --no-cache $SERVICE && \
    docker compose exec -T $SERVICE php artisan migrate --force && \
    docker compose exec -T $SERVICE php artisan config:cache && \
    docker compose exec -T $SERVICE php artisan route:cache && \
    docker compose exec -T $SERVICE php artisan view:cache && \
    docker compose restart $SERVICE && \
    sleep 5 && \
    echo '=== Post-deploy check ===' && \
    docker compose ps && \
    docker compose logs --tail=15 $SERVICE"
```

### Rollback Script
```bash
#!/bin/bash
# rollback.sh — Rollback to a specific commit
set -euo pipefail

SERVER=$1
PROJECT_PATH=$2
COMMIT=$3
SERVICE=${4:-app}

echo "Rolling back to commit: $COMMIT"
ssh deploy@$SERVER "cd $PROJECT_PATH && \
    git checkout $COMMIT && \
    docker compose exec -T $SERVICE php artisan migrate:rollback --step=1 && \
    docker compose restart $SERVICE && \
    sleep 5 && \
    docker compose ps && \
    docker compose logs --tail=15 $SERVICE"
```

## CI/CD Pipeline Templates

### GitHub Actions — Full Pipeline
```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          docker compose -f docker-compose.test.yml up --build --abort-on-container-exit
          docker compose -f docker-compose.test.yml down

  deploy:
    needs: test
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval
    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.DEPLOY_HOST }}
          username: deploy
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          script: |
            cd /app
            git pull origin main
            docker compose build --no-cache app
            docker compose exec -T app php artisan migrate --force
            docker compose exec -T app php artisan optimize
            docker compose restart app worker scheduler
```

## Existing Project Scripts

### Microsoft 365 Operations
```bash
# User management
node scripts/ms365.mjs info <user>          # Get user info
node scripts/ms365.mjs list [filter]         # List users
node scripts/ms365.mjs create <email> <name> <pwd> <dept> <title>
node scripts/ms365.mjs edit <email> <field> <value>
node scripts/ms365.mjs delete <email>
node scripts/ms365.mjs licenses              # Available licenses
node scripts/ms365.mjs assign-license <email> <sku>
node scripts/ms365.mjs remove-license <email> <sku>
node scripts/ms365.mjs list-groups [filter]
node scripts/ms365.mjs groups <email>
node scripts/ms365.mjs add-to-group <email> <group>
node scripts/ms365.mjs remove-from-group <email> <group>
node scripts/ms365.mjs token                 # Get access token
```

### Acodax ERP Operations
```bash
# User and system management
node scripts/acodax.mjs list-users [filter]
node scripts/acodax.mjs user-info <user-id>
node scripts/acodax.mjs create-user <username> <email> <pwd> <first> [last] [role_id] [branch_id]
node scripts/acodax.mjs update-user <user-id> <field> <value>
node scripts/acodax.mjs change-password <user-id> <new-pwd>
node scripts/acodax.mjs change-status <user-id> <0|1>
node scripts/acodax.mjs delete-user <user-id>
node scripts/acodax.mjs roles                # List roles
node scripts/acodax.mjs branches             # List branches
node scripts/acodax.mjs companies            # List companies
node scripts/acodax.mjs token                # Get access token
```

### Project Validation
```bash
# Validate .claude structure
node scripts/validate-structure.js

# Validate JSON files
npm run lint:json

# Run all tests
npm test

# Setup project
node scripts/setup.js
```

## Backup Scripts

### Database Backup
```bash
#!/bin/bash
# backup-db.sh
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/database"
mkdir -p $BACKUP_DIR

docker compose exec -T db pg_dump -U postgres erp_database | \
    gzip > "$BACKUP_DIR/erp_${TIMESTAMP}.sql.gz"

# Upload to S3
aws s3 cp "$BACKUP_DIR/erp_${TIMESTAMP}.sql.gz" \
    "s3://backups/database/erp_${TIMESTAMP}.sql.gz"

# Clean up local backups older than 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: erp_${TIMESTAMP}.sql.gz"
```

### File Backup
```bash
#!/bin/bash
# backup-files.sh
TIMESTAMP=$(date +%Y%m%d)
tar -czf "/backups/files/uploads_${TIMESTAMP}.tar.gz" storage/app/public/
aws s3 sync /backups/files/ s3://backups/files/
find /backups/files/ -name "*.tar.gz" -mtime +30 -delete
```
