---
name: gitops-patterns
description: Use when implementing GitOps workflows for continuous delivery. Covers ArgoCD application definitions, Flux CD setup, repository structure (app-of-apps), environment promotion via Git, image update automation, and drift reconciliation.
user-invocable: false
allowed-tools: ["Read", "Write", "Grep"]
---

# GitOps Patterns

## ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/k8s-manifests
    targetRevision: main
    path: apps/web-app/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        maxDuration: 3m0s
        factor: 2
```

## Repository Structure
```
k8s-manifests/
├── apps/
│   ├── web-app/
│   │   ├── base/
│   │   │   ├── kustomization.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── ingress.yaml
│   │   └── overlays/
│   │       ├── dev/
│   │       │   └── kustomization.yaml
│   │       ├── staging/
│   │       │   └── kustomization.yaml
│   │       └── production/
│   │           └── kustomization.yaml
│   └── api-service/
├── infrastructure/
│   ├── cert-manager/
│   ├── ingress-nginx/
│   └── monitoring/
└── projects/
    └── default.yaml
```

## Best Practices
1. **Single source of truth** — Git is the only source for desired state
2. **Declarative** — Describe desired state, not imperative steps
3. **Pull-based** — ArgoCD/Flux pulls changes, don't push to clusters
4. **Separation** — App code repo separate from manifests repo
5. **Kustomize overlays** — Use base + overlays for environment differences
6. **Sealed Secrets** — Encrypt secrets in Git with Sealed Secrets or SOPS
7. **Image automation** — Auto-update image tags on new builds
8. **Drift detection** — Auto-heal configuration drift
