-- Eyadati Database Setup (Reset & Create)
-- This migration drops existing tables and creates fresh ones

-- Drop existing tables and functions if they exist (for clean setup)
drop table if exists public.favorites cascade;
drop table if exists public.appointments cascade;
drop table if exists public.doctors cascade;
drop table if exists public.profiles cascade;

drop function if exists public.handle_new_user cascade;
drop function if exists public.update_updated_at cascade;
drop function if exists public.check_doctor_availability cascade;
drop function if exists public.check_slot_availability cascade;
drop function if exists public.book_appointment cascade;

-- Enable pgcrypto extension for UUID generation
create extension if not exists "pgcrypto";

-- ============================================
-- PROFILES TABLE
-- Stores all authenticated users
-- ============================================
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('patient', 'doctor')),
  full_name text not null,
  email text,
  phone text,
  city text,
  avatar_url text,
  created_at timestamptz default now()
);

-- Index for role-based queries
create index idx_profiles_role on public.profiles(role);

-- Enable RLS
alter table public.profiles enable row level security;

-- RLS Policies for profiles
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- ============================================
-- DOCTORS TABLE
-- Stores doctor-specific public/business information
-- ============================================
create table public.doctors (
  id uuid primary key references public.profiles(id) on delete cascade,

  specialty text not null,
  address text not null,
  city text,
  maps_link text,

  latitude double precision,
  longitude double precision,

  bio text,
  photo_url text,

  appointment_duration integer not null default 20,
  consultation_duration integer not null default 40,

  opening_at integer not null default 9,
  closing_at integer not null default 17,

  break_start integer,
  break_end integer,

  working_days text[] not null default ARRAY['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],

  manual_pause boolean default false,
  subscription_end timestamptz not null default (now() + interval '1 month'),

  created_at timestamptz default now()
);

-- Indexes for doctor queries
create index idx_doctors_specialty on public.doctors(specialty);
create index idx_doctors_city on public.doctors(city);
create index idx_doctors_subscription on public.doctors(subscription_end);
create index idx_doctors_pause on public.doctors(manual_pause);

-- Enable RLS
alter table public.doctors enable row level security;

-- RLS Policies for doctors
create policy "Public can view active doctors"
  on public.doctors for select
  using (
    subscription_end > now()
    and manual_pause = false
  );

create policy "Doctors can view own doctor profile"
  on public.doctors for select
  using (auth.uid() = id);

create policy "Doctors can update own doctor profile"
  on public.doctors for update
  using (auth.uid() = id);

create policy "Doctors can insert own doctor profile"
  on public.doctors for insert
  with check (auth.uid() = id);

-- ============================================
-- APPOINTMENTS TABLE
-- Stores both online and manual appointments
-- ============================================
create table public.appointments (
  id uuid primary key default gen_random_uuid(),

  doctor_id uuid not null references public.doctors(id) on delete cascade,
  patient_id uuid references public.profiles(id) on delete set null,

  scheduled_at timestamptz not null,
  duration integer not null,

  status text not null check (
    status in ('upcoming', 'completed', 'cancelled', 'absent')
  ),

  booking_type text not null check (
    booking_type in ('online', 'manual')
  ),

  is_consultation boolean default false,

  patient_name_snapshot text not null,
  patient_phone_snapshot text,

  notes text,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes for appointment queries
create index idx_appointments_doctor on public.appointments(doctor_id);
create index idx_appointments_patient on public.appointments(patient_id);
create index idx_appointments_date on public.appointments(scheduled_at);
create index idx_appointments_status on public.appointments(status);
create index idx_appointments_doctor_date on public.appointments(doctor_id, scheduled_at);

-- Enable RLS
alter table public.appointments enable row level security;

-- RLS Policies for appointments
create policy "Patients can view own appointments"
  on public.appointments for select
  using (auth.uid() = patient_id);

create policy "Patients can create own appointments"
  on public.appointments for insert
  with check (
    auth.uid() = patient_id
    and booking_type = 'online'
  );

create policy "Patients can cancel own appointments"
  on public.appointments for update
  using (
    auth.uid() = patient_id
    and status = 'upcoming'
  );

create policy "Doctors can view own appointments"
  on public.appointments for select
  using (auth.uid() = doctor_id);

create policy "Doctors can update own appointments"
  on public.appointments for update
  using (auth.uid() = doctor_id);

create policy "Doctors can create manual appointments"
  on public.appointments for insert
  with check (
    auth.uid() = doctor_id
    and booking_type = 'manual'
  );

-- ============================================
-- FAVORITES TABLE
-- Stores patient favorite doctors
-- ============================================
create table public.favorites (
  patient_id uuid not null references public.profiles(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  created_at timestamptz default now(),

  primary key (patient_id, doctor_id)
);

-- Indexes for favorites queries
create index idx_favorites_patient on public.favorites(patient_id);
create index idx_favorites_doctor on public.favorites(doctor_id);

-- Enable RLS
alter table public.favorites enable row level security;

-- RLS Policies for favorites
create policy "Patients can view own favorites"
  on public.favorites for select
  using (auth.uid() = patient_id);

create policy "Patients can add favorites"
  on public.favorites for insert
  with check (auth.uid() = patient_id);

create policy "Patients can remove favorites"
  on public.favorites for delete
  using (auth.uid() = patient_id);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function: Handle new user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    coalesce(new.raw_user_meta_data->>'role', 'patient')
  );
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to create profile on auth signup
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Function: Update updated_at timestamp
create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Trigger for appointments updated_at
drop trigger if exists appointments_updated_at on public.appointments;
create trigger appointments_updated_at
  before update on public.appointments
  for each row execute procedure public.update_updated_at();

-- Function: Check doctor availability
create or replace function public.check_doctor_availability(doctor_uuid uuid)
returns boolean as $$
declare
  doctor_record record;
begin
  select into doctor_record
    manual_pause,
    subscription_end
  from public.doctors
  where id = doctor_uuid;

  if not found then
    return false;
  end if;

  if doctor_record.manual_pause = true then
    return false;
  end if;

  if doctor_record.subscription_end <= now() then
    return false;
  end if;

  return true;
end;
$$ language plpgsql security definer;

-- Function: Check slot availability
create or replace function public.check_slot_availability(
  doctor_uuid uuid,
  slot_time timestamptz,
  slot_duration integer
)
returns boolean as $$
declare
  conflict_count integer;
begin
  select count(*) into conflict_count
  from public.appointments
  where doctor_id = doctor_uuid
    and status = 'upcoming'
    and (
      (scheduled_at, scheduled_at + (duration || ' minutes')::interval)
      overlaps
      (slot_time, slot_time + (slot_duration || ' minutes')::interval)
    );

  return conflict_count = 0;
end;
$$ language plpgsql security definer;

-- Function: Book appointment with validation
create or replace function public.book_appointment(
  p_doctor_id uuid,
  p_patient_id uuid,
  p_scheduled_at timestamptz,
  p_duration integer,
  p_patient_name text,
  p_patient_phone text,
  p_is_consultation boolean default false,
  p_notes text default null
)
returns uuid as $$
declare
  v_appointment_id uuid;
  v_available boolean;
  v_doctor_active boolean;
begin
  select public.check_doctor_availability(p_doctor_id) into v_doctor_active;
  if not v_doctor_active then
    raise exception 'Doctor is not available for booking';
  end if;

  select public.check_slot_availability(p_doctor_id, p_scheduled_at, p_duration) into v_available;
  if not v_available then
    raise exception 'This time slot is not available';
  end if;

  insert into public.appointments (
    doctor_id,
    patient_id,
    scheduled_at,
    duration,
    status,
    booking_type,
    is_consultation,
    patient_name_snapshot,
    patient_phone_snapshot,
    notes
  ) values (
    p_doctor_id,
    p_patient_id,
    p_scheduled_at,
    p_duration,
    'upcoming',
    'online',
    p_is_consultation,
    p_patient_name,
    p_patient_phone,
    p_notes
  )
  returning id into v_appointment_id;

  return v_appointment_id;
end;
$$ language plpgsql security definer;

-- Grant permissions
grant usage on schema public to anon;
grant execute on all functions in schema public to anon;
grant select on all tables in schema public to anon;
grant insert on public.appointments to anon;
grant update on public.appointments to anon;
grant delete on public.appointments to anon;
grant insert on public.favorites to anon;
grant delete on public.favorites to anon;
