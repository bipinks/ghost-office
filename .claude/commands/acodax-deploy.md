---
name: acodax-deploy
description: Deploy Acodax Property project updates to production server via SSH and Docker Compose
argument-hint: "<project-folder> [branch]"
---

# /acodax-deploy — Acodax Property Deployment

Deploy $ARGUMENTS using the **deployer** agent with the **deploy-acodax-property** skill.

## Workflow
1. SSH into `ubuntu@acodax-property`
2. cd into `/home/ubuntu/<project-folder>`
3. Check current state (git commit, container status)
4. Pull latest code from Git
5. Run Django migrations (`python3 manage.py migrate`)
6. Restart the Docker container
7. Verify deployment health (container status + logs)

## Usage
```
/acodax-deploy "my-project-folder"
/acodax-deploy "my-project-folder staging"
```
