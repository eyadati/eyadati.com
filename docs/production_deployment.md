# Eyadati - Production Deployment Guide

## Pre-Deployment Checklist

### Backend (Supabase)

- [ ] All database migrations applied
- [ ] RLS policies tested and verified
- [ ] Auth email confirmations enabled
- [ ] API rate limits configured
- [ ] Database backups scheduled
- [ ] SSL certificates valid

### Frontend (Flutter)

- [ ] `flutter build web --release` succeeds
- [ ] All environment variables configured
- [ ] PWA manifest configured correctly
- [ ] Offline support tested
- [ ] Build size optimized

### Security

- [ ] No secrets in code
- [ ] `.env` files not committed
- [ ] Service role key secure
- [ ] CORS configured correctly
- [ ] Input validation working
- [ ] SQL injection protected

## Deployment Steps

### 1. Run Migrations on Production
```bash
supabase db push
```

### 2. Build Flutter App
```bash
flutter build web --release
```

### 3. Deploy to Hosting
Deploy the `build/web` folder to your hosting provider.

### 4. Configure Domain
- Point domain to hosting
- Update Supabase allowed URLs
- Update PWA manifest start_url

## Monitoring

### Key Metrics to Track
- Auth error rates
- Booking success/failure rates
- Database query performance
- API response times
- RLS policy violations

### Supabase Dashboard
- Monitor project usage
- Check database size
- Review auth logs
- Check API usage

## Backup & Recovery

### Automated Backups
Supabase provides automatic daily backups for Pro projects.

### Manual Backup
```bash
# Export database
pg_dump -h db.project.supabase.co -U postgres -d postgres > backup.sql
```

### Point-in-Time Recovery
Available on Pro plan for up to 7 days.

## Rollback Plan

1. Identify the issue
2. If database issue:
   - Restore from backup
   - Re-apply migrations
3. If frontend issue:
   - Revert to previous build
   - Deploy stable version

## Emergency Contacts

| Role | Contact |
|------|---------|
| Backend Lead | [Contact] |
| Frontend Lead | [Contact] |
| Supabase Support | support@supabase.io |
| Hosting Support | [Contact] |
