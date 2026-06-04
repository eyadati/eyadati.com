-- Restore missing RLS policies on clinic_group_members
-- Migration 014 dropped all policies without recreating them, leaving
-- clinic_group_members with no SELECT or INSERT policies.
-- This made the clinic calendar unusable — all queries and inserts
-- were silently blocked by RLS (403 errors).

-- SELECT: users can see their own memberships AND members of groups they belong to.
-- Uses is_same_clinic_group() SECURITY DEFINER function (from 013) to avoid recursion.
drop policy if exists "View clinic members" on public.clinic_group_members;
create policy "View clinic members"
  on public.clinic_group_members for select
  using (
    doctor_id = auth.uid()
    or public.is_same_clinic_group(auth.uid(), doctor_id)
  );

-- INSERT: any authenticated user can add members.
-- This is the same approach as the original 012 policy — simple and non-recursive.
drop policy if exists "Insert clinic members" on public.clinic_group_members;
create policy "Insert clinic members"
  on public.clinic_group_members for insert
  with check (auth.role() = 'authenticated');
