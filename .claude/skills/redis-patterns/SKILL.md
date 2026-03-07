---
name: redis-patterns
description: Use when implementing caching, queues, or real-time features with Redis. Covers caching strategies, Laravel queue configuration, pub/sub, rate limiting, session management, data structures, and Redis cluster patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Redis Patterns

Comprehensive patterns for Redis in multi-tenant Laravel applications. Covers caching, queues, pub/sub, rate limiting, sessions, and cluster operations.

---

## 1. Caching Strategies

### Cache-Aside (Lazy Loading)
```php
// Read: check cache first, then database
$product = Cache::remember("product:{$id}", 600, function () use ($id) {
    return Product::with('category')->findOrFail($id);
});
```

### Write-Through
```php
// Write: update database and cache atomically
DB::transaction(function () use ($data, $id) {
    $product = Product::findOrFail($id);
    $product->update($data);
    Cache::put("product:{$id}", $product, 600);
});
```

### Write-Behind (Queue-Based)
```php
// Write to cache immediately, persist to DB via queue
Cache::put("product:{$id}", $data, 600);
dispatch(new PersistProductToDatabase($id, $data));
```

### TTL Management
```php
// Short TTL for volatile data (1-5 min)
Cache::put('dashboard:stats', $stats, 60);

// Medium TTL for semi-stable data (5-60 min)
Cache::put("customer:{$id}", $customer, 1800);

// Long TTL for stable reference data (1-24 hours)
Cache::put('chart_of_accounts', $accounts, 86400);
```

---

## 2. Laravel Cache Integration

### Cache Tags (Group Invalidation)
```php
// Store with tags
Cache::tags(['products', "branch:{$branchId}"])->put(
    "product:{$id}", $product, 600
);

// Flush all products for a branch
Cache::tags(["branch:{$branchId}", 'products'])->flush();
```

### Cache Locks (Preventing Stampede)
```php
$lock = Cache::lock("generate-report:{$reportId}", 30);

if ($lock->get()) {
    try {
        $report = $this->generateExpensiveReport($reportId);
        Cache::put("report:{$reportId}", $report, 3600);
    } finally {
        $lock->release();
    }
}
```

### Atomic Operations
```php
// Increment counters without race conditions
Cache::increment('api:requests:count');
Cache::decrement("stock:{$productId}", $quantity);

// Remember with lock (stampede protection)
Cache::flexible("product:{$id}", [300, 600], function () use ($id) {
    return Product::findOrFail($id);
});
```

---

## 3. Queue Management

### Laravel Horizon Configuration
```php
// config/horizon.php
'environments' => [
    'production' => [
        'supervisor-default' => [
            'connection' => 'redis',
            'queue' => ['default', 'invoices', 'reports', 'notifications'],
            'balance' => 'auto',
            'minProcesses' => 1,
            'maxProcesses' => 10,
            'balanceMaxShift' => 1,
            'balanceCooldown' => 3,
            'tries' => 3,
            'timeout' => 300,
        ],
        'supervisor-long' => [
            'connection' => 'redis',
            'queue' => ['long-running'],
            'balance' => 'simple',
            'processes' => 3,
            'tries' => 1,
            'timeout' => 1800,
        ],
    ],
],
```

### Job Configuration with Retry and Backoff
```php
class GenerateInvoicePdf implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $maxExceptions = 2;
    public int $timeout = 120;
    public array $backoff = [30, 60, 120]; // exponential backoff

    public function handle(): void
    {
        // Business logic
    }

    public function failed(Throwable $exception): void
    {
        Log::error('Invoice PDF generation failed', [
            'invoice_id' => $this->invoice->id,
            'branch_id' => $this->invoice->branch_id,
            'error' => $exception->getMessage(),
        ]);
    }
}
```

### Job Batches
```php
$batch = Bus::batch([
    new ProcessInvoice($invoice1),
    new ProcessInvoice($invoice2),
    new ProcessInvoice($invoice3),
])->then(function (Batch $batch) {
    Log::info('All invoices processed', ['batch_id' => $batch->id]);
})->catch(function (Batch $batch, Throwable $e) {
    Log::error('Batch failed', ['batch_id' => $batch->id]);
})->onQueue('invoices')->dispatch();
```

### Queue Rate Limiting
```php
// In job handle()
Redis::throttle('api-external')->allow(10)->every(60)->then(function () {
    // Call external API (max 10/minute)
}, function () {
    return $this->release(30); // retry in 30s
});
```

---

## 4. Data Structures

### Strings -- Simple key-value, counters, flags
```bash
SET user:1001:last_login "2026-03-07T10:00:00Z"
INCR page:views:homepage
SETEX email:verify:token:abc123 3600 "user@example.com"
```

### Hashes -- Object storage, partial updates
```bash
HSET product:5001 name "Widget" price "29.99" stock "150"
HINCRBY product:5001 stock -1
HGET product:5001 price
```

### Lists -- Queues, recent items, activity feeds
```bash
LPUSH notifications:user:1001 '{"type":"invoice","id":42}'
LTRIM notifications:user:1001 0 99   # keep last 100
LRANGE notifications:user:1001 0 9   # get latest 10
```

### Sets -- Unique collections, tags, membership
```bash
SADD online:users "user:1001" "user:1002"
SISMEMBER online:users "user:1001"
SCARD online:users                    # count online users
```

### Sorted Sets -- Leaderboards, time-series, priority queues
```bash
ZADD sales:leaderboard 15000 "branch:dubai" 12000 "branch:abudhabi"
ZREVRANGE sales:leaderboard 0 9 WITHSCORES   # top 10 branches
ZRANGEBYSCORE overdue:invoices 0 1709827200   # invoices overdue before timestamp
```

---

## 5. Session Management

### Redis Sessions in Laravel
```php
// .env
SESSION_DRIVER=redis
SESSION_CONNECTION=session
REDIS_SESSION_DB=2

// config/database.php — dedicated session connection
'session' => [
    'url' => env('REDIS_URL'),
    'host' => env('REDIS_HOST', '127.0.0.1'),
    'password' => env('REDIS_PASSWORD'),
    'port' => env('REDIS_PORT', 6379),
    'database' => env('REDIS_SESSION_DB', 2),
    'prefix' => 'session:',
],
```

### Multi-Tenant Session Isolation
```php
// AppServiceProvider::boot()
$branchId = auth()->user()?->branch_id ?? 'global';
config(['database.redis.session.prefix' => "session:{$branchId}:"]);
```

---

## 6. Rate Limiting

### Token Bucket (Laravel Built-in)
```php
// RouteServiceProvider or bootstrap/app.php
RateLimiter::for('api', function (Request $request) {
    $branchId = $request->user()?->branch_id ?? 'guest';
    return Limit::perMinute(60)->by("branch:{$branchId}");
});
```

### Sliding Window (Custom)
```php
function slidingWindowRateLimit(string $key, int $maxRequests, int $windowSeconds): bool
{
    $now = microtime(true);
    $windowStart = $now - $windowSeconds;

    $pipe = Redis::pipeline(function ($pipe) use ($key, $now, $windowStart) {
        $pipe->zremrangebyscore($key, '-inf', $windowStart);
        $pipe->zadd($key, [$now => $now]);
        $pipe->zcard($key);
        $pipe->expire($key, $windowSeconds);
    });

    return $pipe[2] <= $maxRequests;
}
```

### Per-Tenant Rate Limits
```php
RateLimiter::for('tenant-api', function (Request $request) {
    $branch = $request->user()->branch;
    $limit = $branch->plan === 'enterprise' ? 1000 : 100;
    return Limit::perMinute($limit)->by("branch:{$branch->id}");
});
```

---

## 7. Pub/Sub and Broadcasting

### Laravel Broadcasting with Redis
```php
// Event
class InvoiceCreated implements ShouldBroadcast
{
    public function __construct(public Invoice $invoice) {}

    public function broadcastOn(): Channel
    {
        return new PrivateChannel("branch.{$this->invoice->branch_id}");
    }

    public function broadcastWith(): array
    {
        return ['invoice_id' => $this->invoice->id, 'total' => $this->invoice->total];
    }
}
```

### Direct Pub/Sub
```php
// Publisher
Redis::publish('stock-alerts', json_encode([
    'branch_id' => $branchId,
    'product_id' => $productId,
    'current_stock' => $stock,
]));

// Subscriber (long-running process)
Redis::subscribe(['stock-alerts'], function (string $message) {
    $data = json_decode($message, true);
    Notification::send($managers, new LowStockAlert($data));
});
```

---

## 8. Cache Invalidation

### Tag-Based Invalidation
```php
// On product update
Cache::tags(["branch:{$branchId}", 'products'])->flush();

// On single product change
Cache::tags(['products'])->forget("product:{$id}");
```

### Event-Driven Invalidation
```php
class InvalidateProductCache
{
    public function handle(ProductUpdated $event): void
    {
        $product = $event->product;
        Cache::forget("product:{$product->id}");
        Cache::tags(["branch:{$product->branch_id}", 'products'])->flush();
        Cache::forget("branch:{$product->branch_id}:product_count");
    }
}
```

### Selective Invalidation with Key Patterns
```bash
# redis-cli: find and delete keys matching a pattern (use SCAN, never KEYS in production)
redis-cli --scan --pattern "branch:42:products:*" | xargs redis-cli DEL
```

---

## 9. Multi-Tenant Caching

### Key Prefixing with branch_id
```php
// Helper for tenant-scoped keys
function tenantCacheKey(string $key): string
{
    $branchId = auth()->user()->branch_id;
    return "branch:{$branchId}:{$key}";
}

Cache::put(tenantCacheKey('dashboard:stats'), $stats, 300);
```

### Tenant-Scoped Cache Flushing
```php
class TenantCacheService
{
    public function flushTenant(int $branchId): void
    {
        Cache::tags(["branch:{$branchId}"])->flush();
    }

    public function warmTenant(int $branchId): void
    {
        $this->cacheProducts($branchId);
        $this->cacheCustomers($branchId);
        $this->cacheSettings($branchId);
    }
}
```

---

## 10. Redis Cluster

### Cluster Configuration
```php
// config/database.php
'redis' => [
    'clusters' => [
        'default' => [
            ['host' => '10.0.1.1', 'port' => 6379],
            ['host' => '10.0.1.2', 'port' => 6379],
            ['host' => '10.0.1.3', 'port' => 6379],
        ],
    ],
    'options' => [
        'cluster' => env('REDIS_CLUSTER', 'redis'),
        'prefix' => env('REDIS_PREFIX', 'erp:'),
    ],
],
```

### Hash Tags for Co-Location
```bash
# Use {hash_tag} to ensure related keys land on the same slot
SET {branch:42}:product:1 "..."
SET {branch:42}:product:2 "..."
# Both keys hash on "branch:42" and go to the same node
```

### Failover and Replica Management
```bash
# Check cluster health
redis-cli --cluster check 10.0.1.1:6379

# View cluster info
redis-cli CLUSTER INFO
redis-cli CLUSTER NODES

# Manual failover (promote replica)
redis-cli -h replica-host CLUSTER FAILOVER
```

---

## 11. Monitoring

### Redis INFO and Diagnostics
```bash
# Memory usage overview
redis-cli INFO memory | grep -E "used_memory_human|maxmemory_human|mem_fragmentation"

# Connected clients and throughput
redis-cli INFO clients
redis-cli INFO stats | grep -E "instantaneous_ops|keyspace_hits|keyspace_misses"

# Cache hit ratio
redis-cli INFO stats | grep "keyspace"
# hit_ratio = keyspace_hits / (keyspace_hits + keyspace_misses) — target > 90%
```

### Slow Log
```bash
redis-cli SLOWLOG GET 10           # last 10 slow commands
redis-cli SLOWLOG LEN              # total slow commands
redis-cli CONFIG SET slowlog-log-slower-than 10000  # log queries > 10ms
```

### Key Expiration and Memory Analysis
```bash
redis-cli --bigkeys                 # find largest keys
redis-cli DBSIZE                    # total key count
redis-cli TTL mykey                 # check TTL on a specific key
redis-cli OBJECT ENCODING mykey     # check internal encoding
redis-cli MEMORY USAGE mykey        # bytes used by key
```

---

## 12. Best Practices

### Key Naming Conventions
```
{resource}:{id}                     — product:5001
{resource}:{id}:{field}             — user:1001:last_login
branch:{branch_id}:{resource}:{id} — branch:42:invoice:7890
cache:{entity}:{scope}:{key}       — cache:reports:monthly:2026-03
lock:{operation}:{id}              — lock:generate-report:55
queue:{name}                       — queue:invoices
```

### Memory Optimization
- Use hashes for small objects (hash-max-ziplist-entries 128)
- Set TTLs on all cache keys to prevent unbounded growth
- Use `UNLINK` instead of `DEL` for non-blocking deletes
- Compress large values before storing (gzip JSON payloads > 1KB)
- Avoid storing full Eloquent models; cache only needed attributes

### Eviction Policies
```bash
# Recommended for caching workloads
CONFIG SET maxmemory-policy allkeys-lru

# For mixed cache + persistent data
CONFIG SET maxmemory-policy volatile-lru

# Never evict (for queues/sessions — ensure enough memory)
CONFIG SET maxmemory-policy noeviction
```

### Persistence (RDB vs AOF)
```bash
# RDB: periodic snapshots (good for caching, fast restart)
CONFIG SET save "900 1 300 10 60 10000"

# AOF: append every write (good for queues/sessions, minimal data loss)
CONFIG SET appendonly yes
CONFIG SET appendfsync everysec

# Production recommendation: enable both RDB + AOF
```

### Connection Management
```php
// config/database.php — separate connections per concern
'redis' => [
    'cache'   => ['database' => 0],  // caching
    'queue'   => ['database' => 1],  // Laravel Horizon queues
    'session' => ['database' => 2],  // user sessions
],
```

### Security
```bash
# Require authentication
CONFIG SET requirepass "strong-random-password"

# Disable dangerous commands in production
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command KEYS ""
rename-command DEBUG ""
```
