# Eyadati - Environment Configuration

## Environment Variables

Create separate `.env` files for each environment:

### Development (.env)
```env
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-local-anon-key
ENVIRONMENT=development
ENABLE_LOGGING=true
ENABLE_DEBUG_MODE=true
```

### Staging (.env.staging)
```env
SUPABASE_URL=https://your-staging-project.supabase.co
SUPABASE_ANON_KEY=your-staging-anon-key
ENVIRONMENT=staging
ENABLE_LOGGING=true
ENABLE_DEBUG_MODE=false
```

### Production (.env.production)
```env
SUPABASE_URL=https://erkldarqweehvwgpncrg.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key
ENVIRONMENT=production
ENABLE_LOGGING=true
ENABLE_DEBUG_MODE=false
```

## Building for Different Environments

### Development
```bash
flutter run
```

### Staging
```bash
flutter build web --release --dart-define=ENVIRONMENT=staging
```

### Production
```bash
flutter build web --release --dart-define=ENVIRONMENT=production
```

## Supabase Configuration

### Development
- Use local Supabase CLI
- `supabase start`
- No real data

### Staging
- Create separate Supabase project for staging
- Mirror production data structure
- Use for testing before production

### Production
- Use production Supabase project
- Enable all security features
- Monitor usage and costs

## Security Checklist

- [ ] All `.env.*` files are in `.gitignore`
- [ ] Service role key never exposed to frontend
- [ ] Anon key used only in Flutter web/mobile
- [ ] RLS enabled on all tables
- [ ] API rate limiting configured
- [ ] Email confirmations enabled in production
