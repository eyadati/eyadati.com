-- Narrow clinic_groups SELECT policy to only members.
-- Migration 019 set it to auth.role() = 'authenticated' (anyone can see all groups)
-- to work around the INSERT+SELECT atomicity problem.
-- Now the Dart code pre-generates the group UUID, so SELECT is not needed
-- on the INSERT path and we can use a strict membership-based policy.

drop policy if exists "Anyone can view clinic groups" on public.clinic_groups;
drop policy if exists "Members view clinic group" on public.clinic_groups;
create policy "Members view clinic group"
  on public.clinic_groups for select
  using (
    exists (
      select 1 from clinic_group_members
      where clinic_group_id = id
        and doctor_id = auth.uid()
    )
  );
