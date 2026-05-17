EYADATI_AUTH_AND_ONBOARDING_ARCHITECTURE_CHECKLIST

==================================================
GLOBAL RULES
==================================================

[ ] Supabase is the only source of truth
[ ] Never use fake fallback profile data
[ ] Never silently ignore save failures
[ ] Never store duplicated user state
[ ] UI must distinguish:
    - loading
    - success
    - empty
    - error

[ ] UI must refresh after every mutation
[ ] All profile updates must refetch fresh backend data
[ ] All auth redirects must depend on real session state
[ ] All role checks must depend on profiles.role
[ ] All uploads must save final public URL into database

==================================================
AUTH MODULE
==================================================

--------------------------------------------------
AUTH SESSION
--------------------------------------------------

[ ] App checks Supabase session on startup
[ ] Null session redirects to login
[ ] Existing session restores correctly
[ ] Logout clears:
    - providers
    - local state
    - navigation stack

[ ] Refreshing browser keeps session alive
[ ] Expired session redirects safely
[ ] Protected routes cannot open without auth

--------------------------------------------------
LOGIN
--------------------------------------------------

[ ] Email login works
[ ] Password validation works
[ ] Invalid credentials show proper error
[ ] Loading state blocks duplicate submits
[ ] Login success fetches fresh profile
[ ] Login success resolves role correctly
[ ] Patient redirects to patient home
[ ] Doctor redirects to doctor dashboard

--------------------------------------------------
REGISTER
--------------------------------------------------

[ ] Register creates auth.users entry
[ ] Register creates matching profiles row
[ ] profiles.id == auth.users.id
[ ] Role is explicitly selected
[ ] Duplicate registration prevented
[ ] Failed registration shows error
[ ] Registration never leaves partial state silently

==================================================
PROFILES TABLE
==================================================

--------------------------------------------------
PROFILES STRUCTURE
--------------------------------------------------

[ ] profiles.id exists
[ ] profiles.role exists
[ ] profiles.full_name exists
[ ] profiles.email handled safely
[ ] profiles.phone handled safely
[ ] profiles.city handled safely
[ ] profiles.avatar_url handled safely

--------------------------------------------------
PROFILE DATA RULES
--------------------------------------------------

[ ] No profile field uses fake default values
[ ] Nullable fields handled intentionally
[ ] Missing required fields block onboarding
[ ] Updates persist after refresh
[ ] UI always displays backend values

==================================================
PATIENT ONBOARDING
==================================================

--------------------------------------------------
PATIENT FLOW
--------------------------------------------------

[ ] Patient onboarding screen exists
[ ] Required fields validated
[ ] Full name required
[ ] Phone validated
[ ] City optional/validated correctly
[ ] Avatar upload optional
[ ] Medical fields optional
[ ] Save button disabled during loading
[ ] Successful onboarding redirects correctly

--------------------------------------------------
PATIENT DATABASE
--------------------------------------------------

[ ] Patient data saved correctly
[ ] Refresh restores patient data
[ ] Profile edit updates backend correctly
[ ] Profile edit triggers refetch
[ ] No stale UI after update

==================================================
DOCTOR ONBOARDING
==================================================

--------------------------------------------------
DOCTOR FLOW
--------------------------------------------------

[ ] Doctor onboarding screen exists
[ ] Specialty required
[ ] Address required
[ ] City handled safely
[ ] Maps link optional
[ ] Bio optional
[ ] Doctor photo upload works
[ ] Working days selection works
[ ] Opening time selection works
[ ] Closing time selection works
[ ] Appointment duration selection works
[ ] Consultation duration selection works
[ ] Break start selection works
[ ] Break end selection works
[ ] Subscription fields initialized correctly
[ ] Doctor redirected after completion

--------------------------------------------------
DOCTOR TIME RULES
--------------------------------------------------

[ ] All time values use consistent format
[ ] Integer minute system used consistently
[ ] Opening time < closing time
[ ] Break start < break end
[ ] Break inside working hours
[ ] Appointment duration valid
[ ] Consultation duration valid
[ ] Durations use allowed increments only

--------------------------------------------------
DOCTOR DATABASE
--------------------------------------------------

[ ] doctors row created correctly
[ ] doctor_schedule rows created correctly
[ ] Working days persist correctly
[ ] Break values persist correctly
[ ] Refresh restores doctor data
[ ] Doctor edits persist after refresh

==================================================
PROFILE EDITING
==================================================

--------------------------------------------------
PATIENT EDITING
--------------------------------------------------

[ ] Patient can edit:
    - full name
    - phone
    - city
    - avatar

[ ] Save updates backend
[ ] Save shows loading
[ ] Save shows success
[ ] Save handles failure
[ ] Fresh data refetched after save

--------------------------------------------------
DOCTOR EDITING
--------------------------------------------------

[ ] Doctor can edit:
    - specialty
    - address
    - city
    - maps link
    - bio
    - working days
    - opening time
    - closing time
    - appointment duration
    - consultation duration
    - break start
    - break end
    - photo

[ ] Save updates backend
[ ] Save shows loading
[ ] Save shows success
[ ] Save handles failure
[ ] Fresh data refetched after save

==================================================
SUPABASE STORAGE
==================================================

--------------------------------------------------
STORAGE BUCKETS
--------------------------------------------------

[ ] Avatar bucket exists
[ ] Doctor photo bucket exists
[ ] Upload permissions configured
[ ] RLS/storage policies configured

--------------------------------------------------
UPLOAD RULES
--------------------------------------------------

[ ] File type validation exists
[ ] File size validation exists
[ ] Broken uploads handled safely
[ ] Upload loading state shown
[ ] Uploaded URL saved into database
[ ] Old image replacement handled safely
[ ] Placeholder UI used only for rendering

==================================================
RLS AND SECURITY
==================================================

--------------------------------------------------
DATABASE SECURITY
--------------------------------------------------

[ ] RLS enabled on profiles
[ ] RLS enabled on doctors
[ ] RLS enabled on patients
[ ] RLS enabled on appointments
[ ] RLS enabled on doctor_schedule
[ ] RLS enabled on favorites

--------------------------------------------------
ACCESS RULES
--------------------------------------------------

[ ] Users read only own profile
[ ] Doctors edit only own doctor data
[ ] Patients edit only own patient data
[ ] Unauthorized access blocked
[ ] Public access restricted correctly

==================================================
STATE MANAGEMENT
==================================================

--------------------------------------------------
PROVIDER RULES
--------------------------------------------------

[ ] Providers do not contain fake fallback data
[ ] Providers do not duplicate backend truth
[ ] Providers invalidate after mutations
[ ] Realtime updates trigger refetch
[ ] Loading states explicit
[ ] Error states explicit

--------------------------------------------------
REPOSITORY RULES
--------------------------------------------------

[ ] Auth repository isolated
[ ] Profile repository isolated
[ ] Doctor repository isolated
[ ] Patient repository isolated
[ ] Storage repository isolated
[ ] UI never calls Supabase directly

==================================================
ONBOARDING UI
==================================================

--------------------------------------------------
DESIGN RULES
--------------------------------------------------

[ ] Shared input components used
[ ] Shared button components used
[ ] Shared spacing system used
[ ] Shared typography system used
[ ] Shared validation style used
[ ] Responsive layout works on:
    - mobile
    - tablet
    - desktop

--------------------------------------------------
UX RULES
--------------------------------------------------

[ ] Required fields visually clear
[ ] Optional fields visually clear
[ ] Errors visible immediately
[ ] Loading state obvious
[ ] Navigation between steps smooth
[ ] No dead-end screens
[ ] No confusing role mixing

==================================================
FINAL ACCEPTANCE TEST
==================================================

--------------------------------------------------
PATIENT FLOW TEST
--------------------------------------------------

[ ] Patient registers successfully
[ ] Patient onboarding completes
[ ] Patient data persists after refresh
[ ] Patient edits profile successfully
[ ] Patient upload works
[ ] Patient login restores data correctly

--------------------------------------------------
DOCTOR FLOW TEST
--------------------------------------------------

[ ] Doctor registers successfully
[ ] Doctor onboarding completes
[ ] Doctor working hours save correctly
[ ] Doctor break times save correctly
[ ] Doctor durations save correctly
[ ] Doctor photo upload works
[ ] Doctor edits persist after refresh
[ ] Doctor login restores data correctly

--------------------------------------------------
SYSTEM RELIABILITY TEST
--------------------------------------------------

[ ] No stale profile data exists
[ ] No fake fallback values mask errors
[ ] All routes protected correctly
[ ] All uploads persist correctly
[ ] All refreshes restore real backend state
[ ] UI and backend stay synchronized