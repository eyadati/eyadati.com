import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/routing/route_names.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/features/doctor/presentation/pages/doctor_calendar_page.dart';
import 'package:eyadati/features/doctor/presentation/providers/doctor_provider.dart';
import 'package:eyadati/features/doctor/presentation/widgets/doctor_notification_sidebar.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DoctorDashboardPage extends ConsumerStatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  ConsumerState<DoctorDashboardPage> createState() =>
      _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends ConsumerState<DoctorDashboardPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isExpanded = true;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final pending = doctorState.allAppointments
        .where((a) => a.status == 'upcoming' && a.bookingType == 'online')
        .toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: DoctorNotificationSidebar(appointments: pending),
      body: Column(
        children: [
          _buildTopBar(doctorState, pending),
          Expanded(
            child: doctorState.errorMessage != null
                ? _buildErrorView(doctorState)
                : Skeletonizer(
                    enabled: doctorState.isLoading,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const DoctorCalendarPage(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(DoctorState doctorState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doctorState.errorMessage ?? '',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(doctorProvider.notifier).clearError();
                ref.read(doctorProvider.notifier).refresh();
              },
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(DoctorState doctorState, List pending) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Eyadati',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(LucideIcons.bell, color: Colors.white),
                    if (pending.isNotEmpty)
                      Positioned(
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(LucideIcons.settings, color: Colors.white),
                onPressed: () => context.push(RouteNames.doctorSettings),
                padding: EdgeInsets.zero,
              ),
              const Spacer(),
              InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 250),
                    turns: _isExpanded ? 0 : 0.5,
                    child: const Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: _buildStatsRow(doctorState),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DoctorState doctorState) {
    final now = DateTime.now();
    final onlineCount = doctorState.allAppointments
        .where((a) => a.bookingType == 'online' && a.startTime.isAfter(now))
        .length;

    final nextAptList = doctorState.upcomingAppointmentsList;
    final nextApt = nextAptList.isNotEmpty ? nextAptList.first : null;

    String nextAptInfo = 'Aucun';
    Color nextAptColor = AppColors.textHint;
    if (nextApt != null) {
      final dateStr = '${nextApt.startTime.day}/${nextApt.startTime.month}';
      final timeStr =
          '${nextApt.startTime.hour.toString().padLeft(2, '0')}:${nextApt.startTime.minute.toString().padLeft(2, '0')}';
      final patientName = nextApt.patientName.isNotEmpty ? nextApt.patientName : 'Patient';
      nextAptInfo = '$patientName — $dateStr $timeStr';
      nextAptColor = AppColors.textPrimary;
    }

    return Row(
      children: [
        Expanded(
          child: _buildCompactStat(
            'Cette semaine',
            '${doctorState.weekAppointmentsCount}',
            LucideIcons.calendar,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCompactStat(
            'En ligne',
            '$onlineCount',
            LucideIcons.video,
            AppColors.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCompactStat(
            'Prochain RDV',
            nextAptInfo,
            LucideIcons.clock,
            nextAptColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
