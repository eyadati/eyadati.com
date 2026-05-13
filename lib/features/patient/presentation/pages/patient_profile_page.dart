import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/buttons/icon_button_tile.dart';
import '../../../../core/widgets/buttons/danger_button.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/providers.dart';

class PatientProfilePage extends ConsumerStatefulWidget {
  const PatientProfilePage({super.key});

  @override
  ConsumerState<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends ConsumerState<PatientProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(patientProvider.notifier).loadPatientData());
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(patientProvider.notifier).clearError();
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);
    final localeNotifier = ref.read(localeProvider.notifier);
    final currentLocale = ref.watch(localeProvider);
    final isArabic = currentLocale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: patientState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            patientState.name.isNotEmpty
                                ? patientState.name[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          patientState.name.isNotEmpty ? patientState.name : 'Patient',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patientState.email.isNotEmpty ? patientState.email : '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (patientState.phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            patientState.phone,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  IconButtonTile(
                    title: 'Modifier le profil',
                    icon: Icons.edit_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  IconButtonTile(
                    title: 'Paramètres du compte',
                    icon: Icons.settings_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  IconButtonTile(
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  IconButtonTile(
                    title: isArabic ? 'اللغة' : 'Langue',
                    subtitle: isArabic ? 'Français / العربية' : 'Français / Arabe',
                    icon: Icons.language,
                    onTap: () async {
                      final newLocale = isArabic ? 'fr' : 'ar';
                      await localeNotifier.setLocale(newLocale);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  IconButtonTile(
                    title: 'À propos',
                    icon: Icons.info_outline,
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  DangerButton(
                    label: 'Déconnexion',
                    icon: Icons.logout,
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}