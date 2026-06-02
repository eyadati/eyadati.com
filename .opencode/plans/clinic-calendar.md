# Clinic Calendar / Partners Feature — Implementation Plan

Based on `docs/partners.md` — SAFEST MVP VERSION (no shared availability, no auto-routing, no merged accounts).

---

## PHASE 1 — Data Model (Database Migrations)

### 1a. `012_clinic_groups.sql` — New tables

```sql
-- Clinic identity
CREATE TABLE public.clinic_groups (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  address    TEXT,
  phone      TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Who belongs to which clinic
CREATE TABLE public.clinic_group_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_group_id UUID NOT NULL REFERENCES clinic_groups(id) ON DELETE CASCADE,
  doctor_id       UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  is_receptionist BOOLEAN DEFAULT FALSE,
  color           TEXT,        -- hex color for this doctor in the shared calendar
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(clinic_group_id, doctor_id)
);

CREATE INDEX idx_clinic_members_group ON clinic_group_members(clinic_group_id);
CREATE INDEX idx_clinic_members_doctor ON clinic_group_members(doctor_id);

ALTER TABLE public.clinic_group_members ENABLE ROW LEVEL SECURITY;

-- Doctors can view their own membership
CREATE POLICY "Members view own"
  ON clinic_group_members FOR SELECT
  USING (doctor_id = auth.uid() OR is_receptionist = TRUE);

-- Receptionists can view all members in their clinic groups
CREATE POLICY "Receptionists view group"
  ON clinic_group_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM clinic_group_members cgm
      WHERE cgm.clinic_group_id = clinic_group_members.clinic_group_id
        AND cgm.doctor_id = auth.uid()
        AND cgm.is_receptionist = TRUE
    )
  );

-- Allow receptionist SELECT on appointments for doctors in their clinic
CREATE POLICY "Receptionists select appointments"
  ON appointments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM clinic_group_members cgm_recep
      JOIN clinic_group_members cgm_doctor
        ON cgm_doctor.clinic_group_id = cgm_recep.clinic_group_id
      WHERE cgm_recep.doctor_id = auth.uid()
        AND cgm_recep.is_receptionist = TRUE
        AND cgm_doctor.doctor_id = appointments.doctor_id
    )
  );

-- Allow receptionist INSERT with manual booking_type for their clinic doctors
CREATE POLICY "Receptionists insert walk-ins"
  ON appointments FOR INSERT
  WITH CHECK (
    booking_type = 'manual'
    AND EXISTS (
      SELECT 1 FROM clinic_group_members cgm_recep
      JOIN clinic_group_members cgm_doctor
        ON cgm_doctor.clinic_group_id = cgm_recep.clinic_group_id
      WHERE cgm_recep.doctor_id = auth.uid()
        AND cgm_recep.is_receptionist = TRUE
        AND cgm_doctor.doctor_id = appointments.doctor_id
    )
  );
```

### 1b. Update `AppointmentData` model — add `doctorId` + `doctorName`

**File: `lib/models/appointment_data.dart`**
- Add fields: `String doctorId`, `String doctorName` (both required)
- Update factory constructor

**File: `lib/features/doctor/presentation/providers/doctor_provider.dart`**
- In `_parseAppointmentRow()`, the `doctor_id` is known from context (current user), no change needed for solo doctor view
- BUT the receptionist view needs `doctor_id` from the row, so the parsing should include it

---

## PHASE 2 — Receptionist Auth & Provider

### 2a. Auth — recognize `receptionist` role

**File: `lib/features/auth/presentation/providers/auth_state.dart`**
- Add `bool isReceptionist = false` field and update `copyWith`

**File: `lib/features/auth/presentation/providers/auth_provider.dart`**
- In `_fetchRoleFromProfile()`, detect `'receptionist'` role
- Set `isReceptionist` flag on state

### 2b. Clinic Receptionist Provider

**New file: `lib/features/clinic/presentation/providers/clinic_provider.dart`**

```
ClinicGroupState:
  List<ClinicGroupMember> members     // doctors in my clinic
  List<AppointmentData> appointments  // all appointments merged
  bool isLoading
  String? error
  Map<String, Color> doctorColors    // consistent color per doctor
  Map<String, String> doctorNames    // doctor_id → name
  String? currentClinicGroupId

ClinicNotifier:
  loadClinicGroup() → fetches current user's clinic_group, members, and load all appointments
  _loadAppointmentsForDoctor(doctorId) → fetches appointments for one doctor
  createWalkIn({doctorId, patientName, patientPhone, scheduledAt, duration, isConsultation}) → INSERT
  refresh() → reloads all appointments
  _subscribeToAppointments() → Realtime subscription for all doctors in clinic
```

This is a new feature area — place in `lib/features/clinic/` mirroring the doctor feature structure.

### 2c. Shared utility for color assignment

**New file: `lib/core/utils/doctor_colors.dart`**
- Generate consistent colors for doctors based on index (cycling through a predefined palette)
- Store in `clinic_group_members.color` column when assigned

---

## PHASE 3 — Receptionist Calendar UI

### 3a. New page: `lib/features/clinic/presentation/pages/clinic_calendar_page.dart`

Reuses the existing `doctor_calendar_page.dart` pattern but:
- Uses `clinicProvider` instead of `doctorProvider`
- All appointments include `doctorName` + `doctorColor` for badges
- Desktop: Syncfusion `SfCalendar` with same week view, but appointments have doctor badges
- Mobile: `DoctorWeekStrip` (reuse) + `DoctorDayListView` (reuse with doctor badges)
- FAB to create walk-in opens `WalkInDialog`

### 3b. Walk-in creation dialog

**New file: `lib/features/clinic/presentation/widgets/walk_in_dialog.dart`**

Reuses `doctor_add_appointment_dialog.dart` pattern but:
- Adds a **doctor picker** (dropdown/segmented control of clinic doctors)
- All availability/duration/slot validation uses the **selected doctor only**
- Patient name + phone fields (same as existing)
- Appointment type + duration (same as existing)
- Time slots filtered by selected doctor's availability

### 3c. Doctor badge on appointment cards

**Modify: `doctor_calendar_page.dart` (desktop `appointmentBuilder`)**
- Add doctor avatar/initials + color bar on the left edge of each card

**Modify: `doctor_day_list_view.dart` (mobile cards)**
- Add doctor color dot + initials/name next to patient name

### 3d. `AppointmentDetailsSheet` — show doctor identity

**Modify: `lib/features/doctor/presentation/widgets/appointment_details_sheet.dart`**
- If `appointment.doctorId` differs from current user, show "Dr. X" badge at top

---

## PHASE 4 — Navigation

### 4a. App routing

**File: `lib/core/routing/app_router.dart`**
- Add route `/clinic-calendar` for receptionist landing
- If user role is `receptionist`, redirect to clinic calendar instead of doctor dashboard

### 4b. Bottom nav / sidebar

- Add "Clinique" tab for receptionists (or replace the doctor dashboard tab)

---

## SAFEST MVP — Scope Lock

| Done? | Item |
|---|---|
| ❌ | Shared calendar view (receptionist sees all doctors) |
| ❌ | Receptionist role in auth |
| ❌ | `clinic_groups` + `clinic_group_members` tables |
| ❌ | RLS for receptionist SELECT/INSERT on appointments |
| ❌ | `doctorId` + `doctorName` on `AppointmentData` |
| ❌ | Clinic provider with merged appointment loading |
| ❌ | Doctor badges (color/initials) on appointment cards |
| ❌ | Walk-in dialog with doctor picker |
| ❌ | Realtime sync for shared calendar |
| ❌ | Receptionist route + navigation |

| ✅ Not needed (MVP) | Reason |
|---|---|
| ❌ Shared availability engine | Explicitly avoided in checklist |
| ❌ Auto-balancing / smart routing | Explicitly avoided |
| ❌ Merged doctor accounts | Explicitly avoided |
| ❌ Patient-side changes | Explicitly avoided |
| ❌ Complex admin dashboard | Keep it simple — one page |
| ❌ Partner-specific billing | Future concern |

---

## Implementation Order

1. DB migration (`012_clinic_groups.sql`) — run in Supabase SQL Editor
2. `AppointmentData` — add `doctorId` + `doctorName`
3. `DoctorNotifier._parseAppointmentRow()` — include `doctor_id` in the select query
4. Auth — add `isReceptionist` to state + provider
5. `ClinicNotifier` + `clinic_provider.dart` (new)
6. `doctor_colors.dart` utility
7. `ClinicCalendarPage` (new, reuses Syncfusion calendar)
8. `WalkInDialog` (new, copies existing dialog + doctor picker)
9. Patch appointment cards for doctor badges (desktop `appointmentBuilder` + mobile `DoctorDayListView`)
10. `AppointmentDetailsSheet` — show doctor identity
11. Routing + navigation for receptionist
12. E2E test
