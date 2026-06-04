-- Fix missing SELECT policy on appointments for clinic members.
-- Migration 014 dropped "Clinic members view appointments" (from 013)
-- and no migration ever recreated it, so the clinic calendar only
-- returns the current user's own appointments.

drop policy if exists "Clinic members view appointments" on appointments;
create policy "Clinic members view appointments"
  on appointments for select
  using (
    public.is_same_clinic_group(auth.uid(), doctor_id)
    or doctor_id = auth.uid()
  );

-- Allow users to read their own profile even if role != 'doctor'.
-- This fixes the bootstrap problem where a user needs to add
-- themselves as the first clinic member but can't find their
-- own profile because the policy filters by role = 'doctor'.
drop policy if exists "Anyone can read doctor profiles" on public.profiles;
create policy "Anyone can read doctor profiles"
  on public.profiles for select
  using (role = 'doctor' or id = auth.uid());
