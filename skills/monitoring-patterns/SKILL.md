---
name: monitoring-patterns
description: Use when setting up observability, alerting, or dashboards. Covers Prometheus scrape configs, Grafana dashboards, Datadog integration, SLO/SLI definition, error budgets, alerting rules, on-call rotation, and the four golden signals.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# Monitoring Patterns

## Prometheus Configuration
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alerts/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'app'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['app:8080']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
```

## Alert Rules
```yaml
groups:
  - name: application
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.instance }}"
          runbook: "https://runbooks.example.com/high-error-rate"

      - alert: HighLatency
        expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "P99 latency above 1s on {{ $labels.instance }}"

      - alert: HighMemoryUsage
        expr: process_resident_memory_bytes / 1024^3 > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Memory usage above 2GB on {{ $labels.instance }}"
```

## Grafana Dashboard (JSON Model)
```json
{
  "title": "Application Overview",
  "panels": [
    {
      "title": "Request Rate",
      "type": "timeseries",
      "targets": [{ "expr": "rate(http_requests_total[5m])" }]
    },
    {
      "title": "Error Rate",
      "type": "timeseries",
      "targets": [{ "expr": "rate(http_requests_total{status=~\"5..\"}[5m])" }]
    },
    {
      "title": "Latency (p50, p95, p99)",
      "type": "timeseries",
      "targets": [
        { "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))", "legendFormat": "p50" },
        { "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))", "legendFormat": "p95" },
        { "expr": "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))", "legendFormat": "p99" }
      ]
    }
  ]
}
```

## Best Practices
1. **Four golden signals** — Monitor latency, traffic, errors, saturation
2. **Percentiles over averages** — Use p50, p95, p99 for latency
3. **Alert on symptoms** — High error rate, not high CPU
4. **Runbook links** — Every alert must link to a runbook
5. **SLO-based alerts** — Alert on error budget burn rate
6. **Dashboard hierarchy** — Overview → Service → Component → Instance
7. **Retention** — 15s resolution for 7d, 1m for 30d, 5m for 1y
8. **Labels** — Consistent labels: service, environment, team, version
