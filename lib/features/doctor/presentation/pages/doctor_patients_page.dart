import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/widgets/cards/stat_card.dart';
import 'package:eyadati/core/widgets/cards/empty_state_card.dart';
import '../providers/doctor_provider.dart';

class DoctorPatientsPage extends ConsumerStatefulWidget {
  const DoctorPatientsPage({super.key});

  @override
  ConsumerState<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends ConsumerState<DoctorPatientsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(doctorProvider.notifier).loadPatients());
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(doctorProvider.notifier).loadPatients(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Patients',
                        value: '${doctorState.totalPatients}',
                        icon: LucideIcons.users,
                        iconColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        title: 'Visites totales',
                        value: '${doctorState.allAppointments.length}',
                        icon: LucideIcons.history,
                        iconColor: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (doctorState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (doctorState.patients.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: EmptyStateCard(
                    icon: LucideIcons.users,
                    title: 'Aucun patient',
                    message: 'Vos patients apparaîtront ici',
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final patient = doctorState.patients[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: _PatientCard(patient: patient),
                    );
                  },
                  childCount: doctorState.patients.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientVisitData patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              patient.patientName.isNotEmpty ? patient.patientName[0].toUpperCase() : 'P',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (patient.patientPhone != null && patient.patientPhone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    patient.patientPhone!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${patient.totalVisits} visite${patient.totalVisits > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (patient.lastVisit != null) ...[
                      const SizedBox(width: 8),
                      Icon(LucideIcons.clock, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(patient.lastVisit!),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }
}