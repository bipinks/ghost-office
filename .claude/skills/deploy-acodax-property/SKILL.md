---
name: deploy-acodax-property
description: Deployment configuration for Acodax Property — a Django project running on Docker Compose in production. Used by the deployer agent.
user-invocable: false
allowed-tools: ["Read", "Bash"]
---

# Deploy: Acodax Property

## Server Details

- **SSH host**: `ubuntu@acodax-property` (configured in ~/.ssh/config)
- **Project directory**: `/home/ubuntu/<project-folder>` (user provides folder name)
- **Branch**: Uses the project's default branch (as set in Git). If user provides a different branch name, use that instead.

## Docker Compose Setup

- **Compose file**: `docker-compose.yml` (production) in project root
- **Service name**: `app`
- **Container name**: `${HOST_PORT}-axisproperties-app` (HOST_PORT from `.env`)
- **Volume mount**: `.:/app` (code changes reflect without rebuild)
- **Dockerfile**: `.docker/Dockerfile`

## Deployment Steps

### 1. Get project folder from user

The user must provide the project folder name. Full path will be `/home/ubuntu/<folder>`.

### 2. Pre-flight (single SSH session)

```bash
ssh ubuntu@acodax-property "cd /home/ubuntu/<folder> && echo '=== CURRENT COMMIT ===' && git log --oneline -1 && echo '=== GIT STATUS ===' && git status --short && echo '=== CONTAINER ===' && docker compose ps && echo '=== HOST PORT ===' && grep HOST_PORT .env"
```

### 3. Deploy (single SSH session)

Combine pull, migrate, restart, and verify into one SSH call to avoid reconnecting:

```bash
ssh ubuntu@acodax-property bash -c "'
cd /home/ubuntu/<folder> &&
echo \"=== PULLING ===\"  &&
git pull &&
echo \"=== MIGRATING ===\" &&
docker compose exec -T app python3 manage.py migrate &&
echo \"=== RESTARTING ===\" &&
docker compose restart app &&
sleep 3 &&
echo \"=== VERIFY ===\"  &&
docker compose ps &&
docker compose logs --tail=15 app
'"
```

**Key flags:**
- Use `docker compose exec -T` (disable TTY) since this runs non-interactively
- `sleep 3` after restart to let the container stabilize before checking logs

### 4. Collect static files (only if frontend/static changes)

Run separately only when needed:

```bash
ssh ubuntu@acodax-property "cd /home/ubuntu/<folder> && docker compose exec -T app python3 manage.py collectstatic --noinput"
```

## Important Notes

- Code is **volume-mounted**, so `git pull` on the host is enough — no image rebuild needed
- Only rebuild image (`docker compose up -d --build app`) if `Dockerfile` or `requirements.txt` changed
- The `.env` file contains `HOST_PORT` which determines the container name and exposed port
- Django runs on port 80 inside the container, mapped to `HOST_PORT` on the host
- Always use `-T` flag with `docker compose exec` in non-interactive SSH sessions

## When to Rebuild Image

If any of these files changed in the pull, rebuild instead of restart:

- `.docker/Dockerfile`
- `requirements.txt` / `Pipfile` / `pyproject.toml`
- Any Docker-related config

```bash
ssh ubuntu@acodax-property "cd /home/ubuntu/<folder> && docker compose up -d --build app"
```

## Rollback

```bash
ssh ubuntu@acodax-property "cd /home/ubuntu/<folder> && git checkout <previous-commit> && docker compose exec -T app python3 manage.py migrate && docker compose restart app"
```
