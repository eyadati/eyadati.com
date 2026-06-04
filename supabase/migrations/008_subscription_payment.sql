-- =====================================================
-- Migration 008: Subscription Payment History
-- =====================================================
-- Adds payment_history table for tracking Chargily payments
-- and idempotency for webhook processing.
-- =====================================================

create table if not exists public.payment_history (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  amount integer not null,
  currency text not null default 'dzd',
  chargily_checkout_id text,
  chargily_event_id text unique,
  status text not null default 'completed',
  period_start timestamptz not null,
  period_end timestamptz not null,
  created_at timestamptz default now()
);

-- Indexes
create index if not exists idx_payment_history_doctor on public.payment_history(doctor_id);
create index if not exists idx_payment_history_event on public.payment_history(chargily_event_id);
create index if not exists idx_payment_history_created on public.payment_history(created_at desc);

-- RLS
alter table public.payment_history enable row level security;

drop policy if exists "Doctors can view own payment history" on public.payment_history;
create policy "Doctors can view own payment history"
  on public.payment_history for select
  using (auth.uid() = doctor_id);

drop policy if exists "Service role can insert payment history" on public.payment_history;
create policy "Service role can insert payment history"
  on public.payment_history for insert
  with check (true);

drop policy if exists "Service role can update payment history" on public.payment_history;
create policy "Service role can update payment history"
  on public.payment_history for update
  using (true);
