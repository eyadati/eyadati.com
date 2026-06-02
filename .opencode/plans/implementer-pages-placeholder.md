# Plan: Implement 3 placeholder pages

## Files to modify

### 1. `lib/repositories/auth_repository.dart`
Add `changePassword` method after `resetPassword` (before `_mapAuthError`):

```dart
Future<AuthResult> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  final passwordError = InputValidator.validatePassword(newPassword);
  if (passwordError != null) {
    return AuthResult.failure(passwordError);
  }

  try {
    final user = _client.auth.currentUser;
    if (user == null || user.email == null) {
      return AuthResult.failure('Not authenticated');
    }

    // Re-authenticate to get a fresh session
    final reauth = await _client.auth.signInWithPassword(
      email: user.email!,
      password: currentPassword,
    );
    if (reauth.user == null) {
      return AuthResult.failure('Current password is incorrect');
    }

    await _client.auth.updateUser(UserAttributes(password: newPassword));
    return AuthResult.success(null);
  } on AuthException catch (e) {
    return AuthResult.failure(_mapAuthError(e.message));
  } catch (e) {
    return AuthResult.failure('Connection error. Please try again.');
  }
}
```

### 2. `lib/features/doctor/presentation/pages/doctor_privacy_page.dart`
Replace with full scrollable French privacy policy (RGPD-compliant):
- Static text covering: data controller, data collected, purpose, legal basis, retention, sharing, cookies, user rights (access, rectification, erasure, portability, objection), security, contact
- Uses `AppColors`/`AppTextStyles` for consistent styling
- Same `Scaffold`/`AppBar` pattern with arrow back

### 3. `lib/features/doctor/presentation/pages/doctor_terms_page.dart`
Replace with full scrollable French terms of use:
- Static text covering: service description, doctor registration, appointment management, patient obligations, liability limitation, intellectual property, account suspension, modifications, governing law
- Same styling as privacy page

### 4. `lib/features/doctor/presentation/pages/doctor_change_password_page.dart`
Replace with real password change form:
- Convert to `ConsumerStatefulWidget`
- Import `authRepositoryProvider` from auth_provider
- Three `TextFormField`s: current password, new password, confirm new password (all `obscureText: true`)
- Client-side validation:
  - Current password: not empty
  - New password: ≥ 6 characters
  - Confirm: matches new password
- Submit button with `CircularProgressIndicator` while loading
- On success: SnackBar "Mot de passe changé avec succès" → `Navigator.pop`
- On failure: SnackBar with error message

## After editing
```bash
flutter analyze
git add -A && git commit -m "feat: implement privacy, terms, and change password pages"
export CLOUDFLARE_API_TOKEN=$(grep CLOUDFLARE_TOKEN .env | head -1 | cut -d= -f2-)
wrangler deploy
```
