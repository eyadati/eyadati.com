import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../providers/providers.dart';
import '../widgets/upcoming_appointment_card.dart';
import '../widgets/search_filter_dialog.dart';

class PatientHomePage extends ConsumerStatefulWidget {
  const PatientHomePage({super.key});

  @override
  ConsumerState<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends ConsumerState<PatientHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(patientProvider.notifier).loadPatientData();
      ref.read(doctorsProvider.notifier).loadDoctors();
      ref.read(favoritesProvider.notifier).loadFavorites();
    });
  }

  Future<void> _refresh() async {
    await ref.read(patientProvider.notifier).loadPatientData();
    await ref.read(doctorsProvider.notifier).refresh();
    await ref.read(favoritesProvider.notifier).refresh();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => const SearchFilterDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Eyadati',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.push(RouteNames.patientProfile),
            icon: const Icon(
              LucideIcons.settings,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            if (patientState.upcomingAppointments.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vos rendez-vous à venir',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...patientState.upcomingAppointments
                          .take(2)
                          .map(
                            (appointment) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: UpcomingAppointmentCard(
                                appointment: appointment,
                              ),
                            ),
                          ),
                      const SizedBox(height: AppSpacing.sm),
                      if (patientState.upcomingAppointments.length > 2)
                        TextButton(
                          onPressed: () =>
                              context.push(RouteNames.patientAppointments),
                          child: Text(
                            '+ ${patientState.upcomingAppointments.length - 2} autres',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (patientState.upcomingAppointments.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSearchDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        icon: const Icon(LucideIcons.search, size: 22),
        label: const Text(
          'Réserver un médecin',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.calendarPlus,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Aucun rendez-vous',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Appuyez sur le bouton ci-dessous pour\ntrouver un médecin',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
