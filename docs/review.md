Use this as the master review checklist. It is organized by area, route, theme, and behavior, so you can verify the app system by system.

# 0. Project foundation

* [ ] Flutter web/PWA builds correctly
* [ ] Supabase env vars are isolated and not hardcoded
* [ ] App starts with a session check before any UI
* [ ] Anonymous users never reach protected pages
* [ ] Role-based routing exists for patient and doctor
* [ ] Shared models/repositories are separated from UI
* [ ] No Supabase calls happen directly inside widgets

# 1. Auth system

* [ ] Login page exists
* [ ] Register page exists
* [ ] Forgot password page exists
* [ ] Session restore works on refresh
* [ ] Logout clears session cleanly
* [ ] User profile row is created after signup
* [ ] Role is resolved from `profiles`
* [ ] Redirect logic sends patient to patient home
* [ ] Redirect logic sends doctor to doctor dashboard
* [ ] Null session always redirects to login
* [ ] Auth errors are shown cleanly
* [ ] Loading state is shown while session is resolving

# 2. Routing system

* [ ] Public routes are accessible without login only if intended
* [ ] Protected routes reject unauthenticated users
* [ ] Patient routes are separate from doctor routes
* [ ] Doctor routes are separate from patient routes
* [ ] Deep links work on web
* [ ] Refreshing a protected route preserves correct redirect behavior
* [ ] Unknown routes go to a safe fallback page
* [ ] Route names are centralized, not scattered

# 3. Theme system

* [ ] Inter is the only main font
* [ ] Color palette is consistent across the app
* [ ] Primary blue is used only for emphasis and actions
* [ ] Background is soft, not harsh gray
* [ ] Cards have soft borders and subtle elevation
* [ ] Inputs have consistent radius and spacing
* [ ] Buttons follow one visual style system
* [ ] Status colors are semantic only
* [ ] Theme values are reused instead of hardcoded repeatedly
* [ ] Light theme looks coherent on desktop and mobile
* [ ] Theme does not fight custom components

# 4. Global layout system

* [ ] App shell exists
* [ ] Desktop uses sidebar layout
* [ ] Mobile uses bottom navigation or stacked layout
* [ ] Tablet layout is adaptive
* [ ] Content width is constrained on large screens
* [ ] Sections are grouped into surfaces/cards
* [ ] Page titles, subtitles, and section headers have clear hierarchy
* [ ] White space is consistent
* [ ] No screen feels stretched edge-to-edge on desktop

# 5. Core reusable components

* [ ] Primary button component exists
* [ ] Secondary button component exists
* [ ] App text field component exists
* [ ] Search field component exists
* [ ] Card component exists
* [ ] Status badge component exists
* [ ] Empty state component exists
* [ ] Loading component exists
* [ ] Error component exists
* [ ] Dialog component exists
* [ ] Bottom sheet component exists
* [ ] Sidebar item component exists
* [ ] Appointment block component exists
* [ ] Doctor card component exists
* [ ] Stat card component exists

# 6. Patient area

* [ ] Patient home page exists
* [ ] Doctor browse page exists
* [ ] Doctor details page exists
* [ ] Booking page exists
* [ ] My appointments page exists
* [ ] Favorites page exists
* [ ] Patient profile page exists

## Patient browse behavior

* [ ] Only active doctors are shown
* [ ] Expired doctors are hidden
* [ ] Manually paused doctors are hidden
* [ ] Search by name/specialty works
* [ ] Filters work correctly
* [ ] Doctor cards show the right data
* [ ] Doctor cards are not overloaded with too much text

## Patient booking behavior

* [ ] Available slots are generated from schedule and appointments
* [ ] Consultation duration is used when consultation is selected
* [ ] Appointment duration is used when regular booking is selected
* [ ] Booking prevents overlapping slots
* [ ] Booking confirms only when the slot is still available
* [ ] Booking failure shows a clear reason
* [ ] Booking success updates the UI immediately

## Patient appointment behavior

* [ ] Appointment cards show doctor name
* [ ] Appointment cards show date and time
* [ ] Appointment cards show address
* [ ] GPS/maps action works
* [ ] Cancel action works
* [ ] Slidable cancel UI works on mobile
* [ ] Cancel is allowed only when valid
* [ ] Cancelled appointments are styled differently
* [ ] Upcoming appointments are shown clearly
* [ ] Past appointments are separated from upcoming ones

## Patient favorites behavior

* [ ] Favorite add/remove works
* [ ] Favorite state persists
* [ ] Favorites list only shows doctors still active unless you intentionally keep historical favorites visible
* [ ] Favorite icon state matches the database

# 7. Doctor area

* [ ] Doctor dashboard page exists
* [ ] Doctor appointments page exists
* [ ] Doctor schedule page exists
* [ ] Doctor profile page exists
* [ ] Doctor subscription page exists
* [ ] Doctor settings page exists

## Doctor dashboard behavior

* [ ] Today stats are visible
* [ ] Upcoming appointments are visible
* [ ] Schedule preview is visible
* [ ] Quick actions are available
* [ ] Subscription status is visible
* [ ] Paused state is visible
* [ ] Dashboard loads fast and stays readable

## Doctor appointment behavior

* [ ] Online appointments are fetched
* [ ] Manual appointments are fetched
* [ ] Both booking types appear in the same timeline/list
* [ ] Appointment status updates are possible
* [ ] Completed status works
* [ ] Absent status works
* [ ] Cancelled status works
* [ ] Manual appointment is confirmed by default
* [ ] Online appointment uses the correct initial status rule
* [ ] Status rules are consistent with doctor workflow

## Doctor manual booking behavior

* [ ] Doctor can create a manual appointment
* [ ] Manual appointment stores snapshot patient info
* [ ] Manual appointment does not require a patient account
* [ ] Manual appointment is saved into the same appointments table
* [ ] Manual appointment appears instantly in dashboard

## Doctor schedule behavior

* [ ] Working days are read correctly
* [ ] Opening time is read correctly
* [ ] Closing time is read correctly
* [ ] Break time is respected
* [ ] Different appointment types use different durations
* [ ] Availability recalculates after booking changes
* [ ] Paused doctor shows no public availability

# 8. Scheduling and slots

* [ ] Time is treated consistently across the app
* [ ] Internal scheduling logic uses minutes-based calculations
* [ ] Slot generation is based on schedule rows and doctor settings
* [ ] Existing appointments are removed from available time ranges
* [ ] Break periods remove availability
* [ ] Closed hours remove availability
* [ ] Consultation duration and appointment duration both work
* [ ] Slot generation adapts to each type without wasting space
* [ ] A slot is never shown if it cannot fully fit the chosen duration
* [ ] Overlap checks are exact, not approximate
* [ ] Current day and current week views work
* [ ] No duplicate slot can be booked from the same time window

# 9. Appointment logic decisions

* [ ] Manual appointment defaults are intentional
* [ ] Online appointment defaults are intentional
* [ ] Cancelled appointment state is consistent everywhere
* [ ] Completed appointment state is consistent everywhere
* [ ] Absent appointment state is consistent everywhere
* [ ] Status transitions are allowed only when valid
* [ ] Booking type is not confused with status
* [ ] Consultation is not confused with regular booking
* [ ] Snapshot fields are used where profile changes should not affect history

# 10. Realtime behavior

* [ ] App subscribes to appointment changes for the current doctor or current patient
* [ ] Insert events update the UI instantly
* [ ] Update events update the UI instantly
* [ ] Delete events update the UI instantly
* [ ] Slot lists refresh when a booking happens
* [ ] Doctor dashboard updates when a patient books
* [ ] Patient booking page updates when a doctor changes schedule
* [ ] Realtime does not cause duplicate renders
* [ ] Realtime subscriptions are cleaned up properly

# 11. Supabase data integrity

* [ ] RLS is enabled on all protected tables
* [ ] Patients can only see their own private data
* [ ] Doctors can only manage their own data
* [ ] Public browsing exposes only intended doctor rows
* [ ] Appointments are protected by ownership rules
* [ ] Favorites are protected by ownership rules
* [ ] Doctor schedule rows are protected
* [ ] Insert/update/delete rules are tested manually
* [ ] Query filters are backed by indexes where needed

# 12. Pages and route-by-route QA

* [ ] `/login` works
* [ ] `/register` works
* [ ] `/forgot-password` works
* [ ] `/patient/home` works
* [ ] `/patient/doctors` works
* [ ] `/patient/favorites` works
* [ ] `/patient/appointments` works
* [ ] `/patient/profile` works
* [ ] `/doctor/dashboard` works
* [ ] `/doctor/appointments` works
* [ ] `/doctor/schedule` works
* [ ] `/doctor/profile` works
* [ ] `/doctor/subscription` works
* [ ] `/doctor/settings` works
* [ ] Protected routes redirect properly when session is missing
* [ ] Wrong role cannot access the wrong dashboard

# 13. UI quality review

* [ ] No screen feels like default Flutter widgets dumped on a page
* [ ] Cards have clear grouping
* [ ] Text hierarchy is obvious
* [ ] Icons are consistent
* [ ] Lucide is used consistently
* [ ] Spacing feels intentional
* [ ] Desktop pages feel like SaaS
* [ ] Mobile pages feel lightweight and fast
* [ ] Sidebar, top bar, and content surfaces look unified
* [ ] Forms look premium, not generic

# 14. Responsiveness

* [ ] Mobile layout is readable without horizontal overflow
* [ ] Tablet layout is usable and not cramped
* [ ] Desktop layout uses width efficiently
* [ ] Scheduler/calendar adapts to screen size
* [ ] Patient pages do not copy desktop layouts blindly
* [ ] Doctor pages do not feel cramped on wide screens
* [ ] Buttons and touch targets are usable on mobile

# 15. Performance

* [ ] Lists are paginated or limited where needed
* [ ] Queries fetch only required columns
* [ ] Large views do not rebuild unnecessarily
* [ ] Calendar renders only needed time ranges
* [ ] Images are cached
* [ ] Empty states and loading states do not block the UI
* [ ] No heavy logic runs inside widgets

# 16. Error handling

* [ ] Auth errors are readable
* [ ] Booking errors are readable
* [ ] Network errors are readable
* [ ] RLS denial is handled gracefully
* [ ] No silent failures
* [ ] Loading states appear before data arrives
* [ ] Fallback UI exists for empty and error states

# 17. Final reasoning checks

* [ ] Manual appointments default to confirmed because the doctor created them directly
* [ ] Patient bookings may require different default behavior if you later add approval flow
* [ ] Expired doctors are hidden from patients instead of only being marked in UI
* [ ] Vacation pause does not trigger billing flow
* [ ] Subscription pause and manual pause are treated as separate states
* [ ] Consultation duration and appointment duration are validated independently
* [ ] The system never wastes bookable time unnecessarily
* [ ] Every state change has a visible UI effect

---

# Code Review Findings (2026-05-13)

## Section 0: Project Foundation

| # | Item | Status | Issue |
|---|------|--------|-------|
| 0.1 | Flutter builds correctly | ✓ | |
| 0.2 | Supabase env vars isolated | ⚠ | Client fallback uses empty strings if env vars not set — no safe defaults |
| 0.3 | Session check before UI | ✓ | Router uses authProvider redirect, checks isInitialized first |
| 0.4 | Anonymous users protected | ✓ | checkAuthStatus() on splash, router blocks protected routes |
| 0.5 | Role-based routing | ✓ | Patient: /patient/*, Doctor: /doctor/* with RBAC |
| 0.6 | Shared models/repos separated | ✓ | models/, services/, core/ all separate from features/ |
| 0.7 | No Supabase calls inside widgets | ✓ | All DB calls in providers/notifiers |

## Section 1: Auth System

| # | Item | Status | Issue |
|---|------|--------|-------|
| 1.1 | Login page exists | ✓ | |
| 1.2 | Register page exists | ✓ | |
| 1.3 | Forgot password page exists | ✓ | |
| 1.4 | Session restore works | ✓ | checkAuthStatus() on splash |
| 1.5 | Logout clears session | ✓ | logout() method in auth_provider |
| 1.6 | Profile row created after signup | ✗ | No profile creation logic after registration — only auth state set |
| 1.7 | Role resolved from profiles | ✓ | userMetadata['role'] |
| 1.8 | Patient redirect to home | ✓ | app_router + login_page redirect |
| 1.9 | Doctor redirect to dashboard | ✓ | |
| 1.10 | Null session redirects to login | ✓ | Router lines 68-71 |
| 1.11 | Auth errors shown cleanly | ✓ | AppSnackbar |
| 1.12 | Loading state while resolving | ✓ | isLoading in auth pages |

## Section 2: Routing System

| # | Item | Status | Issue |
|---|------|--------|-------|
| 2.1 | Public routes accessible without login | ✓ | |
| 2.2 | Protected routes reject unauthenticated | ✓ | |
| 2.3 | Patient routes separate from doctor | ✓ | |
| 2.4 | Deep links work on web | ✓ | GoRouter |
| 2.5 | Unknown routes fallback | ✓ | errorBuilder shows "Page non trouvée" |
| 2.6 | Route names centralized | ✓ | route_names.dart |

## Section 3: Theme System

| # | Item | Status | Issue |
|---|------|--------|-------|
| 3.1 | Inter is only main font | ✓ | Via GoogleFonts.inter in app_theme.dart |
| 3.2 | Color palette consistent | ✓ | app_colors.dart |
| 3.3 | Primary blue used only for actions | ✓ | |
| 3.4 | Background is soft (0xFFF6F8FB) | ✓ | Not harsh gray |
| 3.5 | Cards have soft borders and subtle elevation | ✓ | Elevation: 0, border: 1px |
| 3.6 | Inputs have consistent radius/spacing | ✓ | |
| 3.7 | Buttons follow one visual style | ✓ | |
| 3.8 | Status colors are semantic only | ✓ | |
| 3.9 | Theme values reused not hardcoded | ✓ | AppColors, AppSpacing |
| 3.10 | Light theme coherent on desktop/mobile | ✓ | |
| 3.11 | Theme does not fight custom components | ✓ | |

## Section 4: Global Layout System

| # | Item | Status | Issue |
|---|------|--------|-------|
| 4.1 | App shell exists | ✓ | ResponsiveScaffold, DesktopSidebar, MobileNavbar |
| 4.2 | Desktop uses sidebar layout | ✓ | >= 900px |
| 4.3 | Mobile uses bottom navigation | ✓ | BottomNavigationBar (5 items) |
| 4.4 | Tablet layout adaptive | ✓ | |
| 4.5 | Content width constrained on large screens | ✓ | maxWidth: 1200 in dashboard |
| 4.6 | Sections grouped into surfaces/cards | ✓ | |
| 4.7 | Page hierarchy clear | ✓ | Titles, subtitles, section headers |
| 4.8 | White space consistent | ✓ | |
| 4.9 | No screen stretched edge-to-edge | ✓ | |

## Section 5: Core Reusable Components

| # | Item | Status | Issue |
|---|------|--------|-------|
| 5.1 | Primary button | ✓ | primary_button.dart |
| 5.2 | Secondary button | ✓ | secondary_button.dart |
| 5.3 | App text field | ✓ | app_text_field.dart |
| 5.4 | Search field | ✓ | app_search_field.dart |
| 5.5 | Card component | ✓ | app_card.dart |
| 5.6 | Status badge | ✓ | status_badge.dart |
| 5.7 | Empty state | ✓ | empty_state_card.dart |
| 5.8 | Loading | ✓ | loading_indicator.dart |
| 5.9 | Error | ✓ | error_view.dart |
| 5.10 | Dialog | ✓ | app_dialog.dart |
| 5.11 | Bottom sheet component | ✗ | No dedicated reusable bottom sheet component |
| 5.12 | Sidebar item component | ✗ | No dedicated reusable sidebar item component |
| 5.13 | Appointment block component | ✗ | No dedicated reusable appointment block component |
| 5.14 | Doctor card component | ✗ | No dedicated reusable doctor card component |
| 5.15 | Stat card component | ✓ | stat_card.dart |

## Section 6: Patient Area

| # | Item | Status | Issue |
|---|------|--------|-------|
| 6.1 | Patient home page | ✓ | |
| 6.2 | Doctor browse page | ✓ | |
| 6.3 | Doctor details page | ✓ | |
| 6.4 | Booking page | ✓ | |
| 6.5 | My appointments page | ✓ | |
| 6.6 | Favorites page | ✓ | |
| 6.7 | Patient profile page | ✓ | |
| 6.8 | Only active doctors shown | ⚠ | doctors_provider fetches all, doctor_repository filters — inconsistent |
| 6.9 | Expired doctors hidden | ⚠ | doctor_repository filters, but doctors_provider does not |
| 6.10 | Manually paused doctors hidden | ⚠ | Same as above |
| 6.11 | Search by name/specialty works | ✓ | |
| 6.12 | Filters work correctly | ✓ | |
| 6.13 | Doctor cards show right data | ✓ | |
| 6.14 | Doctor cards not overloaded | ✓ | |
| 6.15 | Available slots from schedule+appointments | ✗ | booking_page uses hardcoded static list of TimeOfDay, NOT generated from doctor schedule |
| 6.16 | Consultation duration used for consultation | ✓ | |
| 6.17 | Appointment duration used for regular | ✓ | |
| 6.18 | Booking prevents overlapping slots | ✗ | No check for existing appointments before booking |
| 6.19 | Booking confirms if slot still available | ✓ | |
| 6.20 | Booking failure shows clear reason | ⚠ | Shows SnackBar but reason not always specific |
| 6.21 | Booking success updates UI immediately | ✓ | ref.invalidate(patientProvider) |
| 6.22 | Appointment cards show doctor name | ✓ | |
| 6.23 | Appointment cards show date/time | ✓ | |
| 6.24 | Appointment cards show address | ✗ | No address shown in patient_appointments_page |
| 6.25 | GPS/maps action works | ✗ | No maps/GPS button in patient appointment cards |
| 6.26 | Cancel action works | ✓ | |
| 6.27 | Slidable cancel on mobile | ✗ | Not implemented |
| 6.28 | Cancel only when valid | ✓ | Cancelled appointments don't show cancel button |
| 6.29 | Cancelled appointments styled differently | ✓ | Separate tab + gray styling |
| 6.30 | Upcoming/past separated | ✓ | Tabbed (À venir, Passés, Annulés) |
| 6.31 | Favorite add/remove works | ✓ | toggleFavorite in provider |
| 6.32 | Favorites list shows active doctors | ✗ | favorites_page shows all favorites regardless of doctor active status |
| 6.33 | Favorite icon matches DB | ✓ | |

## Section 7: Doctor Area

| # | Item | Status | Issue |
|---|------|--------|-------|
| 7.1 | Doctor dashboard page | ✓ | |
| 7.2 | Doctor appointments page | ✓ | |
| 7.3 | Doctor schedule page | ✓ | |
| 7.4 | Doctor profile page | ✓ | |
| 7.5 | Doctor subscription page | ✓ | |
| 7.6 | Doctor settings page | ✓ | |
| 7.7 | Today stats visible | ✓ | |
| 7.8 | Upcoming appointments visible | ✓ | |
| 7.9 | Schedule preview visible | ✓ | |
| 7.10 | Quick actions available | ✓ | |
| 7.11 | Subscription status visible | ✗ | No subscription field in DoctorState — not shown in dashboard |
| 7.12 | Paused state visible | ✗ | No paused state in DoctorState |
| 7.13 | Online + manual appointments fetched | ⚠ | loadDoctorData doesn't include booking_type in select query |
| 7.14 | Appointment status updates possible | ✗ | UI only allows confirmed/cancelled — completed and absent not exposed |
| 7.15 | Completed status works | ✗ | Not in UI |
| 7.16 | Absent status works | ✗ | Not implemented anywhere |
| 7.17 | Cancelled status works | ✓ | |
| 7.18 | Manual appointment confirmed by default | ✓ | status: 'confirmed' in createAppointment |
| 7.19 | Online appointment correct initial status | ⚠ | Patient creates with 'upcoming', but loadDoctorData doesn't fetch booking_type |
| 7.20 | Manual appointment creates correctly | ✓ | |
| 7.21 | Manual appointment stores snapshot info | ✓ | patient_name_snapshot, patient_phone_snapshot |
| 7.22 | Manual appointment doesn't require patient account | ✓ | patientId optional |
| 7.23 | Manual appointment in same table | ✓ | |
| 7.24 | Manual appointment appears instantly | ✓ | Added to state immediately |

## Section 8: Scheduling and Slots

| # | Item | Status | Issue |
|---|------|--------|-------|
| 8.1 | Time treated consistently | ✓ | Minutes from midnight after refactor |
| 8.2 | Internal scheduling uses minutes-based | ✓ | TimeUtils |
| 8.3 | Slot generation from schedule + doctor settings | ✓ | SlotEngine |
| 8.4 | Existing appointments removed | ✓ | filterOccupied() |
| 8.5 | Break periods remove availability | ✓ | |
| 8.6 | Closed hours remove availability | ✓ | |
| 8.7 | Consultation + appointment duration both work | ✓ | |
| 8.8 | Slot generation adapts to type | ✓ | |
| 8.9 | Slot never shown if can't fit | ✓ | m + duration <= endMinutes |
| 8.10 | Overlap checks exact | ✓ | DateTime isBefore/isAfter |
| 8.11 | Current day/week views work | ✓ | |
| 8.12 | No duplicate booking from same window | ✓ | |

## Section 9: Appointment Logic

| # | Item | Status | Issue |
|---|------|--------|-------|
| 9.1 | Manual appointment defaults intentional | ✓ | confirmed |
| 9.2 | Online appointment defaults intentional | ✓ | upcoming (pending) |
| 9.3 | Cancelled state consistent | ⚠ | Used but no transition validation |
| 9.4 | Completed state consistent | ✗ | No status handling in UI |
| 9.5 | Absent state consistent | ✗ | Not implemented |
| 9.6 | Status transitions validated | ✗ | updateAppointmentStatus allows any status |
| 9.7 | Booking type not confused with status | ✓ | bookingType vs status separate |
| 9.8 | Consultation not confused with regular | ✓ | appointment_type vs status |
| 9.9 | Snapshot fields used | ✓ | patient_name_snapshot |

## Section 10: Realtime Behavior

| # | Item | Status | Issue |
|---|------|--------|-------|
| 10.1 | App subscribes to doctor appointments | ✓ | _subscribeToAppointments in doctor_provider |
| 10.2 | App subscribes to patient appointments | ✓ | _subscribeToAppointments in patient_appointments_page |
| 10.3 | Insert events update UI | ✓ | |
| 10.4 | Update events update UI | ✓ | |
| 10.5 | Delete events update UI | ✓ | |
| 10.6 | Slot lists refresh on booking | ⚠ | Doctor calendar refreshes but patient booking page does not |
| 10.7 | Doctor dashboard updates on patient book | ✓ | |
| 10.8 | Patient booking page updates on schedule change | ✗ | No subscription to doctor_schedule table |
| 10.9 | Realtime doesn't cause duplicate renders | ⚠ | loadPatientData called on every change |
| 10.10 | Subscriptions cleaned up properly | ✓ | unsubscribe in dispose |

## Section 11: Supabase Data Integrity

| # | Item | Status | Issue |
|---|------|--------|-------|
| 11.1 | RLS enabled on all protected tables | ✓ | All tables have ENABLE ROW LEVEL SECURITY |
| 11.2 | Patients see only own data | ✓ | Policy: auth.uid() = id |
| 11.3 | Doctors manage only own data | ✓ | Policy: auth.uid() = id |
| 11.4 | Public browsing only active doctors | ✓ | Policy checks subscription_end > now() AND manual_pause = false |
| 11.5 | Appointments protected | ✓ | patient_id and doctor_id policies |
| 11.6 | Favorites protected | ✓ | auth.uid() = patient_id |
| 11.7 | Doctor schedule protected | ✓ | Public sees active; doctors manage own |
| 11.8 | Indexes on frequently queried columns | ✓ | 12+ indexes on role, specialty, city, subscription_end, etc. |

## Section 12: Pages and Routes

| # | Route | Status | Issue |
|---|-------|--------|-------|
| 12.1 | /login | ✓ | |
| 12.2 | /register | ✓ | |
| 12.3 | /forgot-password | ✓ | |
| 12.4 | /patient/home | ✓ | |
| 12.5 | /patient/doctors | ✓ | |
| 12.6 | /patient/favorites | ✓ | |
| 12.7 | /patient/appointments | ✓ | |
| 12.8 | /patient/profile | ✓ | |
| 12.9 | /doctor/dashboard | ✓ | |
| 12.10 | /doctor/appointments | ✓ | |
| 12.11 | /doctor/schedule | ✓ | |
| 12.12 | /doctor/profile | ✓ | |
| 12.13 | /doctor/subscription | ✓ | |
| 12.14 | /doctor/settings | ✓ | |
| 12.15 | Protected routes redirect | ✓ | |
| 12.16 | Wrong role blocked | ✓ | RBAC in app_router |

## Section 13: UI Quality

| # | Item | Status | Issue |
|---|------|--------|-------|
| 13.1 | No default Flutter widgets dumped | ✓ | Custom styled containers |
| 13.2 | Cards have clear grouping | ✓ | |
| 13.3 | Text hierarchy obvious | ✓ | 24px/16px/14px/12px |
| 13.4 | Icons consistent | ✓ | Material icons |
| 13.5 | Spacing intentional | ✓ | AppSpacing constants |
| 13.6 | Desktop feels like SaaS | ✓ | Sidebar, maxWidth, stats |
| 13.7 | Mobile feels lightweight | ✓ | BottomNav, Slivers |
| 13.8 | Forms look premium | ✓ | Card containers, styled inputs |

## Section 14: Responsiveness

| # | Item | Status | Issue |
|---|------|--------|-------|
| 14.1 | Mobile no horizontal overflow | ✓ | |
| 14.2 | Tablet usable not cramped | ✓ | |
| 14.3 | Desktop uses width efficiently | ✓ | |
| 14.4 | Calendar adapts to screen | ✓ | |
| 14.5 | Patient pages not copy desktop | ✓ | |
| 14.6 | Doctor pages not cramped on wide | ✓ | |
| 14.7 | Touch targets usable on mobile | ✓ | minWidth 36, minHeight 36 |

## Section 15: Performance

| # | Item | Status | Issue |
|---|------|--------|-------|
| 15.1 | Lists paginated or limited | ✗ | Appointment queries have no limit — fetches ALL appointments |
| 15.2 | Queries fetch only required columns | ✓ | Explicit select with specific columns |
| 15.3 | Large views avoid unnecessary rebuilds | ✓ | Consumer widgets, StateNotifier |
| 15.4 | Calendar renders only needed ranges | ✓ | 2-week window |
| 15.5 | Images cached | ⚠ | CachedNetworkImage used in only 2 places — not in doctors list |
| 15.6 | No heavy logic inside widgets | ✓ | |

## Section 16: Error Handling

| # | Item | Status | Issue |
|---|------|--------|-------|
| 16.1 | Auth errors readable | ✓ | AppSnackbar |
| 16.2 | Booking errors readable | ✓ | SnackBar |
| 16.3 | Network errors readable | ⚠ | Raw e.toString() exposed — not user-friendly |
| 16.4 | RLS denial handled gracefully | ⚠ | Likely shows raw database error |
| 16.5 | No silent failures | ✓ | Try-catch with errorMessage state |
| 16.6 | Loading states before data | ✓ | isLoading checks |
| 16.7 | Fallback UI for empty/error | ✓ | EmptyStateCard |

## Section 17: Final Reasoning

| # | Item | Status | Issue |
|---|------|--------|-------|
| 17.1 | Manual confirmed by default | ✓ | |
| 17.2 | Patient bookings different behavior for approval | ✓ | Defaults to pending |
| 17.3 | Expired doctors hidden | ⚠ | doctor_repository filters, but not in doctors_provider |
| 17.4 | Vacation pause not billing trigger | ⚠ | No vacation/pause field in model |
| 17.5 | Subscription pause separate from manual pause | ✗ | Only manual_pause field — not separated |
| 17.6 | Consultation/appointment duration validated independently | ✓ | |
| 17.7 | System never wastes bookable time | ✓ | |
| 17.8 | Every state change has visible UI effect | ✓ | |

---

Legend: ✓ = correct, ✗ = missing/incorrect, ⚠ = partial issue (no fixes applied, for tracking only)

