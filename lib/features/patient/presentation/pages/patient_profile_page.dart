import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/buttons/icon_button_tile.dart';
import '../../../../core/widgets/buttons/danger_button.dart';
import '../providers/providers.dart';

class PatientProfilePage extends ConsumerWidget {
  const PatientProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                  Text(
                    patientState.email.isNotEmpty ? patientState.email : 'email@example.com',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
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
              title: 'Langue',
              subtitle: 'Français',
              icon: Icons.language,
              onTap: () {},
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
              onPressed: () {},
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}