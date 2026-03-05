# CLAUDE.md — Kubernetes Microservices Project

## Project Overview
Microservices architecture on Kubernetes (EKS) with GitOps deployment.

## Architecture
- **Cluster**: EKS with managed node groups (3 AZs)
- **Ingress**: Nginx Ingress Controller with cert-manager
- **Service Mesh**: (optional) Istio for mutual TLS
- **GitOps**: ArgoCD for deployment automation
- **Monitoring**: Prometheus + Grafana stack
- **Logging**: Loki + Promtail

## Services
| Service | Port | Replicas | Description |
|---------|------|----------|-------------|
| api-gateway | 8080 | 3 | API gateway and routing |
| user-service | 8081 | 2 | User management |
| order-service | 8082 | 3 | Order processing |
| payment-service | 8083 | 2 | Payment processing |
| notification-service | 8084 | 1 | Email/SMS notifications |

## Deployment
```bash
# Direct kubectl (dev only)
kubectl apply -k overlays/dev/

# Production (via ArgoCD)
git push origin main  # ArgoCD auto-syncs

# Check rollout status
kubectl rollout status deployment/api-gateway -n production
```

## Namespace Convention
- `development`, `staging`, `production` — Application namespaces
- `monitoring` — Prometheus, Grafana
- `argocd` — ArgoCD
- `cert-manager` — Certificate management
- `ingress-nginx` — Ingress controller
