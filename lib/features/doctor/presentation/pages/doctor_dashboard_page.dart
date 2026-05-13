import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
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
            child: Column(
              children: [
                _buildHeader(context, doctorState, isWideScreen),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: _buildContent(doctorState),
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

  Widget _buildHeader(BuildContext context, DoctorState doctorState, bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${doctorState.name.isNotEmpty ? doctorState.name.split(' ').first : 'Docteur'}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Voici un aperçu de votre activité',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${doctorState.todayAppointments} aujourd\'hui',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

  Widget _buildDrawer(BuildContext context, DoctorState doctorState) {
    return Drawer(
      backgroundColor: AppColors.white,
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
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(doctorState.name),
                  style: TextStyle(
                    fontSize: 16,
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
                      doctorState.name.isNotEmpty ? doctorState.name : 'Docteur',
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
          fontSize: 14,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSidebar(BuildContext context, DoctorState doctorState) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(doctorState),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _buildSidebarItem(0, Icons.dashboard_outlined, 'Tableau de bord'),
                _buildSidebarItem(1, Icons.calendar_today_outlined, 'Calendrier'),
                _buildSidebarItem(2, Icons.list_alt_outlined, 'Rendez-vous'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Divider(height: 1),
                ),
                _buildSidebarItem(3, Icons.person_outline, 'Profil'),
                _buildSidebarItem(4, Icons.settings_outlined, 'Paramètres'),
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
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(doctorState.name),
                  style: TextStyle(
                    fontSize: 16,
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
                      doctorState.name.isNotEmpty ? doctorState.name : 'Docteur',
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

  String _getInitials(String name) {
    if (name.isEmpty || name.length <= 2) return 'DR';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        onTap: () {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildContent(DoctorState doctorState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsSection(doctorState),
          const SizedBox(height: AppSpacing.xl),
          _buildQuickActionsSection(),
          const SizedBox(height: AppSpacing.xl),
          _buildUpcomingSection(doctorState),
        ],
      ),
    );
  }

  Widget _buildStatsSection(DoctorState doctorState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        
        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Aujourd\'hui', '${doctorState.todayAppointments}', Icons.today_outlined, AppColors.primary)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildStatCard('Cette semaine', '${doctorState.weekAppointments}', Icons.date_range_outlined, AppColors.secondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _buildStatCard('En attente', '${_getPendingCount(doctorState)}', Icons.pending_outlined, AppColors.warning)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildStatCard('Terminés', '${_getCompletedCount(doctorState)}', Icons.check_circle_outlined, AppColors.success)),
                ],
              ),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(child: _buildStatCard('Aujourd\'hui', '${doctorState.todayAppointments}', Icons.today_outlined, AppColors.primary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildStatCard('Cette semaine', '${doctorState.weekAppointments}', Icons.date_range_outlined, AppColors.secondary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildStatCard('En attente', '${_getPendingCount(doctorState)}', Icons.pending_outlined, AppColors.warning)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildStatCard('Terminés', '${_getCompletedCount(doctorState)}', Icons.check_circle_outlined, AppColors.success)),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 2),
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
        borderRadius: BorderRadius.circular(24),
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
                fontSize: 16,
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
                _buildActionCard('Nouveau rendez-vous', Icons.add_circle_outline, () {}),
                _buildActionCard('Voir le calendrier', Icons.calendar_month_outlined, () {}),
                _buildActionCard('Tous les rendez-vous', Icons.list_alt_outlined, () {}),
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
        width: 180,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: AppColors.primary),
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
        borderRadius: BorderRadius.circular(24),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
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
                    children: doctorState.upcomingAppointments.take(5).map((appointment) {
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(Icons.event_available, size: 32, color: AppColors.textHint),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aucun rendez-vous',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Profitez de votre temps libre !',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentData appointment) {
    final timeStr = '${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')}';
    final statusColor = appointment.status == 'confirmed' ? AppColors.secondary : AppColors.warning;
    final statusLabel = appointment.status == 'confirmed' ? 'Confirmé' : 'En attente';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              appointment.isConsultation ? Icons.video_call_outlined : Icons.person_outline,
              size: 20,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(timeStr, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.calendar_today, size: 14, color: AppColors.textHint),
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
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
