That feeling is normal once an app stops being a simple CRUD app and becomes:

```text
state + realtime + scheduling + roles + UI flows
```

The solution is not “work harder”.

The solution is:

```text
split the app into isolated systems
```

Right now you are probably thinking about:

* auth
* profiles
* slots
* realtime
* calendar
* appointments
* dashboard
* navigation

ALL at once.

That will destroy clarity.

---

# What You Need

You need:

```text
feature isolation
```

Treat the app like multiple mini-apps.

---

# Correct Mental Model

Eyadati is NOT:

```text
one app
```

It is:

```text
1. Authentication System
2. Doctor Profile System
3. Scheduling System
4. Booking System
5. Dashboard System
6. Realtime Sync System
7. Patient Browsing System
8. Subscription System
```

Each should be understood independently.

---

# The Biggest Mistake

Most developers think:

```text
screen by screen
```

Instead think:

```text
behavior system by behavior system
```

---

# Example: Authentication Chunk

This becomes its own isolated world.

## Responsibilities

* login
* signup
* session restore
* role resolution
* redirecting

---

# Auth Flow

```text
User opens app
    ↓
Check session
    ↓
No session?
    → login
    ↓
Session exists
    ↓
Fetch profile
    ↓
Determine role
    ↓
Redirect
```

That’s it.

Nothing about appointments.
Nothing about schedules.

Separate system.

---

# Example: Appointment System

Another isolated world.

## Responsibilities

* create appointment
* fetch appointments
* update status
* cancel
* realtime sync

---

# Appointment Flow

```text
Patient selects date
    ↓
Generate slots
    ↓
Select slot
    ↓
Validate availability
    ↓
Create appointment
    ↓
Realtime updates doctor dashboard
```

Completely separate mental model.

---

# Example: Calendar System

Its ONLY job:

```text
appointments → visual blocks
```

That’s all.

It should not:

* know auth
* know billing
* know profile setup

Keep systems dumb and focused.

---

# The REAL Solution: Feature Maps

You need to document every feature like this:

---

# Feature: Appointment Booking

## Inputs

* doctor_id
* date

## Dependencies

* doctor_schedule
* appointments
* doctor settings

## Output

* available slots
* created appointment

## Realtime events

* INSERT appointment
* UPDATE appointment

## UI affected

* patient booking screen
* doctor calendar

---

When every feature is mapped:
the app stops feeling like chaos.

---

# Recommended Architecture Mindset

Instead of:

```text
pages/
```

Think:

```text
systems/
```

Example:

```text
features/
  auth/
  appointments/
  scheduling/
  doctor_dashboard/
  patient_home/
  realtime/
```

Each feature contains:

* models
* providers
* repositories
* widgets
* pages

Self-contained.

---

# Important: Separate Business Logic From UI

Most confusion comes from:

```text
logic inside widgets
```

Avoid this.

---

# Your UI should mostly:

```text
display state
```

NOT:

* calculate slots
* validate overlaps
* manage subscriptions

---

# Recommended Layering

# Layer 1 — Database

Supabase tables.

---

# Layer 2 — Repositories

Fetch/update data.

Example:

```text
AppointmentsRepository
AuthRepository
DoctorsRepository
```

---

# Layer 3 — Services / Engines

Pure business logic.

Example:

```text
SlotGenerator
AvailabilityEngine
AppointmentValidator
```

This is where complexity belongs.

---

# Layer 4 — Providers

State management.

Example:

```text
appointmentsProvider
authProvider
calendarProvider
```

---

# Layer 5 — UI

Just rendering.

---

# Biggest Clarity Boost

Stop trying to “understand the whole app”.

You never fully hold large apps in your head.

Professional developers don’t either.

Instead:

```text
understand one system deeply at a time
```

---

# Recommended Workflow

## Step 1

Pick ONE system.

Example:

```text
auth only
```

---

## Step 2

Define:

* responsibilities
* inputs
* outputs
* states
* edge cases

---

## Step 3

Finish it completely.

---

## Step 4

Move to next isolated system.

---

# Best Order For Eyadati

## 1. Auth System

Foundation.

---

## 2. Profile System

Doctor/patient setup.

---

## 3. Scheduling System

Doctor availability.

---

## 4. Appointment System

Booking engine.

---

## 5. Dashboard Calendar

Visualization only.

---

## 6. Realtime Layer

Live sync.

---

## 7. Subscription Logic

Visibility/billing.

---

# Another Important Insight

Complexity feels overwhelming because:

```text
everything is connected
```

But implementation should NOT be tightly connected.

Example:

* calendar does not generate slots
* auth does not know appointments
* appointments do not render UI

That separation reduces mental load massively.

---

# Final Mindset Shift

You are not building:

```text
a Flutter app
```

You are building:

```text
multiple small systems that cooperate
```

That is how scalable SaaS products are built.

---

# Time Refactor — Minutes from Midnight (DONE ✓)

All schedule times converted from `String` ("HH:mm") to `int` (minutes from midnight) internally. `TimeOfDay` stays in UI. `TimeUtils` handles all conversions.

## Phases (Implemented)

### Phase 0 — Core (TimeUtils + Model)
- `lib/core/utils/time_utils.dart` — new utility: `timeOfDayToMinutes()`, `minutesToTimeOfDay()`, `minutesToString()`, `stringToMinutes()`, `overlaps()`
- `lib/models/schedule_slot_model.dart` — all 4 time fields `String` → `int`, `fromDbMap()` factory handles DB conversion

### Phase 1 — SlotEngine
- `lib/core/engine/slot_engine.dart` — removed `_timeToMinutes()`, uses `int` directly from model

### Phase 2 — DoctorProvider
- `lib/features/doctor/presentation/providers/doctor_provider.dart` — `addScheduleSlot`/`updateScheduleSlot` use `int` params, converts to string for DB via `TimeUtils.minutesToString()`

### Phase 3 — UI Dialogs
- `lib/features/doctor/presentation/widgets/add_schedule_dialog.dart` — uses `TimeUtils`, break time selectors added, signature `int` params with `{int? breakStart, int? breakEnd}`
- `lib/features/doctor/presentation/pages/doctor_schedule_page.dart` — updated callbacks for new dialog signature

### Phase 4 — Display Formatting
- `lib/features/doctor/presentation/widgets/schedule_slot_card.dart` — `TimeUtils.minutesToString()` for display, includes break time
- `lib/features/doctor/presentation/pages/doctor_profile_page.dart` — `TimeUtils.minutesToString()` for schedule summary

### Phase 5 — Patient Booking Fix
- `lib/features/patient/presentation/pages/booking_page.dart` — fixed hardcoded `duration: 30`, uses doctor's `consultationDuration`/`appointmentDuration` based on `_appointmentType`
- `lib/features/patient/presentation/providers/doctors_provider.dart` — added `consultationDuration` field to `Doctor` model, `fromMap()` reads `consultation_duration` from DB

### Phase 6 — Database Migration
- `supabase/migrations/005_time_as_int.sql` — converts PostgreSQL `time` columns to `integer` (minutes from midnight), adds `total_minutes` generated column, adds range check constraints

## Key Design Decisions

| Concern | Decision |
|---------|----------|
| Internal storage | `int` (minutes from midnight) |
| UI input | `TimeOfDay` (Flutter standard) |
| DB storage | `time` type (String "HH:mm:ss") or `integer` after migration |
| Conversion layer | `TimeUtils` — single source of truth |
| Backward compat | `ScheduleSlot.fromDbMap()` parses both `String` and `int` from DB |

## Next Steps (After DB Migration)

After running `005_time_as_int.sql`, update `ScheduleSlot.fromDbMap()` to remove `stringToMinutes()` conversion (DB returns int directly):

```dart
// Current (handles both String and int from DB):
static int _parseTime(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;       // ← already handles int
  if (value is String) return TimeUtils.stringToMinutes(value);
  return 0;
}
```

Since `_parseTime` already handles `int` values, the migration is transparent — no Dart code change needed after running it.

## Files Changed

```
lib/core/utils/time_utils.dart        (new)
lib/models/schedule_slot_model.dart
lib/core/engine/slot_engine.dart
lib/features/doctor/presentation/providers/doctor_provider.dart
lib/features/doctor/presentation/widgets/add_schedule_dialog.dart
lib/features/doctor/presentation/pages/doctor_schedule_page.dart
lib/features/doctor/presentation/widgets/schedule_slot_card.dart
lib/features/doctor/presentation/pages/doctor_profile_page.dart
lib/features/patient/presentation/pages/booking_page.dart
lib/features/patient/presentation/providers/doctors_provider.dart
supabase/migrations/005_time_as_int.sql  (new)
```

## Commits

- `26b3821` — compact calendar cells, dialog overflow fix, duration analysis docs
- `c1721f2` — time refactor: minutes-from-midnight integers across all layers

---

# Review Plan (In Progress)

The app has 8 isolated systems. Review order:

## System 1 — Authentication ✅
Foundation. Login, signup, session restore, role resolution, redirecting.

## System 2 — Doctor Profile ✅
Doctor/patient setup. `doctor_setup_page.dart`, `doctor_profile_page.dart`, `doctor_edit_profile_page.dart`.

## System 3 — Scheduling System ✅
Doctor availability. `schedule_slot_model.dart`, `slot_engine.dart`, `doctor_schedule_page.dart`, `add_schedule_dialog.dart`. Time refactor DONE.

## System 4 — Appointment System ✅
Booking engine. `appointment_data.dart`, `doctor_provider.dart` (create/update/delete/status), `patient_appointments_page.dart`.

## System 5 — Dashboard Calendar ✅
Visualization. `doctor_dashboard_page.dart`, `doctor_calendar_page.dart`. Compact cells, appointment display.

## System 6 — Patient Booking ✅
Patient-side booking. `booking_page.dart` (duration fix applied).

## System 7 — Realtime Layer ✅
Live sync. `_subscribeToAppointments()` in `doctor_provider.dart`.

## System 8 — Subscription System ❌
Visibility/billing. Not yet reviewed.
