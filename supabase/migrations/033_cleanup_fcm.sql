-- Cleanup FCM / doctor call notification feature
-- Removes tables and columns that are no longer needed

drop table if exists public.push_tokens;
drop table if exists public.call_logs;

alter table public.appointments drop column if exists fcm_reminder_sent;
alter table public.appointments drop column if exists fcm_reminder_scheduled_at;

drop index if exists idx_appointments_fcm_reminder;
