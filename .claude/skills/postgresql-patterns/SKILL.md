---
name: postgresql-patterns
description: Use when designing schemas, writing queries, or optimizing PostgreSQL databases. Covers schema design, indexing strategies, query optimization, partitioning, JSONB operations, CTEs, window functions, and multi-tenant data patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# PostgreSQL Patterns

Comprehensive reference for PostgreSQL schema design, query optimization, and operational patterns in multi-tenant applications.

---

## 1. Schema Design

### Naming Conventions
- Tables: `snake_case`, plural (`invoices`, `purchase_orders`)
- Columns: `snake_case` (`created_at`, `branch_id`, `total_amount`)
- Indexes: `idx_{table}_{columns}` (`idx_invoices_branch_id_date`)
- Foreign keys: `fk_{table}_{ref_table}` (`fk_invoices_branches`)
- Constraints: `chk_{table}_{column}` (`chk_invoices_total_positive`)

### Data Type Selection
```sql
-- Use BIGSERIAL for primary keys (future-proof)
id BIGSERIAL PRIMARY KEY,

-- Use DECIMAL for money (never FLOAT)
total_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,

-- Use TIMESTAMPTZ (never TIMESTAMP without timezone)
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

-- Use TEXT over VARCHAR when no max length is enforced
notes TEXT,

-- Use UUID for public-facing identifiers
public_id UUID NOT NULL DEFAULT gen_random_uuid(),

-- Use BOOLEAN with explicit defaults
is_active BOOLEAN NOT NULL DEFAULT TRUE,

-- Use ENUM types sparingly; prefer CHECK constraints for small sets
status VARCHAR(20) NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'approved', 'posted', 'cancelled')),
```

### Standard Table Template
Every table must include audit columns, soft delete, and multi-tenancy:
```sql
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id),
    invoice_number VARCHAR(50) NOT NULL,
    customer_id BIGINT NOT NULL REFERENCES customers(id),
    date DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft','approved','posted','cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    deleted_at TIMESTAMPTZ,
    UNIQUE (branch_id, invoice_number)
);
```

### Constraints
```sql
-- Check constraints for business rules
ALTER TABLE invoices ADD CONSTRAINT chk_invoices_due_after_date
    CHECK (due_date >= date);

ALTER TABLE invoice_items ADD CONSTRAINT chk_items_quantity_positive
    CHECK (quantity > 0);

ALTER TABLE invoice_items ADD CONSTRAINT chk_items_price_non_negative
    CHECK (unit_price >= 0);

-- Exclusion constraints to prevent overlapping ranges
ALTER TABLE employee_shifts ADD CONSTRAINT no_overlapping_shifts
    EXCLUDE USING gist (
        employee_id WITH =,
        tstzrange(start_time, end_time) WITH &&
    );
```

---

## 2. Multi-Tenant Schema

### branch_id Pattern
```sql
-- Every data table includes branch_id
-- Composite unique constraints scoped to branch
-- Composite indexes always lead with branch_id

CREATE INDEX idx_invoices_branch_status ON invoices (branch_id, status)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_invoices_branch_customer ON invoices (branch_id, customer_id)
    WHERE deleted_at IS NULL;
```

### Row-Level Security (RLS)
```sql
-- Enable RLS on the table
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- Policy: users see only their branch data
CREATE POLICY tenant_isolation ON invoices
    USING (branch_id = current_setting('app.current_branch_id')::BIGINT);

-- Set the branch context per connection (application layer)
SET app.current_branch_id = '42';

-- Force RLS even for table owners
ALTER TABLE invoices FORCE ROW LEVEL SECURITY;
```

### Laravel Global Scope (Application-Level Enforcement)
```php
// app/Scopes/BranchScope.php
class BranchScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        if (auth()->check()) {
            $builder->where($model->getTable() . '.branch_id', auth()->user()->branch_id);
        }
    }
}

// In every model using the HasBranch trait
protected static function booted(): void
{
    static::addGlobalScope(new BranchScope());
    static::creating(function ($model) {
        $model->branch_id = $model->branch_id ?? auth()->user()->branch_id;
    });
}
```

---

## 3. Indexing Strategy

### B-tree Indexes (Default)
```sql
-- Single column for equality/range queries
CREATE INDEX idx_invoices_date ON invoices (date);

-- Composite: most selective column first
CREATE INDEX idx_invoices_branch_status_date ON invoices (branch_id, status, date);

-- Covering index: include columns to enable index-only scans
CREATE INDEX idx_invoices_covering ON invoices (branch_id, status)
    INCLUDE (total_amount, customer_id);
```

### Partial Indexes
```sql
-- Index only active (non-deleted) rows
CREATE INDEX idx_invoices_active ON invoices (branch_id, due_date)
    WHERE deleted_at IS NULL;

-- Index only unpaid invoices for aging reports
CREATE INDEX idx_invoices_unpaid ON invoices (branch_id, due_date)
    WHERE status IN ('approved', 'posted') AND deleted_at IS NULL;
```

### GIN Indexes
```sql
-- For JSONB columns
CREATE INDEX idx_products_metadata ON products USING GIN (metadata);

-- For array columns
CREATE INDEX idx_products_tags ON products USING GIN (tags);

-- For full-text search
CREATE INDEX idx_products_search ON products USING GIN (search_vector);
```

### GiST Indexes
```sql
-- For geometric/range data
CREATE INDEX idx_shifts_timerange ON employee_shifts
    USING GiST (tstzrange(start_time, end_time));

-- For nearest-neighbor / spatial queries
CREATE INDEX idx_locations_coords ON locations USING GiST (point(longitude, latitude));
```

### Index Maintenance
```sql
-- Find unused indexes
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find missing indexes (sequential scans on large tables)
SELECT relname, seq_scan, idx_scan, n_live_tup,
       round(seq_scan::numeric / GREATEST(seq_scan + idx_scan, 1) * 100, 1) AS seq_pct
FROM pg_stat_user_tables
WHERE n_live_tup > 10000 AND seq_scan > idx_scan
ORDER BY seq_tup_read DESC LIMIT 20;

-- Rebuild bloated indexes (non-blocking)
REINDEX INDEX CONCURRENTLY idx_invoices_branch_status_date;
```

---

## 4. Query Optimization

### Using EXPLAIN ANALYZE
```sql
-- Always use ANALYZE for actual execution stats (not just estimates)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT i.id, i.invoice_number, c.name AS customer_name
FROM invoices i
JOIN customers c ON c.id = i.customer_id
WHERE i.branch_id = 42 AND i.status = 'unpaid' AND i.deleted_at IS NULL
ORDER BY i.due_date
LIMIT 25;

-- Key things to look for:
-- Seq Scan on large tables (add index)
-- Nested Loop with high row counts (consider Hash Join)
-- Sort with high memory usage (add index matching ORDER BY)
-- Rows estimated vs actual differ greatly (run ANALYZE on table)
```

### Common Pitfalls
```sql
-- BAD: Function on indexed column prevents index use
SELECT * FROM invoices WHERE EXTRACT(YEAR FROM date) = 2026;
-- GOOD: Use range comparison
SELECT * FROM invoices WHERE date >= '2026-01-01' AND date < '2027-01-01';

-- BAD: Implicit cast prevents index use
SELECT * FROM invoices WHERE invoice_number = 12345;
-- GOOD: Match the column type
SELECT * FROM invoices WHERE invoice_number = '12345';

-- BAD: OR on different columns prevents single index use
SELECT * FROM invoices WHERE customer_id = 5 OR vendor_id = 5;
-- GOOD: Use UNION ALL
SELECT * FROM invoices WHERE customer_id = 5
UNION ALL
SELECT * FROM invoices WHERE vendor_id = 5 AND customer_id != 5;

-- BAD: SELECT * fetches unnecessary data
SELECT * FROM invoices WHERE branch_id = 42;
-- GOOD: Specify only needed columns
SELECT id, invoice_number, total_amount, status FROM invoices WHERE branch_id = 42;
```

### Join Strategies
```sql
-- Use EXISTS instead of IN for correlated subqueries
-- BAD
SELECT * FROM customers WHERE id IN (SELECT customer_id FROM invoices WHERE status = 'unpaid');
-- GOOD
SELECT * FROM customers c WHERE EXISTS (
    SELECT 1 FROM invoices i WHERE i.customer_id = c.id AND i.status = 'unpaid'
);

-- Use lateral joins for top-N-per-group
SELECT c.id, c.name, latest.*
FROM customers c
CROSS JOIN LATERAL (
    SELECT i.invoice_number, i.total_amount, i.date
    FROM invoices i
    WHERE i.customer_id = c.id AND i.deleted_at IS NULL
    ORDER BY i.date DESC LIMIT 3
) latest;
```

---

## 5. CTEs (Common Table Expressions)

### Standard CTE
```sql
WITH unpaid_totals AS (
    SELECT customer_id, SUM(total_amount) AS outstanding
    FROM invoices
    WHERE branch_id = 42 AND status = 'unpaid' AND deleted_at IS NULL
    GROUP BY customer_id
)
SELECT c.name, ut.outstanding
FROM customers c
JOIN unpaid_totals ut ON ut.customer_id = c.id
ORDER BY ut.outstanding DESC;
```

### Recursive CTE (Chart of Accounts Hierarchy)
```sql
WITH RECURSIVE account_tree AS (
    -- Base case: root accounts
    SELECT id, name, parent_id, code, 0 AS depth,
           code::TEXT AS path
    FROM accounts
    WHERE parent_id IS NULL AND branch_id = 42

    UNION ALL

    -- Recursive step: child accounts
    SELECT a.id, a.name, a.parent_id, a.code, t.depth + 1,
           t.path || '.' || a.code
    FROM accounts a
    JOIN account_tree t ON a.parent_id = t.id
)
SELECT id, REPEAT('  ', depth) || name AS indented_name, code, path
FROM account_tree
ORDER BY path;
```

### Materialized vs Non-Materialized
```sql
-- Force materialization (useful when CTE is referenced multiple times)
WITH unpaid AS MATERIALIZED (
    SELECT customer_id, COUNT(*) AS cnt FROM invoices WHERE status = 'unpaid' GROUP BY customer_id
)
SELECT * FROM unpaid WHERE cnt > 5;

-- Prevent materialization (allow optimizer to inline the CTE)
WITH unpaid AS NOT MATERIALIZED (
    SELECT customer_id, COUNT(*) AS cnt FROM invoices WHERE status = 'unpaid' GROUP BY customer_id
)
SELECT * FROM unpaid WHERE cnt > 5;
-- PostgreSQL 12+ inlines non-recursive CTEs by default when referenced once.
```

---

## 6. Window Functions

```sql
-- ROW_NUMBER: sequential numbering within each branch
SELECT id, invoice_number,
    ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY date) AS seq
FROM invoices;

-- RANK / DENSE_RANK: top customers by revenue
SELECT customer_id, total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM (
    SELECT customer_id, SUM(total_amount) AS total_revenue
    FROM invoices WHERE branch_id = 42 AND deleted_at IS NULL
    GROUP BY customer_id
) sub;

-- LAG / LEAD: month-over-month comparison
SELECT month, revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month,
    revenue - LAG(revenue) OVER (ORDER BY month) AS growth
FROM monthly_revenue WHERE branch_id = 42;

-- Running total
SELECT id, date, total_amount,
    SUM(total_amount) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING) AS running_total
FROM invoices WHERE branch_id = 42 AND deleted_at IS NULL;

-- Moving average (last 7 days)
SELECT date, daily_sales,
    AVG(daily_sales) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d
FROM daily_sales_summary WHERE branch_id = 42;
```

---

## 7. JSONB Operations

```sql
-- Store flexible metadata
ALTER TABLE products ADD COLUMN metadata JSONB NOT NULL DEFAULT '{}';

-- Query nested values
SELECT id, name, metadata->>'color' AS color
FROM products
WHERE metadata->>'category' = 'electronics' AND branch_id = 42;

-- Query with containment operator (uses GIN index)
SELECT * FROM products WHERE metadata @> '{"featured": true}';

-- Check key existence
SELECT * FROM products WHERE metadata ? 'warranty_months';

-- Update a nested key (immutable update, returns new JSONB)
UPDATE products
SET metadata = jsonb_set(metadata, '{discount_pct}', '15')
WHERE id = 100;

-- Remove a key
UPDATE products
SET metadata = metadata - 'temporary_flag'
WHERE branch_id = 42;

-- Aggregate JSONB from rows
SELECT jsonb_object_agg(key, value)
FROM product_settings WHERE branch_id = 42;

-- GIN index for JSONB (supports @>, ?, ?|, ?& operators)
CREATE INDEX idx_products_metadata ON products USING GIN (metadata);

-- GIN index for specific path (smaller, faster for known paths)
CREATE INDEX idx_products_meta_category ON products USING GIN ((metadata->'category'));
```

---

## 8. Partitioning

### Range Partitioning (by date)
```sql
CREATE TABLE journal_entries (
    id BIGSERIAL,
    branch_id BIGINT NOT NULL,
    entry_date DATE NOT NULL,
    account_id BIGINT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, entry_date)
) PARTITION BY RANGE (entry_date);

-- Create partitions per financial year
CREATE TABLE journal_entries_2025 PARTITION OF journal_entries
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE journal_entries_2026 PARTITION OF journal_entries
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- Indexes are created per partition
CREATE INDEX idx_je_2026_branch ON journal_entries_2026 (branch_id, account_id);
```

### List Partitioning (by status)
```sql
CREATE TABLE audit_logs (
    id BIGSERIAL,
    log_level VARCHAR(10) NOT NULL,
    message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, log_level)
) PARTITION BY LIST (log_level);

CREATE TABLE audit_logs_info PARTITION OF audit_logs FOR VALUES IN ('info');
CREATE TABLE audit_logs_warn PARTITION OF audit_logs FOR VALUES IN ('warning');
CREATE TABLE audit_logs_error PARTITION OF audit_logs FOR VALUES IN ('error', 'critical');
```

### Hash Partitioning (even distribution by tenant)
```sql
CREATE TABLE events (
    id BIGSERIAL,
    branch_id BIGINT NOT NULL,
    event_type VARCHAR(50),
    payload JSONB,
    PRIMARY KEY (id, branch_id)
) PARTITION BY HASH (branch_id);

CREATE TABLE events_p0 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE events_p1 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE events_p2 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE events_p3 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### Partition Maintenance
```sql
-- Detach old partition (non-blocking in PG 14+)
ALTER TABLE journal_entries DETACH PARTITION journal_entries_2023 CONCURRENTLY;

-- Attach an existing table as a partition
ALTER TABLE journal_entries ATTACH PARTITION journal_entries_2027
    FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');
```

---

## 9. Full-Text Search

```sql
-- Add a generated tsvector column
ALTER TABLE products ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(sku, '')), 'A')
    ) STORED;

CREATE INDEX idx_products_fts ON products USING GIN (search_vector);

-- Search with ranking
SELECT id, name, ts_rank(search_vector, query) AS rank
FROM products, to_tsquery('english', 'laptop & wireless') AS query
WHERE search_vector @@ query AND branch_id = 42 AND deleted_at IS NULL
ORDER BY rank DESC
LIMIT 20;

-- Phrase search
SELECT * FROM products
WHERE search_vector @@ phraseto_tsquery('english', 'stainless steel')
  AND branch_id = 42;
```

---

## 10. Migrations (Laravel)

### Standard Migration
```php
// database/migrations/2026_03_07_000001_create_invoices_table.php
public function up(): void
{
    Schema::create('invoices', function (Blueprint $table) {
        $table->id();                                           // BIGSERIAL
        $table->foreignId('branch_id')->constrained();          // branch_id + FK
        $table->string('invoice_number', 50);
        $table->foreignId('customer_id')->constrained();
        $table->date('date');
        $table->date('due_date');
        $table->decimal('subtotal', 15, 2)->default(0);
        $table->decimal('tax_amount', 15, 2)->default(0);
        $table->decimal('total_amount', 15, 2)->default(0);
        $table->string('status', 20)->default('draft');
        $table->text('notes')->nullable();
        $table->foreignId('created_by')->nullable()->constrained('users');
        $table->foreignId('updated_by')->nullable()->constrained('users');
        $table->timestamps();                                   // created_at, updated_at
        $table->softDeletes();                                  // deleted_at

        $table->unique(['branch_id', 'invoice_number']);
        $table->index(['branch_id', 'status', 'date']);
        $table->index(['branch_id', 'customer_id']);
    });
}

public function down(): void
{
    Schema::dropIfExists('invoices');
}
```

### Zero-Downtime Column Addition
```php
// Step 1: Add nullable column (fast, no lock)
public function up(): void
{
    Schema::table('invoices', function (Blueprint $table) {
        $table->string('reference_code', 30)->nullable()->after('invoice_number');
    });
}

// Step 2: Backfill in batches (separate migration or artisan command)
// Use raw SQL for bulk operations
DB::statement("
    UPDATE invoices SET reference_code = 'REF-' || id::TEXT
    WHERE reference_code IS NULL AND id BETWEEN ? AND ?
", [$start, $end]);

// Step 3: Add NOT NULL constraint (after backfill is complete)
public function up(): void
{
    DB::statement("ALTER TABLE invoices ALTER COLUMN reference_code SET NOT NULL");
}
public function down(): void
{
    DB::statement("ALTER TABLE invoices ALTER COLUMN reference_code DROP NOT NULL");
}
```

### Safe Index Creation
```php
public function up(): void
{
    // CONCURRENTLY prevents table locks during index build
    DB::statement('CREATE INDEX CONCURRENTLY idx_invoices_reference
        ON invoices (branch_id, reference_code) WHERE deleted_at IS NULL');
}

public function down(): void
{
    DB::statement('DROP INDEX CONCURRENTLY IF EXISTS idx_invoices_reference');
}
```

---

## 11. Transactions & Locking

### Isolation Levels
```sql
-- Read Committed (default): sees committed data at statement start
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Repeatable Read: sees snapshot from transaction start
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Serializable: full serializability, may throw serialization errors
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Application must retry on serialization failure (SQLSTATE 40001)
```

### Advisory Locks (Application-Level)
```sql
-- Use for document number generation (prevent gaps)
SELECT pg_advisory_xact_lock(hashtext('invoice_seq_branch_42'));
-- Generate next number, insert row, commit releases lock automatically

-- Try lock (non-blocking)
SELECT pg_try_advisory_xact_lock(hashtext('payroll_run_branch_42'));
-- Returns FALSE if another process holds the lock
```

### Deadlock Prevention
```sql
-- Rule: always lock tables/rows in the same order
-- BAD: Transaction A locks invoices then payments; Transaction B locks payments then invoices
-- GOOD: Always lock invoices first, then payments

-- Use SELECT ... FOR UPDATE with SKIP LOCKED for job queues
SELECT id, payload FROM job_queue
WHERE status = 'pending'
ORDER BY created_at
LIMIT 1
FOR UPDATE SKIP LOCKED;
```

---

## 12. Performance Monitoring

### pg_stat_statements
```sql
-- Enable in postgresql.conf: shared_preload_libraries = 'pg_stat_statements'
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top queries by total time
SELECT query, calls, mean_exec_time::numeric(10,2) AS avg_ms,
       total_exec_time::numeric(12,2) AS total_ms,
       rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC LIMIT 20;

-- Queries with worst cache hit ratio
SELECT query, shared_blks_hit, shared_blks_read,
       round(shared_blks_hit::numeric / GREATEST(shared_blks_hit + shared_blks_read, 1), 3) AS hit_ratio
FROM pg_stat_statements
WHERE shared_blks_hit + shared_blks_read > 100
ORDER BY hit_ratio ASC LIMIT 20;
```

### Table Bloat Detection
```sql
SELECT schemaname, relname,
       n_dead_tup, n_live_tup,
       round(n_dead_tup::numeric / GREATEST(n_live_tup, 1) * 100, 1) AS dead_pct,
       last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;

-- Manual vacuum for bloated tables
VACUUM (VERBOSE, ANALYZE) invoices;
```

### Connection Monitoring
```sql
SELECT state, COUNT(*) FROM pg_stat_activity GROUP BY state;
SELECT datname, usename, client_addr, state, query_start, query
FROM pg_stat_activity WHERE state = 'active' ORDER BY query_start;
```

---

## 13. Backup & Recovery

### pg_dump (Logical Backup)
```bash
# Custom format (compressed, supports parallel restore)
pg_dump -h localhost -U postgres -F c -Z 6 -j 4 erp_production \
    -f /backups/erp_$(date +%Y%m%d_%H%M%S).dump

# Restore (parallel)
pg_restore -h localhost -U postgres -d erp_production -j 4 --clean /backups/erp_20260307.dump
```

### WAL Archiving (Point-in-Time Recovery)
```ini
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'aws s3 cp %p s3://wal-archive/%f'
```

### pg_basebackup (Physical Backup)
```bash
pg_basebackup -h localhost -U replicator -D /backups/base \
    --checkpoint=fast --wal-method=stream -z -P
```

### Point-in-Time Recovery
```ini
# recovery.conf or postgresql.conf (PG 12+)
restore_command = 'aws s3 cp s3://wal-archive/%f %p'
recovery_target_time = '2026-03-07 14:30:00 UTC'
recovery_target_action = 'promote'
```

---

## 14. Connection Pooling (PgBouncer)

### Configuration
```ini
# pgbouncer.ini
[databases]
erp_production = host=127.0.0.1 port=5432 dbname=erp_production

[pgbouncer]
listen_port = 6432
listen_addr = 0.0.0.0
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

# Pool sizing
pool_mode = transaction          ; release connection after each transaction
default_pool_size = 25           ; connections per user/database pair
max_client_conn = 200            ; max client connections to PgBouncer
reserve_pool_size = 5            ; extra connections for burst traffic
reserve_pool_timeout = 3         ; seconds before using reserve pool

# Timeouts
server_idle_timeout = 300
client_idle_timeout = 0
query_timeout = 30
```

### Pool Modes
| Mode | Behavior | Use Case |
|------|----------|----------|
| `session` | Connection held for entire session | LISTEN/NOTIFY, prepared statements |
| `transaction` | Connection released after COMMIT/ROLLBACK | Most web applications (recommended) |
| `statement` | Connection released after each statement | Simple read-only queries only |

### Monitoring PgBouncer
```sql
-- Connect to PgBouncer admin console (port 6432, database pgbouncer)
SHOW POOLS;      -- active/waiting connections per pool
SHOW CLIENTS;    -- all client connections
SHOW SERVERS;    -- all server connections
SHOW STATS;      -- request/query counts and timing
```
