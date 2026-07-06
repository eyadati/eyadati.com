-- Migration: Add FCM reminder tracking columns to appointments
-- Enables 12h push notification reminders with fallback for short-notice bookings

alter table public.appointments
add column fcm_reminder_sent boolean default false,
add column fcm_reminder_scheduled_at timestamptz;

create index idx_appointments_fcm_reminder
  on public.appointments(fcm_reminder_scheduled_at, fcm_reminder_sent)
  where fcm_reminder_sent = false;
