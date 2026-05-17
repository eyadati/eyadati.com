import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/features/doctor/presentation/pages/doctor_calendar_page.dart';
import 'package:eyadati/features/doctor/presentation/pages/doctor_settings_page.dart';
import 'package:eyadati/features/doctor/presentation/providers/doctor_provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class DoctorDashboardPage extends ConsumerStatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  ConsumerState<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends ConsumerState<DoctorDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(doctorState),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildStatsSection(doctorState),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 600,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const DoctorCalendarPage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(DoctorState doctorState) {
    return Container(
      height: 70,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'Eyadati',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorSettingsPage()),
            ),
          ),
          const SizedBox(width: 12),
          _buildAvatarWidget(doctorState.avatarUrl, doctorState.name, 16),
        ],
      ),
    );
  }

  Widget _buildStatsSection(DoctorState doctorState) {
    final now = DateTime.now();
    final onlineCount = doctorState.allAppointments
        .where((a) => a.bookingType == 'online' && a.startTime.isAfter(now))
        .length;

    final nextApt = doctorState.upcomingAppointments.isNotEmpty 
        ? doctorState.upcomingAppointments.first 
        : null;

    String nextAptInfo = 'Aucun';
    if (nextApt != null) {
      final dateStr = '${nextApt.startTime.day}/${nextApt.startTime.month}';
      final timeStr = '${nextApt.startTime.hour}:${nextApt.startTime.minute.toString().padLeft(2, '0')}';
      final type = nextApt.isConsultation ? 'Consultation' : 'RDV';
      nextAptInfo = '$type\n$dateStr à $timeStr';
    }

    return Row(
      children: [
        Expanded(child: _buildStatCard("Cette semaine", '${doctorState.weekAppointmentsCount}', LucideIcons.calendar, AppColors.primary)),
        const SizedBox(width: 24),
        Expanded(child: _buildStatCard("En ligne", '$onlineCount', LucideIcons.video, AppColors.secondary)),
        const SizedBox(width: 24),
        Expanded(child: _buildStatCard("Prochain RDV", nextAptInfo, LucideIcons.user, AppColors.warning)),
      ],
    );
  }
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget(String? avatarUrl, String name, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        _getInitials(name),
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'DR';
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, 1).toUpperCase();
  }
}
