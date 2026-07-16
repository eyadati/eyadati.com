-- ============================================
-- Eyadati: Marketing appointments with scores
-- Doctor: 44350705-98cb-4b8a-bcc4-594dc8cb5534
-- ============================================

-- Clean up old test data
DELETE FROM appointments
WHERE doctor_id = '44350705-98cb-4b8a-bcc4-594dc8cb5534'
  AND scheduled_at >= '2026-07-05 00:00:00+01'
  AND scheduled_at <  '2026-07-19 00:00:00+01';

-- Ensure pgcrypto is available for password hashing
create extension if not exists "pgcrypto";

-- ============================================
-- 1. Create patient auth users & profiles
-- ============================================
-- Score test scenarios:
--   Slimane Berkani:  5 appts, 2 no_shows → 60%   → BLOCKED
--   Tahar Mansouri:   3 appts, 1 no_show  → 67%   → BLOCKED
--   Abdelkader Nouar: 4 appts, 2 no_shows → 50%   → BLOCKED
--   Zineb Ghozali:    4 appts, 1 no_show  → 75%   → NOT blocked (edge)
--   Others:           all present          → 100%  → not blocked

with
patients_data (name, phone, email) as (
  values
    ('Malika Tlemcani',   '0776 78 90 12', 'malika.tlemcani@patient.eyadati.dz'),
    ('Houria Bekkar',     '0552 34 56 78', 'houria.bekkar@patient.eyadati.dz'),
    ('Yacine Khelifi',    '0660 12 34 56', 'yacine.khelifi@patient.eyadati.dz'),
    ('Fouad Sari',        '0669 01 23 45', 'fouad.sari@patient.eyadati.dz'),
    ('Meryem Benali',     '0661 23 45 67', 'meryem.benali@patient.eyadati.dz'),
    ('Leila Messaoudi',   '0775 67 89 01', 'leila.messaoudi@patient.eyadati.dz'),
    ('Saida Rahmani',     '0666 78 90 12', 'saida.rahmani@patient.eyadati.dz'),
    ('Nadia Amrani',      '0553 45 67 89', 'nadia.amrani@patient.eyadati.dz'),
    ('Latifa Dris',       '0662 34 56 78', 'latifa.dris@patient.eyadati.dz'),
    ('Slimane Berkani',   '0779 01 23 45', 'slimane.berkani@patient.eyadati.dz'),
    ('Zineb Ghozali',     '0770 12 34 56', 'zineb.ghozali@patient.eyadati.dz'),
    ('Tahar Mansouri',    '0663 45 67 89', 'tahar.mansouri@patient.eyadati.dz'),
    ('Nabil Ait',         '0555 67 89 01', 'nabil.ait@patient.eyadati.dz'),
    ('Mourad Sakri',      '0773 45 67 89', 'mourad.sakri@patient.eyadati.dz'),
    ('Karim Hadj',        '0772 34 56 78', 'karim.hadj@patient.eyadati.dz'),
    ('Sami Meziane',      '0771 23 45 67', 'sami.meziane@patient.eyadati.dz'),
    ('Farid Bensalem',    '0665 67 89 01', 'farid.bensalem@patient.eyadati.dz'),
    ('Nora Yahia',        '0668 90 12 34', 'nora.yahia@patient.eyadati.dz'),
    ('Sofiane Belaid',    '0664 56 78 90', 'sofiane.belaid@patient.eyadati.dz'),
    ('Naima Boukhriss',   '0558 90 12 34', 'naima.boukhriss@patient.eyadati.dz'),
    ('Lamine Cherif',     '0778 90 12 34', 'lamine.cherif@patient.eyadati.dz'),
    ('Rabah Lounis',      '0551 23 45 67', 'rabah.lounis@patient.eyadati.dz'),
    ('Rachid Ouali',      '0556 78 90 12', 'rachid.ouali@patient.eyadati.dz'),
    ('Hichem Gacem',      '0777 89 01 23', 'hichem.gacem@patient.eyadati.dz'),
    ('Salima Bouzid',     '0559 01 23 45', 'salima.bouzid@patient.eyadati.dz'),
    ('Fatima Zidane',     '0667 89 01 23', 'fatima.zidane@patient.eyadati.dz'),
    ('Ahmed Toumi',       '0550 12 34 56', 'ahmed.toumi@patient.eyadati.dz'),
    ('Wassila Djemai',    '0774 56 78 90', 'wassila.djemai@patient.eyadati.dz'),
    ('Djamila Kaci',      '0554 56 78 90', 'djamila.kaci@patient.eyadati.dz')
),
created_auth as (
  insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
  select
    gen_random_uuid(),
    email,
    crypt('test123', gen_salt('bf')),
    now(),
    jsonb_build_object('full_name', name),
    now(),
    now()
  from patients_data
  returning id, raw_user_meta_data->>'full_name' as full_name
),
created_profiles as (
  insert into public.profiles (id, role, full_name)
  select id, 'patient', full_name
  from created_auth
  returning id, full_name
)
select 'Created ' || count(*) || ' patient profiles' as result from created_profiles;

-- ============================================
-- 2. Insert appointments with scores
-- ============================================
-- All dates are past (July 5-11), so status = 'completed'
-- attendance_status: most are 'present', some 'no_show' for score testing
-- patient_id is looked up from profiles by full_name

with
patient_ids as (
  select id, full_name from public.profiles where role = 'patient'
)
insert into appointments (doctor_id, patient_id, scheduled_at, duration, status, booking_type, is_consultation, patient_name_snapshot, patient_phone_snapshot, notes, attendance_status)
select
  '44350705-98cb-4b8a-bcc4-594dc8cb5534',
  pid.id,
  vals.scheduled_at,
  vals.duration,
  'completed',
  vals.booking_type,
  vals.is_consultation,
  vals.name,
  vals.phone,
  vals.notes,
  vals.attendance
from (
  values
    -- ===== DIMANCHE July 5 =====
    ('2026-07-05 08:00:00+01'::timestamptz, 40, 'online', false, 'Malika Tlemcani',  '0776 78 90 12', 'Angine',                  'present'),
    ('2026-07-05 08:40:00+01'::timestamptz, 30, 'online', false, 'Houria Bekkar',     '0552 34 56 78', 'Bilan annuel',            'present'),
    ('2026-07-05 09:10:00+01'::timestamptz, 25, 'manual', true,  'Yacine Khelifi',    '0660 12 34 56', 'Renouvellement ordonnance','present'),
    ('2026-07-05 09:35:00+01'::timestamptz, 30, 'online', false, 'Fouad Sari',        '0669 01 23 45', 'Consultation cardiologie','present'),
    ('2026-07-05 10:05:00+01'::timestamptz, 30, 'online', false, 'Meryem Benali',     '0661 23 45 67', 'Douleurs articulaires',   'present'),
    ('2026-07-05 10:35:00+01'::timestamptz, 25, 'manual', true,  'Leila Messaoudi',   '0775 67 89 01', 'Consultation approfondie','present'),
    ('2026-07-05 11:00:00+01'::timestamptz, 30, 'online', false, 'Saida Rahmani',     '0666 78 90 12', 'Migraines chroniques',    'present'),
    ('2026-07-05 11:30:00+01'::timestamptz, 15, 'manual', true,  'Nadia Amrani',      '0553 45 67 89', 'Douleurs lombaires',      'present'),
    ('2026-07-05 13:00:00+01'::timestamptz, 35, 'online', false, 'Latifa Dris',       '0662 34 56 78', 'Fièvre persistante',      'present'),
    ('2026-07-05 13:35:00+01'::timestamptz, 30, 'online', false, 'Slimane Berkani',   '0779 01 23 45', 'Consultation approfondie','no_show'),   -- 1/2
    ('2026-07-05 14:05:00+01'::timestamptz, 20, 'online', true,  'Zineb Ghozali',     '0770 12 34 56', 'Fièvre persistante',      'present'),
    ('2026-07-05 14:25:00+01'::timestamptz, 40, 'manual', false, 'Tahar Mansouri',    '0663 45 67 89', 'Consultation approfondie','present'),
    ('2026-07-05 15:05:00+01'::timestamptz, 30, 'online', false, 'Nabil Ait',         '0555 67 89 01', 'Suivi',                  'present'),
    ('2026-07-05 15:35:00+01'::timestamptz, 25, 'online', true,  'Mourad Sakri',      '0773 45 67 89', 'Certificat médical',      'present'),
    ('2026-07-05 16:00:00+01'::timestamptz, 40, 'online', false, 'Karim Hadj',        '0772 34 56 78', 'Allergies',               'present'),
    ('2026-07-05 16:40:00+01'::timestamptz, 25, 'online', true,  'Sami Meziane',      '0771 23 45 67', 'Bilan sanguin',           'present'),
    ('2026-07-05 17:05:00+01'::timestamptz, 30, 'online', false, 'Farid Bensalem',    '0665 67 89 01', 'Renouvellement traitement','present'),
    ('2026-07-05 17:35:00+01'::timestamptz, 40, 'online', false, 'Nora Yahia',        '0668 90 12 34', 'Bilan complet',           'present'),
    ('2026-07-05 18:15:00+01'::timestamptz, 25, 'online', true,  'Sofiane Belaid',    '0664 56 78 90', 'Douleurs lombaires',      'present'),
    ('2026-07-05 18:40:00+01'::timestamptz, 30, 'online', false, 'Naima Boukhriss',   '0558 90 12 34', 'Certificat médical',      'present'),
    ('2026-07-05 19:10:00+01'::timestamptz, 30, 'online', false, 'Lamine Cherif',     '0778 90 12 34', 'Bilan sanguin',           'present'),
    -- ===== LUNDI July 6 =====
    ('2026-07-06 08:00:00+01'::timestamptz, 35, 'online', false, 'Yacine Khelifi',    '0660 12 34 56', 'Fièvre persistante',      'present'),
    ('2026-07-06 08:35:00+01'::timestamptz, 20, 'manual', true,  'Sofiane Belaid',    '0664 56 78 90', 'Angine',                  'present'),
    ('2026-07-06 08:55:00+01'::timestamptz, 40, 'online', false, 'Saida Rahmani',     '0666 78 90 12', 'Bilan annuel',            'present'),
    ('2026-07-06 09:35:00+01'::timestamptz, 30, 'online', false, 'Houria Bekkar',     '0552 34 56 78', 'Check-up général',        'present'),
    ('2026-07-06 10:05:00+01'::timestamptz, 25, 'manual', true,  'Rabah Lounis',      '0551 23 45 67', 'Renouvellement ordonnance','present'),
    ('2026-07-06 10:30:00+01'::timestamptz, 35, 'manual', false, 'Latifa Dris',       '0662 34 56 78', 'Douleurs dorsales',       'present'),
    ('2026-07-06 11:05:00+01'::timestamptz, 15, 'online', true,  'Nadia Amrani',      '0553 45 67 89', 'Bilan complet',           'present'),
    ('2026-07-06 11:20:00+01'::timestamptz, 30, 'manual', false, 'Rachid Ouali',      '0556 78 90 12', 'Fatigue chronique',       'present'),
    ('2026-07-06 13:00:00+01'::timestamptz, 30, 'manual', false, 'Slimane Berkani',   '0779 01 23 45', 'Douleurs lombaires',      'present'),
    ('2026-07-06 13:30:00+01'::timestamptz, 25, 'online', true,  'Sami Meziane',      '0771 23 45 67', 'Suivi tension',           'present'),
    ('2026-07-06 13:55:00+01'::timestamptz, 40, 'online', false, 'Hichem Gacem',      '0777 89 01 23', 'Consultation approfondie','present'),
    ('2026-07-06 14:35:00+01'::timestamptz, 40, 'online', false, 'Salima Bouzid',     '0559 01 23 45', 'Consultation approfondie','present'),
    ('2026-07-06 15:15:00+01'::timestamptz, 25, 'online', true,  'Fouad Sari',        '0669 01 23 45', 'Fièvre persistante',      'present'),
    ('2026-07-06 15:40:00+01'::timestamptz, 40, 'online', false, 'Nora Yahia',        '0668 90 12 34', 'Consultation approfondie','present'),
    ('2026-07-06 16:20:00+01'::timestamptz, 25, 'online', true,  'Zineb Ghozali',     '0770 12 34 56', 'Migraines chroniques',    'present'),
    ('2026-07-06 16:45:00+01'::timestamptz, 35, 'online', false, 'Tahar Mansouri',    '0663 45 67 89', 'Suivi post-opératoire',   'present'),
    ('2026-07-06 17:20:00+01'::timestamptz, 40, 'online', false, 'Abdelkader Nouar',  '0557 89 01 23', 'Angine',                  'present'),
    ('2026-07-06 18:00:00+01'::timestamptz, 20, 'online', true,  'Fatima Zidane',     '0667 89 01 23', 'Consultation cardiologie','present'),
    ('2026-07-06 18:20:00+01'::timestamptz, 30, 'online', false, 'Ahmed Toumi',       '0550 12 34 56', 'Consultation cardiologie','present'),
    ('2026-07-06 18:50:00+01'::timestamptz, 25, 'online', true,  'Lamine Cherif',     '0778 90 12 34', 'Certificat médical',      'present'),
    ('2026-07-06 19:15:00+01'::timestamptz, 30, 'online', false, 'Naima Boukhriss',   '0558 90 12 34', 'Grippe',                  'present'),
    -- ===== MARDI July 7 =====
    ('2026-07-07 08:00:00+01'::timestamptz, 40, 'manual', false, 'Karim Hadj',        '0772 34 56 78', 'Douleurs articulaires',   'present'),
    ('2026-07-07 08:40:00+01'::timestamptz, 30, 'online', false, 'Nora Yahia',        '0668 90 12 34', 'Fatigue générale',        'present'),
    ('2026-07-07 09:10:00+01'::timestamptz, 40, 'online', false, 'Nabil Ait',         '0555 67 89 01', 'Douleurs lombaires',      'present'),
    ('2026-07-07 09:50:00+01'::timestamptz, 25, 'manual', true,  'Fatima Zidane',     '0667 89 01 23', 'Fatigue chronique',       'present'),
    ('2026-07-07 10:15:00+01'::timestamptz, 30, 'online', false, 'Houria Bekkar',     '0552 34 56 78', 'Allergies',               'present'),
    ('2026-07-07 10:45:00+01'::timestamptz, 35, 'online', false, 'Fouad Sari',        '0669 01 23 45', 'Migraines chroniques',    'present'),
    ('2026-07-07 11:20:00+01'::timestamptz, 25, 'online', true,  'Yacine Khelifi',    '0660 12 34 56', 'Consultation approfondie','present'),
    ('2026-07-07 13:00:00+01'::timestamptz, 30, 'online', false, 'Wassila Djemai',    '0774 56 78 90', 'Résultat analyse',        'present'),
    ('2026-07-07 13:30:00+01'::timestamptz, 15, 'online', true,  'Meryem Benali',     '0661 23 45 67', 'Renouvellement traitement','present'),
    ('2026-07-07 13:45:00+01'::timestamptz, 40, 'online', false, 'Abdelkader Nouar',  '0557 89 01 23', 'Fièvre persistante',      'no_show'),  -- 1/2
    ('2026-07-07 14:25:00+01'::timestamptz, 40, 'manual', false, 'Ahmed Toumi',       '0550 12 34 56', 'Migraines chroniques',    'present'),
    ('2026-07-07 15:05:00+01'::timestamptz, 20, 'manual', true,  'Djamila Kaci',      '0554 56 78 90', 'Angine',                  'present'),
    ('2026-07-07 15:25:00+01'::timestamptz, 30, 'manual', false, 'Malika Tlemcani',   '0776 78 90 12', 'Consultation approfondie','present'),
    ('2026-07-07 15:55:00+01'::timestamptz, 35, 'manual', false, 'Rabah Lounis',      '0551 23 45 67', 'Renouvellement ordonnance','present'),
    ('2026-07-07 16:30:00+01'::timestamptz, 40, 'online', false, 'Naima Boukhriss',   '0558 90 12 34', 'Suivi tension',           'present'),
    ('2026-07-07 17:10:00+01'::timestamptz, 15, 'online', true,  'Slimane Berkani',   '0779 01 23 45', 'Douleurs dorsales',       'no_show'),  -- 2/2
    ('2026-07-07 17:25:00+01'::timestamptz, 30, 'manual', false, 'Leila Messaoudi',   '0775 67 89 01', 'Fièvre persistante',      'present'),
    ('2026-07-07 17:55:00+01'::timestamptz, 20, 'manual', true,  'Rachid Ouali',      '0556 78 90 12', 'Fièvre persistante',      'present'),
    ('2026-07-07 18:15:00+01'::timestamptz, 30, 'online', false, 'Saida Rahmani',     '0666 78 90 12', 'Fatigue chronique',        'present'),
    ('2026-07-07 18:45:00+01'::timestamptz, 30, 'online', false, 'Sofiane Belaid',    '0664 56 78 90', 'Fatigue générale',        'no_show'),
    ('2026-07-07 19:15:00+01'::timestamptz, 30, 'online', false, 'Nadia Amrani',      '0553 45 67 89', 'Résultat analyse',        'present'),
    -- ===== MERCREDI July 8 =====
    ('2026-07-08 08:00:00+01'::timestamptz, 25, 'online', true,  'Abdelkader Nouar',  '0557 89 01 23', 'Angine',                  'no_show'),  -- 2/2
    ('2026-07-08 08:25:00+01'::timestamptz, 35, 'online', false, 'Fatima Zidane',     '0667 89 01 23', 'Bilan sanguin',           'present'),
    ('2026-07-08 09:00:00+01'::timestamptz, 35, 'online', false, 'Fouad Sari',        '0669 01 23 45', 'Douleurs lombaires',      'present'),
    ('2026-07-08 09:35:00+01'::timestamptz, 25, 'manual', true,  'Nabil Ait',         '0555 67 89 01', 'Fatigue générale',        'present'),
    ('2026-07-08 10:00:00+01'::timestamptz, 30, 'online', false, 'Leila Messaoudi',   '0775 67 89 01', 'Consultation neurologie', 'present'),
    ('2026-07-08 10:30:00+01'::timestamptz, 30, 'online', false, 'Ahmed Toumi',       '0550 12 34 56', 'Check-up général',        'present'),
    ('2026-07-08 11:00:00+01'::timestamptz, 20, 'manual', true,  'Wassila Djemai',    '0774 56 78 90', 'Bilan complet',           'present'),
    ('2026-07-08 11:20:00+01'::timestamptz, 40, 'online', false, 'Nora Yahia',        '0668 90 12 34', 'Résultat analyse',        'present'),
    ('2026-07-08 13:00:00+01'::timestamptz, 30, 'online', false, 'Meryem Benali',     '0661 23 45 67', 'Consultation cardiologie','present'),
    ('2026-07-08 13:30:00+01'::timestamptz, 15, 'online', true,  'Zineb Ghozali',     '0770 12 34 56', 'Certificat médical',      'no_show'),  -- 1 no-show
    ('2026-07-08 13:45:00+01'::timestamptz, 35, 'online', false, 'Malika Tlemcani',   '0776 78 90 12', 'Consultation diabète',    'present'),
    ('2026-07-08 14:20:00+01'::timestamptz, 40, 'online', false, 'Yacine Khelifi',    '0660 12 34 56', 'Renouvellement ordonnance','present'),
    ('2026-07-08 15:00:00+01'::timestamptz, 35, 'online', false, 'Naima Boukhriss',   '0558 90 12 34', 'Douleurs abdominales',    'present'),
    ('2026-07-08 15:35:00+01'::timestamptz, 20, 'online', true,  'Sami Meziane',      '0771 23 45 67', 'Résultat analyse',        'present'),
    ('2026-07-08 15:55:00+01'::timestamptz, 40, 'manual', false, 'Sofiane Belaid',    '0664 56 78 90', 'Consultation neurologie', 'present'),
    ('2026-07-08 16:35:00+01'::timestamptz, 35, 'online', false, 'Nadia Amrani',      '0553 45 67 89', 'Consultation spécialisée','present'),
    ('2026-07-08 17:10:00+01'::timestamptz, 15, 'online', true,  'Saida Rahmani',     '0666 78 90 12', 'Douleurs articulaires',   'present'),
    ('2026-07-08 17:25:00+01'::timestamptz, 15, 'online', true,  'Tahar Mansouri',    '0663 45 67 89', 'Migraines chroniques',    'no_show'),  -- 1 no-show
    ('2026-07-08 17:40:00+01'::timestamptz, 30, 'online', false, 'Farid Bensalem',    '0665 67 89 01', 'Consultation diabète',    'present'),
    ('2026-07-08 18:10:00+01'::timestamptz, 30, 'online', false, 'Rachid Ouali',      '0556 78 90 12', 'Migraines',               'present'),
    ('2026-07-08 18:40:00+01'::timestamptz, 25, 'online', true,  'Djamila Kaci',      '0554 56 78 90', 'Consultation approfondie','present'),
    ('2026-07-08 19:05:00+01'::timestamptz, 40, 'online', false, 'Lamine Cherif',     '0778 90 12 34', 'Fatigue générale',        'present'),
    -- ===== JEUDI July 9 =====
    ('2026-07-09 08:00:00+01'::timestamptz, 30, 'online', false, 'Fatima Zidane',     '0667 89 01 23', 'Bilan annuel',            'present'),
    ('2026-07-09 08:30:00+01'::timestamptz, 30, 'online', false, 'Malika Tlemcani',   '0776 78 90 12', 'Check-up général',        'present'),
    ('2026-07-09 09:00:00+01'::timestamptz, 20, 'online', true,  'Nabil Ait',         '0555 67 89 01', 'Douleurs articulaires',   'present'),
    ('2026-07-09 09:20:00+01'::timestamptz, 40, 'online', false, 'Salima Bouzid',     '0559 01 23 45', 'Fièvre persistante',      'present'),
    ('2026-07-09 10:00:00+01'::timestamptz, 40, 'online', false, 'Abdelkader Nouar',  '0557 89 01 23', 'Toux persistante',        'present'),
    ('2026-07-09 10:40:00+01'::timestamptz, 30, 'online', false, 'Sofiane Belaid',    '0664 56 78 90', 'Renouvellement ordonnance','present'),
    ('2026-07-09 11:10:00+01'::timestamptz, 15, 'online', true,  'Fouad Sari',        '0669 01 23 45', 'Douleurs dorsales',       'present'),
    ('2026-07-09 13:00:00+01'::timestamptz, 35, 'manual', false, 'Rachid Ouali',      '0556 78 90 12', 'Check-up général',        'present'),
    ('2026-07-09 13:35:00+01'::timestamptz, 25, 'online', true,  'Mourad Sakri',      '0773 45 67 89', 'Fatigue générale',        'present'),
    ('2026-07-09 14:00:00+01'::timestamptz, 30, 'online', false, 'Yacine Khelifi',    '0660 12 34 56', 'Consultation diabète',    'present'),
    ('2026-07-09 14:30:00+01'::timestamptz, 40, 'online', false, 'Wassila Djemai',    '0774 56 78 90', 'Suivi',                   'present'),
    ('2026-07-09 15:10:00+01'::timestamptz, 25, 'manual', true,  'Tahar Mansouri',    '0663 45 67 89', 'Consultation neurologie', 'present'),
    ('2026-07-09 15:35:00+01'::timestamptz, 30, 'online', false, 'Farid Bensalem',    '0665 67 89 01', 'Consultation diabète',    'present'),
    ('2026-07-09 16:05:00+01'::timestamptz, 35, 'online', false, 'Leila Messaoudi',   '0775 67 89 01', 'Bilan complet',           'present'),
    ('2026-07-09 16:40:00+01'::timestamptz, 15, 'manual', true,  'Nadia Amrani',      '0553 45 67 89', 'Suivi tension',           'present'),
    ('2026-07-09 16:55:00+01'::timestamptz, 40, 'online', false, 'Hichem Gacem',      '0777 89 01 23', 'Bilan annuel',            'present'),
    ('2026-07-09 17:35:00+01'::timestamptz, 30, 'online', false, 'Djamila Kaci',      '0554 56 78 90', 'Fatigue chronique',       'present'),
    ('2026-07-09 18:05:00+01'::timestamptz, 35, 'manual', false, 'Nora Yahia',        '0668 90 12 34', 'Certificat médical',      'present'),
    ('2026-07-09 18:40:00+01'::timestamptz, 40, 'online', false, 'Karim Hadj',        '0772 34 56 78', 'Check-up général',        'present'),
    ('2026-07-09 19:20:00+01'::timestamptz, 20, 'manual', true,  'Slimane Berkani',   '0779 01 23 45', 'Bilan complet',           'present'),
    -- ===== SAMEDI July 11 =====
    ('2026-07-11 08:00:00+01'::timestamptz, 30, 'manual', false, 'Lamine Cherif',     '0778 90 12 34', 'Consultation spécialisée','present'),
    ('2026-07-11 08:30:00+01'::timestamptz, 20, 'online', true,  'Nabil Ait',         '0555 67 89 01', 'Renouvellement traitement','present'),
    ('2026-07-11 08:50:00+01'::timestamptz, 30, 'manual', false, 'Naima Boukhriss',   '0558 90 12 34', 'Fièvre persistante',      'present'),
    ('2026-07-11 09:20:00+01'::timestamptz, 35, 'online', false, 'Sami Meziane',      '0771 23 45 67', 'Résultat analyse',        'present'),
    ('2026-07-11 09:55:00+01'::timestamptz, 35, 'manual', false, 'Farid Bensalem',    '0665 67 89 01', 'Suivi tension',           'present'),
    ('2026-07-11 10:30:00+01'::timestamptz, 25, 'online', true,  'Salima Bouzid',     '0559 01 23 45', 'Consultation spécialisée','present'),
    ('2026-07-11 10:55:00+01'::timestamptz, 35, 'online', false, 'Rachid Ouali',      '0556 78 90 12', 'Migraines chroniques',    'present'),
    ('2026-07-11 11:30:00+01'::timestamptz, 30, 'manual', false, 'Malika Tlemcani',   '0776 78 90 12', 'Douleurs articulaires',   'present'),
    ('2026-07-11 13:00:00+01'::timestamptz, 20, 'manual', true,  'Hichem Gacem',      '0777 89 01 23', 'Douleurs dorsales',       'present'),
    ('2026-07-11 13:20:00+01'::timestamptz, 40, 'manual', false, 'Meryem Benali',     '0661 23 45 67', 'Consultation approfondie','present'),
    ('2026-07-11 14:00:00+01'::timestamptz, 25, 'online', true,  'Leila Messaoudi',   '0775 67 89 01', 'Fièvre persistante',      'present'),
    ('2026-07-11 14:25:00+01'::timestamptz, 40, 'online', false, 'Rabah Lounis',      '0551 23 45 67', 'Angine',                  'present'),
    ('2026-07-11 15:05:00+01'::timestamptz, 35, 'online', false, 'Yacine Khelifi',    '0660 12 34 56', 'Bilan complet',           'present'),
    ('2026-07-11 15:40:00+01'::timestamptz, 40, 'online', false, 'Karim Hadj',        '0772 34 56 78', 'Consultation approfondie','present'),
    ('2026-07-11 16:20:00+01'::timestamptz, 25, 'online', true,  'Slimane Berkani',   '0779 01 23 45', 'Consultation cardiologie','present'),
    ('2026-07-11 16:45:00+01'::timestamptz, 30, 'online', false, 'Fatima Zidane',     '0667 89 01 23', 'Ordonnance',              'present'),
    ('2026-07-11 17:15:00+01'::timestamptz, 35, 'online', false, 'Tahar Mansouri',    '0663 45 67 89', 'Suivi',                   'present'),
    ('2026-07-11 17:50:00+01'::timestamptz, 35, 'online', false, 'Djamila Kaci',      '0554 56 78 90', 'Migraines chroniques',    'present'),
    ('2026-07-11 18:25:00+01'::timestamptz, 25, 'online', true,  'Saida Rahmani',     '0666 78 90 12', 'Bilan sanguin',           'present'),
    ('2026-07-11 18:50:00+01'::timestamptz, 40, 'online', false, 'Abdelkader Nouar',  '0557 89 01 23', 'Fatigue chronique',       'present')
) as vals(scheduled_at, duration, booking_type, is_consultation, name, phone, notes, attendance)
cross join lateral (
  select id from patient_ids where full_name = vals.name
) pid;
