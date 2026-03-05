---
name: docker-build
description: Build, optimize, and scan Docker images
argument-hint: "[image name or Dockerfile path]"
---

# /docker-build — Docker Build & Optimization

Build Docker image for $ARGUMENTS using the **container-reviewer** agent:

1. Review existing Dockerfile for best practices
2. Optimize for multi-stage builds and layer caching
3. Ensure security (non-root, minimal base, no secrets)
4. Run security scan (trivy/scout)
5. Generate optimized Dockerfile and Compose config

## Usage
```
/docker-build                    # Review current Dockerfile
/docker-build "optimize"         # Optimize existing
/docker-build "create Node.js"   # Create new Dockerfile
```
