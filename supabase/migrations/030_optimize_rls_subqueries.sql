-- Optimize RLS policies: wrap auth.uid() in subquery (select auth.uid())
-- This gives up to 100x performance by evaluating auth.uid() once per statement
-- instead of once per row. See: https://supabase.com/blog/row-level-security-performance

-- ============================================
-- PROFILES
-- ============================================
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  using ((select auth.uid()) = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using ((select auth.uid()) = id);

drop policy if exists "Anyone can read doctor profiles" on public.profiles;
create policy "Anyone can read doctor profiles"
  on public.profiles for select
  using (role = 'doctor' or id = (select auth.uid()));

-- ============================================
-- DOCTORS
-- ============================================
drop policy if exists "Doctors can view own doctor profile" on public.doctors;
create policy "Doctors can view own doctor profile"
  on public.doctors for select
  using ((select auth.uid()) = id);

drop policy if exists "Doctors can update own doctor profile" on public.doctors;
create policy "Doctors can update own doctor profile"
  on public.doctors for update
  using ((select auth.uid()) = id);

drop policy if exists "Doctors can insert own doctor profile" on public.doctors;
create policy "Doctors can insert own doctor profile"
  on public.doctors for insert
  with check ((select auth.uid()) = id);

-- ============================================
-- DOCTOR SCHEDULE
-- ============================================
drop policy if exists "Doctors can view own schedule" on public.doctor_schedule;
create policy "Doctors can view own schedule"
  on public.doctor_schedule for select
  using ((select auth.uid()) = doctor_id);

drop policy if exists "Doctors can create schedule" on public.doctor_schedule;
create policy "Doctors can create schedule"
  on public.doctor_schedule for insert
  with check ((select auth.uid()) = doctor_id);

drop policy if exists "Doctors can update own schedule" on public.doctor_schedule;
create policy "Doctors can update own schedule"
  on public.doctor_schedule for update
  using ((select auth.uid()) = doctor_id);

drop policy if exists "Doctors can delete own schedule" on public.doctor_schedule;
create policy "Doctors can delete own schedule"
  on public.doctor_schedule for delete
  using ((select auth.uid()) = doctor_id);

-- ============================================
-- APPOINTMENTS
-- ============================================
drop policy if exists "Patients can view own appointments" on public.appointments;
create policy "Patients can view own appointments"
  on public.appointments for select
  using ((select auth.uid()) = patient_id);

drop policy if exists "Patients can create online appointments" on public.appointments;
create policy "Patients can create online appointments"
  on public.appointments for insert
  with check (
    (select auth.uid()) = patient_id
    and booking_type = 'online'
    and status = 'upcoming'
  );

drop policy if exists "Patients can cancel own upcoming appointments" on public.appointments;
create policy "Patients can cancel own upcoming appointments"
  on public.appointments for update
  using (
    (select auth.uid()) = patient_id
    and status = 'upcoming'
  );

drop policy if exists "Doctors can view own appointments" on public.appointments;
create policy "Doctors can view own appointments"
  on public.appointments for select
  using ((select auth.uid()) = doctor_id);

drop policy if exists "Doctors can update own appointments" on public.appointments;
create policy "Doctors can update own appointments"
  on public.appointments for update
  using ((select auth.uid()) = doctor_id);

drop policy if exists "Doctors can create manual appointments" on public.appointments;
create policy "Doctors can create manual appointments"
  on public.appointments for insert
  with check (
    (select auth.uid()) = doctor_id
    and booking_type = 'manual'
  );

drop policy if exists "Doctors can delete own appointments" on public.appointments;
create policy "Doctors can delete own appointments"
  on public.appointments for delete
  using ((select auth.uid()) = doctor_id);

drop policy if exists "Clinic members view appointments" on public.appointments;
create policy "Clinic members view appointments"
  on appointments for select
  using (
    public.is_same_clinic_group((select auth.uid()), doctor_id)
    or doctor_id = (select auth.uid())
  );

drop policy if exists "Clinic members insert walk-ins" on public.appointments;
create policy "Clinic members insert walk-ins"
  on appointments for insert
  with check (
    booking_type = 'manual'
    and public.is_same_clinic_group((select auth.uid()), appointments.doctor_id)
  );

-- ============================================
-- FAVORITES
-- ============================================
drop policy if exists "Patients can view own favorites" on public.favorites;
create policy "Patients can view own favorites"
  on public.favorites for select
  using ((select auth.uid()) = patient_id);

drop policy if exists "Patients can add favorites" on public.favorites;
create policy "Patients can add favorites"
  on public.favorites for insert
  with check ((select auth.uid()) = patient_id);

drop policy if exists "Patients can remove favorites" on public.favorites;
create policy "Patients can remove favorites"
  on public.favorites for delete
  using ((select auth.uid()) = patient_id);

-- ============================================
-- PATIENTS
-- ============================================
drop policy if exists "Patients can view own profile" on public.patients;
create policy "Patients can view own profile"
  on public.patients for select
  using ((select auth.uid()) = id);

drop policy if exists "Doctors can view patients" on public.patients;
create policy "Doctors can view patients"
  on public.patients for select
  using (
    exists (
      select 1 from public.appointments a
      where a.patient_id = (select auth.uid())
        and a.doctor_id = public.patients.id
    )
    or exists (
      select 1 from public.doctors d
      where d.id = (select auth.uid())
    )
  );

drop policy if exists "Patients can update own profile" on public.patients;
create policy "Patients can update own profile"
  on public.patients for update
  using ((select auth.uid()) = id);

drop policy if exists "Patients can insert own profile" on public.patients;
create policy "Patients can insert own profile"
  on public.patients for insert
  with check ((select auth.uid()) = id);

-- ============================================
-- CALL LOGS
-- ============================================
drop policy if exists "Doctors can insert their own call_logs" on public.call_logs;
create policy "Doctors can insert their own call_logs"
  on public.call_logs for insert
  with check ((select auth.uid()) = doctor_id);

drop policy if exists "Doctors can view their own call_logs" on public.call_logs;
create policy "Doctors can view their own call_logs"
  on public.call_logs for select
  using ((select auth.uid()) = doctor_id);

-- ============================================
-- PUSH TOKENS
-- ============================================
drop policy if exists "Users insert their own push tokens" on public.push_tokens;
create policy "Users insert their own push tokens"
  on public.push_tokens for insert
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users view their own push tokens" on public.push_tokens;
create policy "Users view their own push tokens"
  on public.push_tokens for select
  using ((select auth.uid()) = user_id);

drop policy if exists "Users update their own push tokens" on public.push_tokens;
create policy "Users update their own push tokens"
  on public.push_tokens for update
  using ((select auth.uid()) = user_id);

drop policy if exists "Users delete their own push tokens" on public.push_tokens;
create policy "Users delete their own push tokens"
  on public.push_tokens for delete
  using ((select auth.uid()) = user_id);

-- ============================================
-- PAYMENT HISTORY
-- ============================================
drop policy if exists "Doctors can view own payment history" on public.payment_history;
create policy "Doctors can view own payment history"
  on public.payment_history for select
  using ((select auth.uid()) = doctor_id);

-- ============================================
-- PATIENT NOTES
-- ============================================
drop policy if exists "Doctors can select own notes" on public.patient_notes;
create policy "Doctors can select own notes"
  on public.patient_notes for select
  using ((select auth.uid()) = doctor_id);

drop policy if exists "Doctors can insert own notes" on public.patient_notes;
create policy "Doctors can insert own notes"
  on public.patient_notes for insert
  with check ((select auth.uid()) = doctor_id);

drop policy if exists "Doctors can update own notes" on public.patient_notes;
create policy "Doctors can update own notes"
  on public.patient_notes for update
  using ((select auth.uid()) = doctor_id);

drop policy if exists "Doctors can delete own notes" on public.patient_notes;
create policy "Doctors can delete own notes"
  on public.patient_notes for delete
  using ((select auth.uid()) = doctor_id);

-- ============================================
-- CLINIC GROUPS
-- ============================================
drop policy if exists "Members view clinic group" on public.clinic_groups;
create policy "Members view clinic group"
  on public.clinic_groups for select
  using (
    exists (
      select 1 from clinic_group_members
      where clinic_group_id = id
        and doctor_id = (select auth.uid())
    )
  );

drop policy if exists "Anyone can view clinic groups" on public.clinic_groups;
create policy "Anyone can view clinic groups"
  on public.clinic_groups for select
  using ((select auth.role()) = 'authenticated');

-- ============================================
-- CLINIC GROUP MEMBERS
-- ============================================
drop policy if exists "Users can view own memberships" on public.clinic_group_members;
create policy "Users can view own memberships"
  on public.clinic_group_members for select
  using (doctor_id = (select auth.uid()));

drop policy if exists "Clinic members can remove members" on public.clinic_group_members;
create policy "Clinic members can remove members"
  on public.clinic_group_members for delete
  using (public.is_same_clinic_group((select auth.uid()), doctor_id));
