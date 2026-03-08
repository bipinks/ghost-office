---
name: performance-optimization
description: Use when profiling, optimizing, or load testing applications. Covers backend profiling, N+1 query detection, caching strategies, frontend Core Web Vitals, database optimization, load testing with k6, and cost-performance analysis.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Performance Optimization

## 1. Methodology

**Cycle**: Measure -> Identify bottleneck -> Optimize (simplest fix) -> Verify (no regressions).

**Priority order**:
1. Algorithm/query optimization (fix N+1, add indexes, reduce data)
2. Caching (Redis for hot data, computed results)
3. Architecture (queue heavy work, background jobs)
4. Infrastructure (scale up/out only after code is optimized)

One change at a time. Measure each independently.

## 2. Laravel Profiling

```php
// Telescope: flag queries > 50ms
'watchers' => [Watchers\QueryWatcher::class => ['enabled' => true, 'slow' => 50]],

// Strict mode: catch N+1, missing attributes in dev
Model::preventLazyLoading(! app()->isProduction());
Model::preventSilentlyDiscardingAttributes(! app()->isProduction());

// Target: < 10 queries per request, < 50ms total query time
```

Xdebug profiling: `xdebug.mode=profile`, trigger with `XDEBUG_TRIGGER=1`, open cachegrind files in KCacheGrind.

## 3. N+1 Query Fix

```php
// BAD: N+1 -- 1 query for invoices + N for customers
$invoices = Invoice::all();
foreach ($invoices as $inv) { echo $inv->customer->name; }

// GOOD: 2 queries total
$invoices = Invoice::with('customer')->get();
// Nested: with(['customer', 'items.product'])
// Constrained: with(['items' => fn ($q) => $q->select('id', 'invoice_id', 'quantity')])
```

## 4. Database Optimization

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;
-- Look for: Seq Scan (add index), high-row Nested Loop, large Sort, estimate mismatch
```

```sql
-- Index every FK; composite for common filters (most selective first)
CREATE INDEX idx_invoices_branch_status_date ON invoices(branch_id, status, due_date);
-- Partial index for filtered queries
CREATE INDEX idx_invoices_overdue ON invoices(branch_id, due_date)
    WHERE status = 'unpaid' AND deleted_at IS NULL;
-- Covering index to avoid table lookups
CREATE INDEX idx_invoices_list ON invoices(branch_id, status, due_date) INCLUDE (invoice_number, total_amount);
```

```php
// Use JOIN instead of subquery in WHERE
// Use DB aggregates instead of PHP: ->count() not ->get()->count()
// Denormalize computed totals updated via model events
```

## 5. Caching Strategy

```
User -> CDN (static, 1yr) -> Application cache (Redis, 5-60min, event-invalidated) -> Query cache (1-5min, TTL) -> DB
```

```php
$stats = Cache::remember("dashboard:branch:{$branchId}", now()->addMinutes(15),
    fn () => $this->computeDashboardStats($branchId));

// Tags for group invalidation
$customers = Cache::tags(["branch:{$branchId}", 'customers'])
    ->remember("customers:list:{$page}", now()->addMinutes(10), fn () => Customer::paginate(25));
// Invalidate on write
Cache::tags(["branch:{$branchId}", 'customers'])->flush();
```

**Rules**: Event-based invalidation for write-sensitive data. TTL for stale-tolerant data. Always scope keys to tenant. Test invalidation paths.

## 6. Frontend Performance (Core Web Vitals)

| Metric | Good | Poor |
|--------|------|------|
| LCP | <2.5s | >4s |
| FID / INP | <100ms | >300ms |
| CLS | <0.1 | >0.25 |

### Code Splitting
```typescript
// Route-based (Vue Router)
{ path: '/invoices', component: () => import('@/views/Invoices.vue') }

// Tree shaking: import debounce from 'lodash/debounce' not import _ from 'lodash'
// Direct imports: import Button from '@/components/Button.vue' not from barrel index
```

### Bundle Analysis
```typescript
// vite.config.ts
import { visualizer } from 'rollup-plugin-visualizer';
export default defineConfig({
  plugins: [visualizer({ filename: 'dist/bundle-stats.html', gzipSize: true })],
  build: { rollupOptions: { output: { manualChunks: { vendor: ['vue', 'vue-router', 'pinia'] } } } },
});
```

### Images
Use `<picture>` with AVIF/WebP fallback. `loading="lazy"` for below-fold. `srcset` for responsive sizes.

## 7. API Performance

```nginx
# Nginx gzip
gzip on; gzip_types application/json text/plain application/javascript text/css; gzip_min_length 256;
```

- Sparse fieldsets: allow `?fields=id,invoice_number,total`
- Cursor pagination over offset (avoids OFFSET degradation)
- Batch endpoints to reduce round trips

## 8. Queue Optimization

```php
// BAD: single job processes 10K records
Invoice::unpaid()->each(fn ($inv) => $this->process($inv));
// GOOD: chunk into smaller jobs
Invoice::unpaid()->chunkById(100, fn ($inv) => ProcessChunk::dispatch($inv->pluck('id')->toArray()));

// Priority queues: php artisan queue:work --queue=critical,emails,default,reports
// Rate limiting jobs
public function middleware(): array { return [new RateLimited('external-api')]; }
```

## 9. Load Testing (k6)

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 }, { duration: '3m', target: 50 },
    { duration: '1m', target: 200 }, { duration: '3m', target: 200 },
    { duration: '1m', target: 0 },
  ],
  thresholds: { http_req_duration: ['p(95)<300', 'p(99)<500'], http_req_failed: ['rate<0.01'] },
};

export default function () {
  const params = { headers: { Authorization: `Bearer ${__ENV.API_TOKEN}`, Accept: 'application/json' } };
  check(http.get(`${__ENV.BASE_URL}/api/v1/invoices?per_page=25`, params), {
    'status 200': (r) => r.status === 200, 'latency < 300ms': (r) => r.timings.duration < 300,
  });
  sleep(1);
}
```

## 10. Memory & Cost

```php
// Track peak memory per request
$peakMB = round(memory_get_peak_usage(true) / 1024 / 1024, 2);
if ($peakMB > 64) Log::warning("High memory: {$peakMB}MB", ['url' => $request->fullUrl()]);

// Use cursor() for large result sets (constant memory)
Invoice::where('branch_id', $branchId)->cursor()->each(fn ($inv) => process($inv));
```

### Cost Savings
| Strategy | Savings | Commitment |
|----------|---------|-----------|
| Right-sizing | 10-30% | None |
| Reserved Instances | 30-60% | 1-3yr |
| Spot Instances | 60-90% | None (fault-tolerant) |
| ARM instances | 20-40% | None |
| Auto-scaling | 20-40% | None |

Decision: Avg CPU <20% over 7d -> downsize. >80% -> upsize or auto-scale.

## 11. Performance Budget & Review

```json
{ "api": { "list_p95_ms": 300, "get_p95_ms": 150, "create_p95_ms": 500 },
  "frontend": { "initial_bundle_kb": 200, "lcp_ms": 2500, "cls": 0.1 },
  "database": { "simple_query_ms": 10, "complex_join_ms": 100 } }
```

- **Every PR**: Bundle size check, query count in tests
- **Weekly**: p95 latency trends per endpoint
- **Monthly**: Cost-performance review, right-sizing audit
- **Quarterly**: Load test at 2x projected peak
