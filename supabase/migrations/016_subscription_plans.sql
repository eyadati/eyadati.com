-- =====================================================
-- Migration 016: Subscription Plan Types
-- =====================================================
-- Adds plan_type tracking to doctors and payment_history
-- for the 3-tier subscription system.
-- =====================================================

-- Add plan_type to doctors (tracks current/last plan)
alter table public.doctors
  add column if not exists plan_type text not null default 'monthly'
  check (plan_type in ('monthly', 'semiannual', 'annual'));

-- Add plan_type and duration_days to payment_history
alter table public.payment_history
  add column if not exists plan_type text not null default 'monthly'
  check (plan_type in ('monthly', 'semiannual', 'annual'));

alter table public.payment_history
  add column if not exists duration_days integer not null default 30;
