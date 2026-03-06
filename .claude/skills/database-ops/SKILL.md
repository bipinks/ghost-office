---
name: database-ops
description: Use when performing database administration, migrations, or performance tuning. Covers PostgreSQL, MySQL, Redis, and MongoDB operations including replication setup, backup/restore, index optimization, connection pooling, and maintenance windows.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# Database Operations

## PostgreSQL Performance Tuning
```sql
-- Key configuration parameters (postgresql.conf)
-- shared_buffers = 25% of RAM (e.g., 4GB for 16GB server)
-- effective_cache_size = 75% of RAM
-- work_mem = RAM / max_connections / 4
-- maintenance_work_mem = RAM / 8
-- wal_buffers = 64MB
-- max_wal_size = 2GB
-- checkpoint_completion_target = 0.9
-- random_page_cost = 1.1 (SSD), 4.0 (HDD)

-- Find slow queries
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Find missing indexes
SELECT relname, seq_scan, idx_scan, seq_tup_read
FROM pg_stat_user_tables
WHERE seq_scan > 0 AND idx_scan = 0
ORDER BY seq_tup_read DESC;

-- Index maintenance
REINDEX INDEX CONCURRENTLY idx_name;
VACUUM (VERBOSE, ANALYZE) table_name;
```

## Zero-Downtime Migration Pattern
```sql
-- Step 1: Add new column (nullable)
ALTER TABLE users ADD COLUMN email_verified boolean;

-- Step 2: Backfill data (in batches)
UPDATE users SET email_verified = false WHERE email_verified IS NULL AND id BETWEEN 1 AND 10000;

-- Step 3: Set default and NOT NULL (separate steps)
ALTER TABLE users ALTER COLUMN email_verified SET DEFAULT false;
ALTER TABLE users ALTER COLUMN email_verified SET NOT NULL;

-- Step 4: Create index concurrently (non-blocking)
CREATE INDEX CONCURRENTLY idx_users_email_verified ON users(email_verified);
```

## Redis Best Practices
```bash
# Key naming convention
SET user:{user_id}:profile "{json}"
SET session:{session_id} "{json}" EX 3600
SET cache:products:page:{n} "{json}" EX 300

# Memory management
CONFIG SET maxmemory 256mb
CONFIG SET maxmemory-policy allkeys-lru
```

## Best Practices
1. **Connection pooling** — PgBouncer for PostgreSQL, ProxySQL for MySQL
2. **Monitoring** — Track connections, query time, cache hit ratio, replication lag
3. **Backups** — Automated daily with Point-in-Time Recovery capability
4. **Indexes** — Create concurrently, drop unused, rebuild periodically
5. **Vacuum** — Tune autovacuum, don't disable it
6. **Upgrades** — Test on staging with production-size data
