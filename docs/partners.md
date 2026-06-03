

Use **one calendar system**, then switch the **view mode** by routing so it feels like the doctor calendar is being upgraded, not replaced.

# Best approach

## Keep the same scheduler

Do not build a second calendar engine.

Use:

* same week/day grid
* same appointment rendering
* same availability engine
* same realtime updates

Then change only:

* data source
* card content
* tooltip content
* header summary
* doctor ownership display

---

# Transition idea

Route from:

* `/doctor/calendar`

to:

* `/clinic/calendar`

with:

* same selected date
* same week position
* same visual layout
* same animation style

That gives the feeling of:

```text
doctor calendar → expanded clinic calendar
```



---

# For multiple appointments in one card



## Card content

Show only:

* time
* small doctor avatars


---

# Important rule

If a time block has more than one item, do not cram full text into the card.

Use:

* stacked avatars
* small count badge like `+2`
* tooltip or popover for details

Example:

* 2 doctors → show two avatars
* 3+ items → show avatars + `+3`

That prevents visual clutter.

---

# Best UI structure for the multi-doctor mode

## Top bar

Add:

* clinic name
* “All doctors” filter(to hide a specific doctor)
* doctor add and remove icon that opens a dialogue


## Appointment card

Show:

* if one doctor show name and time 2+ doctors show only avatars if one appointment from doc A overlaps with doc B split the appointments and make the smallest duration appointment count as 2 appointments
* same 


## Tooltip

Show:

* full appointment list inside that time block using the existing appointment design in tooltip
* doctor avatar as a leading


---

# Best technical structure

Keep:

* `DoctorCalendarPage`
* `ClinicCalendarPage`

but both should use the same shared:

* scheduler widget
* appointment mapper
* availability logic

Only the view wrapper changes.

That is cleaner than trying to overload the doctor page itself.

---

# Good detail to preserve

When routing between views:

* keep selected day
* keep week offset
* keep scroll position if possible

That makes the transition feel smooth and intentional.

---

# IMPROVEMENT
# EYADATI PARTNERS / CLINIC CALENDAR IMPROVEMENT CHECKLIST

## GOAL
- [ ] Turn the current partners feature into a stable receptionist-first clinic calendar
- [ ] Keep doctors as separate solo accounts on the patient side
- [ ] Keep every appointment owned by exactly one doctor
- [ ] Make the shared clinic calendar faster, clearer, and easier to maintain
- [ ] Reduce UX friction for walk-ins and multi-doctor scanning

---

## 1. ARCHITECTURE RULES
- [ ] Keep the same calendar engine for both doctor and clinic modes
- [ ] Use a dedicated clinic view instead of overloading the doctor view
- [ ] Keep doctor schedules separate internally
- [ ] Keep appointment ownership tied to a single doctor_id
- [ ] Keep receptionist view as a presentation layer on top of the existing data
- [ ] Do not merge doctor accounts or identities
- [ ] Do not create shared doctor auth or shared doctor profiles
- [ ] Do not create shared availability pools unless explicitly needed later
- [ ] Do not let UI logic replace backend validation

---

## 2. DATA MODEL REVIEW
- [ ] Confirm clinic group tables exist and are minimal
- [ ] Keep clinic group membership separate from doctor identity
- [ ] Keep receptionist access separate from doctor access
- [ ] Store doctor ownership for every appointment
- [ ] Store clinic membership for doctors in the receptionist view
- [ ] Make doctor color or avatar identity stable and consistent
- [ ] Keep filtering state separate from stored appointment data
- [ ] Ensure removing a doctor from a clinic does not delete historical appointments
- [ ] Ensure adding a doctor to a clinic does not rewrite old appointment ownership

---

## 3. CLINIC CALENDAR VIEW
- [ ] Create a distinct clinic calendar page or view mode
- [ ] Reuse the existing calendar engine instead of rebuilding it
- [ ] Show all clinic doctors in one calendar for receptionist mode
- [ ] Show each appointment’s doctor identity clearly
- [ ] Support one-day and week views consistently
- [ ] Keep navigation behavior consistent with the current app
- [ ] Keep the transition from doctor calendar to clinic calendar smooth
- [ ] Preserve selected date and week position when switching views
- [ ] Preserve scroll position where possible

---

## 4. APPOINTMENT CARD UX
- [ ] Show doctor avatar or initials on every appointment card
- [ ] Use a stable color identity per doctor
- [ ] Keep cards compact and readable
- [ ] Show patient name clearly
- [ ] Show appointment time clearly
- [ ] Show booking type clearly
- [ ] Show status clearly
- [ ] Do not overload cards with too much text
- [ ] Do not hide doctor ownership behind hover only
- [ ] Make multi-doctor ownership visible at a glance
- [ ] Support stacked avatars or avatar + count when needed
- [ ] Show doctor name in details or tooltip for confirmation

---

## 5. MULTIPLE APPOINTMENTS / DENSE SLOTS
- [ ] Handle multiple appointments in the same visible time area cleanly
- [ ] Use compact stacking or overlap rules that remain readable
- [ ] Add a count badge when too many appointments are in one block
- [ ] Expand or tooltip the full list when a block contains more than one item
- [ ] Ensure hover details remain readable on desktop
- [ ] Ensure tap details remain readable on mobile
- [ ] Prevent visual clutter when the clinic is busy
- [ ] Ensure doctor color remains visible even in dense blocks

---

## 6. RECEPTIONIST BOOKING FLOW
- [ ] Keep tap-to-create behavior instant
- [ ] Open the booking dialog with the selected date/time already set
- [ ] Let receptionist choose patient name
- [ ] Let receptionist choose phone number
- [ ] Let receptionist choose appointment type
- [ ] Let receptionist choose duration
- [ ] Let receptionist choose doctor explicitly
- [ ] Suggest the most available doctor when possible
- [ ] Validate selected doctor availability before save
- [ ] Reject invalid or conflicting bookings clearly
- [ ] Prevent silent reassignment to another doctor
- [ ] Keep the save flow faster than writing on paper

---

## 7. DOCTOR ASSIGNMENT UX
- [ ] Show available doctors prominently in walk-in dialog
- [ ] Hide or disable doctors who are paused, expired, or unavailable
- [ ] Show busy doctors clearly instead of hiding all context
- [ ] Show doctor names and colors in the selector
- [ ] Prefer a visual doctor picker over a plain dropdown when possible
- [ ] Preserve the last selected doctor for faster repeated booking
- [ ] Allow receptionist to switch doctors quickly before save
- [ ] Make doctor ownership obvious in the final appointment card

---

## 8. AVAILABILITY AND CONFLICT RULES
- [ ] Validate appointment against the selected doctor only
- [ ] Validate working hours before saving
- [ ] Validate breaks before saving
- [ ] Validate subscription status before saving
- [ ] Validate pause state before saving
- [ ] Prevent overlaps with online appointments
- [ ] Prevent overlaps with manual walk-ins
- [ ] Prevent same-time double booking
- [ ] Recompute availability after every create, update, cancel, or delete
- [ ] Keep the availability engine as the single source of truth
- [ ] Do not trust visual calendar free space alone

---

## 9. REALTIME SYNC
- [ ] Refresh clinic calendar when appointments change
- [ ] Refresh clinic calendar when doctor schedule changes
- [ ] Refresh clinic calendar when clinic membership changes
- [ ] Prevent duplicated refresh loops
- [ ] Prevent stale cards after live updates
- [ ] Refresh doctor ownership and counts after changes
- [ ] Handle realtime updates while dialog is open
- [ ] Handle reconnects without losing state
- [ ] Keep refresh logic predictable and debounced

---

## 10. FILTERS AND VIEW MODES
- [ ] Add an all-doctors view
- [ ] Add per-doctor quick filters
- [ ] Add a clear selected doctor state
- [ ] Allow hiding one doctor without removing them from the clinic
- [ ] Allow showing all doctors again instantly
- [ ] Keep filter chips readable
- [ ] Make filter states obvious
- [ ] Do not let filters destroy the calendar layout
- [ ] Keep filters responsive on mobile and desktop

---

## 11. RESPONSIVE UI
- [ ] Keep the current desktop scheduler usable on larger screens
- [ ] Provide a clean mobile clinic view
- [ ] Prevent card overcrowding on smaller screens
- [ ] Ensure doctor avatars remain visible on mobile
- [ ] Keep modal forms compact on mobile
- [ ] Keep the doctor selector easy to use on mobile
- [ ] Keep the calendar readable without hover support
- [ ] Provide touch-friendly interaction targets
- [ ] Use the same visual language as the current app

---

## 12. LOADING / EMPTY / ERROR STATES
- [ ] Show a clean loading state when clinic data is loading
- [ ] Show an empty state when the clinic has no doctors
- [ ] Show an empty state when no appointments exist yet
- [ ] Show an empty state when no doctor is available
- [ ] Show error state when group loading fails
- [ ] Show error state when appointment loading fails
- [ ] Show retry actions for failed loads
- [ ] Do not silently fail and leave the screen confusing

---

## 13. ADD / REMOVE DOCTOR WORKFLOW
- [ ] Add doctor by email with clear validation
- [ ] Prevent duplicate clinic membership
- [ ] Confirm before removing a doctor from clinic
- [ ] Do not delete historical appointments on removal
- [ ] Refresh calendar after add/remove operations
- [ ] Handle the current user being removed safely
- [ ] Keep add/remove workflow simple for receptionists
- [ ] Show feedback after add/remove actions

---

## 14. PERFORMANCE AND MAINTAINABILITY
- [ ] Reduce logic inside the calendar page widget
- [ ] Move mapping and transformation logic into helper/services where possible
- [ ] Avoid rebuilding the full calendar when only one appointment changes
- [ ] Avoid refreshing more data than needed
- [ ] Keep the clinic provider focused on data retrieval and state
- [ ] Keep card rendering separate from appointment parsing
- [ ] Keep filter logic centralized
- [ ] Avoid mixing UI state and business state too tightly

---

## 15. UX POLISH
- [ ] Make doctor ownership visible without forcing hover
- [ ] Make multi-doctor scanning easier at a glance
- [ ] Improve tooltip content for dense appointments
- [ ] Improve the top summary row for clinic mode
- [ ] Make the page feel like an upgraded version of the doctor calendar
- [ ] Keep the transition subtle and intentional
- [ ] Avoid enterprise-heavy visuals
- [ ] Keep the soft SaaS theme consistent with the rest of the app
- [ ] Keep the feature convenient, not complicated

---

## 16. EDGE CASES TO HANDLE
- [ ] Doctor is paused
- [ ] Doctor subscription expired
- [ ] Doctor was removed from clinic
- [ ] Doctor has overlapping online and manual bookings
- [ ] Two receptionists try booking the same time
- [ ] Appointment is cancelled while dialog is open
- [ ] Doctor schedule changes while receptionist is booking
- [ ] A clinic has only one active doctor left
- [ ] A clinic has many doctors and cards become crowded
- [ ] Appointment ownership needs to remain clear when multiple items are visible

---

## 17. FINAL ACCEPTANCE
- [ ] Receptionist can view all clinic doctors in one calendar
- [ ] Receptionist can assign walk-ins quickly to the right doctor
- [ ] Every appointment shows clear doctor ownership
- [ ] The clinic calendar is easier than opening separate doctor calendars
- [ ] The booking flow is faster than paper
- [ ] Realtime updates remain stable
- [ ] No merged doctor accounts exist
- [ ] No shared doctor identity exists
- [ ] Patient-side behavior remains unchanged
- [ ] The feature feels simple, stable, and useful



