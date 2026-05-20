## Table `FCM data`

it sends user data so it uses it for FCM

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int8` | Primary Identity |
| `created_at` | `timestamptz` |  |

## Table `appointments`

Occupied time blocks - NOT pre-generated slots. Slots are computed dynamically from doctor_schedule.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `doctor_id` | `uuid` |  |
| `patient_id` | `uuid` |  Nullable |
| `scheduled_at` | `timestamptz` |  |
| `duration` | `int4` |  |
| `status` | `text` |  |
| `booking_type` | `text` |  |
| `is_consultation` | `bool` |  Nullable |
| `patient_name_snapshot` | `text` |  |
| `patient_phone_snapshot` | `text` |  Nullable |
| `notes` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `appointment_type` | `text` |  Nullable |

## Table `doctor_schedule`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `doctor_id` | `uuid` |  |
| `day_of_week` | `int4` |  |
| `start_time` | `int4` |  |
| `end_time` | `int4` |  |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `break_start` | `int4` |  Nullable |
| `break_end` | `int4` |  Nullable |
| `total_minutes` | `int4` |  Nullable |

## Table `doctors`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `specialty` | `text` |  |
| `address` | `text` |  |
| `city` | `text` |  Nullable |
| `maps_link` | `text` |  Nullable |
| `latitude` | `float8` |  Nullable |
| `longitude` | `float8` |  Nullable |
| `bio` | `text` |  Nullable |
| `photo_url` | `text` |  Nullable |
| `appointment_duration` | `int4` |  |
| `consultation_duration` | `int4` |  |
| `manual_pause` | `bool` |  Nullable |
| `subscription_end` | `timestamptz` |  |
| `created_at` | `timestamptz` |  Nullable |

## Table `favorites`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `patient_id` | `uuid` | Primary |
| `doctor_id` | `uuid` | Primary |
| `created_at` | `timestamptz` |  Nullable |

## Table `patients`

Patient profiles with medical information

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `full_name` | `text` |  |
| `phone` | `text` |  Nullable |
| `date_of_birth` | `date` |  Nullable |
| `gender` | `text` |  Nullable |
| `address` | `text` |  Nullable |
| `city` | `text` |  Nullable |
| `emergency_contact` | `text` |  Nullable |
| `emergency_phone` | `text` |  Nullable |
| `blood_type` | `text` |  Nullable |
| `allergies` | `text` |  Nullable |
| `medical_history` | `text` |  Nullable |
| `notes` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `profiles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `role` | `text` |  |
| `full_name` | `text` |  |
| `email` | `text` |  Nullable |
| `phone` | `text` |  Nullable |
| `city` | `text` |  Nullable |
| `avatar_url` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

