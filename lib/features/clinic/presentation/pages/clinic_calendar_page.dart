import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_breakpoints.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/core/routing/route_names.dart';
import 'package:eyadati/models/appointment_data.dart';
import 'package:eyadati/features/doctor/presentation/widgets/doctor_week_strip.dart';
import 'package:eyadati/features/doctor/presentation/widgets/doctor_day_list_view.dart';
import 'package:eyadati/features/doctor/presentation/widgets/appointment_details_sheet.dart';
import '../providers/clinic_provider.dart';
import '../widgets/walk_in_dialog.dart';
import '../widgets/add_doctor_dialog.dart';

class ClinicCalendarPage extends ConsumerStatefulWidget {
  final VoidCallback? onBellPressed;
  final ValueNotifier<DateTime> selectedDateNotifier;

  ClinicCalendarPage({
    super.key,
    this.onBellPressed,
    ValueNotifier<DateTime>? selectedDateNotifier,
  }) : selectedDateNotifier = selectedDateNotifier ?? ValueNotifier(DateTime.now());

  @override
  ConsumerState<ClinicCalendarPage> createState() => _ClinicCalendarPageState();
}

class _ClinicCalendarPageState extends ConsumerState<ClinicCalendarPage>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  final CalendarController _calendarController = CalendarController();
  final _ClinicCalendarDataSource _dataSource = _ClinicCalendarDataSource([]);

  String _lastUpdateKey = '';
  bool _isExpanded = true;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  void _syncSelectedDate() {
    widget.selectedDateNotifier.value = _focusedDay;
  }

  void _updateUrlParam() {
    final formatted =
        '${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}-${_focusedDay.day.toString().padLeft(2, '0')}';
    GoRouter.of(context).replace(
      '${RouteNames.clinicCalendar}?date=$formatted',
    );
  }

  @override
  void initState() {
    super.initState();
    _syncSelectedDate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dateParam = GoRouterState.of(context).uri.queryParameters['date'];
      if (dateParam != null) {
        final parsed = DateTime.tryParse(dateParam);
        if (parsed != null) {
          _focusedDay = parsed;
          _calendarController.displayDate = parsed;
        }
      }
      _updateDataSource(ref.read(clinicProvider));
    });
    Future.microtask(() => ref.read(clinicProvider.notifier).loadClinicGroup());
  }

  double _getTimeIntervalHeight(double screenWidth) {
    if (screenWidth < 600) return 70;
    if (screenWidth < 900) return 80;
    return 90;
  }

  String _formatWeekRange() {
    final months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai',
      'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    final startOfWeek = _focusedDay.subtract(
      Duration(days: _focusedDay.weekday % 7),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    if (startOfWeek.month == endOfWeek.month) {
      return '${startOfWeek.day} - ${endOfWeek.day} ${months[startOfWeek.month]} ${startOfWeek.year}';
    } else if (startOfWeek.year == endOfWeek.year) {
      return '${startOfWeek.day} ${months[startOfWeek.month]} - ${endOfWeek.day} ${months[endOfWeek.month]} ${startOfWeek.year}';
    }
    return '${startOfWeek.day} ${months[startOfWeek.month]} ${startOfWeek.year} - ${endOfWeek.day} ${months[endOfWeek.month]} ${endOfWeek.year}';
  }

  void _previousWeeks() {
    setState(() {
      _focusedDay = _focusedDay.subtract(const Duration(days: 7));
      _syncSelectedDate();
    });
    _calendarController.displayDate = _focusedDay;
    _updateUrlParam();
  }

  void _nextWeeks() {
    setState(() {
      _focusedDay = _focusedDay.add(const Duration(days: 7));
      _syncSelectedDate();
    });
    _calendarController.displayDate = _focusedDay;
    _updateUrlParam();
  }

  void _updateDataSource(ClinicState clinicState) {
    final colorMap = <String, Color>{};
    for (final m in clinicState.members) {
      colorMap[m.doctorId] = m.color;
    }

    final appointments = clinicState.filteredAppointments.map((a) {
      final docColor = colorMap[a.doctorId] ?? AppColors.primary;
      return _ClinicAppointmentWrapper(
        id: a.id,
        startTime: a.startTime,
        endTime: a.endTime,
        patientName: a.patientName,
        status: a.status,
        isConsultation: a.isConsultation,
        duration: a.duration,
        notes: a.notes,
        patientPhone: a.patientPhone,
        patientAvatar: a.patientAvatar,
        patientId: a.patientId,
        bookingType: a.bookingType,
        doctorId: a.doctorId,
        doctorName: a.doctorName,
        doctorColor: docColor,
      );
    }).toList();
    _dataSource.updateAppointments(appointments);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 14 : 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: (isMobile ? AppTextStyles.badge : AppTextStyles.labelSmall).copyWith(
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard(AppointmentData? appointment, {bool isMobile = false}) {
    if (appointment == null) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.clock,
                color: AppColors.primary,
                size: isMobile ? 14 : 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '--',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Prochain RDV',
              style: (isMobile ? AppTextStyles.badge : AppTextStyles.labelSmall).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final timeStr =
        '${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${appointment.startTime.day}/${appointment.startTime.month}';
    final typeColor = appointment.isConsultation
        ? AppColors.consultationColor
        : AppColors.primary;
    final typeLabel = appointment.isConsultation ? 'Consultation' : 'RDV';

    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              typeLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appointment.patientName,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$dateStr à $timeStr',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsRow(ClinicState clinicState, double screenWidth) {
    final isMobile = AppBreakpoints.isMobile(screenWidth);
    final now = DateTime.now();
    final filtered = clinicState.filteredAppointments;

    final upcomingList = filtered
        .where((a) =>
            a.startTime.isAfter(now) &&
            a.status == 'upcoming')
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1) % 7);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekCount = filtered
        .where((a) =>
            a.startTime.isAfter(weekStart) &&
            a.startTime.isBefore(weekEnd))
        .length;
    final onlineCount = filtered
        .where((a) =>
            a.bookingType == 'online' &&
            a.startTime.isAfter(weekStart) &&
            a.startTime.isBefore(weekEnd) &&
            a.status == 'upcoming')
        .length;

    final nextAppointment = upcomingList.isNotEmpty ? upcomingList.first : null;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Cette semaine',
                    '$weekCount',
                    LucideIcons.calendar,
                    AppColors.secondary,
                    isMobile: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'En ligne',
                    '$onlineCount',
                    LucideIcons.video,
                    AppColors.primary,
                    isMobile: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildNextAppointmentCard(nextAppointment, isMobile: true),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Cette semaine',
              '$weekCount',
              LucideIcons.calendar,
              AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'En ligne',
              '$onlineCount',
              LucideIcons.video,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildNextAppointmentCard(nextAppointment)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Chargement du calendrier...',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
              if (buttonLabel != null && onButtonPressed != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onButtonPressed,
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  label: Text(buttonLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Une erreur est survenue',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(clinicProvider.notifier).loadClinicGroup(),
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(int pendingCount, bool hasMembers, String clinicName, {int availableCount = 0, int totalCount = 0}) {
    final isMobile = AppBreakpoints.isMobile(MediaQuery.of(context).size.width);
    final displayName = clinicName.isNotEmpty ? clinicName : 'Ma clinique';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 8 : 10,
      ),
      child: Row(
        children: [
          if (!isMobile)
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
              tooltip: 'Retour au calendrier individuel',
              onPressed: () => context.pop(),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          Flexible(
            child: Row(
              children: [
                Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: (isMobile ? AppTextStyles.titleMedium : AppTextStyles.titleLarge).copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CLINIQUE',
                    style: AppTextStyles.badge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (totalCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: availableCount > 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$availableCount/$totalCount disponibles',
                      style: AppTextStyles.badge.copyWith(
                        color: availableCount > 0 ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
            ],
          ),
          ),
          if (!isMobile) const Spacer(),
          if (!isMobile)
            IconButton(
              icon: const Icon(LucideIcons.chevronLeft, size: 25),
              onPressed: _previousWeeks,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          if (!isMobile) ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _formatWeekRange(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(LucideIcons.chevronRight, size: 25),
              onPressed: _nextWeeks,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
          const Spacer(),
          if (hasMembers)
            IconButton(
              icon: const Icon(LucideIcons.userRoundPlus, color: AppColors.textSecondary),
              tooltip: 'Ajouter un médecin',
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => const AddDoctorDialog(),
              ),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: Stack(
              children: [
                const Icon(LucideIcons.bell, color: AppColors.textPrimary),
                if (pendingCount > 0)
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
            onPressed: widget.onBellPressed,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.settings,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.push(RouteNames.doctorSettings),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: _isExpanded ? 0.5 : 0,
                child: const Icon(
                  LucideIcons.chevronDown,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicState = ref.watch(clinicProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = AppBreakpoints.isMobile(screenWidth);

    final currentKey = clinicState.filteredAppointments
        .map((a) => '${a.id}:${a.status}')
        .join(',');
    if (currentKey != _lastUpdateKey) {
      _lastUpdateKey = currentKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateDataSource(clinicState);
      });
    }

    if (clinicState.isLoading && clinicState.members.isEmpty) {
      return Column(
        children: [
          _buildTopHeader(clinicState.pendingCount, clinicState.members.isNotEmpty, clinicState.clinicName, availableCount: clinicState.availableDoctorCount, totalCount: clinicState.members.length),
          _buildLoadingState(),
        ],
      );
    }

    if (clinicState.error != null && clinicState.members.isEmpty) {
      return Column(
        children: [
          _buildTopHeader(clinicState.pendingCount, clinicState.members.isNotEmpty, clinicState.clinicName, availableCount: clinicState.availableDoctorCount, totalCount: clinicState.members.length),
          _buildErrorState(clinicState.error!),
        ],
      );
    }

    if (clinicState.members.isEmpty && !clinicState.isLoading) {
      return Column(
        children: [
          _buildTopHeader(clinicState.pendingCount, false, clinicState.clinicName, availableCount: 0, totalCount: 0),
          _buildEmptyState(
            icon: LucideIcons.users,
            title: 'Aucun médecin dans la clinique',
            subtitle: 'Ajoutez des médecins pour commencer à gérer les rendez-vous.',
            buttonLabel: 'Ajouter un médecin',
            onButtonPressed: () => showDialog(
              context: context,
              builder: (ctx) => const AddDoctorDialog(),
            ),
          ),
        ],
      );
    }

    if (clinicState.members.isNotEmpty && clinicState.availableDoctorCount == 0 && !clinicState.isLoading) {
      return Column(
        children: [
          _buildTopHeader(clinicState.pendingCount, true, clinicState.clinicName, availableCount: 0, totalCount: clinicState.members.length),
          _buildEmptyState(
            icon: LucideIcons.pauseCircle,
            title: 'Aucun médecin disponible',
            subtitle: 'Tous les médecins sont suspendus ou ont un abonnement expiré.',
          ),
        ],
      );
    }

    return Column(
      children: [
        if (clinicState.isLoading && clinicState.members.isNotEmpty)
          const LinearProgressIndicator(
            backgroundColor: AppColors.border,
            color: AppColors.primary,
            minHeight: 2,
          ),
        _buildTopHeader(clinicState.pendingCount, clinicState.members.isNotEmpty, clinicState.clinicName, availableCount: clinicState.availableDoctorCount, totalCount: clinicState.members.length),
        _buildFilterChips(clinicState),
        if (clinicState.error != null && clinicState.members.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clinicState.error!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildCardsRow(clinicState, screenWidth),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isMobile
                  ? _buildMobileDayView(clinicState)
                  : _buildTabletCalendar(clinicState, screenWidth),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDayView(ClinicState clinicState) {
    final dayAppointments = clinicState.filteredAppointments.where((a) =>
      a.startTime.year == _focusedDay.year &&
      a.startTime.month == _focusedDay.month &&
      a.startTime.day == _focusedDay.day
    ).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: DoctorWeekStrip(
            selectedDate: _focusedDay,
            appointments: clinicState.filteredAppointments,
            onDateSelected: (date) {
              setState(() {
                _focusedDay = date;
                _syncSelectedDate();
              });
              _calendarController.displayDate = date;
              _updateUrlParam();
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(clinicProvider.notifier).refresh(),
            child: DoctorDayListView(
              selectedDate: _focusedDay,
              appointments: dayAppointments,
              startHour: 8,
              endHour: 19,
              onAppointmentTap: (apt) => _showAppointmentDetails(apt),
              onEmptySlotTap: (time) => _showWalkInDialog(time),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletCalendar(
    ClinicState clinicState,
    double screenWidth,
  ) {
    return SfCalendarTheme(
      data: SfCalendarThemeData(
        backgroundColor: AppColors.white,
        todayHighlightColor: AppColors.primary,
        selectionBorderColor: AppColors.primary,
        cellBorderColor: AppColors.primary.withValues(alpha: 0.65),
        viewHeaderBackgroundColor: AppColors.white,
        timeTextStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textHint,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: SfCalendar(
        controller: _calendarController,
        dataSource: _dataSource,
        view: CalendarView.week,
        initialDisplayDate: _focusedDay,
        showCurrentTimeIndicator: true,
        headerHeight: 0,
        todayHighlightColor: AppColors.primary,
        timeSlotViewSettings: TimeSlotViewSettings(
          startHour: 8,
          endHour: 19,
          timeInterval: const Duration(hours: 1),
          timeIntervalHeight: _getTimeIntervalHeight(screenWidth),
          timeFormat: 'H a',
          timeRulerSize: 60,
          dayFormat: 'EEE',
          dateFormat: 'd',
        ),
        selectionDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        viewHeaderStyle: ViewHeaderStyle(
          dayTextStyle: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textHint,
          ),
          dateTextStyle: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        appointmentBuilder: (context, details) {
          final appointments = details.appointments;
          final isDense = appointments.length > 1;

          if (isDense) {
            final wrappers = appointments.cast<_ClinicAppointmentWrapper>().toList();
            return GestureDetector(
              onTap: () => _showDenseSlotDetails(wrappers),
              child: _buildDenseAppointmentWidget(wrappers),
            );
          }

          final apt = appointments.first as _ClinicAppointmentWrapper;
          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (c) => AppointmentDetailsSheet(
                  appointment: AppointmentData(
                    id: apt.id,
                    startTime: apt.startTime,
                    endTime: apt.endTime,
                    patientName: apt.patientName,
                    status: apt.status,
                    isConsultation: apt.isConsultation,
                    duration: apt.duration,
                    notes: apt.notes,
                    patientPhone: apt.patientPhone,
                    patientAvatar: apt.patientAvatar,
                    patientId: apt.patientId,
                    bookingType: apt.bookingType,
                    doctorId: apt.doctorId,
                    doctorName: apt.doctorName,
                  ),
                ),
              );
            },
            child: Tooltip(
              richMessage: WidgetSpan(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: apt.status == 'cancelled'
                        ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: apt.status == 'cancelled'
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.primaryLight,
                            child: Text(
                              apt.patientName.isNotEmpty
                                  ? apt.patientName[0].toUpperCase()
                                  : 'P',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: apt.status == 'cancelled'
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        apt.patientName,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: apt.status == 'cancelled'
                                              ? AppColors.error
                                              : AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (apt.status == 'cancelled') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Annulé',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: apt.doctorColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        apt.doctorName,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: apt.doctorColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        onTap: (CalendarTapDetails details) {
          if (details.appointments == null || details.appointments!.isEmpty) {
            if (details.date != null) {
              _showWalkInDialog(details.date!);
            }
          }
        },
        onViewChanged: (details) {
          if (details.visibleDates.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _focusedDay = details.visibleDates[details.visibleDates.length ~/ 2];
                _syncSelectedDate();
              });
            });
          }
        },
      ),
    );
  }

  Widget _buildAppointmentWidget(_ClinicAppointmentWrapper apt, Rect bounds) {
    Color bgColor;
    Color textColor;
    Color accentColor;
    bool isCancelled = apt.status == 'cancelled';

    if (isCancelled) {
      bgColor = AppColors.error.withValues(alpha: 0.15);
      textColor = AppColors.error;
      accentColor = AppColors.error;
    } else if (apt.bookingType == 'home') {
      bgColor = AppColors.aptHomeVisit;
      textColor = AppColors.aptHomeVisitText;
      accentColor = AppColors.aptHomeVisitText;
    } else if (apt.isConsultation) {
      bgColor = AppColors.aptInPerson;
      textColor = AppColors.aptInPersonText;
      accentColor = AppColors.aptInPersonText;
    } else {
      bgColor = AppColors.aptVideoCall;
      textColor = AppColors.aptVideoCallText;
      accentColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: isCancelled
            ? Border.all(
                color: AppColors.error.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                        Text(
                          apt.patientName,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isCancelled
                                ? AppColors.error
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: apt.doctorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          apt.doctorName,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: apt.doctorColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${apt.startTime.hour}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (isCancelled) ...[
                    const SizedBox(width: 6),
                    Text(
                      'Annulé',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenseAppointmentWidget(List<_ClinicAppointmentWrapper> appointments) {
    final remaining = appointments.length - 2;
    final showCount = appointments.length > 2 ? 2 : appointments.length;
    final hasCancelled = appointments.any((a) => a.status == 'cancelled');

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: hasCancelled
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasCancelled
              ? AppColors.error.withValues(alpha: 0.25)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < showCount; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i < showCount - 1 ? 2 : 0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: appointments[i].status == 'cancelled'
                          ? AppColors.error
                          : appointments[i].doctorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        appointments[0].patientName,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: appointments[0].status == 'cancelled'
                              ? AppColors.error
                              : AppColors.textPrimary,
                          decoration: appointments[0].status == 'cancelled'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (appointments[0].status == 'cancelled') ...[
                      const SizedBox(width: 4),
                      Text(
                        'Annulé',
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.error,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (appointments.length > 1)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          appointments[1].patientName,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            color: appointments[1].status == 'cancelled'
                                ? AppColors.error
                                : AppColors.textSecondary,
                            decoration: appointments[1].status == 'cancelled'
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (appointments[1].status == 'cancelled') ...[
                        const SizedBox(width: 4),
                        Text(
                          'Annulé',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.error,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          if (remaining > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '+$remaining',
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDenseSlotDetails(List<_ClinicAppointmentWrapper> appointments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${appointments.length} rendez-vous',
                  style: AppTextStyles.sectionTitle,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...appointments.map((apt) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: apt.status == 'cancelled'
                    ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: apt.doctorColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apt.patientName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: apt.status == 'cancelled'
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: apt.doctorColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${apt.doctorName} • ${apt.startTime.hour}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (apt.status == 'cancelled')
                    Text(
                      'Annulé',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ClinicState clinicState) {
    if (clinicState.members.isEmpty) return const SizedBox.shrink();

    final allSelected = clinicState.hiddenDoctorIds.isEmpty;
    final availableCount = clinicState.availableDoctorCount;
    final totalCount = clinicState.members.length;

    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: clinicState.members.length + 2,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$availableCount/$totalCount disponibles',
                  style: AppTextStyles.badge.copyWith(
                    color: availableCount > 0 ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }

          if (index == 1) {
            final isSelected = allSelected;
            return FilterChip(
              label: Text(
                'Tous les médecins',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                if (!isSelected) {
                  ref.read(clinicProvider.notifier).showAllDoctors();
                }
              },
              visualDensity: VisualDensity.compact,
            );
          }

          final member = clinicState.members[index - 2];
          final isHidden = clinicState.hiddenDoctorIds.contains(member.doctorId);
          final isUnavailable = !member.isAvailable;

          return GestureDetector(
            onLongPress: () => _confirmRemoveDoctor(member),
            child: FilterChip(
              avatar: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isUnavailable ? AppColors.textSecondary : member.color,
                  shape: BoxShape.circle,
                ),
              ),
              label: Text(
                '${member.doctorName}${isUnavailable ? ' ⚠' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isHidden ? FontWeight.normal : FontWeight.w600,
                  color: isUnavailable ? AppColors.textSecondary : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              selected: !isHidden,
              onSelected: isUnavailable
                  ? null
                  : (_) {
                      ref.read(clinicProvider.notifier).toggleDoctorFilter(member.doctorId);
                    },
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemoveDoctor(ClinicGroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer le médecin'),
        content: Text('Voulez-vous retirer ${member.doctorName} de la clinique ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Retirer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(clinicProvider.notifier).removeDoctor(member.doctorId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.doctorName} a été retiré de la clinique'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showWalkInDialog(DateTime time) {
    final clinicState = ref.read(clinicProvider);
    final notifier = ref.read(clinicProvider.notifier);
    final suggestedId = notifier.suggestMostAvailableDoctor(time);
    showDialog(
      context: context,
      builder: (ctx) => WalkInDialog(
        initialDate: time,
        members: clinicState.members,
        lastSelectedDoctorId: notifier.lastSelectedDoctorId,
        suggestedDoctorId: suggestedId,
      ),
    );
  }

  void _showAppointmentDetails(AppointmentData appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppointmentDetailsSheet(appointment: appointment),
    );
  }
}

class _ClinicAppointmentWrapper extends Appointment {
  @override
  final String id;
  final String patientName;
  final String status;
  final bool isConsultation;
  final int duration;
  @override
  final String? notes;
  final String? patientPhone;
  final String? patientAvatar;
  final String? patientId;
  final String bookingType;
  final String doctorId;
  final String doctorName;
  final Color doctorColor;

  _ClinicAppointmentWrapper({
    required this.id,
    required DateTime startTime,
    required DateTime endTime,
    required this.patientName,
    required this.status,
    required this.isConsultation,
    required this.duration,
    this.notes,
    this.patientPhone,
    this.patientAvatar,
    this.patientId,
    this.bookingType = 'online',
    this.doctorId = '',
    this.doctorName = '',
    this.doctorColor = AppColors.primary,
  }) : super(
         id: id,
         startTime: startTime,
         endTime: endTime,
         subject: patientName,
         notes: notes,
         color: isConsultation
             ? AppColors.consultationColor
             : AppColors.primary,
       );

  @override
  Color get color {
    if (status == 'cancelled') {
      return AppColors.error.withValues(alpha: 0.7);
    }
    return isConsultation ? AppColors.consultationColor : AppColors.primary;
  }
}

class _ClinicCalendarDataSource extends CalendarDataSource {
  _ClinicCalendarDataSource(List<Appointment> appointments) {
    this.appointments = appointments;
  }

  void updateAppointments(List<Appointment> appointments) {
    this.appointments = appointments;
    notifyListeners(CalendarDataSourceAction.reset, appointments);
  }
}
