-- Explicit Data API Grants
-- As of mid-2026, new tables are no longer auto-exposed to the Data API.
-- Must explicitly grant Postgres permissions for the frontend to access them.

-- Grant schema usage
grant usage on schema public to anon, authenticated;

-- Profiles
grant select, insert, update on public.profiles to anon, authenticated;

-- Doctors
grant select, insert, update on public.doctors to anon, authenticated;

-- Doctor schedule
grant select, insert, update, delete on public.doctor_schedule to anon, authenticated;

-- Appointments
grant select, insert, update, delete on public.appointments to anon, authenticated;

-- Favorites
grant select, insert, delete on public.favorites to anon, authenticated;

-- Patients
grant select, insert, update on public.patients to anon, authenticated;

-- Call logs
grant select, insert on public.call_logs to anon, authenticated;

-- Push tokens
grant select, insert, update, delete on public.push_tokens to anon, authenticated;

-- Payment history
grant select on public.payment_history to anon, authenticated;

-- Clinic groups
grant select, insert, update, delete on public.clinic_groups to anon, authenticated;

-- Clinic group members
grant select, insert, delete on public.clinic_group_members to anon, authenticated;

-- Patient notes
grant select, insert, update, delete on public.patient_notes to anon, authenticated;
