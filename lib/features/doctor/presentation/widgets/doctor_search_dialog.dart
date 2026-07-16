import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/core/utils/phone_launcher.dart';
import '../providers/global_patient_search_provider.dart';

class DoctorSearchDialog extends ConsumerStatefulWidget {
  const DoctorSearchDialog({super.key});

  @override
  ConsumerState<DoctorSearchDialog> createState() => _DoctorSearchDialogState();
}

class _DoctorSearchDialogState extends ConsumerState<DoctorSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocus.requestFocus();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(globalPatientSearchProvider);
    final notifier = ref.read(globalPatientSearchProvider.notifier);

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width > 768
            ? MediaQuery.of(context).size.width * 0.5
            : MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchField(notifier),
            if (searchState.isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppColors.border,
              ),
            Expanded(child: _buildContent(searchState, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recherche patient',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: AppColors.textHint, size: 20),
                tooltip: 'Score de fiabilité',
                onPressed: () => _showReliabilityInfo(context),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReliabilityInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 22, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('Score de fiabilité'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le score de fiabilité mesure l\'assiduité du patient à ses rendez-vous (en ligne et en cabinet).',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Le score nécessite au moins 3 rendez-vous pour être calculé.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: AppColors.success),
                SizedBox(width: 6),
                Text(' > 75% : Bonne assiduité', style: TextStyle(fontSize: 13)),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: AppColors.warning),
                SizedBox(width: 6),
                Text(' 50% – 75% : Assiduité moyenne', style: TextStyle(fontSize: 13)),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: AppColors.error),
                SizedBox(width: 6),
                Text(' < 50% : Faible assiduité', style: TextStyle(fontSize: 13)),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Un score inférieur à 50% empêche le patient de réserver en ligne. '
              'Le patient peut contacter le cabinet directement.',
              style: TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(GlobalPatientSearchNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        onChanged: notifier.search,
        onSubmitted: notifier.search,
        decoration: InputDecoration(
          hintText: 'Rechercher par numéro ou nom...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    notifier.search('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(GlobalPatientSearchState state, GlobalPatientSearchNotifier notifier) {
    if (state.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Recherchez un patient',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Saisissez un numéro de téléphone ou un nom',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Erreur de recherche',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => notifier.retry(state.query),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Aucun patient trouvé',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun résultat pour "${state.query}"\nEssayez un autre numéro ou nom',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    final resultCount = state.results.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            '$resultCount résultat${resultCount > 1 ? 's' : ''}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            itemCount: resultCount,
            itemBuilder: (context, index) {
              return _PatientSearchCard(result: state.results[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _PatientSearchCard extends StatelessWidget {
  final PatientSearchResult result;

  const _PatientSearchCard({required this.result});

  Color _getScoreColor() {
    if (!result.hasSufficientHistory) return AppColors.textHint;
    final rate = result.reliabilityRate;
    if (rate == null) return AppColors.textHint;
    if (rate <= 0.25) return AppColors.error;
    if (rate <= 0.50) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final phone = result.phone ?? '';
    final scoreColor = _getScoreColor();
    final isBlocked = result.hasSufficientHistory &&
        result.reliabilityRate != null &&
        result.reliabilityRate! < 0.75;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 86,
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  result.fullName.isNotEmpty ? result.fullName[0].toUpperCase() : '?',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.fullName.isNotEmpty ? result.fullName : 'Patient',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: () => launchPhoneUrl(phone, context),
                        borderRadius: BorderRadius.circular(4),
                        child: Text(
                          '📞 $phone',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (result.totalVisits > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            '${result.totalVisits} RDV',
                            style: AppTextStyles.cardSubtitle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.cancel, size: 14, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            '${result.noShowCount} absent(s)',
                            style: AppTextStyles.cardSubtitle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (result.reliabilityPct != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: result.reliabilityPct! >= 75
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${result.reliabilityPct}% fiabilité',
                              style: AppTextStyles.cardSubtitle.copyWith(
                                color: result.reliabilityPct! >= 75
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (result.hasSufficientHistory)
                _buildBlockedBadge(isBlocked),
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  icon: const Icon(Icons.phone, size: 18, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  onPressed: () => launchPhoneUrl(phone, context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedBadge(bool isBlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isBlocked
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBlocked ? Icons.block : Icons.check_circle,
            size: 12,
            color: isBlocked ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            isBlocked ? 'Bloqué' : '${result.reliabilityPct}%',
            style: AppTextStyles.caption.copyWith(
              color: isBlocked ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
