-- Fix: PostgREST INSERT+SELECT atomic operation on clinic_groups fails
-- because the SELECT policy requires a pre-existing membership row,
-- which doesn't exist when creating the group for the first time.
-- This causes a 403 and rollback, leaving the table empty.

drop policy if exists "Members view clinic group" on public.clinic_groups;
drop policy if exists "Anyone can view clinic groups" on public.clinic_groups;
create policy "Anyone can view clinic groups"
  on public.clinic_groups for select
  using (auth.role() = 'authenticated');
