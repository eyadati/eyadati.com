-- Run this in Supabase SQL Editor after deploying the send-appointment-reminder function
-- Schedules the function to run every 1 minute, checking for pending reminders

select cron.schedule(
  'send-appointment-reminders',
  '* * * * *',
  $$ select net.http_post(
    url := 'https://erkldarqweehvwgpncrg.supabase.co/functions/v1/send-appointment-reminder',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  )::text $$
);
