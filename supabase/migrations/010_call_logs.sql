-- Migration: Call logs table for desktop-to-phone call notification relay
-- Desktop clicks "Call patient" → inserts row → Realtime pushes to phone → phone launches tel:

create table if not exists public.call_logs (
  id uuid default gen_random_uuid() primary key,
  doctor_id uuid references auth.users(id) on delete cascade not null,
  patient_phone text not null,
  patient_name text,
  patient_id text,
  status text not null default 'pending',
  created_at timestamptz default now()
);

create index if not exists call_logs_doctor_id_idx on public.call_logs(doctor_id);
create index if not exists call_logs_created_at_idx on public.call_logs(created_at desc);

alter table public.call_logs enable row level security;

create policy "Doctors can insert their own call_logs"
  on public.call_logs for insert
  with check (auth.uid() = doctor_id);

create policy "Doctors can view their own call_logs"
  on public.call_logs for select
  using (auth.uid() = doctor_id);

-- Enable Realtime replication for this table
alter publication supabase_realtime add table public.call_logs;
