# Server Management Tools

## Overview
Reference for server management tools and commands used by the devops-engineer and monitoring-agent.

## Docker Compose Operations

```bash
# Service lifecycle
docker compose up -d                    # Start all services
docker compose down                     # Stop all services
docker compose restart <service>        # Restart a service
docker compose stop <service>           # Stop a service
docker compose pull                     # Pull latest images

# Monitoring
docker compose ps                       # List services and status
docker compose logs -f --tail=100 <svc> # Follow logs
docker stats --no-stream                # Resource usage snapshot

# Execution
docker compose exec -T <svc> <cmd>      # Run command in container
docker compose run --rm <svc> <cmd>     # Run one-off command

# Build
docker compose build --no-cache <svc>   # Rebuild image
docker compose build --pull <svc>       # Rebuild with latest base
```

## Laravel Artisan Commands

```bash
# Common operations
php artisan migrate --force             # Run migrations (production)
php artisan migrate:rollback --step=1   # Rollback last migration
php artisan db:seed --class=Seeder      # Run specific seeder
php artisan config:cache                # Cache configuration
php artisan route:cache                 # Cache routes
php artisan view:cache                  # Cache views
php artisan cache:clear                 # Clear application cache
php artisan queue:restart               # Restart queue workers
php artisan queue:failed                # List failed jobs
php artisan queue:retry all             # Retry all failed jobs
php artisan schedule:list               # List scheduled tasks
php artisan down --secret=<token>       # Maintenance mode with bypass
php artisan up                          # Disable maintenance mode
```

## Nginx Operations

```bash
# Configuration
nginx -t                                # Test configuration
nginx -s reload                         # Reload configuration
nginx -s stop                           # Stop Nginx

# Logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Common config locations
/etc/nginx/nginx.conf                   # Main config
/etc/nginx/sites-available/             # Site configs
/etc/nginx/sites-enabled/               # Active sites
```

## SSL/TLS Management

```bash
# Let's Encrypt
certbot certonly --nginx -d domain.com  # Issue certificate
certbot renew                           # Renew certificates
certbot certificates                    # List certificates

# Check certificate
echo | openssl s_client -connect domain.com:443 2>/dev/null | openssl x509 -noout -dates
```

## System Administration

```bash
# Disk space
df -h                                   # Disk usage summary
du -sh /var/lib/docker/                 # Docker disk usage
docker system prune -f                  # Clean unused Docker resources

# Memory
free -h                                 # Memory usage
top -bn1 | head -20                     # Process list

# Network
ss -tlnp                                # Listening ports
curl -s http://localhost/health         # Health check

# Process management
systemctl status docker                 # Docker service status
systemctl restart docker                # Restart Docker daemon
journalctl -u docker --since "1h ago"   # Docker system logs
```

## Automation Scripts

### Available Scripts (scripts/)
```bash
node scripts/ms365.mjs <command>        # Microsoft 365 operations
node scripts/setup.js                   # Project setup
node scripts/validate-structure.js      # Validate .claude structure
```

See individual agent documentation for detailed script usage.
