---
name: forge-deploy
description: Provision and deploy site via Laravel Forge
argument-hint: "[domain or server action]"
disable-model-invocation: true
---

# /forge-deploy — Laravel Forge Deployment

Provision Forge site for $ARGUMENTS using the **laravel-forge** skill:

1. Create or select Forge server
2. Create site with domain and PHP version
3. Install Git repository and configure deployment script
4. Set up SSL certificate (Let's Encrypt)
5. Configure environment variables
6. Set up queue workers and scheduled tasks
7. Enable auto-deploy on push

## Usage
```
/forge-deploy "new site example.com on production server"
/forge-deploy "update deployment script for staging"
/forge-deploy "add queue worker with 3 processes"
```
