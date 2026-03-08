---
name: postgresql-patterns
description: Use when designing schemas, writing queries, or optimizing PostgreSQL databases. Covers schema design, indexing strategies, query optimization, partitioning, JSONB operations, CTEs, window functions, and multi-tenant data patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob"]
---

# PostgreSQL Patterns

## 1. Schema Design

**Naming**: Tables `snake_case` plural. Indexes `idx_{table}_{columns}`. FKs `fk_{table}_{ref}`. Constraints `chk_{table}_{column}`.

### Data Type Selection
```sql
id BIGSERIAL PRIMARY KEY,                    -- future-proof PKs
total_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,  -- never FLOAT for money
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),     -- never TIMESTAMP without TZ
notes TEXT,                                  -- TEXT over VARCHAR when no max
public_id UUID NOT NULL DEFAULT gen_random_uuid(), -- for public-facing IDs
is_active BOOLEAN NOT NULL DEFAULT TRUE,
status VARCHAR(20) NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'approved', 'posted', 'cancelled')),
```

### Standard Table Template
```sql
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    branch_id BIGINT NOT NULL REFERENCES branches(id),
    invoice_number VARCHAR(50) NOT NULL,
    customer_id BIGINT NOT NULL REFERENCES customers(id),
    date DATE NOT NULL, due_date DATE NOT NULL,
    subtotal DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by BIGINT REFERENCES users(id),
    deleted_at TIMESTAMPTZ,
    UNIQUE (branch_id, invoice_number)
);
-- Check constraints for business rules
ALTER TABLE invoices ADD CONSTRAINT chk_invoices_due_after_date CHECK (due_date >= date);
```

## 2. Multi-Tenant (branch_id)

```sql
-- Composite indexes always lead with branch_id; partial for active rows
CREATE INDEX idx_invoices_branch_status ON invoices (branch_id, status) WHERE deleted_at IS NULL;

-- Row-Level Security
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON invoices
    USING (branch_id = current_setting('app.current_branch_id')::BIGINT);
ALTER TABLE invoices FORCE ROW LEVEL SECURITY;
-- Set per connection: SET app.current_branch_id = '42';
```

## 3. Indexing Strategy

```sql
-- B-tree: composite with most selective first
CREATE INDEX idx_invoices_branch_status_date ON invoices (branch_id, status, date);
-- Covering index for index-only scans
CREATE INDEX idx_invoices_covering ON invoices (branch_id, status) INCLUDE (total_amount, customer_id);
-- Partial index for specific queries
CREATE INDEX idx_invoices_unpaid ON invoices (branch_id, due_date)
    WHERE status IN ('approved', 'posted') AND deleted_at IS NULL;
-- GIN for JSONB, arrays, full-text search
CREATE INDEX idx_products_metadata ON products USING GIN (metadata);
CREATE INDEX idx_products_fts ON products USING GIN (search_vector);
-- GiST for range/spatial data
CREATE INDEX idx_shifts_timerange ON employee_shifts USING GiST (tstzrange(start_time, end_time));
```

### Index Maintenance
```sql
-- Find unused indexes
SELECT indexrelname, idx_scan FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelname NOT LIKE '%_pkey' ORDER BY pg_relation_size(indexrelid) DESC;
-- Find missing indexes (seq scans on large tables)
SELECT relname, seq_scan, idx_scan, n_live_tup FROM pg_stat_user_tables
WHERE n_live_tup > 10000 AND seq_scan > idx_scan ORDER BY seq_tup_read DESC LIMIT 20;
-- Non-blocking rebuild
REINDEX INDEX CONCURRENTLY idx_invoices_branch_status_date;
```

## 4. Query Optimization

```sql
-- Always use ANALYZE for actual execution stats
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;
-- Look for: Seq Scan (add index), high-row Nested Loop, large Sort, estimate vs actual mismatch (run ANALYZE)
```

### Common Pitfalls
```sql
-- BAD: function on indexed column     GOOD: range comparison
WHERE EXTRACT(YEAR FROM date) = 2026;  WHERE date >= '2026-01-01' AND date < '2027-01-01';
-- BAD: implicit cast                  GOOD: match column type
WHERE invoice_number = 12345;          WHERE invoice_number = '12345';
-- BAD: OR on different columns        GOOD: UNION ALL
-- BAD: SELECT *                       GOOD: specify needed columns
-- Use EXISTS instead of IN for correlated subqueries
-- Use LATERAL JOIN for top-N-per-group
```

## 5. CTEs and Window Functions

```sql
-- Standard CTE
WITH unpaid AS (
    SELECT customer_id, SUM(total_amount) AS outstanding
    FROM invoices WHERE branch_id = 42 AND status = 'unpaid' AND deleted_at IS NULL
    GROUP BY customer_id
)
SELECT c.name, u.outstanding FROM customers c JOIN unpaid u ON u.customer_id = c.id;

-- Recursive CTE (chart of accounts hierarchy)
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, code, 0 AS depth, code::TEXT AS path
    FROM accounts WHERE parent_id IS NULL AND branch_id = 42
    UNION ALL
    SELECT a.id, a.name, a.parent_id, a.code, t.depth + 1, t.path || '.' || a.code
    FROM accounts a JOIN tree t ON a.parent_id = t.id
)
SELECT * FROM tree ORDER BY path;

-- Window functions
ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY date)         -- sequential numbering
RANK() OVER (ORDER BY total_revenue DESC)                        -- ranking
LAG(revenue) OVER (ORDER BY month)                               -- month-over-month
SUM(amount) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING)        -- running total
AVG(sales) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)  -- moving avg
```

PG 12+ inlines non-recursive CTEs referenced once. Use `MATERIALIZED`/`NOT MATERIALIZED` to control.

## 6. JSONB Operations

```sql
-- Query: containment (uses GIN index)
SELECT * FROM products WHERE metadata @> '{"featured": true}';
-- Key existence
SELECT * FROM products WHERE metadata ? 'warranty_months';
-- Update nested key
UPDATE products SET metadata = jsonb_set(metadata, '{discount_pct}', '15') WHERE id = 100;
-- Remove key
UPDATE products SET metadata = metadata - 'temporary_flag';
-- GIN index for specific path (smaller, faster)
CREATE INDEX idx_meta_cat ON products USING GIN ((metadata->'category'));
```

## 7. Partitioning

| Strategy | Use Case | Example |
|----------|----------|---------|
| Range (date) | Time-series, journal entries | `PARTITION BY RANGE (entry_date)` |
| List (status) | Audit logs by level | `PARTITION BY LIST (log_level)` |
| Hash (tenant) | Even distribution | `PARTITION BY HASH (branch_id)` |

```sql
CREATE TABLE journal_entries (
    id BIGSERIAL, branch_id BIGINT NOT NULL, entry_date DATE NOT NULL,
    PRIMARY KEY (id, entry_date)
) PARTITION BY RANGE (entry_date);
CREATE TABLE je_2026 PARTITION OF journal_entries FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
-- Detach old partition (non-blocking PG 14+)
ALTER TABLE journal_entries DETACH PARTITION je_2023 CONCURRENTLY;
```

## 8. Full-Text Search

```sql
ALTER TABLE products ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(description, '')), 'B')
) STORED;
CREATE INDEX idx_products_fts ON products USING GIN (search_vector);

SELECT id, name, ts_rank(search_vector, query) AS rank
FROM products, to_tsquery('english', 'laptop & wireless') AS query
WHERE search_vector @@ query AND branch_id = 42 ORDER BY rank DESC LIMIT 20;
```

## 9. Transactions & Locking

| Isolation Level | Behavior | Use Case |
|----------------|----------|----------|
| Read Committed (default) | Sees committed data at statement start | Most queries |
| Repeatable Read | Snapshot from transaction start | Consistent reports |
| Serializable | Full serializability (retry on 40001) | Financial operations |

```sql
-- Advisory locks for sequence generation (prevent gaps)
SELECT pg_advisory_xact_lock(hashtext('invoice_seq_branch_42'));
-- Job queue pattern
SELECT id, payload FROM job_queue WHERE status = 'pending'
ORDER BY created_at LIMIT 1 FOR UPDATE SKIP LOCKED;
```

Deadlock prevention: always lock tables/rows in the same order.

## 10. Performance Monitoring

```sql
-- Top queries by total time (requires pg_stat_statements extension)
SELECT query, calls, mean_exec_time::numeric(10,2) AS avg_ms, total_exec_time::numeric(12,2) AS total_ms
FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 20;
-- Table bloat
SELECT relname, n_dead_tup, n_live_tup, last_autovacuum FROM pg_stat_user_tables
WHERE n_dead_tup > 10000 ORDER BY n_dead_tup DESC;
-- Connection monitoring
SELECT state, COUNT(*) FROM pg_stat_activity GROUP BY state;
```

## 11. Backup & Recovery

```bash
# Custom format backup (compressed, parallel restore)
pg_dump -h localhost -U postgres -Fc -Z6 -j4 erp_production -f /backups/erp_$(date +%Y%m%d).dump
# Restore
pg_restore -h localhost -U postgres -d erp_production -j4 --clean /backups/erp_20260307.dump
```

WAL archiving for PITR: `archive_command = 'aws s3 cp %p s3://wal-archive/%f'`. Recovery: set `recovery_target_time` and `restore_command`.

## 12. PgBouncer

| Pool Mode | Behavior | Use Case |
|-----------|----------|----------|
| `session` | Held for entire session | LISTEN/NOTIFY, prepared statements |
| `transaction` | Released after COMMIT | **Most web apps (recommended)** |
| `statement` | Released after each statement | Simple read-only only |

Key settings: `default_pool_size=25`, `max_client_conn=200`, `query_timeout=30`.
