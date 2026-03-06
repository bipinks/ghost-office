---
name: backup-disaster-recovery
description: Use when designing backup strategies or disaster recovery plans. Covers the 3-2-1 backup rule, RTO/RPO definitions, cross-region replication, automated backup scripts, restore testing procedures, and business continuity planning.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# Backup & Disaster Recovery

## Backup Strategy (3-2-1 Rule)
- **3** copies of data
- **2** different storage media
- **1** offsite/off-cloud copy

## Database Backup Automation
```bash
#!/bin/bash
# PostgreSQL backup with rotation
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/postgresql"
RETENTION_DAYS=30

pg_dump -h $DB_HOST -U $DB_USER -F c -Z 9 $DB_NAME > "$BACKUP_DIR/$DB_NAME-$TIMESTAMP.dump"

# Upload to S3
aws s3 cp "$BACKUP_DIR/$DB_NAME-$TIMESTAMP.dump" \
  "s3://backups-bucket/postgresql/$DB_NAME/$TIMESTAMP.dump" \
  --storage-class STANDARD_IA

# Cleanup old local backups
find $BACKUP_DIR -name "*.dump" -mtime +$RETENTION_DAYS -delete

# Verify backup integrity
pg_restore --list "$BACKUP_DIR/$DB_NAME-$TIMESTAMP.dump" > /dev/null 2>&1
echo "Backup verified: $?"
```

## DR Tiers
| Tier | RTO | RPO | Strategy | Cost |
|------|-----|-----|----------|------|
| Backup & Restore | Hours | Hours | Regular backups, restore on demand | $ |
| Pilot Light | Minutes | Minutes | Core infra running, scale on event | $$ |
| Warm Standby | Minutes | Seconds | Scaled-down replica running | $$$ |
| Multi-Active | Zero | Zero | Active-active across regions | $$$$ |

## Best Practices
1. **Test restores** — Regularly verify backup restoration works
2. **Automate everything** — No manual backup processes
3. **Encrypt backups** — At rest and in transit
4. **Monitor backup jobs** — Alert on failures immediately
5. **Document RTO/RPO** — Define and test recovery objectives
6. **Runbooks** — Step-by-step DR procedures accessible during incidents
7. **DR drills** — Quarterly failover exercises
8. **Cross-region copies** — At least one backup in a different region
