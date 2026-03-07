---
name: performance-optimization
description: Use when profiling, optimizing, or load testing applications. Covers backend profiling, N+1 query detection, caching strategies, frontend Core Web Vitals, database optimization, load testing with k6, and cost-performance analysis.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Performance Optimization

## 1. Profiling Methodology

Follow a disciplined cycle for every optimization effort:

1. **Measure** -- Establish a baseline with real data. Never guess.
2. **Identify** -- Find the single largest bottleneck (CPU, I/O, query, network).
3. **Optimize** -- Apply the simplest fix that addresses the root cause.
4. **Verify** -- Measure again against the baseline. Confirm no regressions.

Priority order for fixes:
1. Algorithm / query optimization (fix N+1, add indexes, reduce data)
2. Caching (cache computed results, use Redis for hot data)
3. Architecture (queue heavy work, use background jobs)
4. Infrastructure (scale up/out only after code is optimized)

Rule: one change at a time. Measure each independently.

---

## 2. Laravel Profiling

### Laravel Telescope (Development)
```php
// config/telescope.php -- enable specific watchers
'watchers' => [
    Watchers\QueryWatcher::class => [
        'enabled' => true,
        'slow' => 50, // flag queries slower than 50ms
    ],
    Watchers\RequestWatcher::class => ['enabled' => true],
    Watchers\CacheWatcher::class  => ['enabled' => true],
    Watchers\JobWatcher::class    => ['enabled' => true],
],
```

### Laravel Debugbar (Development)
```php
// .env
DEBUGBAR_ENABLED=true

// Check query count and time per request in the toolbar.
// Target: < 10 queries per request, < 50ms total query time.
```

### Clockwork (Development + Staging)
```php
// config/clockwork.php
'enable' => env('CLOCKWORK_ENABLE', false),
'storage' => 'sql',
'features' => [
    'performance' => ['client_metrics' => true],
    'database'    => ['detect_duplicate_queries' => true],
],
```

### Xdebug Profiling (Deep Analysis)
```ini
; php.ini -- enable on demand only
xdebug.mode=profile
xdebug.output_dir=/tmp/xdebug
xdebug.start_with_request=trigger
; Use XDEBUG_TRIGGER=1 query param or cookie to activate.
; Open cachegrind files with KCacheGrind or QCacheGrind.
```

---

## 3. N+1 Query Detection

### The Problem
```php
// BAD: N+1 -- 1 query for invoices + N queries for customers
$invoices = Invoice::all();
foreach ($invoices as $invoice) {
    echo $invoice->customer->name; // separate query per invoice
}
```

### The Fix: Eager Loading
```php
// GOOD: 2 queries total (invoices + customers)
$invoices = Invoice::with('customer')->get();

// Nested eager loading
$invoices = Invoice::with(['customer', 'items.product'])->get();

// Constrained eager loading
$invoices = Invoice::with(['items' => function ($query) {
    $query->where('quantity', '>', 0)->select('id', 'invoice_id', 'product_id', 'quantity');
}])->get();
```

### Laravel Strict Mode (Prevent in Development)
```php
// app/Providers/AppServiceProvider.php
public function boot(): void
{
    Model::preventLazyLoading(! app()->isProduction());
    Model::preventSilentlyDiscardingAttributes(! app()->isProduction());
    Model::preventAccessingMissingAttributes(! app()->isProduction());
}
```

---

## 4. Database Query Optimization

### EXPLAIN ANALYZE
```sql
-- Always run EXPLAIN ANALYZE on slow queries
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT i.id, i.invoice_number, c.name AS customer_name
FROM invoices i
JOIN customers c ON c.id = i.customer_id
WHERE i.branch_id = 5
  AND i.status = 'unpaid'
  AND i.due_date < CURRENT_DATE
ORDER BY i.due_date ASC
LIMIT 25;

-- Look for: Seq Scan (missing index), Nested Loop with high rows,
-- Sort with high memory, Hash Join on large sets.
```

### Index Strategy
```sql
-- Every foreign key gets an index
CREATE INDEX idx_invoices_customer_id ON invoices(customer_id);

-- Composite index for common filter combinations (most selective first)
CREATE INDEX idx_invoices_branch_status_date
    ON invoices(branch_id, status, due_date);

-- Partial index for filtered queries
CREATE INDEX idx_invoices_overdue
    ON invoices(branch_id, due_date)
    WHERE status = 'unpaid' AND deleted_at IS NULL;

-- Covering index to avoid table lookups
CREATE INDEX idx_invoices_list
    ON invoices(branch_id, status, due_date)
    INCLUDE (invoice_number, total_amount);
```

### Query Rewriting
```php
// BAD: subquery in WHERE
Invoice::whereIn('customer_id', function ($q) {
    $q->select('id')->from('customers')->where('tier', 'gold');
})->get();

// GOOD: JOIN instead
Invoice::join('customers', 'customers.id', '=', 'invoices.customer_id')
    ->where('customers.tier', 'gold')
    ->select('invoices.*')
    ->get();

// BAD: counting in PHP
$count = Invoice::where('branch_id', $branchId)->get()->count();

// GOOD: aggregate in database
$count = Invoice::where('branch_id', $branchId)->count();
```

### Denormalization (When Justified)
```php
// Store computed total on invoice instead of SUM on every read
// Update via model events
protected static function booted(): void
{
    static::saved(function (InvoiceItem $item) {
        $item->invoice->update([
            'total_amount' => $item->invoice->items()->sum(
                DB::raw('quantity * unit_price')
            ),
        ]);
    });
}
```

---

## 5. Caching Strategy

### Cache Layers
```
User -> CDN (static assets, 1yr TTL)
     -> Full-page cache (public pages, 5-60min)
     -> Application cache (Redis, 5-60min, event-invalidated)
     -> Query cache (Redis, 1-5min, TTL-based)
     -> Database
```

### Application Cache (Redis)
```php
// Cache expensive computation
$dashboardStats = Cache::remember(
    "dashboard:branch:{$branchId}",
    now()->addMinutes(15),
    fn () => $this->computeDashboardStats($branchId)
);

// Cache with tags for group invalidation
$customers = Cache::tags(["branch:{$branchId}", 'customers'])
    ->remember("customers:list:{$page}", now()->addMinutes(10), function () {
        return Customer::paginate(25);
    });

// Invalidate on write
public function store(CreateCustomerRequest $request): CustomerResource
{
    $customer = $this->service->create($request->validated());
    Cache::tags(["branch:{$customer->branch_id}", 'customers'])->flush();
    return new CustomerResource($customer);
}
```

### Cache Warming
```php
// app/Console/Commands/WarmCache.php
class WarmCache extends Command
{
    protected $signature = 'cache:warm';

    public function handle(): void
    {
        Branch::each(function (Branch $branch) {
            Cache::remember("dashboard:branch:{$branch->id}", now()->addMinutes(30),
                fn () => (new DashboardService)->computeStats($branch->id)
            );
        });
        $this->info('Cache warmed for all branches.');
    }
}
// Schedule: $schedule->command('cache:warm')->hourly();
```

### Cache Invalidation Rules
- Use event-based invalidation for data that changes on writes.
- Use TTL-based expiry for data that can tolerate staleness.
- Never cache user-specific data without scoping the key to the user.
- Test invalidation paths as thoroughly as caching paths.

---

## 6. Frontend Performance (Core Web Vitals)

### Targets
| Metric | Good | Needs Work | Poor |
|--------|------|------------|------|
| LCP (Largest Contentful Paint) | < 2.5s | 2.5-4s | > 4s |
| FID (First Input Delay) / INP | < 100ms | 100-300ms | > 300ms |
| CLS (Cumulative Layout Shift) | < 0.1 | 0.1-0.25 | > 0.25 |

### Lighthouse CI
```bash
# Run Lighthouse in CI
npm install -g @lhci/cli
lhci autorun --config=lighthouserc.json
```

```json
// lighthouserc.json
{
  "ci": {
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "first-contentful-paint": ["warn", { "maxNumericValue": 1500 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "total-byte-weight": ["warn", { "maxNumericValue": 500000 }]
      }
    }
  }
}
```

### Bundle Analysis (Vite/Webpack)
```typescript
// vite.config.ts
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  plugins: [
    visualizer({ filename: 'dist/bundle-stats.html', gzipSize: true }),
  ],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia'],
          charts: ['chart.js'],
        },
      },
    },
  },
});
```

---

## 7. Code Splitting

### Route-Based Splitting (Vue Router)
```typescript
// router/index.ts
const routes = [
  { path: '/', component: () => import('@/views/Dashboard.vue') },
  { path: '/invoices', component: () => import('@/views/Invoices.vue') },
  { path: '/reports', component: () => import('@/views/Reports.vue') },
];
```

### Dynamic Imports with Prefetching
```typescript
// Prefetch on hover for perceived speed
const InvoiceForm = defineAsyncComponent({
  loader: () => import('@/components/InvoiceForm.vue'),
  loadingComponent: LoadingSpinner,
  delay: 200,
});

// Webpack magic comment for prefetch hint
const ReportBuilder = () => import(/* webpackPrefetch: true */ '@/views/ReportBuilder.vue');
```

### Tree Shaking
```typescript
// BAD: imports entire library
import _ from 'lodash';
_.debounce(fn, 300);

// GOOD: import only what you need
import debounce from 'lodash/debounce';
debounce(fn, 300);

// BAD: barrel exports prevent tree shaking
import { Button, Input, Modal } from '@/components';

// GOOD: direct imports
import Button from '@/components/Button.vue';
```

---

## 8. Image Optimization

### Format Selection
```html
<!-- Use <picture> for modern format fallback -->
<picture>
  <source srcset="/img/hero.avif" type="image/avif" />
  <source srcset="/img/hero.webp" type="image/webp" />
  <img src="/img/hero.jpg" alt="Hero" width="1200" height="600" loading="lazy" />
</picture>
```

### Responsive Images
```html
<img
  srcset="/img/product-400.webp 400w, /img/product-800.webp 800w, /img/product-1200.webp 1200w"
  sizes="(max-width: 600px) 400px, (max-width: 1024px) 800px, 1200px"
  src="/img/product-800.webp"
  alt="Product"
  loading="lazy"
  decoding="async"
/>
```

### Build-Time Optimization
```bash
# Convert to WebP with quality 80
cwebp -q 80 input.png -o output.webp

# Generate responsive sizes
convert input.jpg -resize 400x  output-400.jpg
convert input.jpg -resize 800x  output-800.jpg
convert input.jpg -resize 1200x output-1200.jpg
```

---

## 9. API Performance

### Response Compression
```php
// Nginx gzip (preferred over PHP-level compression)
// nginx.conf
gzip on;
gzip_types application/json text/plain application/javascript text/css;
gzip_min_length 256;
gzip_comp_level 5;
```

### Field Selection (Sparse Fieldsets)
```php
// Controller: allow clients to request only needed fields
public function index(Request $request): AnonymousResourceCollection
{
    $fields = $request->input('fields', ['id', 'invoice_number', 'total_amount', 'status']);
    $invoices = Invoice::select($fields)
        ->where('branch_id', auth()->user()->branch_id)
        ->cursorPaginate(25);

    return InvoiceResource::collection($invoices);
}
```

### Cursor Pagination (Efficient for Large Datasets)
```php
// Cursor-based pagination avoids OFFSET performance degradation
$invoices = Invoice::where('branch_id', $branchId)
    ->orderBy('id')
    ->cursorPaginate(25);
// Returns: { data: [...], meta: { next_cursor: "...", prev_cursor: "..." } }
```

### Batch Endpoints
```php
// Accept multiple operations in a single request to reduce round trips
Route::post('/api/v1/batch', function (Request $request) {
    $results = collect($request->input('operations'))->map(function ($op) {
        return app()->call($op['action'], $op['params']);
    });
    return response()->json(['data' => $results]);
});
```

---

## 10. Queue Optimization

### Job Chunking
```php
// BAD: single job processes 10,000 records
class ProcessAllInvoices implements ShouldQueue
{
    public function handle(): void
    {
        Invoice::unpaid()->each(fn ($inv) => $this->process($inv)); // memory spike
    }
}

// GOOD: chunk into smaller jobs
class DispatchInvoiceProcessing implements ShouldQueue
{
    public function handle(): void
    {
        Invoice::unpaid()->chunkById(100, function ($invoices) {
            ProcessInvoiceChunk::dispatch($invoices->pluck('id')->toArray());
        });
    }
}
```

### Priority Queues
```php
// config/queue.php -- define priority queues
'connections' => [
    'redis' => [
        'queue' => 'default',
    ],
],

// Dispatch to specific queues
SendInvoiceEmail::dispatch($invoice)->onQueue('emails');
GenerateReport::dispatch($params)->onQueue('reports');

// Worker processes high-priority first
// php artisan queue:work --queue=critical,emails,default,reports
```

### Rate Limiting Jobs
```php
use Illuminate\Queue\Middleware\RateLimited;

class CallExternalApi implements ShouldQueue
{
    public function middleware(): array
    {
        return [new RateLimited('external-api')]; // defined in AppServiceProvider
    }
}

// AppServiceProvider::boot()
RateLimiter::for('external-api', fn () => Limit::perMinute(60));
```

---

## 11. Load Testing with k6

### Basic Test Script
```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // ramp up
    { duration: '3m', target: 50 },   // steady state
    { duration: '1m', target: 200 },  // peak
    { duration: '3m', target: 200 },  // hold peak
    { duration: '1m', target: 0 },    // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<300', 'p(99)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';

export default function () {
  const token = __ENV.API_TOKEN;
  const params = { headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' } };

  // List invoices
  const listRes = http.get(`${BASE_URL}/api/v1/invoices?per_page=25`, params);
  check(listRes, {
    'list status 200': (r) => r.status === 200,
    'list latency < 300ms': (r) => r.timings.duration < 300,
  });

  sleep(1);

  // Get single invoice
  const getRes = http.get(`${BASE_URL}/api/v1/invoices/1`, params);
  check(getRes, {
    'get status 200': (r) => r.status === 200,
    'get latency < 150ms': (r) => r.timings.duration < 150,
  });

  sleep(1);
}
```

### CI Integration
```yaml
# .github/workflows/load-test.yml
- name: Run k6 load test
  uses: grafana/k6-action@v0.3.1
  with:
    filename: tests/load/load-test.js
  env:
    BASE_URL: http://localhost:8000
    API_TOKEN: ${{ secrets.TEST_API_TOKEN }}
```

---

## 12. Memory Profiling

### PHP Memory Limits
```php
// Track peak memory per request (middleware)
class MemoryUsageMiddleware
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);
        $peakMB = round(memory_get_peak_usage(true) / 1024 / 1024, 2);

        if ($peakMB > 64) {
            Log::warning("High memory usage: {$peakMB}MB", [
                'url' => $request->fullUrl(),
                'method' => $request->method(),
            ]);
        }

        return $response;
    }
}

// Use cursor() instead of get() for large result sets
Invoice::where('branch_id', $branchId)->cursor()->each(function ($invoice) {
    // processes one record at a time, constant memory
});
```

### Node.js Memory Leaks
```typescript
// Detect leaks with --inspect and Chrome DevTools
// node --inspect server.js
// Open chrome://inspect, take heap snapshots, compare allocations.

// Common leak patterns:
// 1. Growing event listener lists -- always removeListener on cleanup
// 2. Closures holding references to large objects
// 3. Unbounded caches without eviction -- use LRU cache with max size

import { LRUCache } from 'lru-cache';
const cache = new LRUCache<string, object>({ max: 1000, ttl: 1000 * 60 * 5 });
```

---

## 13. Cost-Performance Analysis

### Right-Sizing Compute
```bash
# Check average CPU over 7 days (AWS)
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --start-time $(date -d '7 days ago' --iso-8601=seconds) \
  --end-time $(date --iso-8601=seconds) \
  --period 3600 --statistics Average

# Decision thresholds:
# Average CPU < 20% over 7 days  -> downsize instance
# Average CPU > 80% over 7 days  -> upsize or add auto-scaling
# Memory < 30% utilized          -> switch to compute-optimized
```

### Savings Strategies
| Strategy | Typical Savings | Commitment | Best For |
|----------|----------------|------------|----------|
| Right-sizing | 10-30% | None | All workloads |
| Reserved Instances | 30-60% | 1-3 years | Steady-state |
| Savings Plans | 30-50% | 1-3 years | Flexible compute |
| Spot Instances | 60-90% | None | Fault-tolerant jobs |
| ARM instances | 20-40% | None | Compatible workloads |
| Auto-scaling | 20-40% | None | Variable traffic |

### Auto-Scaling Thresholds
```yaml
# ECS auto-scaling policy
ScalingPolicy:
  TargetTrackingScaling:
    TargetValue: 60.0                # target CPU %
    ScaleOutCooldown: 60             # seconds before next scale-out
    ScaleInCooldown: 300             # seconds before scale-in (conservative)
    PredefinedMetricSpecification:
      PredefinedMetricType: ECSServiceAverageCPUUtilization
  MinCapacity: 2
  MaxCapacity: 10
```

### Monthly Cost Review Checklist
- [ ] Identify instances with avg CPU below 20%
- [ ] Check for unattached EBS volumes and idle load balancers
- [ ] Review S3 storage tiers (move cold data to Intelligent-Tiering)
- [ ] Validate reserved instance coverage matches actual usage
- [ ] Audit unused Elastic IPs (each unused IP costs $3.65/month)
- [ ] Verify dev/staging environments scale down outside business hours

---

## 14. Performance Budget

### Setting Targets
```json
// performance-budget.json
{
  "api": {
    "list_p95_ms": 300,
    "get_p95_ms": 150,
    "create_p95_ms": 500,
    "report_p95_ms": 10000,
    "error_rate_max": 0.01
  },
  "frontend": {
    "initial_bundle_kb": 200,
    "total_bundle_kb": 500,
    "lcp_ms": 2500,
    "fid_ms": 100,
    "cls": 0.1
  },
  "database": {
    "simple_query_ms": 10,
    "complex_join_ms": 100,
    "report_query_ms": 5000,
    "connection_pool_pct": 70
  }
}
```

### CI Enforcement (Bundle Size Gate)
```yaml
# .github/workflows/ci.yml
- name: Check bundle size
  run: |
    npm run build
    INITIAL_SIZE=$(stat -c%s dist/assets/index-*.js | head -1)
    INITIAL_KB=$((INITIAL_SIZE / 1024))
    if [ "$INITIAL_KB" -gt 200 ]; then
      echo "FAIL: Initial bundle ${INITIAL_KB}KB exceeds 200KB budget"
      exit 1
    fi
    echo "PASS: Initial bundle ${INITIAL_KB}KB within budget"
```

### Monitoring Regression
```typescript
// Track performance metrics over time and alert on degradation
// Use Prometheus histogram for request duration
import { Histogram } from 'prom-client';

const httpDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5, 10],
});

// Alert rule: p95 > 2x target for 15 minutes = warning
// Alert rule: p95 > 5x target for 5 minutes = critical
```

### Performance Review Cadence
- **Every PR**: Bundle size check, query count check in tests.
- **Weekly**: Review p95 latency trends per endpoint.
- **Monthly**: Full cost-performance review, right-sizing audit.
- **Quarterly**: Load test at 2x projected peak traffic.
