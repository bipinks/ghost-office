---
name: docker-patterns
description: Use when creating Dockerfiles, docker-compose configs, or optimizing container images. Covers multi-stage builds, layer caching, security scanning with Trivy, non-root users, health checks, and Compose service orchestration.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# Docker Patterns

## Optimized Dockerfile (Multi-Stage)
```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:20-alpine AS production
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001
WORKDIR /app
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./

USER nextjs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/healthz || exit 1
ENTRYPOINT ["node"]
CMD ["dist/server.js"]
```

## Docker Compose (Production)
```yaml
version: '3.9'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/app
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: user
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d app"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass "${REDIS_PASSWORD}" --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

volumes:
  postgres_data:
  redis_data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

## .dockerignore
```
.git
.gitignore
node_modules
npm-debug.log
Dockerfile*
docker-compose*
.dockerignore
.env*
*.md
.github
tests
coverage
.vscode
.idea
```

## Best Practices
1. **Multi-stage builds** — Separate build and runtime for smallest images
2. **Specific base tags** — Never use `latest`, pin exact versions
3. **Non-root user** — Always run as non-root in production
4. **Layer caching** — Order instructions from least to most frequently changing
5. **HEALTHCHECK** — Always define health checks
6. **Cleanup in same layer** — `apt-get install && apt-get clean` in one RUN
7. **COPY specific files** — Not the entire context
8. **Security scanning** — Use `docker scout`, `trivy`, or `snyk`
9. **Secrets** — Never bake secrets into images; use build secrets or runtime injection
10. **Signal handling** — Use `tini` or `dumb-init` for proper PID 1 behavior

## Security Scanning
```bash
# Scan with Docker Scout
docker scout cves myapp:latest

# Scan with Trivy
trivy image myapp:latest

# Scan with Snyk
snyk container test myapp:latest
```
