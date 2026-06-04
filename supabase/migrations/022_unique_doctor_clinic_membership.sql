-- Prevent a doctor from belonging to multiple clinic groups.
-- The app already prevents this at the application level (Fix #2),
-- but add a DB-level unique constraint as a safety net.
-- First, deduplicate any existing rows (keep the first membership per doctor).

delete from clinic_group_members
where id in (
  select id from (
    select id,
           row_number() over (partition by doctor_id order by created_at) as rn
    from clinic_group_members
  ) dup
  where dup.rn > 1
);

drop index if exists idx_clinic_members_doctor_unique;
create unique index idx_clinic_members_doctor_unique
  on clinic_group_members(doctor_id);
