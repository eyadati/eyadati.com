import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/models/appointment_data.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../providers/doctor_provider.dart';
import 'doctor_calendar_page.dart';
import 'doctor_settings_page.dart';
import 'doctor_patients_page.dart';
import '../widgets/doctor_add_appointment_dialog.dart';
import '../widgets/appointment_details_sheet.dart';

enum DoctorPage { dashboard, calendar, settings, patients }

class DoctorDashboardPage extends ConsumerStatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  ConsumerState<DoctorDashboardPage> createState() =>
      _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends ConsumerState<DoctorDashboardPage> {
  DoctorPage _currentPage = DoctorPage.dashboard;

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isWideScreen ? null : _buildDrawer(doctorState),
      body: Row(
        children: [
          if (isWideScreen) _buildSidebar(doctorState),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _buildCurrentPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DoctorState doctorState, bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (!isWideScreen)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                color: AppColors.textSecondary,
              ),
            ),
          if (!isWideScreen) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _getPageTitle(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${doctorState.todayAppointments}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case DoctorPage.dashboard:
        return 'Tableau de bord';
      case DoctorPage.calendar:
        return 'Calendrier';
      case DoctorPage.settings:
        return 'Paramètres';
      case DoctorPage.patients:
        return 'Mes patients';
    }
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case DoctorPage.dashboard:
        return _buildDashboardContent();
      case DoctorPage.calendar:
        return const DoctorCalendarPage();
      case DoctorPage.settings:
        return const DoctorSettingsPage();
      case DoctorPage.patients:
        return const DoctorPatientsPage();
    }
  }

  Widget _buildDashboardContent() {
    final doctorState = ref.watch(doctorProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(doctorProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctorState.isLoading)
              _buildLoadingSkeletons()
            else ...[
              _buildStatsSection(doctorState),
              const SizedBox(height: AppSpacing.xl),
              _buildQuickActionsSection(),
              const SizedBox(height: AppSpacing.xl),
              _buildUpcomingSection(doctorState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeletons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLoadingCard(height: 100)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildLoadingCard(height: 100)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildLoadingCard(height: 100)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildLoadingCard(height: 100)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildLoadingCard(height: 160),
        const SizedBox(height: AppSpacing.xl),
        _buildLoadingCard(height: 200),
      ],
    );
  }

  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(DoctorState doctorState) {
    final now = DateTime.now();
    final onlineCount = doctorState.upcomingAppointments
        .where((a) => a.bookingType == 'online' && a.startTime.isAfter(now))
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Aujourd'hui",
                      '${doctorState.todayAppointments}',
                      Icons.today_outlined,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatCard(
                      "Cette semaine",
                      '${doctorState.weekAppointments}',
                      Icons.date_range_outlined,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'En ligne',
                      '$onlineCount',
                      Icons.videocam_outlined,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatCard(
                      'En attente',
                      '${doctorState.upcomingAppointments.where((a) => a.status == 'pending').length}',
                      Icons.pending_outlined,
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Aujourd'hui",
                '${doctorState.todayAppointments}',
                Icons.today_outlined,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                "Cette semaine",
                '${doctorState.weekAppointments}',
                Icons.date_range_outlined,
                AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                'En ligne',
                '$onlineCount',
                Icons.videocam_outlined,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                'En attente',
                '${doctorState.upcomingAppointments.where((a) => a.status == 'pending').length}',
                Icons.pending_outlined,
                AppColors.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _buildActionCard(
                  'Nouveau rendez-vous',
                  Icons.add_circle_outline,
                  () {
                    final now = DateTime.now();
                    showDialog(
                      context: context,
                      builder: (ctx) =>
                          DoctorAddAppointmentDialog(initialDate: now),
                    );
                  },
                ),
                _buildActionCard(
                  'Calendrier',
                  Icons.calendar_month_outlined,
                  () => _navigateTo(DoctorPage.calendar),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(DoctorState doctorState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rendez-vous à venir',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateTo(DoctorPage.calendar),
                  child: Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: doctorState.upcomingAppointments.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: doctorState.upcomingAppointments.take(5).map((
                      appointment,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildAppointmentCard(appointment),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.event_available, size: 32, color: AppColors.textHint),
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

  Widget _buildAppointmentCard(AppointmentData appointment) {
    final timeStr =
        '${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')}';
    final statusColor = appointment.status == 'confirmed'
        ? AppColors.secondary
        : AppColors.warning;
    final statusLabel = appointment.status == 'confirmed'
        ? 'Confirmé'
        : 'En attente';

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => AppointmentDetailsSheet(appointment: appointment),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: appointment.isConsultation
                    ? AppColors.consultationColor.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                appointment.isConsultation
                    ? Icons.video_call_outlined
                    : Icons.person_outline,
                size: 18,
                color: appointment.isConsultation
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
                    appointment.patientName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$timeStr • ${appointment.startTime.day}/${appointment.startTime.month}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(DoctorState doctorState) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          _buildDrawerHeader(doctorState),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _buildDrawerItem(
                  DoctorPage.dashboard,
                  LucideIcons.layoutDashboard,
                  'Tableau de bord',
                ),
                _buildDrawerItem(
                  DoctorPage.calendar,
                  LucideIcons.calendarDays,
                  'Calendrier',
                ),
                _buildDrawerItem(
                  DoctorPage.patients,
                  LucideIcons.users,
                  'Patients',
                ),
                _buildDrawerItem(
                  DoctorPage.settings,
                  LucideIcons.settings,
                  'Paramètres',
                ),
                _buildDrawerItem(
                  DoctorPage.calendar,
                  Icons.calendar_today_outlined,
                  'Calendrier',
                ),
                _buildDrawerItem(
                  DoctorPage.patients,
                  Icons.people_outline,
                  'Patients',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(
                  DoctorPage.settings,
                  Icons.settings_outlined,
                  'Paramètres',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(DoctorState doctorState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatarWidget(doctorState.avatarUrl, doctorState.name, 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorState.name.isNotEmpty
                          ? doctorState.name
                          : 'Docteur',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (doctorState.specialty.isNotEmpty)
                      Text(
                        doctorState.specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(DoctorState doctorState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatarWidget(doctorState.avatarUrl, doctorState.name, 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorState.name.isNotEmpty
                          ? doctorState.name
                          : 'Docteur',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (doctorState.specialty.isNotEmpty)
                      Text(
                        doctorState.specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget(String? avatarUrl, String name, double radius) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey,
        foregroundColor: AppColors.primary,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade400,
      child: Text(
        _getInitials(name),
        style: TextStyle(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty || name.length <= 2) return 'DR';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildDrawerItem(DoctorPage page, IconData icon, String label) {
    final isSelected = _currentPage == page;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
          border: isSelected
              ? Border(left: BorderSide(color: AppColors.primary, width: 3))
              : null,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            size: 22,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          onTap: () {
            setState(() => _currentPage = page);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildSidebar(DoctorState doctorState) {
    return Container(
      width: 240,
      color: AppColors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Image.asset(
              'assets/logo.png',
              height: 45,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                LucideIcons.stethoscope,
                size: 32,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _buildSidebarItem(
                  DoctorPage.dashboard,
                  LucideIcons.layoutDashboard,
                  'Tableau de bord',
                ),
                _buildSidebarItem(
                  DoctorPage.calendar,
                  LucideIcons.calendarDays,
                  'Calendrier',
                ),
                _buildSidebarItem(
                  DoctorPage.patients,
                  LucideIcons.users,
                  'Patients',
                ),
                _buildSidebarItem(
                  DoctorPage.settings,
                  LucideIcons.settings,
                  'Paramètres',
                ),
              ],
            ),
          ),
          _buildSidebarFooter(doctorState),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter(DoctorState doctorState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),

      child: Row(
        children: [
          _buildAvatarWidget(doctorState.avatarUrl, doctorState.name, 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorState.name.isNotEmpty ? doctorState.name : 'Docteur',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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

  Widget _buildSidebarItem(DoctorPage page, IconData icon, String label) {
    final isSelected = _currentPage == page;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
          border: isSelected
              ? Border(left: BorderSide(color: AppColors.primary, width: 3))
              : null,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            size: 22,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          onTap: () => _navigateTo(page),
        ),
      ),
    );
  }

  void _navigateTo(DoctorPage page) {
    setState(() => _currentPage = page);
  }
}
