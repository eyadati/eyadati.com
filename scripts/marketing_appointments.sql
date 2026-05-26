-- Eyadati: Fill week with marketing appointments
-- Doctor: 594b87e4-58fa-44ef-81aa-6bee2713ef6f
-- Days: Sun June 7 – Sat June 13 (skip Fri June 12)
-- Hours: 08:00-20:00, lunch 12:00-13:00
-- Regular visits: 15-30min | Consultations: 45-60min

-- Clear existing upcoming appointments that week
DELETE FROM appointments
WHERE doctor_id = '594b87e4-58fa-44ef-81aa-6bee2713ef6f'
  AND scheduled_at >= '2026-06-07 00:00:00+01'
  AND scheduled_at <  '2026-06-14 00:00:00+01'
  AND status = 'upcoming';

INSERT INTO appointments (doctor_id, scheduled_at, duration, status, booking_type, is_consultation, patient_name_snapshot, patient_phone_snapshot, notes) VALUES
-- ===== SUNDAY June 7 =====
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 08:00:00+01', 30, 'upcoming', 'online',  false, 'Ahmed Toumi',        '0550 12 34 56', 'Check-up général'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 08:30:00+01', 20, 'upcoming', 'manual', false, 'Meryem Benali',      '0661 23 45 67', 'Renouvellement ordonnance'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 08:50:00+01', 50, 'upcoming', 'online',  true,  'Karim Hadj',         '0772 34 56 78', 'Consultation spécialisée'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 09:40:00+01', 20, 'upcoming', 'online',  false, 'Nadia Amrani',       '0553 45 67 89', 'Résultat analyse'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 10:00:00+01', 60, 'upcoming', 'online',  true,  'Sofiane Belaid',     '0664 56 78 90', 'Bilan complet'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 11:00:00+01', 20, 'upcoming', 'manual', false, 'Leila Messaoudi',    '0775 67 89 01', 'Suivi tension'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 11:20:00+01', 25, 'upcoming', 'online',  false, 'Rachid Ouali',       '0556 78 90 12', 'Douleurs articulaires'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 11:45:00+01', 15, 'upcoming', 'online',  false, 'Fatima Zidane',      '0667 89 01 23', 'Allergies'),
-- lunch
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 13:00:00+01', 45, 'upcoming', 'online',  true,  'Lamine Cherif',      '0778 90 12 34', 'Consultation diabète'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 13:45:00+01', 20, 'upcoming', 'manual', false, 'Salima Bouzid',      '0559 01 23 45', 'Certificat médical'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 14:05:00+01', 30, 'upcoming', 'online',  false, 'Yacine Khelifi',     '0660 12 34 56', 'Douleurs dorsales'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 14:35:00+01', 55, 'upcoming', 'online',  true,  'Sami Meziane',       '0771 23 45 67', 'Consultation approfondie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 15:30:00+01', 20, 'upcoming', 'online',  false, 'Houria Bekkar',      '0552 34 56 78', 'Renouvellement traitement'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 15:50:00+01', 25, 'upcoming', 'online',  false, 'Tahar Mansouri',     '0663 45 67 89', 'Migraines chroniques'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 16:15:00+01', 20, 'upcoming', 'online',  false, 'Wassila Djemai',     '0774 56 78 90', 'Angine'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 16:35:00+01', 60, 'upcoming', 'online',  true,  'Nabil Ait',          '0555 67 89 01', 'Consultation cardiologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 17:35:00+01', 20, 'upcoming', 'manual', false, 'Saida Rahmani',      '0666 78 90 12', 'Bilan annuel'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 17:55:00+01', 30, 'upcoming', 'online',  false, 'Hichem Gacem',       '0777 89 01 23', 'Fièvre persistante'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 18:25:00+01', 20, 'upcoming', 'online',  false, 'Naima Boukhriss',    '0558 90 12 34', 'Suivi post-opératoire'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 18:45:00+01', 45, 'upcoming', 'online',  true,  'Fouad Sari',         '0669 01 23 45', 'Consultation neurologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-07 19:30:00+01', 25, 'upcoming', 'online',  false, 'Zineb Ghozali',      '0770 12 34 56', 'Ordonnance'),

-- ===== MONDAY June 8 =====
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 08:00:00+01', 25, 'upcoming', 'online',  false, 'Rabah Lounis',       '0551 23 45 67', 'Check-up'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 08:25:00+01', 20, 'upcoming', 'manual', false, 'Latifa Dris',        '0662 34 56 78', 'Certificat'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 08:45:00+01', 50, 'upcoming', 'online',  true,  'Mourad Sakri',       '0773 45 67 89', 'Consultation spécialisée'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 09:35:00+01', 15, 'upcoming', 'online',  false, 'Djamila Kaci',       '0554 56 78 90', 'Toux persistante'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 09:50:00+01', 60, 'upcoming', 'online',  true,  'Farid Bensalem',     '0665 67 89 01', 'Bilan complet'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 10:50:00+01', 20, 'upcoming', 'manual', false, 'Malika Tlemcani',    '0776 78 90 12', 'Renouvellement traitement'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 11:10:00+01', 30, 'upcoming', 'online',  false, 'Abdelkader Nouar',   '0557 89 01 23', 'Douleurs articulaires'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 11:40:00+01', 20, 'upcoming', 'online',  false, 'Nora Yahia',         '0668 90 12 34', 'Allergies'),
-- lunch
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 13:00:00+01', 45, 'upcoming', 'online',  true,  'Slimane Berkani',    '0779 01 23 45', 'Consultation diabète'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 13:45:00+01', 20, 'upcoming', 'manual', false, 'Rym Kadem',          '0550 12 34 56', 'Certificat médical'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 14:05:00+01', 30, 'upcoming', 'online',  false, 'Idir Ameur',         '0661 23 45 67', 'Douleurs dorsales'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 14:35:00+01', 55, 'upcoming', 'online',  true,  'Samira Fellag',      '0772 34 56 78', 'Consultation approfondie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 15:30:00+01', 20, 'upcoming', 'online',  false, 'Ali Benziane',       '0553 45 67 89', 'Suivi'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 15:50:00+01', 25, 'upcoming', 'online',  false, 'Souad Maouche',      '0664 56 78 90', 'Fatigue'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 16:15:00+01', 20, 'upcoming', 'online',  false, 'Hakim Boudiaf',      '0775 67 89 01', 'Angine'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 16:35:00+01', 60, 'upcoming', 'online',  true,  'Yamina Derradji',    '0556 78 90 12', 'Consultation cardiologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 17:35:00+01', 20, 'upcoming', 'manual', false, 'Lakhdar Belaid',     '0667 89 01 23', 'Bilan annuel'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 17:55:00+01', 30, 'upcoming', 'online',  false, 'Ferial Hamdi',       '0778 90 12 34', 'Fièvre persistante'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 18:25:00+01', 20, 'upcoming', 'online',  false, 'Driss Chaib',        '0559 01 23 45', 'Suivi post-opératoire'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 18:45:00+01', 50, 'upcoming', 'online',  true,  'Habiba Zenati',      '0660 12 34 56', 'Consultation neurologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-08 19:35:00+01', 25, 'upcoming', 'manual', false, 'Kamel Moussaoui',    '0771 23 45 67', 'Ordonnance'),

-- ===== TUESDAY June 9 =====
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 08:00:00+01', 30, 'upcoming', 'online',  false, 'Nabila Cheriet',     '0552 34 56 78', 'Check-up général'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 08:30:00+01', 20, 'upcoming', 'manual', false, 'Said Benmoussa',     '0663 45 67 89', 'Renouvellement'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 08:50:00+01', 60, 'upcoming', 'online',  true,  'Louisa Ksentini',    '0774 56 78 90', 'Consultation spécialisée'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 09:50:00+01', 15, 'upcoming', 'online',  false, 'Tayeb Abbassi',      '0555 67 89 01', 'Résultat analyse'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 10:05:00+01', 20, 'upcoming', 'online',  false, 'Zahia Bougherara',   '0666 78 90 12', 'Douleurs abdominales'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 10:25:00+01', 45, 'upcoming', 'online',  true,  'Riad Mezough',       '0777 89 01 23', 'Consultation approfondie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 11:10:00+01', 25, 'upcoming', 'manual', false, 'Sonia Hamdani',      '0558 90 12 34', 'Bilan sanguin'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 11:35:00+01', 20, 'upcoming', 'online',  false, 'Farouk Bensebaini',  '0669 01 23 45', 'Allergies'),
-- lunch
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 13:00:00+01', 50, 'upcoming', 'online',  true,  'Yasmina Adli',       '0770 12 34 56', 'Consultation diabète'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 13:50:00+01', 20, 'upcoming', 'online',  false, 'Mokhtar Larbi',      '0551 23 45 67', 'Suivi'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 14:10:00+01', 30, 'upcoming', 'manual', false, 'Kheira Boussaid',    '0662 34 56 78', 'Douleurs articulaires'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 14:40:00+01', 60, 'upcoming', 'online',  true,  'Djamel Aouar',       '0773 45 67 89', 'Bilan complet'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 15:40:00+01', 20, 'upcoming', 'manual', false, 'Fadila Belkacem',    '0554 56 78 90', 'Certificat médical'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 16:00:00+01', 25, 'upcoming', 'online',  false, 'Adel Bouchama',      '0665 67 89 01', 'Fatigue générale'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 16:25:00+01', 20, 'upcoming', 'online',  false, 'Dounia Zeddam',      '0776 78 90 12', 'Ordonnance'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 16:45:00+01', 55, 'upcoming', 'online',  true,  'Hocine Tighilt',     '0557 89 01 23', 'Consultation neurologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 17:40:00+01', 20, 'upcoming', 'online',  false, 'Malika Oukaci',      '0668 90 12 34', 'Angine'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 18:00:00+01', 30, 'upcoming', 'online',  false, 'Azzedine Kermiche',  '0779 01 23 45', 'Migraines'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 18:30:00+01', 20, 'upcoming', 'manual', false, 'Nassima Bahloul',    '0550 12 34 56', 'Bilan'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 18:50:00+01', 45, 'upcoming', 'online',  true,  'Khaled Sahnoun',     '0661 23 45 67', 'Consultation spécialisée'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-09 19:35:00+01', 25, 'upcoming', 'online',  false, 'Samia Guermat',      '0772 34 56 78', 'Fièvre persistante'),

-- ===== WEDNESDAY June 10 =====
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 08:00:00+01', 20, 'upcoming', 'online',  false, 'Hamid Berrah',       '0553 45 67 89', 'Check-up'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 08:20:00+01', 30, 'upcoming', 'manual', false, 'Nadia Hemdani',      '0664 56 78 90', 'Renouvellement'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 08:50:00+01', 55, 'upcoming', 'online',  true,  'Fathi Bouziane',     '0775 67 89 01', 'Consultation spécialisée'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 09:45:00+01', 20, 'upcoming', 'online',  false, 'Zakia Madi',         '0556 78 90 12', 'Suivi post-op'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 10:05:00+01', 15, 'upcoming', 'manual', false, 'Tahar Belhadj',      '0667 89 01 23', 'Analyse'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 10:20:00+01', 60, 'upcoming', 'online',  true,  'Assia Kherbouche',   '0778 90 12 34', 'Consultation approfondie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 11:20:00+01', 20, 'upcoming', 'online',  false, 'Yazid Hammache',     '0559 01 23 45', 'Angine'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 11:40:00+01', 20, 'upcoming', 'online',  false, 'Rachida Talbi',      '0660 12 34 56', 'Allergies'),
-- lunch
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 13:00:00+01', 45, 'upcoming', 'online',  true,  'Mounir Kacem',       '0771 23 45 67', 'Consultation diabète'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 13:45:00+01', 25, 'upcoming', 'manual', false, 'Hanane Boussetta',   '0552 34 56 78', 'Certificat'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 14:10:00+01', 20, 'upcoming', 'online',  false, 'Lounis Adjali',      '0663 45 67 89', 'Fatigue'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 14:30:00+01', 50, 'upcoming', 'online',  true,  'Nouria Yacine',      '0774 56 78 90', 'Bilan complet'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 15:20:00+01', 20, 'upcoming', 'online',  false, 'Bachir Zenagui',     '0555 67 89 01', 'Suivi tension'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 15:40:00+01', 30, 'upcoming', 'online',  false, 'Latifa Bensalem',    '0666 78 90 12', 'Douleurs thoraciques'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 16:10:00+01', 20, 'upcoming', 'manual', false, 'Sofiane Atrous',     '0777 89 01 23', 'Renouvellement'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 16:30:00+01', 60, 'upcoming', 'online',  true,  'Karima Sebti',       '0558 90 12 34', 'Consultation cardiologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 17:30:00+01', 20, 'upcoming', 'online',  false, 'Ali Bouzidi',        '0669 01 23 45', 'Bilan'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 17:50:00+01', 25, 'upcoming', 'manual', false, 'Mona Laggoune',      '0770 12 34 56', 'Douleurs dorsales'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 18:15:00+01', 20, 'upcoming', 'online',  false, 'Salah Kerrouche',    '0551 23 45 67', 'Grippe'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 18:35:00+01', 45, 'upcoming', 'online',  true,  'Hayat Bounab',       '0662 34 56 78', 'Consultation neurologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-10 19:20:00+01', 30, 'upcoming', 'online',  false, 'Mustapha Halim',     '0773 45 67 89', 'Migraines'),

-- ===== THURSDAY June 11 =====
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 08:00:00+01', 25, 'upcoming', 'online',  false, 'Selma Maameri',      '0554 56 78 90', 'Check-up général'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 08:25:00+01', 20, 'upcoming', 'manual', false, 'Abdelhak Amri',      '0665 67 89 01', 'Certificat'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 08:45:00+01', 60, 'upcoming', 'online',  true,  'Nassira Belaidi',    '0776 78 90 12', 'Consultation spécialisée'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 09:45:00+01', 15, 'upcoming', 'online',  false, 'Aziz Ghoul',         '0557 89 01 23', 'Analyse sang'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 10:00:00+01', 30, 'upcoming', 'online',  false, 'Dalila Mehenni',     '0668 90 12 34', 'Douleurs lombaires'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 10:30:00+01', 50, 'upcoming', 'online',  true,  'Abdellah Ziani',     '0779 01 23 45', 'Consultation diabète'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 11:20:00+01', 20, 'upcoming', 'manual', false, 'Nora Slimani',       '0550 12 34 56', 'Renouvellement'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 11:40:00+01', 20, 'upcoming', 'online',  false, 'Redouane Amirat',    '0661 23 45 67', 'Allergies'),
-- lunch
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 13:00:00+01', 45, 'upcoming', 'online',  true,  'Fatma Serradj',      '0772 34 56 78', 'Consultation approfondie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 13:45:00+01', 20, 'upcoming', 'online',  false, 'Djamel Djenidi',     '0553 45 67 89', 'Suivi'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 14:05:00+01', 30, 'upcoming', 'manual', false, 'Zineb Ferhat',       '0664 56 78 90', 'Douleurs articulaires'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 14:35:00+01', 55, 'upcoming', 'online',  true,  'Kamel Djaout',       '0775 67 89 01', 'Bilan complet'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 15:30:00+01', 20, 'upcoming', 'online',  false, 'Sabrina Atmani',     '0556 78 90 12', 'Fièvre'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 15:50:00+01', 25, 'upcoming', 'online',  false, 'Sadek Boukhari',     '0667 89 01 23', 'Fatigue chronique'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 16:15:00+01', 20, 'upcoming', 'manual', false, 'Lydia Toubal',       '0778 90 12 34', 'Ordonnance'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 16:35:00+01', 60, 'upcoming', 'online',  true,  'Abdelmadjid Rezki',  '0559 01 23 45', 'Consultation cardiologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 17:35:00+01', 20, 'upcoming', 'online',  false, 'Wahiba Bouafia',     '0660 12 34 56', 'Angine'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 17:55:00+01', 30, 'upcoming', 'online',  false, 'Nacer Khelifi',      '0771 23 45 67', 'Suivi post-opératoire'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 18:25:00+01', 20, 'upcoming', 'online',  false, 'Safia Ait Ali',      '0552 34 56 78', 'Bilan'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 18:45:00+01', 50, 'upcoming', 'online',  true,  'Mehdi Larbi',        '0663 45 67 89', 'Consultation neurologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-11 19:35:00+01', 25, 'upcoming', 'manual', false, 'Amina Oussedik',     '0774 56 78 90', 'Certificat médical'),

-- ===== SATURDAY June 13 =====
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 08:00:00+01', 20, 'upcoming', 'online',  false, 'Ahmed Toumi',        '0550 12 34 56', 'Check-up'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 08:20:00+01', 30, 'upcoming', 'manual', false, 'Meryem Benali',      '0661 23 45 67', 'Renouvellement'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 08:50:00+01', 60, 'upcoming', 'online',  true,  'Karim Hadj',         '0772 34 56 78', 'Consultation spécialisée'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 09:50:00+01', 15, 'upcoming', 'online',  false, 'Nadia Amrani',       '0553 45 67 89', 'Résultat analyse'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 10:05:00+01', 25, 'upcoming', 'online',  false, 'Sofiane Belaid',     '0664 56 78 90', 'Douleurs'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 10:30:00+01', 50, 'upcoming', 'online',  true,  'Leila Messaoudi',    '0775 67 89 01', 'Consultation approfondie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 11:20:00+01', 20, 'upcoming', 'manual', false, 'Rachid Ouali',       '0556 78 90 12', 'Ordonnance'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 11:40:00+01', 20, 'upcoming', 'online',  false, 'Fatima Zidane',      '0667 89 01 23', 'Allergies'),
-- lunch
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 13:00:00+01', 45, 'upcoming', 'online',  true,  'Lamine Cherif',      '0778 90 12 34', 'Consultation diabète'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 13:45:00+01', 20, 'upcoming', 'online',  false, 'Salima Bouzid',      '0559 01 23 45', 'Suivi'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 14:05:00+01', 30, 'upcoming', 'online',  false, 'Yacine Khelifi',     '0660 12 34 56', 'Migraines'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 14:35:00+01', 55, 'upcoming', 'online',  true,  'Sami Meziane',       '0771 23 45 67', 'Bilan complet'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 15:30:00+01', 20, 'upcoming', 'manual', false, 'Houria Bekkar',      '0552 34 56 78', 'Certificat médical'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 15:50:00+01', 25, 'upcoming', 'online',  false, 'Tahar Mansouri',     '0663 45 67 89', 'Fatigue'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 16:15:00+01', 20, 'upcoming', 'online',  false, 'Wassila Djemai',     '0774 56 78 90', 'Angine'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 16:35:00+01', 60, 'upcoming', 'online',  true,  'Nabil Ait',          '0555 67 89 01', 'Consultation cardiologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 17:35:00+01', 20, 'upcoming', 'online',  false, 'Saida Rahmani',      '0666 78 90 12', 'Bilan'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 17:55:00+01', 30, 'upcoming', 'manual', false, 'Hichem Gacem',       '0777 89 01 23', 'Douleurs dorsales'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 18:25:00+01', 20, 'upcoming', 'online',  false, 'Naima Boukhriss',    '0558 90 12 34', 'Renouvellement'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 18:45:00+01', 50, 'upcoming', 'online',  true,  'Fouad Sari',         '0669 01 23 45', 'Consultation neurologie'),
('594b87e4-58fa-44ef-81aa-6bee2713ef6f', '2026-06-13 19:35:00+01', 25, 'upcoming', 'online',  false, 'Zineb Ghozali',      '0770 12 34 56', 'Fièvre persistante');
