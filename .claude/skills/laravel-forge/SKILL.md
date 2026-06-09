---
name: laravel-forge
description: Use when managing Laravel Forge servers, sites, deployments, SSL, databases, queue workers, scheduled jobs, security rules, and server provisioning. Covers Forge CLI, API, deployment scripts, Nginx templates, daemon management, and zero-downtime deployments.
user-invocable: false
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
---

# Laravel Forge -- Server Management & Deployment

## 1. Overview

Laravel Forge provisions and manages PHP servers on cloud providers (DigitalOcean, AWS, Hetzner, Linode, Vultr, custom VPS). It handles:

- Server provisioning (Nginx, PHP-FPM, MySQL/PostgreSQL, Redis, Supervisor, UFW)
- Site management (domains, SSL, deployment scripts, environment variables)
- Database creation and user management
- Queue worker configuration via Supervisor
- Scheduled job (cron) management
- SSH key management
- Server monitoring and alerts
- Push-to-deploy via Git webhooks

## 2. Forge CLI

### Installation

```bash
composer global require laravel/forge-cli
forge login  # Authenticate with API token
```

### Server Commands

```bash
# List servers
forge server:list

# SSH into server
forge ssh                        # Default server
forge ssh my-server              # Named server
forge server:switch my-server    # Set default server

# Server info
forge server:info
forge server:logs                # System logs
forge server:reboot              # Reboot (with confirmation)
```

### Site Commands

```bash
# List sites
forge site:list

# Deploy a site
forge deploy                     # Default site
forge deploy example.com         # Named site

# View deploy log
forge deploy:log
forge deploy:log example.com

# Enable/disable push-to-deploy
forge deploy:enable
forge deploy:disable

# Maintenance mode
forge site:down example.com
forge site:up example.com

# View Nginx config
forge nginx:get example.com
forge nginx:edit example.com
```

### Database Commands

```bash
forge database:list
forge database:create my_database
forge database:delete my_database
```

### Daemon Commands

```bash
forge daemon:list
forge daemon:create --command="php artisan horizon" --user=forge
forge daemon:delete <id>
forge daemon:restart <id>
```

### SSH Key Commands

```bash
forge ssh-key:list
forge ssh-key:add "Key Name" --file=~/.ssh/id_rsa.pub
forge ssh-key:delete <id>
```

### Environment Commands

```bash
forge env                        # View .env
forge env:pull                   # Download .env to local
forge env:push                   # Upload local .env to server
```

## 3. Forge API

Base URL: `https://forge.laravel.com/api/v1`

### Authentication

```bash
# All requests require Bearer token
curl -H "Authorization: Bearer $FORGE_API_TOKEN" \
     -H "Accept: application/json" \
     https://forge.laravel.com/api/v1/servers
```

### Common Endpoints

```
GET    /servers                          # List servers
GET    /servers/{id}                     # Server details
POST   /servers                          # Create server
DELETE /servers/{id}                     # Delete server

GET    /servers/{id}/sites               # List sites
POST   /servers/{id}/sites               # Create site
GET    /servers/{id}/sites/{id}          # Site details
DELETE /servers/{id}/sites/{id}          # Delete site

POST   /servers/{id}/sites/{id}/deployment/deploy  # Trigger deploy
GET    /servers/{id}/sites/{id}/deployment/log      # Deploy log

GET    /servers/{id}/sites/{id}/env      # Get .env
PUT    /servers/{id}/sites/{id}/env      # Update .env

POST   /servers/{id}/sites/{id}/certificates/letsencrypt  # SSL cert
GET    /servers/{id}/sites/{id}/certificates               # List certs

GET    /servers/{id}/daemons             # List daemons
POST   /servers/{id}/daemons             # Create daemon
DELETE /servers/{id}/daemons/{id}        # Delete daemon

GET    /servers/{id}/jobs                # List scheduled jobs
POST   /servers/{id}/jobs                # Create scheduled job
DELETE /servers/{id}/jobs/{id}           # Delete scheduled job

GET    /servers/{id}/databases           # List databases
POST   /servers/{id}/databases           # Create database

GET    /servers/{id}/workers             # List workers
POST   /servers/{id}/workers             # Create worker
DELETE /servers/{id}/workers/{id}        # Delete worker
```

### API Usage with curl

```bash
# Trigger deployment
curl -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  "https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/deployment/deploy"

# Get deployment log
curl -H "Authorization: Bearer $FORGE_API_TOKEN" \
     -H "Accept: application/json" \
     "https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/deployment/log"

# Update environment variables
curl -X PUT \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"content":"APP_ENV=production\nAPP_KEY=base64:..."}' \
  "https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/env"
```

## 4. Deployment Scripts

### Standard Deploy Script

```bash
cd /home/forge/example.com

git pull origin $FORGE_SITE_BRANCH

$FORGE_COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader

( flock -w 10 9 || exit 1
    echo 'Restarting FPM...'; sudo -S service $FORGE_PHP_FPM reload ) 9>/tmp/fpmlock

if [ -f artisan ]; then
    $FORGE_PHP artisan migrate --force
    $FORGE_PHP artisan config:cache
    $FORGE_PHP artisan route:cache
    $FORGE_PHP artisan view:cache
    $FORGE_PHP artisan event:cache
fi
```

### Zero-Downtime Deploy Script (Envoyer-style)

```bash
cd /home/forge/example.com

# Pull latest code
git pull origin $FORGE_SITE_BRANCH

# Install dependencies (no dev)
$FORGE_COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Build frontend assets
npm ci --production
npm run build

# Run migrations
$FORGE_PHP artisan migrate --force

# Cache configuration
$FORGE_PHP artisan config:cache
$FORGE_PHP artisan route:cache
$FORGE_PHP artisan view:cache
$FORGE_PHP artisan event:cache

# Restart queue workers gracefully
$FORGE_PHP artisan queue:restart

# Restart Horizon (if used)
if [ -f artisan ] && $FORGE_PHP artisan list 2>/dev/null | grep -q horizon; then
    $FORGE_PHP artisan horizon:terminate
fi

# Reload PHP-FPM (zero-downtime)
( flock -w 10 9 || exit 1
    echo 'Restarting FPM...'; sudo -S service $FORGE_PHP_FPM reload ) 9>/tmp/fpmlock

echo "Deployment finished at $(date)"
```

### Deploy Script with Health Check

```bash
cd /home/forge/example.com

git pull origin $FORGE_SITE_BRANCH

$FORGE_COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader

$FORGE_PHP artisan migrate --force
$FORGE_PHP artisan config:cache
$FORGE_PHP artisan route:cache
$FORGE_PHP artisan view:cache

( flock -w 10 9 || exit 1
    sudo -S service $FORGE_PHP_FPM reload ) 9>/tmp/fpmlock

# Health check
sleep 2
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health)
if [ "$HTTP_STATUS" != "200" ]; then
    echo "Health check failed with status $HTTP_STATUS"
    exit 1
fi

echo "Deploy successful — health check passed"
```

## 4b. Changing a Site's Deploy Branch (DESTRUCTIVE — read first)

Changing a site's branch via `POST /servers/{id}/sites/{id}/git` (same repo, new branch) is **not a metadata update** — Forge **re-clones the repository**. This has bitten us in production:

1. **Wipes `vendor/`** (gitignored) → the next deploy fails with `vendor/autoload.php: No such file or directory` unless the deploy script runs `composer install`.
2. **Resets `.env`** from the repo's `.env.example` — empties `APP_KEY` and sets `DB_DATABASE=forge` (Forge only re-injects the real DB *password*). Result: migrations run against the wrong `forge` database, and the web app returns 500 `No application encryption key has been specified` (the deploy's `artisan optimize` caches the empty key).
3. **Regenerates the deploy script** — passing `"composer": false` drops the `composer install` line.

### Safe branch-change procedure

```bash
SID=<server-id>; SITE=<site-id>; SITEDIR=/home/forge/<domain>
# 1. Back up the live .env BEFORE touching git
ssh forge@<server-ip> "cp $SITEDIR/.env /tmp/<domain>.env.bak"
#    (also: forge env:pull / GET .../env to keep a local copy)

# 2. Change the branch (do NOT pass composer:false — keep composer install)
curl -s -X POST -H "Authorization: Bearer $FORGE_API_TOKEN" -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"provider":"github","repository":"org/repo","branch":"<new-branch>"}' \
  "https://forge.laravel.com/api/v1/servers/$SID/sites/$SITE/git"
#    poll until repository_status == installed

# 3. Restore the .env (Forge will have reset it) — at minimum APP_KEY + DB_DATABASE
ssh forge@<server-ip> "cp /tmp/<domain>.env.bak $SITEDIR/.env"

# 4. Make sure the deploy script has composer install, then deploy
#    PUT .../deployment/script  (composer install --no-dev --optimize-autoloader)
#    POST .../deployment/deploy

# 5. Rebuild config cache from the restored .env and confirm the real DB
ssh forge@<server-ip> "cd $SITEDIR && php artisan optimize:clear && php artisan optimize"

# 6. Apply pending migrations to the CORRECT tenant DB (mind branch schema divergence)
ssh forge@<server-ip> "cd $SITEDIR && php artisan migrate:status && php artisan migrate --force"
```

**Verify after:** `php artisan migrate:status` shows 0 pending; the cached config has a non-empty `app.key` and the right `DB_DATABASE`; the live URL returns 200.

**Beware schema divergence:** different branches can have different migration sets. After the re-clone, run migrations against the tenant DB (e.g. `live_db_dms_*`), not the default `forge` db — and never assume the new branch's migrations are a clean superset of the old branch's.

## 5. Forge Variables

Forge provides these variables in deployment scripts:

| Variable | Description |
|----------|-------------|
| `$FORGE_SERVER_ID` | Server ID |
| `$FORGE_SITE_BRANCH` | Git branch configured for the site |
| `$FORGE_COMPOSER` | Path to Composer binary |
| `$FORGE_PHP` | Path to PHP binary (versioned) |
| `$FORGE_PHP_FPM` | PHP-FPM service name |
| `$FORGE_SITE_PATH` | Full path to the site directory |

## 6. Nginx Configuration

### Default Site Config (Forge-managed)

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name example.com;
    
    # Forge handles SSL redirect automatically
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com;
    server_tokens off;
    root /home/forge/example.com/public;

    # SSL managed by Forge (Let's Encrypt)
    ssl_certificate /etc/nginx/ssl/example.com/server.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com/server.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:...;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

### Custom Nginx Directives

Add in Forge UI under Site > Nginx > "Before" or "After" sections:

```nginx
# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;

location /api/ {
    limit_req zone=api burst=20 nodelay;
    try_files $uri $uri/ /index.php?$query_string;
}

# Static file caching
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
}

# WebSocket support (Laravel Reverb / Pusher)
location /app {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
}
```

## 7. Queue Workers (Supervisor)

### Forge Worker Configuration

```
Command:     php artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
Number:      2
User:        forge
Directory:   /home/forge/example.com
Stop Signal: SIGTERM
Stop Secs:   10
```

### Horizon Configuration

```
Command:     php artisan horizon
Number:      1
User:        forge
Directory:   /home/forge/example.com
Stop Signal: SIGTERM
Stop Secs:   30
```

Forge auto-generates Supervisor configs at `/etc/supervisor/conf.d/`.

## 8. Scheduled Jobs

Configure in Forge UI or via API:

| Field | Example |
|-------|---------|
| Command | `php /home/forge/example.com/artisan schedule:run` |
| User | `forge` |
| Frequency | `* * * * *` (every minute) |

This runs Laravel's built-in scheduler. Individual job schedules are defined in `routes/console.php` (Laravel 11+) or `app/Console/Kernel.php`.

## 9. SSL Certificates

### Let's Encrypt (Free)

Forge handles auto-issuance and renewal:

```bash
# Via CLI
forge ssl:install example.com

# Via API
curl -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"domains":["example.com","www.example.com"]}' \
  "https://forge.laravel.com/api/v1/servers/$SERVER_ID/sites/$SITE_ID/certificates/letsencrypt"
```

### Custom Certificate

Upload via Forge UI: Site > SSL > Install Existing Certificate.

## 10. Security Rules (UFW Firewall)

Forge configures UFW with sensible defaults:

```
22/tcp    ALLOW    # SSH
80/tcp    ALLOW    # HTTP
443/tcp   ALLOW    # HTTPS
```

Add custom rules via Forge UI or API:

```bash
# Allow IP for database access
curl -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Office DB Access","port":"5432","type":"allow","ip_address":"203.0.113.10"}' \
  "https://forge.laravel.com/api/v1/servers/$SERVER_ID/firewall-rules"
```

## 11. Database Management

### Forge-Provisioned Databases

Forge installs MySQL or PostgreSQL during server provisioning. Manage via UI or API:

```bash
# Create database
curl -X POST \
  -H "Authorization: Bearer $FORGE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"my_app_db","user":"my_app_user","password":"secure_password"}' \
  "https://forge.laravel.com/api/v1/servers/$SERVER_ID/databases"
```

### Backup with Forge

Forge supports automated backups to S3-compatible storage:
- Configure backup profile in Forge UI
- Set schedule (daily, weekly)
- Set retention period
- Automatic upload to S3/Spaces/Wasabi

## 12. Server Recipes

Recipes are Bash scripts that run across one or more servers:

```bash
# Example: Update system packages
apt-get update && apt-get upgrade -y

# Example: Install additional PHP extension
apt-get install -y php8.3-imagick
service php8.3-fpm restart

# Example: Configure log rotation
cat > /etc/logrotate.d/laravel << 'EOF'
/home/forge/example.com/storage/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
}
EOF
```

## 13. Monitoring

### Forge Server Monitoring

Forge tracks:
- CPU usage
- Memory usage
- Disk usage
- Network throughput

Alerts configurable per metric with thresholds.

### Application-Level Monitoring

Complement Forge monitoring with:

```php
// routes/api.php — Health endpoint
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'database' => DB::connection()->getPdo() ? 'connected' : 'disconnected',
        'cache' => Cache::store()->get('health_check_ping') !== null ? 'ok' : 'degraded',
        'queue' => Queue::size() < 1000 ? 'ok' : 'backlogged',
        'disk' => disk_free_space('/') > 1073741824 ? 'ok' : 'low',  // 1GB threshold
    ]);
});
```

## 14. Multi-Server Patterns

### Web + Worker Separation

```
Server 1: Web (Nginx + PHP-FPM)
  - Sites: example.com
  - No queue workers

Server 2: Worker (Queue + Scheduler)
  - No sites
  - Horizon: 1 daemon
  - Scheduler: cron every minute
  - Same codebase deployed via Git
```

### Load Balancer Setup

```
Load Balancer (Forge-managed or external)
  ├── Web Server 1 (Forge)
  ├── Web Server 2 (Forge)
  └── Web Server 3 (Forge)

Shared:
  - Database: Managed RDS/Cloud SQL (external)
  - Redis: Managed ElastiCache/Memorystore (external)
  - Storage: S3 for file uploads
  - Sessions: Redis (shared)
  - Cache: Redis (shared)
```

## 15. Troubleshooting

### Common Issues

**Deploy fails — permission denied:**
```bash
# Fix storage permissions
ssh forge@server
cd /home/forge/example.com
chmod -R 775 storage bootstrap/cache
chown -R forge:www-data storage bootstrap/cache
```

**PHP-FPM not restarting:**
```bash
# Check PHP-FPM status
sudo systemctl status php8.3-fpm
# Manual restart
sudo systemctl restart php8.3-fpm
```

**Queue workers stuck:**
```bash
# Via Forge CLI
forge daemon:restart <worker-id>

# Or SSH and restart Supervisor
sudo supervisorctl restart all
```

**SSL renewal failed:**
```bash
# Check certbot logs
sudo cat /var/log/letsencrypt/letsencrypt.log
# Manual renewal
sudo certbot renew --nginx
```

**Disk space full:**
```bash
# Check disk usage
df -h
# Clear old logs
sudo truncate -s 0 /var/log/nginx/access.log
php artisan log:clear
# Clear old releases/backups
find /home/forge/example.com/storage/logs -name "*.log" -mtime +30 -delete
```

## 16. Best Practices

1. **Environment variables** — Never commit `.env`; manage via Forge UI or `forge env:push`
2. **Deploy hooks** — Use Forge deploy notifications (Slack, Discord, email) for visibility
3. **Isolated sites** — Use site isolation for multi-tenant servers (separate Linux users)
4. **PHP version** — Pin PHP version per site; don't rely on system default
5. **Server recipes** — Use recipes for repeatable server configuration, not manual SSH
6. **Backup strategy** — Enable Forge backups + separate offsite backup for critical data
7. **Firewall** — Restrict database ports to known IPs only
8. **Monitoring** — Enable Forge monitoring + external uptime monitoring (UptimeRobot, Pingdom)
9. **SSH keys** — Use Forge SSH key management; never share the `forge` user password
10. **Git webhooks** — Use push-to-deploy for staging; manual deploy for production
