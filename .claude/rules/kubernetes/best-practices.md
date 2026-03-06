---
paths:
  - "**/*.yaml"
  - "**/*.yml"
  - "**/k8s/**"
  - "**/kubernetes/**"
  - "**/helm/**"
---

# Kubernetes Rules

## Pod Security
- Always set `runAsNonRoot: true`
- Drop ALL capabilities, add only needed ones
- Use read-only root filesystem
- Set `allowPrivilegeEscalation: false`
- Never use `hostNetwork`, `hostPID`, or `hostIPC`

## Resource Management
- Set resource requests AND limits for every container
- Use LimitRange and ResourceQuota per namespace
- Configure HorizontalPodAutoscaler for production workloads
- Set PodDisruptionBudget for high-availability services

## Health Checks
- Configure liveness probes (is the container alive?)
- Configure readiness probes (is it ready for traffic?)
- Use startup probes for slow-starting containers
- Don't use the same endpoint for liveness and readiness

## Networking
- Default deny network policies
- Explicitly allow only required traffic
- Use services for internal communication
- Ingress with TLS termination

## Labels
Required labels: `app`, `version`, `environment`, `team`, `component`
