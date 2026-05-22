import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/core/widgets/feedback/loading_indicator.dart';
import 'package:eyadati/features/doctor/presentation/providers/subscription_provider.dart';
import 'package:eyadati/models/payment_history.dart';
import 'package:intl/intl.dart';

class DoctorSubscriptionPage extends ConsumerWidget {
  const DoctorSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);
    final notifier = ref.read(subscriptionProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Abonnement'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => notifier.loadSubscription(),
          ),
        ],
      ),
      body: subState.isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubscriptionCard(subState),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPricingInfo(),
                  const SizedBox(height: AppSpacing.lg),
                  if (subState.lastPayment != null) ...[
                    Text('Dernier paiement', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.md),
                    _buildLastPayment(subState.lastPayment!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _buildActionButtons(context, ref, subState),
                  if (subState.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildErrorBanner(subState.error!, notifier),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSubscriptionCard(SubscriptionState state) {
    final isActive = state.isActive;
    final remainingDays = state.remainingDays;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (state.subscriptionEnd == null) {
      statusColor = AppColors.textSecondary;
      statusText = 'Aucun abonnement';
      statusIcon = LucideIcons.circleAlert;
    } else if (!isActive) {
      statusColor = AppColors.error;
      statusText = 'Expiré';
      statusIcon = LucideIcons.circleX;
    } else if (remainingDays <= 7) {
      statusColor = AppColors.warning;
      statusText = 'Expire bientôt ($remainingDays j)';
      statusIcon = LucideIcons.clock;
    } else {
      statusColor = AppColors.secondary;
      statusText = 'Actif ($remainingDays jours restants)';
      statusIcon = LucideIcons.circleCheck;
    }

    return Container(
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
            color: isActive ? AppColors.warning : AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Plan Pro', style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '6 000 DZD',
                style: AppTextStyles.statValue.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text('/mois', style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: AppSpacing.xs),
                Text(statusText, style: AppTextStyles.badge.copyWith(color: statusColor)),
              ],
            ),
          ),
          if (state.subscriptionEnd != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Expire le ${DateFormat('dd MMMM yyyy', 'fr').format(state.subscriptionEnd!)}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildLastPayment(PaymentHistory payment) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.receipt, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Paiement du ${DateFormat('dd MMM yyyy', 'fr').format(payment.periodStart)}',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${payment.amount} DZD',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                'Au ${DateFormat('dd MMM yyyy', 'fr').format(payment.periodEnd)}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, SubscriptionState state) {
    final isCreating = state.isCreatingCheckout;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isCreating
                ? null
                : () async {
                    final url = await ref.read(subscriptionProvider.notifier).createCheckout();
                    if (url != null && context.mounted) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
            icon: isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.creditCard, size: 20),
            label: Text(
              isCreating ? 'Création du paiement...' : 'Payer maintenant — 6 000 DZD',
              style: AppTextStyles.labelLarge,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(subscriptionProvider.notifier).loadSubscription();
            },
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: Text('Actualiser le statut', style: AppTextStyles.labelMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error, SubscriptionNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, size: 20, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(error, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 16, color: AppColors.error),
            onPressed: () => notifier.clearError(),
          ),
        ],
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
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
