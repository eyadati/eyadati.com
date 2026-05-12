# Eyadati - Database Backup & Recovery Guide

## Supabase Managed Backups

Supabase provides automatic backups for all projects:

### Free Tier
- Manual point-in-time recovery available
- No automatic daily backups

### Pro Tier
- Automatic daily backups
- Point-in-time recovery up to 7 days
- Physical backups stored in separate region

## Manual Backup Methods

### 1. SQL Export (pg_dump)

```bash
# Install pg_dump if needed
# Connect to Supabase

pg_dump -h db.erkldarqweehvwgpncrg.supabase.co \
  -U postgres \
  -d postgres \
  --no-owner \
  --no-acl \
  > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 2. Table-Specific Export

```bash
# Export only application tables
pg_dump -h db.erkldarqweehvwgpncrg.supabase.co \
  -U postgres \
  -d postgres \
  --data-only \
  --table=profiles \
  --table=doctors \
  --table=appointments \
  --table=favorites \
  > data_backup.sql
```

### 3. Using Supabase CLI

```bash
supabase db dump -f backup.sql
```

## Backup Schedule

| Backup Type | Frequency | Retention | Storage |
|-------------|-----------|-----------|---------|
| Daily automated | Daily | 7 days | Supabase managed |
| Weekly manual | Weekly | 4 weeks | External storage |
| Monthly manual | Monthly | 6 months | External storage |
| Pre-deployment | Before changes | 90 days | External storage |

## Recovery Procedures

### 1. Point-in-Time Recovery (Supabase Dashboard)

1. Go to Supabase Dashboard
2. Select your project
3. Navigate to Database > Backups
4. Select point-in-time
5. Click Restore
6. Confirm restoration

### 2. SQL Restore

```bash
psql -h db.erkldarqweehvwgpncrg.supabase.co \
  -U postgres \
  -d postgres \
  < backup.sql
```

### 3. Selective Table Restore

```sql
-- Connect to database
-- Truncate existing data (careful!)
TRUNCATE TABLE appointments RESTART IDENTITY CASCADE;

-- Import from backup
\i data_backup.sql
```

## Migration Versioning

All database migrations are stored in:
```
supabase/migrations/
```

Current migrations:
- `001_initial_setup.sql` - Tables and RLS
- `002_security_hardening.sql` - Security functions
- `003_performance_optimization.sql` - Indexes

### Migration Best Practices

1. Never modify existing migrations
2. Create new migration for changes
3. Test migrations on staging first
4. Keep migration history in version control

## Verification Checklist

After any backup or restore:

- [ ] All tables exist
- [ ] Row counts match expected
- [ ] Indexes present
- [ ] RLS policies applied
- [ ] Triggers working
- [ ] Functions executable
- [ ] Auth still works
- [ ] Sample queries succeed
