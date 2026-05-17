import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/core/providers/locale_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/doctor_provider.dart';
import 'doctor_change_password_page.dart';
import 'doctor_edit_profile_page.dart';
import 'doctor_privacy_page.dart';
import 'doctor_schedule_page.dart';
import 'doctor_subscription_page.dart';
import 'doctor_terms_page.dart';

class DoctorSettingsPage extends ConsumerStatefulWidget {
  const DoctorSettingsPage({super.key});

  @override
  ConsumerState<DoctorSettingsPage> createState() => _DoctorSettingsPageState();
}

class _DoctorSettingsPageState extends ConsumerState<DoctorSettingsPage> {
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
              title: Text('Français', style: AppTextStyles.bodyMedium),
              trailing: !isArabic
                  ? Icon(LucideIcons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('fr');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('العربية', style: AppTextStyles.bodyMedium),
              trailing: isArabic
                  ? Icon(LucideIcons.check, color: AppColors.primary)
                  : null,
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
        title: const Text('Deconnexion'),
        content: const Text('Voulez-vous vraiment vous deconnecter ?'),
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
            child: Text(
              'Deconnexion',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(doctorState),
          const SizedBox(height: AppSpacing.xl),
          _buildSectionTitle('Compte'),
          const SizedBox(height: AppSpacing.sm),
          _buildMenuItem(
            icon: LucideIcons.pencil,
            title: 'Modifier le profil',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorEditProfilePage(),
              ),
            ),
          ),
          _buildMenuItem(
            icon: LucideIcons.clock,
            title: 'Horaires de travail',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorSchedulePage(),
              ),
            ),
          ),
          _buildMenuItem(
            icon: LucideIcons.creditCard,
            title: 'Abonnement',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorSubscriptionPage(),
              ),
            ),
          ),
          _buildMenuItem(
            icon: LucideIcons.lock,
            title: 'Changer le mot de passe',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorChangePasswordPage(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('Langue'),
          const SizedBox(height: AppSpacing.sm),
          _buildMenuItem(
            icon: LucideIcons.languages,
            title: 'Langue',
            trailing: isArabic ? 'العربية' : 'Français',
            onTap: _showLanguageSheet,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('À propos'),
          const SizedBox(height: AppSpacing.sm),
          _buildMenuItem(
            icon: LucideIcons.fileText,
            title: "Conditions d'utilisation",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorTermsPage(),
              ),
            ),
          ),
          _buildMenuItem(
            icon: LucideIcons.shield,
            title: 'Politique de confidentialité',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorPrivacyPage(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildVersionCard(),
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

  Widget _buildProfileHeader(DoctorState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildAvatar(state.avatarUrl, state.name),
          const SizedBox(height: AppSpacing.md),
          Text(
            state.name.isNotEmpty ? state.name : 'Docteur',
            style: AppTextStyles.headlineMedium,
          ),
          if (state.specialty.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              state.specialty,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (state.city.isNotEmpty)
            _buildInfoChip(LucideIcons.mapPin, state.city),
          if (state.phone.isNotEmpty)
            _buildInfoChip(LucideIcons.phone, state.phone),
          if (state.scheduleSlots.isNotEmpty)
            _buildInfoChip(LucideIcons.clock, _buildScheduleSummary(state)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDurationChip('RDV: ${state.appointmentDuration}min', LucideIcons.timer),
              const SizedBox(width: 8),
              _buildDurationChip('Consult: ${state.consultationDuration}min', LucideIcons.stethoscope),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: AppColors.background,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            placeholder: (context, url) => CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary,
              child: Text(
                _getInitials(name),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            errorWidget: (context, url, error) => CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary,
              child: Text(
                _getInitials(name),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.primary,
      child: Text(
        _getInitials(name),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty || name.length <= 2) return 'DR';
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  String _buildScheduleSummary(DoctorState state) {
    if (state.scheduleSlots.isEmpty) return 'Non configuré';
    final dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final activeSlots = state.scheduleSlots.where((s) => s.isActive).toList();
    if (activeSlots.isEmpty) return 'Non configuré';
    final workingDays = activeSlots.map((s) => dayNames[s.dayOfWeek]).toList();
    return workingDays.join(', ');
  }

  Widget _buildVersionCard() {
    return Container(
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
              Text(
                'Version 1.0.0',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
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
                if (trailing != null)
                  Text(
                    trailing,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  )
                else
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppColors.textHint,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
