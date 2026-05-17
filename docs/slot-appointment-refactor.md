# Eyadati Calendar & Availability Refactor Checklist

# PRIMARY OBJECTIVE

Transform the current calendar system into:

```text
Visual Calendar
+
Availability Engine
+
Fast Booking UX
```

WITHOUT:

* visual slot calculations
* stored slots
* calendar-driven logic
* leftover-space rendering

---

# CORE ARCHITECTURE RULES

# RULE 1 — Calendar Is Presentation Only

Syncfusion Calendar MUST ONLY:

* render appointments
* render durations visually
* handle taps
* navigate dates

Syncfusion MUST NEVER:

* calculate availability
* generate slots
* validate overlaps
* compute remaining space
* manage booking logic

---

# RULE 2 — Appointments Are Source Of Truth

Database stores ONLY:

* appointments
* doctor schedules

NEVER store:

* generated slots
* free slots
* reserved slots
* visual slot state

---

# RULE 3 — Availability Is Derived Dynamically

Availability must always be computed from:

```text
working ranges
-
occupied ranges
=
free ranges
```

---

# RULE 4 — Time Uses Integer Minutes

ALL scheduling logic MUST use:

```text
minutes from midnight
```

Examples:

```text
09:00 → 540
10:30 → 630
17:00 → 1020
```

NEVER use:

* formatted strings
* DateFormat
* widget times
* visual grid positions

for calculations.

---

# RULE 5 — Slot Means Valid Start Time

A slot is:

```text
a valid starting minute where a duration fits
```

NOT:

* visual cell
* database object
* scheduler block

---

# REQUIRED REFACTOR

# REMOVE SLOT THINKING ENTIRELY

DELETE:

* scheduleSlots
* slot occupancy
* slot splitting
* slot rendering logic
* remaining-space visual calculations

REPLACE WITH:

* occupied ranges
* free ranges
* valid starts

---

# FILE STRUCTURE

# Calendar Shell

File:

```text
doctor_calendar_page.dart
```

---

## RESPONSIBILITIES

ONLY:

* page layout
* navigation
* toolbar
* calendar callbacks
* bottom sheet opening

---

## MUST NOT

* calculate slots
* calculate availability
* map appointments
* perform time calculations

---

# Calendar Widget

File:

```text
doctor_calendar_widget.dart
```

---

## RESPONSIBILITIES

ONLY:

* render Syncfusion Calendar
* receive datasource
* expose tap callbacks

---

## MUST NOT

* know business logic
* know schedules
* know overlaps
* know free ranges

---

# Calendar Mapper

File:

```text
calendar_mapper.dart
```

---

## RESPONSIBILITY

Convert:

```text
AppointmentEntity
→
Syncfusion Appointment
```

---

## MUST HANDLE

* colors
* subjects
* status styles
* duration rendering

---

## MUST NOT

* calculate availability
* calculate fitting
* generate slots

---

# Availability Engine

File:

```text
availability_service.dart
```

---

# THIS IS THE SCHEDULING BRAIN

ALL scheduling logic MUST live here.

---

## RESPONSIBILITIES

* generate occupied ranges
* generate free ranges
* generate valid start times
* validate duration fit
* validate overlaps
* compute availability

---

## INPUTS

* doctor schedule
* appointments
* selected date
* requested duration

---

## OUTPUTS

### FreeRange

```dart
class FreeRange {
  int startMinute;
  int endMinute;
}
```

---

### ValidStart

```dart
class ValidStart {
  int minute;
  int duration;
}
```

---

## MUST NOT

* know widgets
* know calendar UI
* know navigation

---

# Booking Bottom Sheet

File:

```text
appointment_booking_sheet.dart
```

---

## RESPONSIBILITIES

* patient selection
* appointment type selection
* duration selection
* valid start selection
* booking confirmation

---

## MUST RECEIVE

Already computed:

* valid starts
* duration presets

---

## MUST NOT

* calculate free ranges
* calculate overlaps
* generate slots

---

# PROVIDER RULES

# DoctorProvider MUST ONLY

* fetch appointments
* fetch schedules
* expose state
* subscribe realtime
* trigger refreshes
* call services/repositories

---

# DoctorProvider MUST NEVER

* calculate slots
* calculate free ranges
* validate overlaps
* generate availability

Move all logic to:

```text
availability_service.dart
```

---

# REMOVE THESE PATTERNS

# DELETE

```dart
scheduleSlots
```

---

# DELETE

```dart
getAvailableSlotsForDay()
```

---

# DELETE

Visual leftover calculations.

---

# DELETE

Slot-based UI rendering.

---

# REMOVE MOCK DATA FROM UI

MOVE:

```dart
_generateMockAppointments()
```

TO:

```text
dev/mock/mock_calendar_data.dart
```

---

# TIME UTILITIES

Create:

```text
time_utils.dart
```

---

# REQUIRED HELPERS

```dart
timeToMinutes()
minutesToTime()
combineDateAndMinute()
extractMinuteFromDate()
formatMinute()
```

---

# NEVER

Repeat raw conversion logic in widgets.

---

# AVAILABILITY ENGINE FLOW

# STEP 1 — Load Schedule

Get:

* opening minute
* closing minute
* break ranges

---

# STEP 2 — Load Appointments

Fetch all active appointments for selected day.

IGNORE:

* cancelled
* absent

when computing occupied ranges.

---

# STEP 3 — Build Occupied Ranges

Each appointment becomes:

```text
[startMinute, endMinute]
```

Breaks also become occupied ranges.

---

# STEP 4 — Sort Ranges

Sort ascending by:

```text
startMinute
```

---

# STEP 5 — Generate Free Ranges

Example:

Working range:

```text
09:00–17:00
```

Occupied:

```text
09:00–09:40
12:00–13:00
```

Result:

```text
09:40–12:00
13:00–17:00
```

---

# STEP 6 — Generate Valid Starts

Given:

```text
duration = 20
```

Generate starts every:

```text
10 minutes
```

ONLY if:

```text
start + duration <= freeRangeEnd
```

---

# OVERLAP VALIDATION

# ONLY USE THIS RULE

Conflict exists if:

```text
newStart < existingEnd
AND
newEnd > existingStart
```

Do NOT invent custom overlap logic.

---

# DURATION RULES

# Patients

Patients:

* cannot choose arbitrary duration
* cannot choose arbitrary times

Use doctor defaults:

* appointment_duration
* consultation_duration

---

# Doctors

Doctors MAY:

* override duration
* use preset durations

BUT:

* availability engine must validate fit

---

# ALLOWED DOCTOR PRESETS

```text
10
20
30
40
60
```

Avoid arbitrary minute entry.

---

# CALENDAR UI RULES

# Calendar ONLY SHOWS

* appointments
* duration sizes
* colors
* statuses

---

# Calendar MUST NOT SHOW

* remaining gaps
* sub-slots
* split slot visuals
* calculated free fragments

---

# BOOKING UX RULES

# Doctor Tap Flow

Doctor taps calendar:

```text
10:00 area
```

Bottom sheet opens:

```text
Available:
10:00
10:10
10:20
```

Doctor selects one.

DONE.

---

# DO NOT

Visually carve empty time space.

That complexity is unnecessary.

---

# REALTIME RULES

Realtime MUST:

* subscribe per doctor
* refresh only visible days/range

---

# AFTER REALTIME UPDATE

Recompute:

* occupied ranges
* free ranges
* valid starts

NOT:

* visual slots

---

# PERFORMANCE RULES

# NEVER

Generate:

* month-wide slots
* yearly slots

---

# ONLY GENERATE

* selected day
  OR
* visible week

---

# CACHE RULES

Cache:

```text
DayAvailability
```

Invalidate ONLY when:

* appointments change
* schedules change

---

# FINAL SYSTEM FLOW

```text
Doctor Opens Calendar
        ↓
Syncfusion Renders Appointments
        ↓
Doctor Selects Day/Time
        ↓
Availability Service Computes:
    - occupied ranges
    - free ranges
    - valid starts
        ↓
Booking Bottom Sheet Opens
        ↓
Doctor Chooses:
    - patient
    - type
    - duration
    - suggested start
        ↓
Collision Validation
        ↓
Supabase Insert
        ↓
Realtime Refresh
        ↓
Calendar Updates
```
