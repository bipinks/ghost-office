# Database Operations Tools

## Overview
Reference for database management tools used by the database-engineer and backend-engineer.

## PostgreSQL Operations

### Connection
```bash
# Via Docker
docker compose exec -T db psql -U postgres erp_database

# Direct connection
psql -h localhost -U postgres -d erp_database
```

### Common Queries
```sql
-- Active connections
SELECT pid, usename, datname, state, query_start, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;

-- Index usage
SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Unused indexes
SELECT indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelname NOT LIKE '%_pkey';

-- Slow queries (if pg_stat_statements enabled)
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Kill a query
SELECT pg_cancel_backend(<pid>);      -- Graceful
SELECT pg_terminate_backend(<pid>);   -- Force
```

### Backup & Restore
```bash
# Full backup
pg_dump -U postgres erp_database > backup.sql
pg_dump -U postgres -Fc erp_database > backup.dump  # Custom format (compressed)

# Restore
psql -U postgres erp_database < backup.sql
pg_restore -U postgres -d erp_database backup.dump

# Backup specific tables
pg_dump -U postgres -t invoices -t invoice_items erp_database > invoices_backup.sql
```

### Maintenance
```sql
-- Analyze tables (update query planner statistics)
ANALYZE;
ANALYZE invoices;

-- Vacuum (reclaim space)
VACUUM ANALYZE;
VACUUM FULL invoices;  -- Reclaims disk space (locks table!)

-- Reindex
REINDEX TABLE invoices;
REINDEX DATABASE erp_database;
```

## Redis Operations

```bash
# Connect
docker compose exec -T redis redis-cli

# Common commands
redis-cli INFO memory                   # Memory usage
redis-cli INFO keyspace                 # Key statistics
redis-cli DBSIZE                        # Number of keys
redis-cli KEYS "cache:*" | head -20     # List keys (careful in prod!)
redis-cli FLUSHDB                       # Clear current database
redis-cli MONITOR                       # Watch all commands (debug only)

# Queue monitoring
redis-cli LLEN queues:default           # Queue length
redis-cli LLEN queues:high              # High priority queue
```

## Laravel Migration Commands

```bash
# Create migration
php artisan make:migration create_invoices_table
php artisan make:migration add_tax_column_to_invoices

# Run migrations
php artisan migrate                     # Run pending migrations
php artisan migrate --force             # Run in production (no prompt)
php artisan migrate:rollback            # Rollback last batch
php artisan migrate:rollback --step=2   # Rollback last 2 migrations
php artisan migrate:status              # Show migration status
php artisan migrate:fresh --seed        # Reset + seed (dev only!)

# Seeding
php artisan db:seed                     # Run all seeders
php artisan db:seed --class=InvoiceSeeder  # Specific seeder
```

## Data Export/Import

```bash
# CSV export
psql -U postgres -d erp_database -c "COPY (SELECT * FROM invoices WHERE branch_id = 1) TO STDOUT CSV HEADER" > invoices.csv

# CSV import
psql -U postgres -d erp_database -c "COPY invoices FROM STDIN CSV HEADER" < invoices.csv

# JSON export via Laravel
php artisan tinker --execute="echo Invoice::where('branch_id', 1)->get()->toJson();"
```

## Performance Analysis

```sql
-- Explain a query
EXPLAIN ANALYZE SELECT * FROM invoices WHERE branch_id = 1 AND status = 'unpaid';

-- Check if index is being used
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;

-- Table statistics
SELECT relname, n_live_tup, n_dead_tup, last_vacuum, last_analyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```
