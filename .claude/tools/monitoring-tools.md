# Monitoring Tools Reference

## Overview
Reference for monitoring and observability tools used by the monitoring-agent and performance-agent.

## Application Health Checks

```bash
# HTTP health endpoint
curl -s https://app.example.com/api/health | jq .

# Expected response
{
  "status": "healthy",
  "database": "connected",
  "redis": "connected",
  "queue": "processing",
  "disk": "ok",
  "uptime": "5d 3h 22m"
}

# Quick health check script
for svc in app api worker; do
  echo -n "$svc: "
  curl -s -o /dev/null -w "%{http_code}" "http://localhost/$svc/health"
  echo
done
```

## Docker Monitoring

```bash
# Container resource usage
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Container health status
docker inspect --format='{{.State.Health.Status}}' <container>

# Container restart count
docker inspect --format='{{.RestartCount}}' <container>

# Docker system disk usage
docker system df
```

## Log Analysis

### Application Logs
```bash
# Search for errors in last hour
docker compose logs --since 1h app | grep -i error

# Count errors by type
docker compose logs --since 24h app | grep -oP '"level":"(error|critical)"' | sort | uniq -c | sort -rn

# Follow logs with filtering
docker compose logs -f app | grep --line-buffered "500\|error\|exception"

# JSON log parsing (if structured logging)
docker compose logs app | jq -r 'select(.level == "error") | "\(.timestamp) \(.message)"'
```

### Nginx Access Logs
```bash
# Top requested URLs
awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head 20

# 5xx errors
awk '$9 >= 500' /var/log/nginx/access.log | tail -20

# Response time analysis (if $request_time is logged)
awk '{print $NF}' /var/log/nginx/access.log | sort -n | tail -20

# Requests per minute
awk '{print $4}' /var/log/nginx/access.log | cut -d: -f1-2 | sort | uniq -c | tail -10
```

## Database Monitoring

```sql
-- Active connections by state
SELECT state, count(*) FROM pg_stat_activity GROUP BY state;

-- Long running queries (> 30 seconds)
SELECT pid, now() - query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND now() - query_start > interval '30 seconds';

-- Table bloat check
SELECT schemaname, tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total,
    n_dead_tup, n_live_tup,
    ROUND(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) AS dead_pct
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC LIMIT 10;

-- Replication lag (if applicable)
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS byte_lag
FROM pg_stat_replication;
```

## Queue Monitoring

```bash
# Laravel Horizon dashboard (if installed)
# Visit: https://app.example.com/horizon

# Queue depth
redis-cli LLEN queues:default
redis-cli LLEN queues:high
redis-cli LLEN queues:low

# Failed jobs
php artisan queue:failed --format=json | jq length

# Worker status
docker compose ps worker
docker compose logs --tail=20 worker
```

## Performance Profiling

### Backend
```bash
# Laravel Telescope (if installed)
# Visit: https://app.example.com/telescope

# Laravel Debugbar (dev only)
# Enabled via .env: DEBUGBAR_ENABLED=true

# Xdebug profiling
# Set in php.ini: xdebug.mode=profile
# Analyze with: qcachegrind or webgrind
```

### Frontend
```bash
# Lighthouse audit
npx lighthouse https://app.example.com --output json --output html

# Bundle analysis
npx vite-bundle-visualizer
```

## Alerting Integration

### Slack Webhook
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"[ALERT] API error rate > 5%"}' \
  $SLACK_WEBHOOK_URL
```

### PagerDuty
```bash
curl -X POST https://events.pagerduty.com/v2/enqueue \
  -H 'Content-Type: application/json' \
  -d '{
    "routing_key": "'$PD_ROUTING_KEY'",
    "event_action": "trigger",
    "payload": {
      "summary": "API error rate critical",
      "severity": "critical",
      "source": "monitoring-agent"
    }
  }'
```

## Metrics Collection

### Prometheus (if configured)
```
# Key metrics to scrape
http_request_duration_seconds{quantile="0.95"}
http_requests_total{status="5xx"}
process_cpu_seconds_total
process_resident_memory_bytes
db_query_duration_seconds
queue_jobs_processed_total
queue_jobs_failed_total
```

### CloudWatch (if on AWS)
```bash
# Get metric data
aws cloudwatch get-metric-statistics \
  --namespace "ERP/Application" \
  --metric-name "RequestLatency" \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average p95
```
