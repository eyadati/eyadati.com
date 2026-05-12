import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/buttons/icon_button_tile.dart';

class DoctorSettingsPage extends ConsumerWidget {
  const DoctorSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Modifier le profil',
              icon: Icons.person_outline,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Changer le mot de passe',
              icon: Icons.lock_outline,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Notifications push',
              icon: Icons.notifications_outlined,
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.primary,
              ),
              onTap: null,
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Rappels par email',
              icon: Icons.email_outlined,
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.primary,
              ),
              onTap: null,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Langue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Langue',
              subtitle: 'Français',
              icon: Icons.language,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'À propos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButtonTile(
              title: 'Version',
              subtitle: '1.0.0',
              icon: Icons.info_outline,
              onTap: null,
            ),
            IconButtonTile(
              title: 'Conditions d\'utilisation',
              icon: Icons.description_outlined,
              onTap: () {},
            ),
            IconButtonTile(
              title: 'Politique de confidentialité',
              icon: Icons.privacy_tip_outlined,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eyadati',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Plateforme de gestion de cabinet médical',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}