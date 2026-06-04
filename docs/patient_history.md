# PATIENT HISTORY FEATURE - OPENCODE IMPLEMENTATION CHECKLIST

## FEATURE GOAL

Build a lightweight patient history system for ONLINE PATIENTS ONLY.

Purpose:

* Help doctors remember previous visits.
* Reduce repeated questions.
* Provide visit context before consultation.
* Keep implementation simple and MVP-friendly.
* Reuse existing appointment card design language.

---

# DATABASE

## Patient Notes Table

* [ ] Create `patient_notes` table

Required fields:

* [ ] id (uuid)
* [ ] patient_id (uuid)
* [ ] doctor_id (uuid)
* [ ] appointment_id (uuid)
* [ ] note_text (text)
* [ ] created_at (timestamp)
* [ ] updated_at (timestamp)

Rules:

* [ ] Every note must belong to an appointment
* [ ] Every note must belong to a patient
* [ ] Every note must belong to a doctor
* [ ] No orphan notes allowed
* [ ] Notes remain available after appointment completion
* [ ] Notes remain available after appointment cancellation

---

# DATA LOADING

## Patient List Query

* [ ] Only include ONLINE patients
* [ ] Exclude walk-in appointments
* [ ] Group visits by patient_id
* [ ] Calculate visit count
* [ ] Calculate last visit date
* [ ] Calculate latest note preview

Required sorting:

* [ ] Most recently visited patient first

---

## Search

Search fields:

* [ ] patient name
* [ ] patient phone

Do NOT search:

* [ ] note content
* [ ] appointment notes
* [ ] diagnosis text

MVP Scope Only

---

# UI STRUCTURE

## New Tab

Add:

* [ ] Online Patients tab

Navigation:

```text
Dashboard
Calendar
Patients History
Settings
```

---

## Search Bar

Top of page.

Requirements:

* [ ] Sticky position
* [ ] Instant filtering
* [ ] Clear button
* [ ] Empty state

Placeholder:

```text
Search patient...
```

---

# PATIENT LIST

## Patient Card

Reuse existing appointment card style.

Do NOT create a new visual system.

Card displays:

* [ ] Patient avatar
* [ ] Patient name
* [ ] Phone number
* [ ] Visit count
* [ ] Last visit date
* [ ] Expand arrow

Card height:

* [ ] Similar to appointment cards

Visual consistency:

* [ ] Same border radius
* [ ] Same shadows
* [ ] Same typography
* [ ] Same spacing scale

---

# EXPANDABLE TILE

## Closed State

Show only:

* [ ] Name
* [ ] Phone
* [ ] Visit count
* [ ] Last visit

Keep compact.

---

## Expanded State

Reveal:

* [ ] Timeline section
* [ ] Visit history
* [ ] Notes section
* [ ] Add note button

Animation:

* [ ] Smooth expand
* [ ] Smooth collapse

---

# VISIT HISTORY

## Timeline

Display visits chronologically.

Newest first.

Each visit card shows:

* [ ] Appointment date
* [ ] Appointment time
* [ ] Consultation/Appointment type
* [ ] Status

Reuse:

* [ ] Existing appointment card UI

Do not redesign appointment cards.

---

# NOTE SYSTEM

## Add Note

Button:

```text
Add Note
```

Requirements:

* [ ] Create note
* [ ] Edit note
* [ ] Delete note
* [ ] Auto-save optional

Note belongs to:

* [ ] Appointment
* [ ] Patient
* [ ] Doctor

Never store loose notes.

---

## Voice Input

Requirements:

* [ ] Microphone button
* [ ] Speech-to-text
* [ ] Insert result into text field
* [ ] Allow manual editing before save
* [ ] Allow retry

Failure handling:

* [ ] Speech permission denied
* [ ] Recognition failed
* [ ] No speech detected

---

# NOTE CARD

Each note card displays:

* [ ] Visit date
* [ ] Visit time
* [ ] Note content
* [ ] Created timestamp
* [ ] Edit button

Optional:

* [ ] Doctor avatar

Not required for MVP.

---

# EMPTY STATES

## No Patients

Display:

```text
No online patients yet.
```

---

## No Notes

Display:

```text
No notes added yet.
```

---

## Search Empty

Display:

```text
No patients found.
```

---

# PERFORMANCE

## Loading

* [ ] Lazy load notes
* [ ] Do not load all notes immediately
* [ ] Load notes when patient expands

Reason:

Large clinics may have hundreds of visits.

---

## Queries

* [ ] Avoid N+1 queries
* [ ] Batch load patient summaries
* [ ] Index patient_id
* [ ] Index doctor_id
* [ ] Index appointment_id

---

# SECURITY

## RLS

* [ ] Doctor sees only own notes
* [ ] Partner doctors cannot access private notes
* [ ] Receptionist cannot edit notes
* [ ] Receptionist read access configurable later

---

# REALTIME

## Updates

* [ ] New note appears instantly
* [ ] Edited note updates instantly
* [ ] Deleted note disappears instantly

Use existing Supabase realtime architecture.

---

# MVP ACCEPTANCE CRITERIA

* [ ] Online patients appear in searchable list
* [ ] Visit count displayed correctly
* [ ] Last visit displayed correctly
* [ ] Expandable patient cards work
* [ ] Appointment history visible
* [ ] Notes linked to visits
* [ ] Voice-to-text works
* [ ] Notes persist after refresh
* [ ] Notes update realtime
* [ ] UI matches existing appointment cards
* [ ] No walk-in patients included
* [ ] No duplicate patient entries
* [ ] No orphan notes possible
* [ ] Empty states implemented
* [ ] Loading states implemented
