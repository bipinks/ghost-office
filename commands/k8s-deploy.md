---
name: k8s-deploy
description: Deploy application to Kubernetes cluster
argument-hint: "[app name or namespace]"
disable-model-invocation: true
---

# /k8s-deploy — Kubernetes Deployment

Deploy $ARGUMENTS to Kubernetes using the **deployment-manager** agent with the **kubernetes-patterns** skill:

1. Review or generate K8s manifests (Deployment, Service, Ingress)
2. Set resource limits, health checks, security context
3. Configure HPA and PodDisruptionBudget
4. Apply with rollout strategy
5. Verify deployment health

## Usage
```
/k8s-deploy                          # Review and deploy
/k8s-deploy "create manifests"       # Generate from scratch
/k8s-deploy "rollback"               # Rollback to previous
```
