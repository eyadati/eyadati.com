import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/doctor_provider.dart';

class DoctorDashboardPage extends ConsumerStatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  ConsumerState<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends ConsumerState<DoctorDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isWideScreen ? null : _buildDrawer(context, doctorState),
      body: Row(
        children: [
          if (isWideScreen) _buildSidebar(context, doctorState),
          Expanded(
            child: _buildContent(doctorState),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, DoctorState doctorState) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(doctorState),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _buildDrawerItem(0, Icons.dashboard_outlined, 'Tableau de bord'),
                _buildDrawerItem(1, Icons.calendar_today_outlined, 'Calendrier'),
                _buildDrawerItem(2, Icons.list_alt_outlined, 'Rendez-vous'),
                const Divider(height: 32),
                _buildDrawerItem(3, Icons.person_outline, 'Profil'),
                _buildDrawerItem(4, Icons.settings_outlined, 'Paramètres'),
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
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text(
                  doctorState.name.isNotEmpty && doctorState.name.length > 2
                      ? doctorState.name.substring(0, 2).toUpperCase()
                      : 'DR',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                      doctorState.name.isNotEmpty ? doctorState.name : 'Docteur',
                      style: const TextStyle(
                        fontSize: 16,
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                '${doctorState.todayAppointments} aujourd\'hui',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
        _navigateToRoute(index);
      },
    );
  }

  Widget _buildSidebar(BuildContext context, DoctorState doctorState) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          right: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(doctorState),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _buildSidebarItem(0, Icons.dashboard, 'Tableau de bord'),
                _buildSidebarItem(1, Icons.calendar_today, 'Calendrier'),
                _buildSidebarItem(2, Icons.list_alt, 'Rendez-vous'),
                const Divider(height: 32),
                _buildSidebarItem(3, Icons.person, 'Profil'),
                _buildSidebarItem(4, Icons.settings, 'Paramètres'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(DoctorState doctorState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text(
                  doctorState.name.isNotEmpty && doctorState.name.length > 2
                      ? doctorState.name.substring(0, 2).toUpperCase()
                      : 'DR',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                      doctorState.name.isNotEmpty ? doctorState.name : 'Docteur',
                      style: const TextStyle(
                        fontSize: 16,
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
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${doctorState.todayAppointments} rendez-vous aujourd\'hui',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() => _selectedIndex = index);
          _navigateToRoute(index);
        },
      ),
    );
  }

  void _navigateToRoute(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        context.push(RouteNames.doctorSchedule);
        break;
      case 2:
        context.push(RouteNames.doctorAppointments);
        break;
      case 3:
        context.push(RouteNames.doctorProfile);
        break;
      case 4:
        context.push(RouteNames.doctorSettings);
        break;
    }
  }

  Widget _buildContent(DoctorState doctorState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(doctorState),
          const SizedBox(height: AppSpacing.xl),
          _buildStats(doctorState),
          const SizedBox(height: AppSpacing.xl),
          _buildQuickActions(),
          const SizedBox(height: AppSpacing.xl),
          _buildUpcomingAppointments(doctorState),
        ],
      ),
    );
  }

  Widget _buildHeader(DoctorState doctorState) {
    return Row(
      children: [
        if (MediaQuery.of(context).size.width < 900)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctorState.name.isNotEmpty ? doctorState.name : 'Bienvenue',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tableau de bord',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(DoctorState doctorState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        
        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Aujourd\'hui', '${doctorState.todayAppointments}', Icons.today, AppColors.primary)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildStatCard('Cette semaine', '${doctorState.weekAppointments}', Icons.date_range, AppColors.secondary)),
                ],
              ),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(child: _buildStatCard('Aujourd\'hui', '${doctorState.todayAppointments}', Icons.today, AppColors.primary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildStatCard('Cette semaine', '${doctorState.weekAppointments}', Icons.date_range, AppColors.secondary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildStatCard('En attente', '${_getPendingCount(doctorState)}', Icons.pending_actions, AppColors.warning)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildStatCard('Terminés', '${_getCompletedCount(doctorState)}', Icons.check_circle, AppColors.success)),
          ],
        );
      },
    );
  }

  int _getPendingCount(DoctorState state) {
    return state.upcomingAppointments.where((a) => a.status == 'pending' || a.status == 'confirmed').length;
  }

  int _getCompletedCount(DoctorState state) {
    return 0;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildActionCard('Nouveau rendez-vous', Icons.add_circle_outline, () => context.push(RouteNames.doctorSchedule)),
            _buildActionCard('Voir le calendrier', Icons.calendar_month, () => context.push(RouteNames.doctorSchedule)),
            _buildActionCard('Tous les rendez-vous', Icons.list_alt, () => context.push(RouteNames.doctorAppointments)),
          ],
        ),
      ],
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments(DoctorState doctorState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rendez-vous à venir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.doctorAppointments),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (doctorState.upcomingAppointments.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: AppColors.textHint),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Aucun rendez-vous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Profitez de votre temps libre !',
                    style: TextStyle(fontSize: 14, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: doctorState.upcomingAppointments.take(5).map((appointment) {
              return _buildAppointmentCard(appointment);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(AppointmentData appointment) {
    final timeStr = '${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')}';
    final statusColor = appointment.status == 'confirmed' ? AppColors.secondary : AppColors.warning;
    final statusLabel = appointment.status == 'confirmed' ? 'Confirmé' : 'En attente';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: appointment.isConsultation
                  ? AppColors.consultationColor.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              appointment.isConsultation ? Icons.video_call : Icons.person,
              color: appointment.isConsultation ? AppColors.consultationColor : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(timeStr, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${appointment.startTime.day}/${appointment.startTime.month}',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}