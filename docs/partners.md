# EYADATI PARTNERS / CLINIC CALENDAR CHECKLIST

## PURPOSE
- [ ] Keep doctors as independent solo accounts on the patient side
- [ ] Add a receptionist-only clinic calendar that merges visibility for multiple doctors
- [ ] Keep every appointment owned by exactly one doctor
- [ ] Avoid merged doctor identities, merged profiles, or shared auth

---

## CORE RULES
- [ ] Do not change patient-side doctor browsing
- [ ] Do not change patient-side booking behavior unless required for receptionist workflows
- [ ] Do not merge doctor schedules into one shared doctor
- [ ] Do not create a shared availability pool
- [ ] Do not auto-route appointments without explicit rules
- [ ] Keep booking validation per doctor
- [ ] Keep all appointments tied to a single `doctor_id`

---

## DATA MODEL
- [ ] Create a lightweight clinic grouping layer
- [ ] Add `clinic_groups`
- [ ] Add `clinic_group_members`
- [ ] Keep membership separate from doctor profile data
- [ ] Keep receptionist permissions separate from doctor permissions
- [ ] Add clinic identity only for shared receptionist view
- [ ] Do not create shared doctor accounts

---

## CLINIC GROUP TABLES
- [ ] `clinic_groups` stores clinic identity
- [ ] `clinic_group_members` stores which doctors belong to the clinic group
- [ ] Optional receptionist role support is explicit
- [ ] Membership changes do not alter doctor identity
- [ ] Membership changes do not alter patient-side behavior

---

## CALENDAR BEHAVIOR
- [ ] Build one receptionist-facing clinic calendar
- [ ] Show appointments from all doctors in the clinic group
- [ ] Show each appointment’s doctor owner clearly
- [ ] Use doctor avatar, initials, or a color marker on each card
- [ ] Keep the doctor identity visible in the card and details view
- [ ] Prevent confusion between doctors in the shared calendar
- [ ] Keep the current week/day layout behavior consistent with the app

---

## BOOKING BEHAVIOR
- [ ] Receptionist can create walk-in appointments from the clinic calendar
- [ ] Receptionist must choose a doctor for each walk-in
- [ ] Appointment creation must validate the chosen doctor’s availability
- [ ] Appointment creation must respect that doctor’s schedule
- [ ] Appointment creation must respect that doctor’s durations
- [ ] Appointment creation must respect breaks and pauses
- [ ] Appointment creation must reject overlaps
- [ ] Appointment creation must fail clearly if the doctor is not free
- [ ] Appointment creation must never silently switch doctors

---

## VISIBILITY RULES
- [ ] Receptionist sees both doctors in one calendar
- [ ] Receptionist sees online appointments and walk-ins in one view
- [ ] Patient-side views remain solo-doctor only
- [ ] Doctor-side views can stay solo or can optionally filter to own appointments
- [ ] Shared calendar is a receptionist convenience layer only

---

## REALTIME RULES
- [ ] Shared calendar updates when Doctor A changes
- [ ] Shared calendar updates when Doctor B changes
- [ ] Shared calendar updates when a walk-in is added
- [ ] Shared calendar updates when an appointment is cancelled
- [ ] Shared calendar updates when a schedule changes
- [ ] Shared calendar updates when a doctor pauses or returns
- [ ] Realtime refresh must not duplicate appointments
- [ ] Realtime refresh must not leave stale cards on screen

---

## PER-DOCTOR VALIDATION
- [ ] Each doctor keeps their own schedule
- [ ] Each doctor keeps their own working hours
- [ ] Each doctor keeps their own breaks
- [ ] Each doctor keeps their own appointment durations
- [ ] Each doctor keeps their own consultation durations
- [ ] Each doctor keeps their own pause and subscription rules
- [ ] Availability checks always use the selected doctor only

---

## EDGE CASES
- [ ] One doctor free, one doctor busy
- [ ] Both doctors free
- [ ] Both doctors busy
- [ ] One doctor paused
- [ ] One doctor expired
- [ ] One doctor has only short gaps
- [ ] One doctor has online appointments already on the calendar
- [ ] A walk-in gets assigned during a crowded period
- [ ] A receptionist opens the modal from a day where no doctor is free
- [ ] A doctor changes schedule while receptionist is booking
- [ ] Realtime update arrives while receptionist modal is open

---

## PERMISSIONS
- [ ] Receptionist can view clinic calendar
- [ ] Receptionist can create walk-ins
- [ ] Receptionist can assign doctor for walk-ins
- [ ] Receptionist can edit appointments only if allowed
- [ ] Doctors should not gain unexpected access to other doctors’ private workflow
- [ ] Patient-side access must remain unchanged
- [ ] Permission rules must be explicit and tested

---

## UI / UX FOR THE FEATURE
- [ ] Keep the current clinic calendar style
- [ ] Use a clear doctor badge or avatar on each appointment card
- [ ] Use one subtle color identity per doctor
- [ ] Keep cards compact and readable
- [ ] Keep the week calendar the primary receptionist view
- [ ] Keep the modal fast and minimal
- [ ] Do not add a separate complex admin dashboard for this feature
- [ ] Do not force the receptionist to open two calendars
- [ ] Do not hide doctor ownership
- [ ] Do not overcrowd the interface

---

## RECEPTIONIST MODAL FLOW
- [ ] Tap empty time block
- [ ] Open modal instantly
- [ ] Preselect date and time
- [ ] Choose patient
- [ ] Choose doctor
- [ ] Choose appointment type
- [ ] Choose duration
- [ ] Show only valid available times
- [ ] Confirm with one click
- [ ] Save and refresh calendar instantly

---

## SAFEST MVP VERSION
- [ ] Shared calendar view only
- [ ] Separate doctor schedules
- [ ] Separate doctor appointment ownership
- [ ] Manual walk-in assignment by receptionist
- [ ] Doctor avatar or initials on every card
- [ ] Realtime sync
- [ ] No shared availability engine
- [ ] No auto-balancing
- [ ] No smart doctor routing
- [ ] No merged accounts

---

## THINGS TO AVOID
- [ ] Shared doctor identity
- [ ] Shared doctor login
- [ ] Shared schedule rows
- [ ] Shared appointment ownership
- [ ] Automatic doctor reassignment without consent
- [ ] Load balancing logic
- [ ] AI-driven routing
- [ ] Hidden appointment ownership
- [ ] Complex partner-specific billing logic
- [ ] Overengineering the receptionist workflow

---

## UI FIT FOR CURRENT APP
- [ ] Keep the existing clean calendar layout
- [ ] Add doctor avatars on appointment blocks
- [ ] Add a small doctor color tag or initials badge
- [ ] Keep the receptionist modal consistent with the current appointment dialog
- [ ] Keep the same soft SaaS theme
- [ ] Keep the same weekday/week calendar style
- [ ] Keep the same compact appointment cards
- [ ] Keep the same quick-create interaction pattern
- [ ] Keep the same keyboard-fast input behavior
- [ ] Keep the current app feeling operational, not enterprise-heavy

---

## FINAL ACCEPTANCE
- [ ] Receptionist can see both doctors in one calendar
- [ ] Receptionist can create walk-ins faster than opening separate calendars
- [ ] Every appointment clearly shows which doctor owns it
- [ ] No patient-side behavior changes unexpectedly
- [ ] No merged doctor accounts exist
- [ ] No shared schedule corruption exists
- [ ] Calendar stays stable during realtime updates
- [ ] Feature remains simple, convenient, and fast