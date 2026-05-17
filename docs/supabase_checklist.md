# Fresh Data & Realtime Reliability Architecture

# Objective

Ensure Eyadati always displays:

* live doctor data
* live appointments
* accurate schedules
* fresh availability

WITHOUT:

* stale fallback values
* outdated cached state
* duplicated local state
* inconsistent realtime updates

The goal is to make the app behave like a reliable realtime SaaS instead of a partially offline app relying on fallback data.

---

# Core Problem

The current issue comes from:

* excessive fallback values
* duplicated state sources
* optimistic UI without proper invalidation
* local mock/default values masking failed fetches
* providers holding stale derived data

This creates situations where:

* doctor data appears outdated
* appointments don’t refresh correctly
* UI silently falls back to fake/default values
* realtime updates partially apply

---

# Core Reliability Principles

# 1. Supabase Is The Source Of Truth

The app must always treat Supabase as:

```text
single source of truth
```

Local state exists only for:

* rendering
* temporary caching
* optimistic UI

NOT as permanent truth.

---

# 2. Never Hide Fetch Failures With Fake Defaults

Avoid patterns like:

```dart
doctor.name ?? 'Doctor'
appointments ?? []
duration ?? 20
```

when the value SHOULD exist.

This masks backend issues and creates silent bugs.

Fallbacks should only exist for:

* optional cosmetic fields
* loading placeholders
* explicitly nullable fields

---

# 3. Separate Loading State From Empty State

These are NOT the same:

```text
loading data
```

vs

```text
doctor has no appointments
```

The UI must clearly distinguish:

* loading
* empty
* error
* success

---

# 4. Realtime Must Trigger Refetch Logic

Realtime updates should NOT manually mutate deep local state.

Instead:

```text
Realtime Event
    ↓
Invalidate Provider
    ↓
Refetch Fresh Data
    ↓
Rebuild UI
```

This avoids state drift.

---

# Recommended Architecture

# Repository Layer

Create repositories responsible ONLY for backend communication.

---

## Doctor Repository

Responsibilities:

* fetch doctor profile
* fetch doctor settings
* update doctor settings

---

## Appointment Repository

Responsibilities:

* fetch appointments
* create appointment
* update appointment
* cancel appointment

---

## Schedule Repository

Responsibilities:

* fetch schedules
* update schedules

---

# Provider Layer

Providers should:

* expose UI state
* call repositories
* manage loading/error states
* subscribe to realtime

Providers should NOT:

* hardcode fallback values
* contain business scheduling logic
* manually synchronize duplicated lists

---

# State Rules

# DO NOT Store Duplicate Derived Lists

Avoid:

```dart
todayAppointments
weekAppointments
upcomingAppointments
calendarAppointments
```

all stored independently.

Instead:

```text
one source list
+
computed getters
```

Example:

```dart
allAppointments
```

then derive:

* today
* week
* pending
* cancelled

dynamically.

---

# Fresh Fetch Rules

# ALWAYS Refetch After

* appointment creation
* appointment cancellation
* schedule update
* doctor settings update
* subscription update

---

# Realtime Strategy

# Subscribe Per Doctor

Subscribe ONLY to:

```text
appointments
doctor_schedule
doctors
```

filtered by:

```text
doctor_id
```

---

# On Realtime Event

DO:

```text
invalidate provider
refetch fresh state
```

DO NOT:

* patch local arrays manually
* splice deeply nested state
* partially update derived state

---

# Cache Strategy

# Cache ONLY Short-Term UI State

Safe cache examples:

* selected day
* current week
* scroll position
* opened appointment

NOT:

* permanent appointment truth
* doctor truth
* slot truth

---

# Loading Strategy

# Use Explicit State Objects

Avoid:

```dart
doctor == null
```

as the only loading detection.

Use clear states:

```text
loading
success
empty
error
```

---

# Error Handling Rules

# NEVER Silent Fail

Bad:

```dart
catch (_) {}
```

Good:

* log error
* expose error state
* retry fetch if needed

---

# Availability Data Rules

Availability must ALWAYS be recomputed from:

* latest appointments
* latest schedules

NEVER cache generated slots permanently.

---

# Offline & Fallback Rules

# Allowed Fallbacks

ONLY for:

* avatar placeholders
* empty bio text
* optional notes
* UI skeletons

---

# Forbidden Fallbacks

NEVER fallback:

* appointment duration
* doctor schedule
* appointment data
* doctor availability
* subscription state

Those must come from backend truth.

---

# Recommended Data Flow

```text
Supabase
    ↓
Repositories
    ↓
Riverpod Providers
    ↓
Realtime Invalidation
    ↓
Fresh Refetch
    ↓
Availability Engine
    ↓
UI Rendering
```

---

# Reliability Checklist

# Doctor Data

* always fetched from backend
* no hardcoded defaults
* no stale local copies

---

# Appointment Data

* single source list
* realtime invalidation
* fresh fetch after mutations

---

# Schedule Data

* fetched separately
* invalidates availability engine

---

# Availability

* computed dynamically
* never persisted
* recomputed after updates

---

# Calendar

* presentation only
* never source of truth

---

# UI

* explicit loading/error/empty states
* no fake placeholder logic masking issues

---

# Final Goal

Eyadati should behave like:

```text
a realtime scheduling platform
```

NOT:

```text
a locally simulated calendar with backend sync
```

The backend must drive the application state consistently, while the frontend becomes a reliable renderer of fresh backend data.
