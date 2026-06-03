-- Allow clinic group members to remove other members from the same group.
-- Uses the existing is_same_clinic_group() SECURITY DEFINER function
-- to avoid RLS recursion.

drop policy if exists "Clinic members can remove members" on public.clinic_group_members;

create policy "Clinic members can remove members"
  on public.clinic_group_members for delete
  using (
    public.is_same_clinic_group(auth.uid(), doctor_id)
  );
