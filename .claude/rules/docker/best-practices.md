---
paths:
  - "**/Dockerfile*"
  - "**/docker-compose*"
  - "**/.dockerignore"
---

# Docker Rules

## Image Security
- Use specific version tags, never `latest`
- Use official or verified base images
- Scan images for vulnerabilities in CI
- Sign images in production pipelines

## Runtime
- Run as non-root user (USER instruction)
- Use multi-stage builds for minimal images
- Define HEALTHCHECK in Dockerfile
- Use `.dockerignore` to exclude unnecessary files
- Handle signals properly (tini/dumb-init for PID 1)

## Build Optimization
- Order layers from least to most frequently changing
- Combine RUN commands to reduce layers
- Clean up in the same RUN layer (apt-get clean)
- Use BuildKit cache mounts for package managers

## Compose
- Use `depends_on` with health checks
- Set resource limits (cpus, memory)
- Use named volumes for persistent data
- Use secrets for sensitive configuration
