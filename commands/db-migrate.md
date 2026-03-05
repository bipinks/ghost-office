---
name: db-migrate
description: Plan and execute database migrations safely
argument-hint: "[database or migration name]"
disable-model-invocation: true
---

# /db-migrate — Database Migration

Run database migration for $ARGUMENTS using the **database-ops** agent:

1. Review migration scripts for safety
2. Check backward compatibility (expand-contract)
3. Test on staging with production-size data
4. Execute with proper lock timeouts
5. Verify post-migration integrity
6. Generate rollback scripts

## Usage
```
/db-migrate "add email_verified column to users"
/db-migrate "review pending migrations"
/db-migrate "rollback last migration"
```
