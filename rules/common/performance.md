# Performance — DevOps Rules

## Infrastructure Performance
- Right-size resources based on actual utilization, not guesswork
- Use auto-scaling for variable workloads
- Cache frequently accessed data (Redis, CDN)
- Optimize database queries before scaling hardware
- Use connection pooling for database connections

## Pipeline Performance
- Cache dependencies between pipeline runs
- Parallelize independent stages
- Use incremental builds when possible
- Optimize Docker builds with layer caching
- Use smaller, purpose-built base images

## Monitoring Performance
- Set SLOs before optimization (know your targets)
- Monitor p50, p95, p99 latencies (not averages)
- Alert on trends, not individual spikes
- Profile before optimizing (measure, don't guess)
