import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/core/widgets/cards/empty_state_card.dart';
import '../providers/global_patient_search_provider.dart';

class DoctorGlobalSearchPage extends ConsumerStatefulWidget {
  const DoctorGlobalSearchPage({super.key});

  @override
  ConsumerState<DoctorGlobalSearchPage> createState() => _DoctorGlobalSearchPageState();
}

class _DoctorGlobalSearchPageState extends ConsumerState<DoctorGlobalSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(globalPatientSearchProvider);
    final notifier = ref.read(globalPatientSearchProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recherche patient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              keyboardType: TextInputType.phone,
              onChanged: notifier.search,
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
          ),
          Expanded(child: _buildContent(searchState)),
        ],
      ),
    );
  }

  Widget _buildContent(GlobalPatientSearchState state) {
    if (state.query.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.search,
        title: 'Recherchez un patient',
        message: 'Saisissez un numéro de téléphone ou un nom',
      );
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
            ],
          ),
        ),
      );
    }

    if (state.results.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.person_off,
        title: 'Aucun patient trouvé',
        message: 'Essayez un autre numéro ou nom',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(globalPatientSearchProvider.notifier).search(state.query),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 80),
        itemCount: state.results.length,
        itemBuilder: (context, index) => _PatientResultCard(result: state.results[index]),
      ),
    );
  }
}

class _PatientResultCard extends StatelessWidget {
  final PatientSearchResult result;

  const _PatientResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final phone = result.phone ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                          phone,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (result.fullName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            result.fullName,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (phone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('tel:$phone')),
                        child: Text(
                          phone,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
