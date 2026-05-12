# Eyadati — Flutter PWA for Doctor Appointments

## Project Overview
Flutter PWA SaaS for doctors and patients. French first, Arabic RTL supported.

## Architecture

### Language Support
- **Primary**: French (fr)
- **Secondary**: Arabic (ar) with RTL support
- **Localization**: flutter_localizations + intl

---

## Technology Stack

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Backend
  supabase_flutter:

  # State management
  flutter_riverpod:
  riverpod_annotation:

  # Routing
  go_router:

  # UI
  google_fonts:
  lucide_flutter:
  flutter_slidable:
  cached_network_image:
  skeletonizer:
  flutter_animate:

  # Utils
  intl:
  logger:
  shared_preferences:
  connectivity_plus:

dev_dependencies:
  flutter_test:
    sdk: flutter

  build_runner:
  riverpod_generator:
  flutter_lints:
```

---

## File Structure

```text
lib/
├── main.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   ├── app_breakpoints.dart
│   │   ├── app_strings.dart
│   │   └── app_icons.dart
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── text_styles.dart
│   │   └── theme_extensions.dart
│   │
│   ├── routing/
│   │   ├── app_router.dart
│   │   ├── route_names.dart
│   │   ├── route_guards.dart
│   │   └── redirect_logic.dart
│   │
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   ├── date_utils.dart
│   │   ├── responsive_utils.dart
│   │   └── extensions.dart
│   │
│   ├── services/
│   │   ├── supabase_service.dart
│   │   ├── session_service.dart
│   │   └── connectivity_service.dart
│   │
│   ├── errors/
│   │   ├── app_exceptions.dart
│   │   ├── failure.dart
│   │   └── error_handler.dart
│   │
│   └── widgets/
│       ├── buttons/
│       │   ├── primary_button.dart
│       │   ├── secondary_button.dart
│       │   ├── icon_button_tile.dart
│       │   └── danger_button.dart
│       │
│       ├── inputs/
│       │   ├── app_text_field.dart
│       │   ├── app_search_field.dart
│       │   ├── app_dropdown.dart
│       │   └── password_field.dart
│       │
│       ├── cards/
│       │   ├── app_card.dart
│       │   ├── stat_card.dart
│       │   ├── empty_state_card.dart
│       │   └── info_card.dart
│       │
│       ├── feedback/
│       │   ├── loading_indicator.dart
│       │   ├── app_snackbar.dart
│       │   ├── app_dialog.dart
│       │   └── error_view.dart
│       │
│       ├── layout/
│       │   ├── app_shell.dart
│       │   ├── responsive_scaffold.dart
│       │   ├── desktop_sidebar.dart
│       │   ├── mobile_navbar.dart
│       │   ├── top_app_bar.dart
│       │   └── page_container.dart
│       │
│       └── misc/
│           ├── status_badge.dart
│           ├── avatar_view.dart
│           ├── section_title.dart
│           └── dotted_divider.dart
│
├── features/
│   ├── auth/
│   │   ├── pages/
│   │   │   ├── splash_page.dart
│   │   │   ├── login_page.dart
│   │   │   ├── register_page.dart
│   │   │   └── forgot_password_page.dart
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   └── session_provider.dart
│   │   ├── widgets/
│   │   │   ├── auth_header.dart
│   │   │   ├── auth_card.dart
│   │   │   └── auth_footer.dart
│   │   └── controllers/
│   │       └── auth_controller.dart
│   │
│   ├── patient/
│   │   ├── pages/
│   │   │   ├── patient_home_page.dart
│   │   │   ├── doctors_browse_page.dart
│   │   │   ├── doctor_details_page.dart
│   │   │   ├── favorites_page.dart
│   │   │   └── my_appointments_page.dart
│   │   ├── widgets/
│   │   │   ├── doctor_card.dart
│   │   │   ├── specialty_chip.dart
│   │   │   ├── appointment_card.dart
│   │   │   ├── slot_selector.dart
│   │   │   ├── doctor_header.dart
│   │   │   ├── favorite_button.dart
│   │   │   ├── appointment_timeline.dart
│   │   │   └── empty_appointments.dart
│   │   ├── providers/
│   │   │   ├── doctors_provider.dart
│   │   │   ├── favorites_provider.dart
│   │   │   └── appointments_provider.dart
│   │   └── controllers/
│   │       ├── booking_controller.dart
│   │       └── favorites_controller.dart
│   │
│   ├── doctor/
│   │   ├── pages/
│   │   │   ├── doctor_dashboard_page.dart
│   │   │   ├── doctor_schedule_page.dart
│   │   │   ├── doctor_appointments_page.dart
│   │   │   ├── doctor_profile_page.dart
│   │   │   ├── doctor_subscription_page.dart
│   │   │   └── doctor_settings_page.dart
│   │   ├── widgets/
│   │   │   ├── dashboard_stats_row.dart
│   │   │   ├── doctor_calendar.dart      # Custom calendar from scratch
│   │   │   ├── schedule_sidebar.dart
│   │   │   ├── appointment_block.dart
│   │   │   ├── upcoming_appointments.dart
│   │   │   ├── quick_actions_card.dart
│   │   │   ├── doctor_status_banner.dart
│   │   │   ├── earnings_card.dart
│   │   │   ├── availability_editor.dart
│   │   │   └── subscription_banner.dart
│   │   ├── providers/
│   │   │   ├── dashboard_provider.dart
│   │   │   ├── doctor_schedule_provider.dart
│   │   │   └── doctor_appointments_provider.dart
│   │   └── controllers/
│   │       ├── doctor_dashboard_controller.dart
│   │       ├── availability_controller.dart
│   │       └── appointment_status_controller.dart
│   │
│   ├── appointments/
│   │   ├── pages/
│   │   │   ├── appointment_details_page.dart
│   │   │   ├── booking_page.dart
│   │   │   └── reschedule_page.dart
│   │   ├── widgets/
│   │   │   ├── calendar_header.dart
│   │   │   ├── day_selector.dart
│   │   │   ├── time_slot_chip.dart
│   │   │   ├── appointment_status_chip.dart
│   │   │   ├── consultation_toggle.dart
│   │   │   └── appointment_actions_sheet.dart
│   │   ├── providers/
│   │   │   └── booking_provider.dart
│   │   └── controllers/
│   │       └── appointment_controller.dart
│   │
│   ├── profile/
│   │   ├── pages/
│   │   │   ├── edit_profile_page.dart
│   │   │   ├── account_settings_page.dart
│   │   │   └── notification_settings_page.dart
│   │   ├── widgets/
│   │   │   ├── profile_header.dart
│   │   │   ├── profile_avatar.dart
│   │   │   ├── settings_tile.dart
│   │   │   └── profile_form.dart
│   │   ├── providers/
│   │   │   └── profile_provider.dart
│   │   └── controllers/
│   │       └── profile_controller.dart
│   │
│   └── subscription/
│       ├── pages/
│       │   ├── subscription_page.dart
│       │   ├── billing_history_page.dart
│       │   └── payment_success_page.dart
│       ├── widgets/
│       │   ├── pricing_card.dart
│       │   ├── subscription_status_card.dart
│       │   └── payment_method_tile.dart
│       ├── providers/
│       │   └── subscription_provider.dart
│       └── controllers/
│           └── subscription_controller.dart
│
├── models/
│   ├── profile_model.dart
│   ├── doctor_model.dart
│   ├── appointment_model.dart
│   └── favorite_model.dart
│
├── repositories/
│   ├── auth_repository.dart
│   ├── profile_repository.dart
│   ├── doctors_repository.dart
│   ├── appointments_repository.dart
│   └── favorites_repository.dart
│
└── l10n/
    ├── app_fr.arb
    └── app_ar.arb
```

---

## Custom Doctor Calendar Specification

The doctor calendar is **custom built from scratch** for full control.

### Features Required:
1. **Monthly View**
   - Swipeable month navigation
   - Day cells with appointment indicators (dots)
   - Today highlight
   - Selected day highlight

2. **Daily Time Grid**
   - Hourly rows (configurable: 6AM - 10PM default)
   - 15/30/60 minute slot divisions
   - Current time indicator line
   - Scrollable to current time on load

3. **Appointment Blocks**
   - Positioned based on scheduled_at time
   - Height based on duration
   - Color coded by status
   - Clickable for details
   - Draggable for rescheduling (optional)

4. **Interactions**
   - Tap day to show day's appointments
   - Tap block to view/edit appointment
   - Long press empty slot to quick-create
   - Pinch to zoom time scale (optional)

### Data Structure:
```dart
class CalendarConfig {
  final int startHour;      // e.g., 6
  final int endHour;        // e.g., 22
  final int slotMinutes;    // e.g., 15
  final bool showPastHours; // false by default
}
```

### Events:
```dart
class CalendarEvent {
  final String id;
  final DateTime start;
  final DateTime end;
  final AppointmentStatus status;
  final String patientName;
  final bool isConsultation;
}
```

---

## Route Structure

```text
/                           → Splash (auto-redirect)
/login                      → Auth login
/register                  → Auth register
/forgot-password            → Forgot password

/patient/home              → Patient home
/patient/doctors           → Browse doctors
/patient/doctors/:id       → Doctor details
/patient/doctors/:id/book  → Book appointment
/patient/appointments     → My appointments
/patient/favorites         → Favorite doctors
/patient/profile           → Patient profile

/doctor/dashboard           → Doctor dashboard
/doctor/schedule           → Doctor calendar/schedule
/doctor/appointments       → Doctor appointments list
/doctor/profile            → Doctor profile
/doctor/subscription       → Subscription management
/doctor/settings           → App settings
```

---

## Localization

### Supported Locales
- `fr` - French (primary)
- `ar` - Arabic (RTL)

### String Keys Convention
```
auth_login_title
auth_login_subtitle
auth_email_label
auth_password_label
common_loading
common_error
common_retry
...
```

---

## Assets

```
assets/
├── favicon.png
├── logo.png
└── (generated during build)
```

---

## Implementation Order

1. **Theme + Constants** - Healthcare theme, spacing, colors
2. **Core Widgets** - Buttons, inputs, cards, layout
3. **Routing + Navigation** - go_router setup, shells
4. **Auth UI** - Login, register, splash
5. **Patient Flow** - Browse, details, booking
6. **Doctor Dashboard** - Custom calendar, stats
7. **Appointments UI** - Booking flow, details
8. **Profile/Settings** - User management
9. **Subscription Pages** - Billing UI
10. **Polish** - Responsive, animations, RTL

---

## Design Rules

### Colors
- Primary Blue (#1565C0) - Trust, important actions
- Secondary Green (#388E3C) - Health, success statuses
- Background: Light gray (#EEEEEE)
- Cards: White (#FAFAFA)
- Borders: Subtle (#E0E0E0)

### Typography
- Font: Inter only
- Weights: 400, 500, 600
- Avoid oversized icons (18-22px)

### Icons
- Use Lucide Flutter consistently
- Sizes: 18, 20, 22px

### Spacing
- 8pt grid system
- Cards: 16px horizontal margin, 8px vertical
- Buttons: 16px padding

---

## Most Important Rule

Do NOT style screens individually.

Everything comes from:
- Theme
- Reusable widgets
- Spacing system
- Typography system

This creates the premium SaaS feel.
