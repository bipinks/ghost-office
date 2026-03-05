---
name: log-management
description: Use when setting up centralized logging, log parsing, or log-based alerting. Covers ELK/OpenSearch stack, CloudWatch Logs, Grafana Loki, structured logging formats (JSON), log rotation, retention policies, and correlation patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Grep"]
---

# Log Management

## Structured Logging Format
```json
{
  "timestamp": "2026-03-05T09:30:00Z",
  "level": "ERROR",
  "service": "api-gateway",
  "trace_id": "abc123def456",
  "span_id": "789ghi",
  "message": "Failed to process payment",
  "error": "Connection timeout to payment-service",
  "context": {
    "user_id": "usr_123",
    "order_id": "ord_456",
    "amount": 99.99
  }
}
```

## ELK Stack (Docker Compose)
```yaml
services:
  elasticsearch:
    image: elasticsearch:8.12.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=true
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"

  logstash:
    image: logstash:8.12.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    depends_on:
      - elasticsearch

  kibana:
    image: kibana:8.12.0
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch

  filebeat:
    image: elastic/filebeat:8.12.0
    volumes:
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
```

## Best Practices
1. **Structured logging** — JSON format with consistent fields
2. **Correlation IDs** — Trace requests across services
3. **Log levels** — Use ERROR, WARN, INFO, DEBUG appropriately
4. **Centralize** — Aggregate all logs to a single platform
5. **Retention** — Define retention by compliance needs (90d typical)
6. **Alerts** — Alert on ERROR rate spikes and specific patterns
7. **Don't log secrets** — Mask PII, credentials, and tokens
8. **Sampling** — Sample debug logs in production for cost control
