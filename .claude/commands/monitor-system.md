---
name: monitor-system
description: Check system health, review metrics, and identify issues
argument-hint: "[service name or 'all' for full system check]"
---

## Monitor System

Check system health for: $ARGUMENTS

### Agents Involved
- **monitoring-agent** — Health checks and metrics review
- **performance-agent** — Performance analysis
- **devops-engineer** — Infrastructure status

### Workflow

1. **monitoring-agent**: System health check
   - Check all service health endpoints
   - Review error rates (last 1h, 24h)
   - Check SLO compliance
   - Review active alerts and incidents

2. **performance-agent**: Performance review
   - API latency percentiles (p50, p95, p99)
   - Database query performance
   - Resource utilization (CPU, memory, disk)
   - Queue backlog and processing rate

3. **devops-engineer**: Infrastructure status
   - Server/container status
   - Disk space and growth trends
   - SSL certificate expiry check
   - Backup status verification

4. **Generate Health Report**
   - Overall system status (healthy/degraded/critical)
   - Service-by-service breakdown
   - Metrics summary with trends
   - Active issues and recommended actions

### Output
System health report with metrics, trends, and actionable recommendations.
