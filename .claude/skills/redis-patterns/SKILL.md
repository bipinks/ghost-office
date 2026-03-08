---
name: redis-patterns
description: Use when implementing caching, queues, or real-time features with Redis. Covers caching strategies, Laravel queue configuration, pub/sub, rate limiting, session management, data structures, and Redis cluster patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# Redis Patterns

Patterns for Redis in multi-tenant Laravel applications.

## Caching Strategies

| Strategy | Pattern | Use When |
|----------|---------|----------|
| Cache-aside | Read cache, miss loads from DB | Default for most reads |
| Write-through | Update DB + cache atomically | Frequently read after write |
| Write-behind | Cache immediately, DB via queue | High write throughput, eventual consistency OK |

```php
// Cache-aside with TTL
$product = Cache::remember("product:{$id}", 600, fn () => Product::with('category')->findOrFail($id));

// Write-through
DB::transaction(function () use ($data, $id) {
    $product = Product::findOrFail($id)->tap(fn ($p) => $p->update($data));
    Cache::put("product:{$id}", $product, 600);
});

// TTL guidance: volatile 1-5min, semi-stable 5-60min, reference 1-24hr
```

### Tags, Locks, Atomics
```php
// Tag-based invalidation
Cache::tags(['products', "branch:{$branchId}"])->put("product:{$id}", $product, 600);
Cache::tags(["branch:{$branchId}", 'products'])->flush();

// Lock to prevent stampede
$lock = Cache::lock("generate-report:{$reportId}", 30);
if ($lock->get()) { try { /* work */ } finally { $lock->release(); } }

// Atomic counter
Cache::increment('api:requests:count');
```

## Queue Management (Horizon)

```php
// config/horizon.php
'production' => [
    'supervisor-default' => [
        'queue' => ['default', 'invoices', 'reports', 'notifications'],
        'balance' => 'auto', 'minProcesses' => 1, 'maxProcesses' => 10,
        'tries' => 3, 'timeout' => 300,
    ],
    'supervisor-long' => [
        'queue' => ['long-running'], 'balance' => 'simple',
        'processes' => 3, 'tries' => 1, 'timeout' => 1800,
    ],
],

// Job with retry and backoff
class GenerateInvoicePdf implements ShouldQueue {
    public int $tries = 3;
    public int $timeout = 120;
    public array $backoff = [30, 60, 120];
    public function failed(Throwable $e): void { Log::error('PDF failed', ['id' => $this->invoice->id]); }
}

// Batches
Bus::batch([new ProcessInvoice($inv1), new ProcessInvoice($inv2)])
    ->then(fn (Batch $b) => Log::info('Done'))->onQueue('invoices')->dispatch();

// Rate limiting external API calls
Redis::throttle('api-external')->allow(10)->every(60)->then(fn () => /* call */, fn () => $this->release(30));
```

## Data Structures

| Structure | Use | Key Commands |
|-----------|-----|-------------|
| Strings | Counters, flags, tokens | `SETEX`, `INCR`, `GET/SET` |
| Hashes | Object storage, partial updates | `HSET`, `HGET`, `HINCRBY` |
| Lists | Queues, recent items | `LPUSH`, `RPOP`, `LTRIM` (cap size) |
| Sets | Unique collections, membership | `SADD`, `SISMEMBER`, `SINTER` |
| Sorted Sets | Leaderboards, time-series, priority | `ZADD`, `ZREVRANGE`, `ZRANGEBYSCORE` |

```bash
# Hash example: partial object update
HSET product:5001 name "Widget" price "29.99" stock "150"
HINCRBY product:5001 stock -1

# Sorted set: leaderboard
ZADD sales:leaderboard 15000 "branch:dubai"
ZREVRANGE sales:leaderboard 0 9 WITHSCORES
```

## Session Management

```php
// .env: SESSION_DRIVER=redis, SESSION_CONNECTION=session
// Dedicated connection on database 2 with prefix 'session:'
// Multi-tenant isolation: prefix with branch_id
config(['database.redis.session.prefix' => "session:{$branchId}:"]);
```

## Rate Limiting

```php
// Per-tenant with plan-based limits
RateLimiter::for('tenant-api', function (Request $request) {
    $branch = $request->user()->branch;
    $limit = $branch->plan === 'enterprise' ? 1000 : 100;
    return Limit::perMinute($limit)->by("branch:{$branch->id}");
});
```

Custom sliding window: sorted sets with `ZREMRANGEBYSCORE` + `ZADD` + `ZCARD` in a pipeline.

## Pub/Sub and Broadcasting

```php
// Laravel Broadcasting
class InvoiceCreated implements ShouldBroadcast {
    public function broadcastOn(): Channel {
        return new PrivateChannel("branch.{$this->invoice->branch_id}");
    }
    public function broadcastWith(): array {
        return ['invoice_id' => $this->invoice->id, 'total' => $this->invoice->total];
    }
}

// Direct pub/sub
Redis::publish('stock-alerts', json_encode(['branch_id' => $branchId, 'product_id' => $productId]));
```

## Cache Invalidation

```php
// Event-driven (preferred)
class InvalidateProductCache {
    public function handle(ProductUpdated $event): void {
        Cache::forget("product:{$event->product->id}");
        Cache::tags(["branch:{$event->product->branch_id}", 'products'])->flush();
    }
}
// Pattern cleanup: use SCAN (never KEYS in production)
// redis-cli --scan --pattern "branch:42:products:*" | xargs redis-cli DEL
```

## Multi-Tenant Caching

Prefix all keys with `branch:{id}:`. Use cache tags for per-tenant flushing. Warm caches on tenant activation.

## Operations & Monitoring

```bash
redis-cli INFO memory | grep used_memory_human
redis-cli INFO stats | grep "keyspace_hits\|keyspace_misses"  # target hit ratio > 90%
redis-cli SLOWLOG GET 10
redis-cli --bigkeys
```

## Best Practices

- **Key naming**: `{resource}:{id}`, `branch:{branch_id}:{resource}:{id}`, `lock:{operation}:{id}`
- **Memory**: TTLs on all cache keys. Hashes for small objects. Compress JSON >1KB. Cache needed attributes only. UNLINK for non-blocking deletes.
- **Eviction**: `allkeys-lru` for caching | `volatile-lru` for mixed | `noeviction` for queues/sessions
- **Persistence**: RDB for caching (fast restart) | AOF for queues/sessions | Production: both
- **Connections**: Separate databases per concern -- 0: cache, 1: queue, 2: session
- **Security**: `requirepass`, rename dangerous commands (FLUSHALL, FLUSHDB, KEYS, DEBUG) to empty string
- **Cluster**: Use hash tags `{branch:42}` to co-locate related keys on same slot
