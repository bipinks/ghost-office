---
name: laravel-forge
description: Use when provisioning Laravel/PHP sites via Forge API. Covers server creation, site setup, Git repo install, deployment scripts, SSL with Let's Encrypt, queue workers, scheduled tasks, and Nginx configuration.
user-invocable: true
disable-model-invocation: true
context: fork
allowed-tools: ["Read", "Write", "Bash"]
argument-hint: "site domain or server action"
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "#!/bin/bash\nif [ -z \"$FORGE_API_TOKEN\" ]; then\n  echo '❌ [Hook] FORGE_API_TOKEN is not set. Export it before running Forge commands.' >&2\n  exit 1\nfi"
---

# Laravel Forge — Site Provisioning & Management

## Overview
Laravel Forge provides server management and deployment for PHP applications. This skill covers complete site provisioning workflows via the Forge API and CLI.

## Site Provisioning Workflow

### 1. Server Creation
```bash
# Create server via Forge API
curl -X POST https://forge.laravel.com/api/v1/servers \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "ocean2",
    "credential_id": 1,
    "name": "production-web-01",
    "type": "app",
    "size": "s-2vcpu-4gb",
    "region": "nyc3",
    "php_version": "php83",
    "database": "postgres16",
    "database_type": "postgres"
  }'
```

### 2. Site Creation
```bash
# Create site on server
curl -X POST https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.com",
    "project_type": "php",
    "directory": "/public",
    "isolated": true,
    "username": "forge",
    "php_version": "php83"
  }'
```

### 3. SSL Certificate
```bash
# Install Let's Encrypt SSL
curl -X POST https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/certificates/letsencrypt \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domains": ["example.com", "www.example.com"]
  }'
```

### 4. Git Repository
```bash
# Install Git repository
curl -X POST https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/git \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "github",
    "repository": "org/repo",
    "branch": "main",
    "composer": true
  }'
```

### 5. Deployment Script
```bash
cd /home/forge/example.com

git pull origin $FORGE_SITE_BRANCH

composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
php artisan icons:cache

npm ci
npm run build

php artisan queue:restart

echo "Deployed at $(date)"
```

### 6. Environment Variables
```bash
# Update environment file
curl -X PUT https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/env \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "APP_ENV=production\nAPP_KEY=base64:...\nDB_CONNECTION=pgsql\nDB_HOST=127.0.0.1\n..."
  }'
```

### 7. Queue Workers (Daemons)
```bash
# Create daemon for queue worker
curl -X POST https://forge.laravel.com/api/v1/servers/$SERVER_ID/daemons \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "php /home/forge/example.com/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600",
    "user": "forge",
    "directory": "/home/forge/example.com",
    "processes": 2,
    "startsecs": 1,
    "stopsignal": "SIGTERM",
    "stopwaitsecs": 10
  }'
```

### 8. Scheduled Tasks
```bash
# Create scheduled task (cron)
curl -X POST https://forge.laravel.com/api/v1/servers/$SERVER_ID/jobs \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "php /home/forge/example.com/artisan schedule:run",
    "frequency": "minutely",
    "user": "forge"
  }'
```

## Nginx Configuration
```nginx
# Custom Nginx config for the site
server {
    listen 443 ssl http2;
    server_name example.com;
    root /home/forge/example.com/public;

    client_max_body_size 50M;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Gzip compression
    gzip on;
    gzip_types text/css application/javascript application/json image/svg+xml;
    gzip_min_length 1024;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

## Best Practices
1. **Isolated sites** — Use site isolation for multi-tenant servers
2. **Auto-deploy** — Enable push-to-deploy from main branch
3. **Zero-downtime** — Use Envoyer for zero-downtime deployments
4. **Monitoring** — Enable server monitoring in Forge dashboard
5. **Backups** — Configure automated database backups
6. **SSL renewal** — Let's Encrypt auto-renews, but verify cron is running
7. **Security** — Keep PHP, Nginx, and OS packages updated
8. **Firewall** — Configure Forge firewall rules (only allow necessary ports)
