import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/core/widgets/cards/info_card.dart';

class DoctorSubscriptionPage extends ConsumerWidget {
  const DoctorSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Abonnement'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.crown,
                    size: 64,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Plan Pro',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('499 MAD', style: AppTextStyles.statValue.copyWith(color: AppColors.primary)),
                      Text('/mois', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Abonnement actif', style: AppTextStyles.badge.copyWith(color: AppColors.secondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Inclus dans le plan', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            _FeatureItem(
              icon: LucideIcons.circleCheck,
              text: 'Rendez-vous illimités',
              color: AppColors.secondary,
            ),
            _FeatureItem(
              icon: LucideIcons.circleCheck,
              text: 'Calendrier avancé',
              color: AppColors.secondary,
            ),
            _FeatureItem(
              icon: LucideIcons.circleCheck,
              text: 'Notifications patients',
              color: AppColors.secondary,
            ),
            _FeatureItem(
              icon: LucideIcons.circleCheck,
              text: 'Support prioritaire',
              color: AppColors.secondary,
            ),
            _FeatureItem(
              icon: LucideIcons.circleCheck,
              text: 'Rapports détaillés',
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Prochain paiement', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            InfoCard(
              title: 'Date',
              value: '15 Juin 2026',
              icon: LucideIcons.calendar,
              iconColor: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            InfoCard(
              title: 'Montant',
              value: '499 MAD',
              icon: LucideIcons.euro,
              iconColor: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text('Historique', style: AppTextStyles.labelMedium),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Annuler', style: AppTextStyles.labelMedium),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}