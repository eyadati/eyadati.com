# Appointment & Slot System Roadmap (Eyadati)

Your structure is already good enough for a scalable booking system.

The main challenge now is not database structure.

It is:

```
slot generation architecture
```

You need to separate clearly:

1. Doctor availability
2. Generated potential slots
3. Occupied slots (appointments)
4. Realtime synchronization

Most booking systems become messy because these concepts get mixed.

---

## Core Philosophy

You should NEVER store:

```
all possible slots in database
```

That becomes:

- bloated
- expensive
- hard to maintain
- difficult to sync

Instead:

## Correct Approach

Slots should be:

```
generated dynamically
```

from:

- doctor schedule
- appointment duration
- break time
- existing appointments

This is how modern booking systems work.

---

## Main System Flow

```
Doctor Schedule
        ↓
Generate Possible Slots
        ↓
Fetch Existing Appointments
        ↓
Remove Occupied Times
        ↓
Return Available Slots
```

This is the heart of your booking engine.

---

## Important Tables Roles

### doctors

Global doctor settings:

- durations
- working days
- opening hours
- pauses
- subscription state

Think of this as:

```
doctor configuration
```

---

### doctor_schedule

This should become:

```
daily schedule overrides
```

More flexible than `working_days`.

You should gradually rely on this table more.

Because later you'll want:

- different hours per day
- custom schedules
- special cases

Example:

```
Monday: 09-17
Tuesday: 10-14
Friday: 08-12
```

This table should become the source of truth for availability.

---

### appointments

Represents:

```
occupied time blocks
```

NOT slots.

This distinction is critical.

---

## Recommended Booking Architecture

### Layer 1 — Schedule Engine

Responsible for:

- generating theoretical slots

Input:

```
doctor
date
schedule
duration
```

Output:

```
List<PotentialSlot>
```

Example:

```
09:00
09:20
09:40
10:00
```

No appointment checking yet.

---

### Layer 2 — Conflict Engine

Responsible for:

- removing occupied slots

Input:

```
Potential slots
+
Existing appointments
```

Output:

```
Available slots
```

---

### Layer 3 — Booking Engine

Responsible for:

- validating slot still free
- inserting appointment
- realtime sync

This is where race conditions matter.

---

## Slot Generation Logic

The generator should:

### Step 1

Check:

```
manual_pause == false
subscription_end > now()
```

If false:

```
no slots
```

---

### Step 2

Get schedule for requested day.

Example:

```
Tuesday
09:00 → 17:00
```

---

### Step 3

Determine slot duration.

Example:

```
consultation ? consultation_duration : appointment_duration
```

---

### Step 4

Generate time intervals.

Example:

```
09:00
09:20
09:40
10:00
```

until:

```
closing_time - duration
```

---

### Step 5

Exclude break period.

Example:

```
12:00 → 13:00
```

Remove overlapping generated slots.

---

## Appointment Conflict Logic

Now fetch appointments for that day.

You already store:

```
scheduled_at
duration
```

Perfect.

Convert appointments into:

```
start → end ranges
```

Example:

```
10:00 → 10:20
```

Then compare generated slots.

---

## Overlap Rule

A slot is unavailable if:

```
slot_start < appointment_end
AND
slot_end > appointment_start
```

This rule is the core of scheduling systems.

---

## Manual + Online Appointments

Good news:
your current structure already supports both perfectly.

Because:

```
booking_type
```

is metadata only.

The scheduler should NOT care whether appointment is:

- manual
- online

Both simply:

```
occupy time
```

This is correct architecture.

---

## Realtime Architecture

This is extremely important.

---

### Realtime Goal

When:

- patient books
- receptionist adds walk-in
- doctor edits status

The calendar should update instantly.

---

### Recommended Realtime Structure

#### Doctor Dashboard Subscribes To:

```
appointments
```

filtered by:

```
doctor_id
```

Listen for:

- INSERT
- UPDATE
- DELETE

---

#### Patient Booking Page Subscribes To:

same doctor/day appointments.

This allows:

- live slot invalidation
- instant UI updates

Example:

```
slot disappears instantly after booking
```

Very important for avoiding double booking.

---

## Race Condition Protection

Critical.

Realtime alone is NOT enough.

Two patients may:

- see same slot
- click simultaneously

You MUST validate server-side before insert.

---

### Correct Flow

#### Client

Attempts booking.

---

#### Server Validation

Check:

```
is slot still available?
```

using overlap logic.

---

#### If free

Insert appointment.

---

#### If occupied

Reject booking.

---

**Important**

This validation should ideally happen:

```
inside postgres function / RPC
```

NOT purely in Flutter.

Because:

```
client validation is not safe
```

---

### Recommended Realtime UX

#### Doctor Dashboard

Realtime:

- new appointments appear instantly
- cancellations disappear
- status updates sync live

---

#### Patient Booking

Realtime:

- slot disappears instantly
- unavailable state updates

This creates:

```
live booking feel
```

---

## Doctor Dashboard Calendar Flow

Doctor opens week:

```
Fetch appointments for week
        ↓
Map into appointment blocks
        ↓
Render calendar grid
        ↓
Realtime updates modify provider state
        ↓
UI rerenders affected blocks only
```

---

## Recommended Data Fetching Strategy

Avoid:

```
fetch entire month constantly
```

Use:

```
visible date range only
```

Example:

- current week
- selected day

This reduces:

- Supabase reads
- memory usage
- rerenders

---

### Suggested Provider Separation

#### Availability Provider

Responsible for:

```
available slots
```

---

#### Appointments Provider

Responsible for:

```
existing appointments
```

---

#### Dashboard Provider

Responsible for:

```
calendar UI state
```

This separation keeps the system clean.

---

## Important Future-Proofing

Your current structure already supports future features like:

- vacations
- custom holidays
- schedule overrides
- partner doctors
- recurring schedules
- receptionist multi-user support

without major rewrites.

That's good schema design.

---

## Biggest Recommendation

Move toward:

```
doctor_schedule
```

being the primary source of working hours.

Right now you have duplicated logic:

- working_days
- opening_at
- closing_at
- doctor_schedule

Long-term:

```
doctor_schedule should own scheduling
```

because it is more flexible and scalable.

---

## Recommended Final Architecture

### Database

Stores:

- schedules
- appointments
- doctor settings

---

### Backend Logic

Handles:

- overlap validation
- slot generation
- availability calculation

---

### Flutter

Handles:

- rendering
- realtime updates
- interactions
- optimistic UI

This separation is the correct scalable approach.

---

# Implementation Plan

## Phase 1: Clean Data Layer (Database)

**Goal:** Consolidate to single source of truth for schedules

| Task | Description |
|---|---|
| 1.1 | Make `doctor_schedule` the **primary source** — migrate all `working_days`, `opening_at`, `closing_at` data from `doctors` table into `doctor_schedule` rows |
| 1.2 | Update `doctors` table to keep only **global config** (durations, subscription, pause) — remove day/time columns |
| 1.3 | Add `break_start` / `break_end` columns to `doctor_schedule` (per-day breaks) instead of global in `doctors` |
| 1.4 | Add SQL constraint that ensures only ONE active schedule row per `doctor_id + day_of_week` |
| 1.5 | Remove `working_days` text[] from `doctors` — no longer needed |
| 1.6 | Add `patients` table for patient profiles (name, phone, notes, etc.) |
| 1.7 | Add `appointment_type` column to appointments (`standard`/`consultation`) |

---

## Phase 2: Slot Generation Engine (Flutter)

**Goal:** Build pure Dart slot generator — no SQL complexity

| Task | Description |
|---|---|
| 2.1 | Create `SlotEngine` class — pure Dart, stateless, testable |
| 2.2 | Layer 1 — `ScheduleEngine.generateSlots(date, scheduleSlots, duration)` → returns all possible time intervals |
| 2.3 | Layer 2 — `ConflictEngine.filterOccupied(potentialSlots, appointments)` → removes booked times |
| 2.4 | Add break time exclusion (per-day breaks from `doctor_schedule`) |
| 2.5 | Add past-time exclusion (no slots in the past) |
| 2.6 | Add overlap rule: `slot.start < apt.end && slot.end > apt.start` |
| 2.7 | Support both `appointment_duration` and `consultation_duration` |
| 2.8 | Handle multiple schedule rows per day (e.g., 09-12 and 14-17) |

---

## Phase 3: Provider Separation

**Goal:** Separate concerns into focused providers

| Task | Description |
|---|---|
| 3.1 | Create `AvailabilityProvider` — manages slot generation only |
| 3.2 | Create `AppointmentsProvider` — manages CRUD for appointments |
| 3.3 | Refactor `DoctorProvider` to delegate scheduling to `SlotEngine` |
| 3.4 | Patient-side: create `PatientBookingProvider` — generates slots for booking |
| 3.5 | Expose `availableSlotsForDate(date)` method on provider |
| 3.6 | Remove redundant `loadScheduleForDay()` — replaced by `SlotEngine` |

---

## Phase 4: Real-time Sync

**Goal:** Live calendar updates across all views

| Task | Description |
|---|---|
| 4.1 | Realtime channel on `appointments` table (already exists) — verify it triggers slot refresh |
| 4.2 | When realtime fires INSERT/UPDATE/DELETE → recompute available slots via `SlotEngine` |
| 4.3 | Add realtime subscription for patient booking page |
| 4.4 | Add optimistic UI — slot disappears immediately on booking, reappears if failed |
| 4.5 | Add conflict check in `AppointmentsProvider.createAppointment()` before insert |

---

## Phase 5: Booking Validation (Server-side)

**Goal:** Prevent double-booking race conditions

| Task | Description |
|---|---|
| 5.1 | Create PostgreSQL function `check_slot_availability(doctor_id, slot_time, duration)` using overlap rule |
| 5.2 | `createAppointment()` in provider calls this function before inserting |
| 5.3 | Handle race condition: if slot taken between UI click and DB insert, return clear error |
| 5.4 | Patient booking flow also uses same validation |

---

## Phase 6: UI Refactor

**Goal:** Update UI to use new slot engine

| Task | Description |
|---|---|
| 6.1 | Refactor `DoctorAddAppointmentDialog` — use `SlotEngine` instead of `_computeAvailableSlots` |
| 6.2 | Refactor `DoctorCalendarPage` — use `SlotEngine` for `_isDayScheduled` |
| 6.3 | Refactor patient `BookingPage` — use `SlotEngine` for slot display |
| 6.4 | Refactor `DoctorSchedulePage` — CRUD on `doctor_schedule` table directly |
| 6.5 | Refactor `DoctorPatientsPage` — use new `patients` table |
| 6.6 | Add loading states during slot generation |
| 6.7 | Update `_DayAppointmentsSheet` to show computed availability |

---

## Phase 7: Testing & Polish

**Goal:** Ensure reliability

| Task | Description |
|---|---|
| 7.1 | Add unit tests for `SlotEngine` — test overlap logic, break times, multiple slots per day |
| 7.2 | Test race condition: two simultaneous bookings |
| 7.3 | Test realtime: slot disappears after other user books |
| 7.4 | Verify all old SQL functions are removed or updated to use `doctor_schedule` |

---

## Target Data Model

### doctor_schedule (source of truth for availability)

```sql
id              uuid PK
doctor_id       uuid FK (refs doctors)
day_of_week     int (0=Sunday .. 6=Saturday)
start_time      time
end_time        time
break_start     time (nullable) -- per-day break
break_end       time (nullable)
is_active       bool default true
created_at      timestamptz
updated_at      timestamptz

-- Unique constraint: one active schedule per doctor per day
UNIQUE(doctor_id, day_of_week) WHERE is_active = true
```

### appointments (occupied time blocks)

```sql
id                  uuid PK
doctor_id           uuid FK (refs doctors)
patient_id          uuid FK (refs patients) nullable
scheduled_at        timestamptz
duration            int (minutes)
status              text ('upcoming'/'completed'/'cancelled'/'absent')
booking_type        text ('online'/'manual')
is_consultation     bool default false
patient_name_snapshot   text (fallback for manual)
patient_phone_snapshot  text
notes               text
created_at          timestamptz
updated_at          timestamptz
```

### patients (new table)

```sql
id          uuid PK (refs profiles)
name        text
phone       text
email       text
notes       text
medical_history text
created_at  timestamptz
updated_at  timestamptz
```

### doctors (global config only — no day/time columns)

```sql
id                      uuid PK (refs profiles)
specialty                text
address                 text
city                    text
maps_link               text
photo_url               text

appointment_duration    int (default 20)
consultation_duration   int (default 30)

manual_pause            bool default false
subscription_end        timestamptz

created_at              timestamptz
```

---

## Final System Flow

```
User opens booking page
        ↓
Provider fetches doctor_schedule (all rows for doctor)
        ↓
SlotEngine.generate() → potential slots
        ↓
Provider fetches appointments for that day
        ↓
SlotEngine.filter() → removes occupied
        ↓
UI shows available slots
        ↓
User taps slot → booking request
        ↓
Provider checks server-side validation (overlap rule)
        ↓
Insert → success → realtime fires → all clients update
```

---

## Key Architecture Principles

1. **Never store generated slots in DB** — compute dynamically
2. **`doctor_schedule` is the single source of truth** for availability
3. **`appointments` are occupied blocks only** — not pre-generated slots
4. **Overlap rule is the core** — `slot_start < apt_end && slot_end > apt_start`
5. **Server-side validation is mandatory** — client validation is not safe
6. **Realtime keeps all clients in sync** — slot availability updates live
7. **Separate concerns** — Availability vs Appointments vs Calendar UI
8. **Pure Dart slot engine** — stateless, testable, no SQL dependency