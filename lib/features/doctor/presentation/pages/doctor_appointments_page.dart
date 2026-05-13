import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import '../providers/doctor_provider.dart';
import '../widgets/appointment_details_sheet.dart';

class DoctorAppointmentsPage extends ConsumerWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorState = ref.watch(doctorProvider);
    final all = doctorState.allAppointments;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
              tabs: [
                Tab(text: 'Tous (${all.length})'),
                Tab(text: 'Confirmés (${all.where((a) => a.status == 'confirmed').length})'),
                Tab(text: 'En attente (${all.where((a) => a.status == 'pending').length})'),
                Tab(text: 'Annulés (${all.where((a) => a.status == 'cancelled').length})'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(doctorProvider.notifier).refresh(),
              child: TabBarView(
                children: [
                  _buildList(context, all),
                  _buildList(context, all.where((a) => a.status == 'confirmed').toList()),
                  _buildList(context, all.where((a) => a.status == 'pending').toList()),
                  _buildList(context, all.where((a) => a.status == 'cancelled').toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<AppointmentData> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucun rendez-vous',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final apt = appointments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => AppointmentDetailsSheet(appointment: apt),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: apt.status == 'cancelled'
                      ? AppColors.error.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: apt.status == 'cancelled'
                          ? AppColors.error.withValues(alpha: 0.1)
                          : apt.isConsultation
                              ? AppColors.consultationColor.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      apt.isConsultation ? Icons.video_call_outlined : Icons.person_outline,
                      size: 18,
                      color: apt.status == 'cancelled'
                          ? AppColors.error
                          : apt.isConsultation
                              ? AppColors.consultationColor
                              : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apt.patientName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            decoration: apt.status == 'cancelled'
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${apt.startTime.day}/${apt.startTime.month}/${apt.startTime.year} à ${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(apt.status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    if (status == 'confirmed') {
      color = AppColors.success;
      label = 'Confirmé';
    } else if (status == 'cancelled') {
      color = AppColors.error;
      label = 'Annulé';
    } else {
      color = AppColors.warning;
      label = 'En attente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}