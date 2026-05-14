# Syncfusion Calendar Refactor Plan

## Status: Complete ✓

All phases committed. Run `flutter analyze` for 0 errors (warnings/info only).

---

## Decisions Made

1. **Status values**: All appointments (online & manual) use `'upcoming'` status. `'pending'` will be removed. `'confirmed'` was removed (not in DB schema).
2. **View toggle**: Week/Day toggle + week changer in the AppBar for cleaner UI.
3. **Dynamic hours**: Calendar adjusts visible hours based on doctor's earliest/latest schedule slot times. Fallback: 8:00-20:00.

---

## Phase 0 — Critical Bug Fixes

### 0.1 Fix `createAppointment` status
- **File**: `lib/features/doctor/presentation/providers/doctor_provider.dart`
- **Change**: `'status': 'confirmed'` → `'status': 'upcoming'`
- **Also add**: `'appointment_type': isConsultation ? 'consultation' : 'standard'`

### 0.2 Fix `SlotEngine` to only block active appointments
- **File**: `lib/core/engine/slot_engine.dart`
- **Change**: Filter `existingAppointments` to only `upcoming` + `pending` before checking overlaps
- **Reason**: cancelled/completed/absent appointments should not block slot availability

### 0.3 Add `isConsultation` to `AppointmentData`
- **File**: `lib/models/appointment_data.dart`
- **Change**: Ensure `isConsultation` field exists and is used by `_AppointmentWrapper`

---

## Phase 1 — Calendar UI Configuration

### 1.1 Time grid settings
- `timeInterval: Duration(minutes: 15)` — 15-min grid for precise minute positioning
- `timeIntervalHeight`: responsive (70/80/90 by screen width)
- `timeRulerSize: 56`
- `timeFormat: 'HH:mm'`
- `minimumAppointmentDuration: Duration(minutes: 15)` — prevents invisible micro-appointments
- `cellEndPadding: 4`

| Screen Width | Height per hour |
|---|---|
| Mobile (<600px) | 70px |
| Tablet (600-900px) | 80px |
| Desktop (≥900px) | 90px |

### 1.2 Dynamic visible hours
- Start from earliest `startTime` in `doctorState.scheduleSlots`
- End at latest `endTime` in `doctorState.scheduleSlots`
- Default fallback: 8:00 → 20:00

---

## Phase 2 — Appointment Rendering

### 2.1 Appointment builder
- Use `details.bounds` (Rect) for precise sizing
- Color by status + type:
  - cancelled → AppColors.error (50% opacity)
  - absent → AppColors.textHint
  - completed → AppColors.success
  - upcoming: consultation → AppColors.consultationColor, standard → AppColors.primary
- Border-left accent (3px)
- 15% opacity fill
- Shows time + patient name (only if bounds.height > 30)

### 2.2 Overlap handling
- Syncfusion handles automatically via column distribution

---

## Phase 3 — Interactive Cells

### 3.1 Selected cell decoration
```dart
selectionDecoration: BoxDecoration(
  color: AppColors.primary.withValues(alpha: 0.1),
  border: Border.all(color: AppColors.primary, width: 2),
  borderRadius: BorderRadius.circular(4),
)
```

### 3.2 Cell tap → dialog with pre-filled time
- `details.pacingInfo?.triggerTime` gives exact tapped time
- Pass to `DoctorAddAppointmentDialog` via new `initialTime` parameter

### 3.3 Update `DoctorAddAppointmentDialog`
- Accept `DateTime? initialTime` parameter
- Pre-select grid cell matching the initial time
- Fallback to first available slot if no match

---

## Phase 4 — AppBar with View Toggle & Week Changer

### 4.1 Layout
```
AppBar: [View Toggle] | [Prev] [Today/Date Range] [Next]
```

### 4.2 View Toggle
- Segmented buttons: "Semaine" / "Jour" / "Liste" (schedule)
- `CalendarView.week` / `CalendarView.day` / `CalendarView.schedule`

### 4.3 Week Navigation
- Chevron left/right to navigate weeks
- "Aujourd'hui" button or tap date range to jump to today
- Date range display: "14 - 20 Jan 2025" format

### 4.4 Schedule view
- `CalendarView.schedule` shows agenda-style list of upcoming appointments
- Can serve as primary view on mobile

---

## Phase 5 — Data Source Architecture

### 5.1 `initState` + `ref.listen` pattern
- Initial load in `initState` via `addPostFrameCallback`
- `ref.listen` updates data source when `allAppointments` changes
- Remove `didUpdateWidget` pattern

### 5.2 Remove debug prints
- All `print()` statements removed from production code

---

## Phase 6 — Realtime Sync

### 6.1 Verify realtime subscription
- `doctor_provider.dart` already has Postgres subscription
- `_refreshAppointments` → `_dataSource.updateAppointments`

### 6.2 Optimistic UI
- On `createAppointment` success: immediately add to `_dataSource`
- Don't wait for realtime trigger

---

## Key API References

### Syncfusion Calendar Data Source
- `CalendarDataSource.appointments` — list of `Appointment`
- `notifyListeners(CalendarDataSourceAction.reset, appointments)` — bulk refresh
- Override `handleLoadMore` for on-demand loading (not used currently)

### Syncfusion TimeSlotViewSettings
- `timeInterval` — grid granularity (15 min recommended)
- `timeIntervalHeight` — pixels per hour (70-90 responsive)
- `timeRulerSize` — time label column width
- `minimumAppointmentDuration` — prevents invisible micro-appointments
- `startHour` / `endHour` — visible time range

### Syncfusion CalendarView
- `day` — single day time grid
- `week` — 7-day time grid
- `schedule` — agenda/list view

### Appointment Height Formula
```
height = duration_minutes * (timeIntervalHeight / 60)
yPosition = (hour + minute/60) * timeIntervalHeight - (startHour * timeIntervalHeight)
```

### Syncfusion Appointment Fields
- `startTime` (DateTime) — required
- `endTime` (DateTime) — required, if before startTime → 30min from start
- `subject` (String) — display text
- `color` (Color) — background
- `notes` (String?) — optional
- `id` (Object?) — unique identifier

---

## Files to Modify

| File | Phases |
|---|---|
| `doctor_provider.dart` | 0.1 |
| `lib/core/engine/slot_engine.dart` | 0.2 |
| `lib/models/appointment_data.dart` | 0.3 |
| `doctor_calendar_page.dart` | 1, 2, 3, 4, 5 |
| `doctor_add_appointment_dialog.dart` | 3 |
| `doctor_appointments_page.dart` | 4 (schedule view) |

---

## Implementation Order

1. Phase 0 (bug fixes) — committed first
2. Phase 1 (UI config) + Phase 2 (rendering)
3. Phase 3 (interactive cells)
4. Phase 4 (AppBar toggle) — biggest UX change
5. Phase 5 (data source cleanup)
6. Phase 6 (realtime + optimistic UI)