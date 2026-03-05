---
name: backup
description: Configure and manage backup strategies
argument-hint: "[service or database name]"
disable-model-invocation: true
---

# /backup — Backup Management

Configure backups for $ARGUMENTS using the **database-ops** agent with the **backup-disaster-recovery** skill:

1. Design backup strategy (3-2-1 rule)
2. Configure automated backup scripts
3. Set up cross-region replication
4. Test restore procedures
5. Document RTO/RPO

## Usage
```
/backup "PostgreSQL daily backup to S3"
/backup "verify restore for production database"
/backup "set up cross-region replication"
```
