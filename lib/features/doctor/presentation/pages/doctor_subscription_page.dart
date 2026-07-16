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

class _PlanOption {
  final String planType;
  final String name;
  final int monthlyPrice;
  final int totalPrice;
  final int durationMonths;
  final int savings;
  final String? badge;

  const _PlanOption({
    required this.planType,
    required this.name,
    required this.monthlyPrice,
    required this.totalPrice,
    required this.durationMonths,
    required this.savings,
    this.badge,
  });
}

const _planOptions = [
  _PlanOption(
    planType: 'monthly',
    name: '1 mois',
    monthlyPrice: 3500,
    totalPrice: 3500,
    durationMonths: 1,
    savings: 0,
  ),
  _PlanOption(
    planType: 'quarterly',
    name: '3 mois',
    monthlyPrice: 3500,
    totalPrice: 10500,
    durationMonths: 3,
    savings: 0,
  ),
  _PlanOption(
    planType: 'semiannual',
    name: '6 mois',
    monthlyPrice: 2975,
    totalPrice: 17850,
    durationMonths: 6,
    savings: 3150,
    badge: '15% de réduction',
  ),
];

class DoctorSubscriptionPage extends ConsumerStatefulWidget {
  const DoctorSubscriptionPage({super.key});

  @override
  ConsumerState<DoctorSubscriptionPage> createState() => _DoctorSubscriptionPageState();
}

class _DoctorSubscriptionPageState extends ConsumerState<DoctorSubscriptionPage> {
  String _selectedPlan = 'monthly';

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final notifier = ref.read(subscriptionProvider.notifier);

    final selectedConfig = _planOptions.firstWhere((p) => p.planType == _selectedPlan);

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
                  _buildStatusCard(subState),
                  if (subState.subscriptionEnd != null && !subState.isActive)
                    _buildExpiredBanner(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Choisissez votre formule', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: AppSpacing.md),
                  _buildPlanCards(subState),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFeaturesList(),
                  const SizedBox(height: AppSpacing.lg),
                  if (subState.lastPayment != null) ...[
                    Text('Dernier paiement', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.md),
                    _buildLastPayment(subState.lastPayment!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _buildPayButton(subState, selectedConfig),
                  const SizedBox(height: AppSpacing.md),
                  _buildRefreshButton(notifier),
                  if (subState.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildErrorBanner(subState.error!, notifier),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(SubscriptionState state) {
    final isActive = state.isActive;

    Color statusColor;
    String statusText;

    if (state.subscriptionEnd == null) {
      statusColor = AppColors.textSecondary;
      statusText = 'Aucun abonnement';
    } else if (!isActive) {
      statusColor = AppColors.error;
      statusText = 'Expiré';
    } else if (state.remainingDays <= 7) {
      statusColor = AppColors.warning;
      statusText = 'Expire bientôt (${state.remainingDays} j)';
    } else {
      statusColor = AppColors.secondary;
      statusText = 'Actif (${state.remainingDays} jours restants)';
    }

    final planName = state.planType != null
        ? _planOptions.firstWhere((p) => p.planType == state.planType!).name
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? AppColors.warning.withValues(alpha: 0.15) : AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.crown,
              size: 24,
              color: isActive ? AppColors.warning : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName != null ? 'Plan $planName' : 'Aucun abonnement',
                  style: AppTextStyles.bodyMedium,
                ),
                if (state.subscriptionEnd != null)
                  Text(
                    'Expire le ${DateFormat('dd MMMM yyyy', 'fr').format(state.subscriptionEnd!)}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(statusText, style: AppTextStyles.badge.copyWith(color: statusColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.block, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Votre abonnement a expiré',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vous ne pouvez plus recevoir de nouveaux rendez-vous. '
                    'Sélectionnez une formule ci-dessous pour réactiver votre abonnement.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCards(SubscriptionState state) {
    return Column(
      children: _planOptions.map((plan) {
        final isSelected = _selectedPlan == plan.planType;
        final isCurrent = state.planType == plan.planType && state.isActive;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlan = plan.planType),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(plan.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            if (plan.badge != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  plan.badge!,
                                  style: AppTextStyles.badge.copyWith(color: AppColors.warning, fontSize: 10),
                                ),
                              ),
                            ],
                            if (isCurrent) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Actuel',
                                  style: AppTextStyles.badge.copyWith(color: AppColors.secondary, fontSize: 10),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Text(
                              '${plan.totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} DA',
                              style: AppTextStyles.statValue.copyWith(
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '(${plan.monthlyPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} DA/mois)',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        if (plan.durationMonths > 1 && plan.savings > 0) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Économisez ${plan.savings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} DA',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inclus dans toutes les formules', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          _FeatureItem(icon: LucideIcons.check, text: 'Rendez-vous illimités'),
          _FeatureItem(icon: LucideIcons.check, text: 'Calendrier avancé'),
          _FeatureItem(icon: LucideIcons.check, text: 'Notifications patients'),
          _FeatureItem(icon: LucideIcons.check, text: 'Support prioritaire'),
          _FeatureItem(icon: LucideIcons.check, text: 'Rapports détaillés'),
        ],
      ),
    );
  }

  Widget _buildPayButton(SubscriptionState state, _PlanOption plan) {
    final isCreating = state.isCreatingCheckout;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isCreating
            ? null
            : () async {
                final notifier = ref.read(subscriptionProvider.notifier);
                final url = await notifier.createCheckout(planType: plan.planType);
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
          isCreating
              ? 'Création du paiement...'
              : 'Payer ${plan.totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} DA — ${plan.name}',
          style: AppTextStyles.labelLarge,
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRefreshButton(SubscriptionNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => notifier.loadSubscription(),
        icon: const Icon(LucideIcons.refreshCw, size: 18),
        label: Text('Actualiser le statut', style: AppTextStyles.labelMedium),
      ),
    );
  }

  Widget _buildLastPayment(PaymentHistory payment) {
    final planLabel = _planOptions.firstWhere(
      (p) => p.planType == payment.planType,
      orElse: () => const _PlanOption(planType: '', name: '', monthlyPrice: 0, totalPrice: 0, durationMonths: 0, savings: 0),
    );
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
              Expanded(
                child: Text(
                  '${planLabel.name.isNotEmpty ? '${planLabel.name} — ' : ''}${DateFormat('dd MMM yyyy', 'fr').format(payment.periodStart)}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
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

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
