-- Make clinic RLS policies fully idempotent
-- Ensures all CREATE POLICY statements in migration 013 can be safely re-run.

drop policy if exists "Users can view own memberships" on public.clinic_group_members;
drop policy if exists "Users can add members" on public.clinic_group_members;
drop policy if exists "Clinic members view appointments" on appointments;
drop policy if exists "Clinic members insert walk-ins" on appointments;
