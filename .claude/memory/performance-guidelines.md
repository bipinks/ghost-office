# Performance Guidelines — ERP Platform

## Performance Targets

### API Response Times
| Operation | p50 | p95 | p99 |
|-----------|-----|-----|-----|
| List endpoints (paginated) | < 100ms | < 300ms | < 500ms |
| Single resource GET | < 50ms | < 150ms | < 300ms |
| Create/Update (simple) | < 200ms | < 500ms | < 1s |
| Create/Update (complex, e.g., invoice with items) | < 500ms | < 1s | < 2s |
| Report generation | < 2s | < 10s | < 30s |
| Search/filter | < 100ms | < 300ms | < 500ms |
| File upload | < 2s | < 5s | < 10s |

### Frontend Metrics
| Metric | Target |
|--------|--------|
| First Contentful Paint | < 1.5s |
| Largest Contentful Paint | < 2.5s |
| Time to Interactive | < 3.5s |
| Cumulative Layout Shift | < 0.1 |
| Initial bundle (gzipped) | < 200KB |

### Database
| Operation | Target |
|-----------|--------|
| Simple query (indexed) | < 10ms |
| Complex join | < 100ms |
| Report query | < 5s |
| Migration (per table) | < 30s |

## Optimization Rules

### Rule 1: Measure First
- Never optimize without profiling
- Use EXPLAIN ANALYZE for database queries
- Use browser DevTools for frontend performance
- Use APM tools for end-to-end tracing

### Rule 2: Optimize the Right Thing
Priority order:
1. **Algorithm/query optimization** — Fix N+1, add indexes, reduce data
2. **Caching** — Cache computed results, use Redis for hot data
3. **Architecture** — Queue heavy work, use background jobs
4. **Infrastructure** — Scale up/out only after optimizing code

### Rule 3: Cache Strategically

```
Request → Route Cache → Config Cache → Application Cache → Query Cache → Database
```

#### Cache Layers
| Layer | Tool | TTL | Invalidation |
|-------|------|-----|--------------|
| HTTP/CDN | Cloudflare/Nginx | 1 year (static) | Deploy-based versioning |
| Application | Redis | 5-60 min | Event-based (on data change) |
| Query | Redis | 1-5 min | TTL expiry |
| Session | Redis | 2 hours | Logout/timeout |
| Config/Route | File cache | Until cleared | `artisan config:cache` |

### Rule 4: Database Performance

**Indexing Strategy**:
```sql
-- Index every foreign key
CREATE INDEX idx_invoices_customer_id ON invoices(customer_id);

-- Composite index for common queries (most selective first)
CREATE INDEX idx_invoices_branch_status_date ON invoices(branch_id, status, date);

-- Partial index for filtered queries
CREATE INDEX idx_invoices_unpaid ON invoices(branch_id, due_date)
    WHERE status = 'unpaid' AND deleted_at IS NULL;
```

**Query Rules**:
- Always use eager loading for relationships (`with()` in Eloquent)
- Never use `SELECT *` — specify columns
- Use pagination for all list queries (never load all records)
- Use `chunk()` or `cursor()` for batch processing
- Avoid subqueries in WHERE — use JOINs instead
- Use database aggregates instead of PHP array operations

### Rule 5: Frontend Performance

**Bundle Optimization**:
- Code splitting per route (lazy loading)
- Tree shaking for unused imports
- Compress images (WebP format)
- Use SVG for icons
- Lazy load images below the fold

**Rendering**:
- Virtual scrolling for long lists (> 100 items)
- Debounce search inputs (300ms)
- Throttle scroll events (100ms)
- Memoize expensive computed properties
- Use pagination instead of infinite scroll for data tables

### Rule 6: Background Processing

Move to background jobs:
- Report generation (especially PDF)
- Email sending
- Data import/export
- Bulk operations (> 100 records)
- Third-party API calls
- File processing (resize, convert)

## Load Testing

### Scenarios
1. **Normal load**: 50 concurrent users, 10 req/s
2. **Peak load**: 200 concurrent users, 50 req/s
3. **Stress test**: 500 concurrent users, 100 req/s
4. **Soak test**: Normal load for 4 hours (memory leak detection)

### Tools
- **k6** or **Artillery** for HTTP load testing
- **pgbench** for database load testing
- **Lighthouse** for frontend performance audit

## Monitoring Performance

### Key Metrics to Track
- Request latency (p50, p95, p99) per endpoint
- Error rate per endpoint
- Database query time per query type
- Cache hit rate
- Queue depth and processing time
- Memory and CPU utilization per service
- Active database connections

### Alert Thresholds
- API p95 latency > 2x target for 15 minutes → Warning
- API p95 latency > 5x target for 5 minutes → Critical
- Database query > 5 seconds → Warning
- Cache hit rate < 80% → Warning
- Queue depth > 1000 → Warning
