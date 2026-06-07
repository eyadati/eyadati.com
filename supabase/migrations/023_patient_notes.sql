-- Migration: Patient notes for online patient history
-- Each note belongs to an appointment, a patient, and a doctor
-- No orphan notes allowed

create table if not exists public.patient_notes (
  id uuid default gen_random_uuid() primary key,
  patient_id uuid references auth.users(id) on delete cascade not null,
  doctor_id uuid references auth.users(id) on delete cascade not null,
  appointment_id uuid references public.appointments(id) on delete cascade not null,
  note_text text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists patient_notes_patient_id_idx on public.patient_notes(patient_id);
create index if not exists patient_notes_doctor_id_idx on public.patient_notes(doctor_id);
create index if not exists patient_notes_appointment_id_idx on public.patient_notes(appointment_id);
create index if not exists patient_notes_created_at_idx on public.patient_notes(created_at desc);

alter table public.patient_notes enable row level security;

drop policy if exists "Doctors can select own notes" on public.patient_notes;
create policy "Doctors can select own notes"
  on public.patient_notes for select
  using (auth.uid() = doctor_id);

drop policy if exists "Doctors can insert own notes" on public.patient_notes;
create policy "Doctors can insert own notes"
  on public.patient_notes for insert
  with check (auth.uid() = doctor_id);

drop policy if exists "Doctors can update own notes" on public.patient_notes;
create policy "Doctors can update own notes"
  on public.patient_notes for update
  using (auth.uid() = doctor_id);

drop policy if exists "Doctors can delete own notes" on public.patient_notes;
create policy "Doctors can delete own notes"
  on public.patient_notes for delete
  using (auth.uid() = doctor_id);

-- Enable Realtime replication
do $$
begin
  alter publication supabase_realtime add table public.patient_notes;
exception
  when duplicate_object then null;
end $$;
