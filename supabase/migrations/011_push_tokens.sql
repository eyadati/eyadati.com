-- Migration: FCM push token storage for call notification delivery
-- Phone PWA registers FCM token here → Edge Function queries it to send push

create table if not exists public.push_tokens (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  token text not null,
  platform text not null default 'web_mobile',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, token)
);

create index if not exists push_tokens_user_id_idx on public.push_tokens(user_id);

alter table public.push_tokens enable row level security;

drop policy if exists "Users insert their own push tokens" on public.push_tokens;
create policy "Users insert their own push tokens"
  on public.push_tokens for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users view their own push tokens" on public.push_tokens;
create policy "Users view their own push tokens"
  on public.push_tokens for select
  using (auth.uid() = user_id);

drop policy if exists "Users update their own push tokens" on public.push_tokens;
create policy "Users update their own push tokens"
  on public.push_tokens for update
  using (auth.uid() = user_id);

drop policy if exists "Users delete their own push tokens" on public.push_tokens;
create policy "Users delete their own push tokens"
  on public.push_tokens for delete
  using (auth.uid() = user_id);
