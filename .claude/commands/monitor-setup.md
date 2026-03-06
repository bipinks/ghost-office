---
name: monitor-setup
description: Set up monitoring, alerting, and dashboards
argument-hint: "[service or stack to monitor]"
---

# /monitor-setup — Monitoring Setup

Set up monitoring for $ARGUMENTS using the **monitoring-analyst** agent:

1. Design observability stack (metrics, logs, traces)
2. Configure Prometheus/Grafana or Datadog
3. Create dashboards (four golden signals)
4. Set up alert rules with runbook links
5. Define SLOs and error budgets

## Usage
```
/monitor-setup "Prometheus + Grafana for K8s cluster"
/monitor-setup "CloudWatch alerts for ECS services"
/monitor-setup "Create SLOs for the API service"
```
