# CLAUDE.md — Laravel Forge Project

## Project Overview
Laravel application deployed via Laravel Forge on DigitalOcean.

## Architecture
- **Server**: DigitalOcean droplet managed by Forge
- **Framework**: Laravel 11 with PHP 8.3
- **Database**: PostgreSQL 16
- **Cache/Queue**: Redis 7
- **Web Server**: Nginx with PHP-FPM
- **SSL**: Let's Encrypt (auto-renewal)
- **CI/CD**: Push-to-deploy on main branch

## Forge Configuration
- **Server**: production-web-01 (s-2vcpu-4gb)
- **Site**: example.com (isolated)
- **Repository**: github.com/org/laravel-app (main branch)
- **Deploy Script**: See `deploy.sh`
- **Queue Workers**: 2 processes via Supervisor
- **Scheduler**: Laravel scheduler via cron (every minute)

## Key Commands
```bash
# Deploy
forge deploy site:example.com

# SSH into server
ssh forge@production-web-01

# Queue management
php artisan queue:restart
php artisan horizon:terminate

# Maintenance
php artisan down --refresh=15 --retry=60
php artisan up
```

## Environment Files
- `.env` — Managed via Forge UI (never in Git)
- `.env.example` — Template with required variables

## Monitoring
- Forge server monitoring enabled
- Laravel Telescope for debugging
- Sentry for error tracking
- CloudFlare for CDN/WAF
