import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/core/providers/locale_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DoctorSettingsPage extends ConsumerStatefulWidget {
  const DoctorSettingsPage({super.key});

  @override
  ConsumerState<DoctorSettingsPage> createState() => _DoctorSettingsPageState();
}

class _DoctorSettingsPageState extends ConsumerState<DoctorSettingsPage> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('push_notifications') ?? true;
      _emailEnabled = prefs.getBool('email_reminders') ?? true;
    });
  }

  Future<void> _savePushSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', value);
    setState(() => _pushEnabled = value);
  }

  Future<void> _saveEmailSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_reminders', value);
    setState(() => _emailEnabled = value);
  }

  void _showLanguageSheet() {
    final locale = ref.read(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Langue', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Text('🇫🇷', style: TextStyle(fontSize: 24)),
              title: Text('Français', style: AppTextStyles.bodyMedium),
              trailing: !isArabic ? Icon(LucideIcons.check, color: AppColors.primary) : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('fr');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Text('🇩🇿', style: TextStyle(fontSize: 24)),
              title: Text('العربية', style: AppTextStyles.bodyMedium),
              trailing: isArabic ? Icon(LucideIcons.check, color: AppColors.primary) : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('ar');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
            },
            child: Text('Déconnexion', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Compte'),
          const SizedBox(height: AppSpacing.sm),
          _buildMenuItem(
            context: context,
            ref: ref,
            icon: LucideIcons.user,
            title: 'Modifier le profil',
            onTap: () {},
          ),
          _buildMenuItem(
            context: context,
            ref: ref,
            icon: LucideIcons.lock,
            title: 'Changer le mot de passe',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('Notifications'),
          const SizedBox(height: AppSpacing.sm),
          _buildToggleItem(
            icon: LucideIcons.bell,
            title: 'Notifications push',
            value: _pushEnabled,
            onChanged: _savePushSetting,
          ),
          _buildToggleItem(
            icon: LucideIcons.mail,
            title: 'Rappels par email',
            value: _emailEnabled,
            onChanged: _saveEmailSetting,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('Langue'),
          const SizedBox(height: AppSpacing.sm),
          _buildMenuItem(
            context: context,
            ref: ref,
            icon: LucideIcons.languages,
            title: 'Langue',
            trailing: isArabic ? 'العربية' : 'Français',
            onTap: _showLanguageSheet,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('À propos'),
          const SizedBox(height: AppSpacing.sm),
          _buildMenuItem(
            context: context,
            ref: ref,
            icon: LucideIcons.fileText,
            title: "Conditions d'utilisation",
            onTap: () {},
          ),
          _buildMenuItem(
            context: context,
            ref: ref,
            icon: LucideIcons.shield,
            title: 'Politique de confidentialité',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.stethoscope,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eyadati', style: AppTextStyles.labelLarge),
                    Text('Version 1.0.0', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w300)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: Icon(LucideIcons.logOut, size: 18),
              label: const Text('Déconnexion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary));
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
              if (trailing != null) Text(trailing, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w300))
              else Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.primary;
                return AppColors.textHint;
              }),
            ),
          ],
        ),
      ),
    );
  }
}