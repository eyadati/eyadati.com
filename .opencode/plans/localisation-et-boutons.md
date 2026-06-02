# Plan: Translate snackbar, move mobile call icon, add phone icon to patient card & Annuler

## Files to modify
1. `lib/features/doctor/presentation/widgets/appointment_details_sheet.dart`
2. `lib/features/doctor/presentation/pages/doctor_patients_page.dart`

---

## Step 1 — Translate snackbar strings (appointment_details_sheet.dart)

| English | French |
|---|---|
| `'Call logged but notification failed'` (L101) | `'Appel enregistré mais notification échouée'` |
| `'Notification sent to phone'` (L108) | `'Notification envoyée au téléphone'` |
| `'Failed to send notification'` (L118) | `'Échec de l\'envoi de la notification'` |

## Step 2 — Move mobile call icon to trailing in outer Row (appointment_details_sheet.dart)

**Current code (L54-68):**
```dart
if (appointment.patientPhone != null)
  Row(
    children: [
      Text('📞 ${appointment.patientPhone}', style: AppTextStyles.patientId),
      if (AppBreakpoints.isMobile(MediaQuery.of(context).size.width))
        TextButton.icon(
          icon: Icon(Icons.phone, size: 14, color: AppColors.primary),
          label: Text('Call', style: TextStyle(fontSize: 12, color: AppColors.primary)),
          style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          onPressed: () => launchUrl(Uri.parse('tel:${appointment.patientPhone}')),
        )
      else
        TextButton.icon(
          icon: Icon(Icons.phone_forwarded, size: 14, color: AppColors.primary),
          label: Text('Notify phone', ...),
          ...
        ),
    ],
  ),
```

**Change to (L54-68):**
```dart
if (appointment.patientPhone != null)
  Row(
    children: [
      Text('📞 ${appointment.patientPhone}', style: AppTextStyles.patientId),
      if (!AppBreakpoints.isMobile(MediaQuery.of(context).size.width))
        TextButton.icon(
          icon: Icon(Icons.phone_forwarded, size: 14, color: AppColors.primary),
          label: Text('Notify phone', ...),
          ...
        ),
    ],
  ),
```

**Add trailing IconButton in outer Row** — between Expanded Column (L131) and close X IconButton (L132):
```dart
if (AppBreakpoints.isMobile(MediaQuery.of(context).size.width) && appointment.patientPhone != null)
  IconButton(
    icon: Icon(Icons.phone, color: AppColors.primary, size: 24),
    onPressed: () => launchUrl(Uri.parse('tel:${appointment.patientPhone}')),
  ),
```

## Step 3 — Add phone icon to _PatientCard (doctor_patients_page.dart)

**Add import:**
```dart
import 'package:url_launcher/url_launcher.dart';
```

**Current (L119-159):**
```dart
Row(
  children: [
    CircleAvatar,
    SizedBox(width: AppSpacing.md),
    Expanded(Column: [name, phone, visits]),
    Icon(chevronRight),
  ],
)
```

**Change to — add between Expanded and chevronRight:**
```dart
if (patient.patientPhone != null && patient.patientPhone!.isNotEmpty)
  IconButton(
    icon: Icon(Icons.phone, color: AppColors.primary),
    onPressed: () => launchUrl(Uri.parse('tel:${patient.patientPhone}')),
  ),
```

## Step 4 — Add phone icon beside Annuler button (appointment_details_sheet.dart)

**Current (L212-238):**
```dart
if (!isCancelled) ...[
  SizedBox(
    width: double.infinity,
    child: _ActionButton(
      label: 'Annuler',
      icon: LucideIcons.circleX,
      color: AppColors.error,
      onTap: () async { ... },
    ),
  ),
] else ...[
  SizedBox(
    width: double.infinity,
    child: _ActionButton(
      label: 'Supprimer',
      icon: LucideIcons.trash2,
      color: AppColors.error,
      onTap: () async { ... },
    ),
  ),
],
```

**Change to:**
```dart
if (!isCancelled) ...[
  Row(
    children: [
      if (appointment.patientPhone != null)
        IconButton(
          icon: Icon(Icons.phone, color: AppColors.primary, size: 24),
          onPressed: () => launchUrl(Uri.parse('tel:${appointment.patientPhone}')),
        ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: _ActionButton(
          label: 'Annuler',
          icon: LucideIcons.circleX,
          color: AppColors.error,
          onTap: () async { ... },
        ),
      ),
    ],
  ),
] else ...[
  SizedBox(
    width: double.infinity,
    child: _ActionButton(
      label: 'Supprimer',
      icon: LucideIcons.trash2,
      color: AppColors.error,
      onTap: () async { ... },
    ),
  ),
],
```

## Step 5 — Run `flutter analyze` to verify 0 errors
