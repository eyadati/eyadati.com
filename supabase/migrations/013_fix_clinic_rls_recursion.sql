-- Fix infinite RLS recursion in clinic_group_members policies
-- Self-referencing subqueries in RLS policies cause PostgreSQL recursion detection.
-- Fix: use a SECURITY DEFINER function to bypass RLS for internal group checks.

-- SECURITY DEFINER function: checks if two doctors share any clinic group.
-- Runs with owner privileges, bypassing RLS on clinic_group_members.
create or replace function public.is_same_clinic_group(member_id uuid, target_doctor_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from clinic_group_members cgm1
    join clinic_group_members cgm2 on cgm2.clinic_group_id = cgm1.clinic_group_id
    where cgm1.doctor_id = member_id
      and cgm2.doctor_id = target_doctor_id
  );
$$;

-- Clean up ALL existing policies on clinic_group_members (old + new names)
drop policy if exists "Members view own" on public.clinic_group_members;
drop policy if exists "Receptionists view group members" on public.clinic_group_members;
drop policy if exists "Members view group members" on public.clinic_group_members;
drop policy if exists "Authenticated users can add members" on public.clinic_group_members;

-- Simple non-recursive policy: users can see their own membership rows
drop policy if exists "Users can view own memberships" on public.clinic_group_members;
create policy "Users can view own memberships"
  on public.clinic_group_members for select
  using (doctor_id = auth.uid());

-- Any authenticated user can add members (needed for invite flow)
drop policy if exists "Users can add members" on public.clinic_group_members;
create policy "Users can add members"
  on public.clinic_group_members for insert
  with check (auth.role() = 'authenticated');

-- Clean up old appointments policies (old + new names)
drop policy if exists "Receptionists select appointments" on appointments;
drop policy if exists "Members view clinic appointments" on appointments;

-- Recreate using the SECURITY DEFINER function to avoid recursion
drop policy if exists "Clinic members view appointments" on appointments;
create policy "Clinic members view appointments"
  on appointments for select
  using (
    public.is_same_clinic_group(auth.uid(), doctor_id)
    or doctor_id = auth.uid()
  );

drop policy if exists "Receptionists insert walk-ins" on appointments;
drop policy if exists "Members insert walk-ins" on appointments;
drop policy if exists "Clinic members insert walk-ins" on appointments;

create policy "Clinic members insert walk-ins"
  on appointments for insert
  with check (
    booking_type = 'manual'
    and public.is_same_clinic_group(auth.uid(), appointments.doctor_id)
  );
