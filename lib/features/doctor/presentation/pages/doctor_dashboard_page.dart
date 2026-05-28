import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/features/doctor/presentation/pages/doctor_calendar_page.dart';
import 'package:eyadati/features/doctor/presentation/providers/doctor_provider.dart';
import 'package:eyadati/features/doctor/presentation/widgets/doctor_notification_sidebar.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DoctorDashboardPage extends ConsumerStatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  ConsumerState<DoctorDashboardPage> createState() =>
      _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends ConsumerState<DoctorDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      body: doctorState.errorMessage != null
          ? _buildErrorView(doctorState)
          : Skeletonizer(
              enabled: doctorState.isLoading,
              child: DoctorCalendarPage(
                onBellPressed: () =>
                    _scaffoldKey.currentState?.openEndDrawer(),
              ),
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
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: AppColors.error,
            ),
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
}
