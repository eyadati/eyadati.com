-- Migration: Clinic groups for multi-doctor calendar
-- Doctors remain independent solo accounts
-- Lightweight clinic grouping so a doctor can view/manage appointments
-- for all doctors in their clinic group

-- Clinic identity
create table if not exists public.clinic_groups (
  id         uuid primary key default gen_random_uuid(),
  name       text not null default '',
  address    text,
  phone      text,
  created_at timestamptz default now()
);

alter table public.clinic_groups enable row level security;

-- Doctors belonging to a clinic
create table if not exists public.clinic_group_members (
  id              uuid primary key default gen_random_uuid(),
  clinic_group_id uuid not null references clinic_groups(id) on delete cascade,
  doctor_id       uuid not null references doctors(id) on delete cascade,
  color           text,
  created_at      timestamptz default now(),
  unique(clinic_group_id, doctor_id)
);

create index if not exists idx_clinic_members_group on clinic_group_members(clinic_group_id);
create index if not exists idx_clinic_members_doctor on clinic_group_members(doctor_id);

alter table public.clinic_group_members enable row level security;

-- RLS: Authenticated users can read doctor profiles (needed for email lookup)
drop policy if exists "Anyone can read doctor profiles" on public.profiles;
create policy "Anyone can read doctor profiles"
  on public.profiles for select
  using (role = 'doctor');

-- RLS: Any authenticated user can create a clinic group
drop policy if exists "Authenticated users can create clinic groups" on public.clinic_groups;
create policy "Authenticated users can create clinic groups"
  on public.clinic_groups for insert
  with check (auth.role() = 'authenticated');

-- RLS: Members can view their own clinic group
drop policy if exists "Members view clinic group" on public.clinic_groups;
create policy "Members view clinic group"
  on public.clinic_groups for select
  using (
    exists (
      select 1 from clinic_group_members cgm
      where cgm.clinic_group_id = clinic_groups.id
        and cgm.doctor_id = auth.uid()
    )
  );

-- RLS: Members can view all members in their groups
drop policy if exists "Members view group members" on public.clinic_group_members;
create policy "Members view group members"
  on public.clinic_group_members for select
  using (
    exists (
      select 1 from clinic_group_members cgm
      where cgm.clinic_group_id = clinic_group_members.clinic_group_id
        and cgm.doctor_id = auth.uid()
    )
  );

-- RLS: Authenticated users can add members (first member creation + invite)
drop policy if exists "Authenticated users can add members" on public.clinic_group_members;
create policy "Authenticated users can add members"
  on public.clinic_group_members for insert
  with check (auth.role() = 'authenticated');

-- RLS: Members can view appointments for all doctors in their clinic groups
drop policy if exists "Members view clinic appointments" on appointments;
create policy "Members view clinic appointments"
  on appointments for select
  using (
    exists (
      select 1 from clinic_group_members cgm_req
      join clinic_group_members cgm_doc
        on cgm_doc.clinic_group_id = cgm_req.clinic_group_id
      where cgm_req.doctor_id = auth.uid()
        and cgm_doc.doctor_id = appointments.doctor_id
    )
    or doctor_id = auth.uid()
  );

-- RLS: Members can insert walk-in appointments for doctors in their group
drop policy if exists "Members insert walk-ins" on appointments;
create policy "Members insert walk-ins"
  on appointments for insert
  with check (
    booking_type = 'manual'
    and exists (
      select 1 from clinic_group_members cgm_req
      join clinic_group_members cgm_doc
        on cgm_doc.clinic_group_id = cgm_req.clinic_group_id
      where cgm_req.doctor_id = auth.uid()
        and cgm_doc.doctor_id = appointments.doctor_id
    )
  );
