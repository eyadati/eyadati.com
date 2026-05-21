import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/models/appointment_data.dart';
import 'package:eyadati/models/schedule_slot_model.dart';
import '../providers/doctor_provider.dart';
import '../widgets/doctor_add_appointment_dialog.dart';
import '../widgets/appointment_details_sheet.dart';

class DoctorCalendarPage extends ConsumerStatefulWidget {
  const DoctorCalendarPage({super.key});

  @override
  ConsumerState<DoctorCalendarPage> createState() => _DoctorCalendarPageState();
}

class _DoctorCalendarPageState extends ConsumerState<DoctorCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  final CalendarController _calendarController = CalendarController();
  final _CalendarDataSource _dataSource = _CalendarDataSource([]);
  CalendarView _currentView = CalendarView.week;
  String _lastUpdateKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateDataSource(ref.read(doctorProvider));
    });
  }

  (int startHour, int endHour) _getVisibleHours(DoctorState state) {
    if (state.scheduleSlots.isEmpty) return (8, 20);
    int earliest = 24;
    int latest = 0;
    for (final slot in state.scheduleSlots) {
      if (!slot.isActive) continue;
      if (slot.startTime < earliest) earliest = slot.startTime;
      if (slot.endTime > latest) latest = slot.endTime;
    }
    if (earliest == 24) return (8, 20);
    final start = earliest ~/ 60;
    final end = (latest / 60).ceil();
    final minRange = 6;
    int adjustedEnd = end;
    if (end - start < minRange) {
      adjustedEnd = start + minRange;
    }
    return (start.clamp(6, 22), adjustedEnd.clamp(start + 1, 23));
  }

  double _getTimeIntervalHeight(double screenWidth) {
    if (screenWidth < 600) return 70;
    if (screenWidth < 900) return 80;
    return 90;
  }

  String _formatWeekRange() {
    final months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
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

  String _formatDayRange() {
    final months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return '${_focusedDay.day} ${months[_focusedDay.month]} ${_focusedDay.year}';
  }

  void _previousWeeks() {
    setState(() {
      _focusedDay = _focusedDay.subtract(const Duration(days: 7));
    });
    _calendarController.displayDate = _focusedDay;
  }

  void _nextWeeks() {
    setState(() {
      _focusedDay = _focusedDay.add(const Duration(days: 7));
    });
    _calendarController.displayDate = _focusedDay;
  }

  void _previousDay() {
    setState(() {
      _focusedDay = _focusedDay.subtract(const Duration(days: 1));
    });
    _calendarController.displayDate = _focusedDay;
  }

  void _nextDay() {
    setState(() {
      _focusedDay = _focusedDay.add(const Duration(days: 1));
    });
    _calendarController.displayDate = _focusedDay;
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _focusedDay = today;
    });
    _calendarController.displayDate = today;
  }

  void _switchView(CalendarView view) {
    setState(() {
      _currentView = view;
    });
  }

  void _updateDataSource(DoctorState doctorState) {
    final appointments = doctorState.allAppointments
        .map(
          (apt) => _AppointmentWrapper(
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
          ),
        )
        .toList();
    _dataSource.updateAppointments(appointments);
  }

  void _showAddAppointmentDialog(DateTime day, {DateTime? initialTime}) {
    showDialog(
      context: context,
      builder: (ctx) => DoctorAddAppointmentDialog(
        initialDate: day,
        initialTime: initialTime,
      ),
    );
  }

  AppointmentData _toAppointmentData(_AppointmentWrapper apt) {
    return AppointmentData(
      id: apt.id,
      startTime: apt.startTime,
      endTime: apt.endTime,
      patientName: apt.patientName,
      patientAvatar: apt.patientAvatar,
      patientPhone: apt.patientPhone,
      status: apt.status,
      isConsultation: apt.isConsultation,
      notes: apt.notes,
      duration: apt.duration,
      patientId: apt.patientId,
      bookingType: apt.bookingType,
    );
  }

  Color _getStatusColor(_AppointmentWrapper apt) {
    if (apt.status == 'cancelled') {
      return AppColors.error.withValues(alpha: 0.5);
    }
    return apt.isConsultation ? AppColors.consultationColor : AppColors.primary;
  }

  Widget _buildNotificationBell(DoctorState state) {
    // Remove pending notification bell - not needed with upcoming/cancelled only
    return IconButton(
      icon: Icon(LucideIcons.bell, size: 22),
      onPressed: null,
      color: AppColors.textHint,
    );
  }

  void _showNotificationSheet(
    BuildContext context,
    List<AppointmentData> pending,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationSheet(appointments: pending),
    );
  }

  List<TimeRegion> _buildBreakRegions(
    List<ScheduleSlot> slots,
    DateTime focusedDay,
  ) {
    final regions = <TimeRegion>[];
    final startOfWeek = focusedDay.subtract(
      Duration(days: focusedDay.weekday % 7),
    );

    for (final slot in slots) {
      if (!slot.hasBreak) continue;
      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        if (day.weekday % 7 != slot.dayOfWeek) continue;
        if (!day.isAfter(DateTime.now().subtract(const Duration(days: 1))))
          continue;

        final breakStart = DateTime(
          day.year,
          day.month,
          day.day,
          slot.breakStart! ~/ 60,
          slot.breakStart! % 60,
        );
        final breakEnd = DateTime(
          day.year,
          day.month,
          day.day,
          slot.breakEnd! ~/ 60,
          slot.breakEnd! % 60,
        );

        regions.add(
          TimeRegion(
            startTime: breakStart,
            endTime: breakEnd,
            color: AppColors.textHint.withValues(alpha: 0.08),
            enablePointerInteraction: false,
            text: 'Pause',
            textStyle: AppTextStyles.labelSmall,
          ),
        );
      }
    }
    return regions;
  }

  Widget _buildCardsRow(DoctorState doctorState) {
    final now = DateTime.now();
    // Per supabase_checklist: Use computed getters instead of stored derived lists
    final upcomingList = doctorState.upcomingAppointmentsList;

    final weekCount = doctorState.weekAppointmentsCount;
    final onlineCount = upcomingList
        .where((a) => a.bookingType == 'online' && a.startTime.isAfter(now))
        .length;

    final nextAppointment = upcomingList.isNotEmpty ? upcomingList.first : null;

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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard(AppointmentData? appointment) {
    if (appointment == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.clock,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '--',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Prochain RDV',
              style: AppTextStyles.labelSmall.copyWith(
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
      padding: const EdgeInsets.all(12),
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
            style: const TextStyle(
              fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final (startHour, endHour) = _getVisibleHours(doctorState);

    final currentKey = doctorState.allAppointments
        .map((a) => '${a.id}:${a.status}')
        .join(',');
    if (currentKey != _lastUpdateKey) {
      _lastUpdateKey = currentKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateDataSource(doctorState);
      });
    }

    final breakRegions = _buildBreakRegions(
      doctorState.scheduleSlots,
      _focusedDay,
    );
    final isDayView = _currentView == CalendarView.day;

    return Column(
      children: [
        _buildCalendarHeader(isDayView),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: SfCalendarTheme(
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
              view: _currentView,
              initialDisplayDate: _focusedDay,
              showCurrentTimeIndicator: true,
              headerHeight: 0,
              todayHighlightColor: AppColors.primary,
              specialRegions: breakRegions,
              timeSlotViewSettings: TimeSlotViewSettings(
                startHour: startHour.toDouble(),
                endHour: endHour.toDouble(),
                timeInterval: const Duration(hours: 1),
                timeIntervalHeight: 120,
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
                final apt = details.appointments.first as _AppointmentWrapper;
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
                        ),
                      ),
                    );
                  },
                  child: Tooltip(
                    richMessage: WidgetSpan(
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      apt.patientName,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: apt.status == 'cancelled'
                                            ? AppColors.error
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (apt.status == 'cancelled') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                                Text(
                                  '${apt.isConsultation ? "Consultation" : "RDV"} • ${apt.startTime.hour}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: apt.status == 'cancelled'
                                        ? AppColors.error.withValues(alpha: 0.7)
                                        : AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    waitDuration: const Duration(milliseconds: 300),
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: _buildAppointmentWidget(apt, details.bounds),
                  ),
                );
              },
              onTap: (CalendarTapDetails details) {
                if (details.appointments == null ||
                    details.appointments!.isEmpty) {
                  if (details.date != null) {
                    showDialog(
                      context: context,
                      builder: (ctx) => DoctorAddAppointmentDialog(
                        initialDate: details.date!,
                      ),
                    );
                  }
                }
              },
              onViewChanged: (details) {
                if (details.visibleDates.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _focusedDay = details
                          .visibleDates[details.visibleDates.length ~/ 2];
                    });
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(bool isDayView) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, size: 20),
            onPressed: isDayView ? _previousDay : _previousWeeks,
            padding: EdgeInsets.zero,
          ),
          Text(
            isDayView ? _formatDayRange() : _formatWeekRange(),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, size: 20),
            onPressed: isDayView ? _nextDay : _nextWeeks,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleItem(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textHint,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentWidget(_AppointmentWrapper apt, Rect bounds) {
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
            ? Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1)
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
                    '${apt.startTime.hour}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    apt.patientName,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isCancelled ? AppColors.error : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
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

  Widget _buildScheduleView(DoctorState state) {
    // Per supabase_checklist: Use computed getter instead of stored derived list
    final upcoming = state.upcomingAppointmentsList;
    if (upcoming.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendarX, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('Aucun rendez-vous à venir', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcoming.length,
      itemBuilder: (context, index) {
        final apt = upcoming[index];
        final color = apt.isConsultation
            ? AppColors.consultationColor
            : AppColors.primary;
        final dateStr =
            '${apt.startTime.day}/${apt.startTime.month}/${apt.startTime.year}';
        final timeStr =
            '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(apt.patientName, style: AppTextStyles.titleSmall),
            subtitle: Text(
              '$dateStr à $timeStr • ${apt.duration} min',
              style: AppTextStyles.bodySmall,
            ),
            trailing: IconButton(
              icon: const Icon(LucideIcons.chevronRight, size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (c) => AppointmentDetailsSheet(appointment: apt),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final CalendarView currentView;
  final VoidCallback onWeekTap;
  final VoidCallback onDayTap;
  final VoidCallback onScheduleTap;

  const _ViewToggle({
    required this.currentView,
    required this.onWeekTap,
    required this.onDayTap,
    required this.onScheduleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: LucideIcons.calendarDays,
            label: 'Semaine',
            isSelected: currentView == CalendarView.week,
            onTap: onWeekTap,
          ),
          _ToggleButton(
            icon: LucideIcons.calendar,
            label: 'Jour',
            isSelected: currentView == CalendarView.day,
            onTap: onDayTap,
          ),
          _ToggleButton(
            icon: LucideIcons.list,
            label: 'Liste',
            isSelected: currentView == CalendarView.schedule,
            onTap: onScheduleTap,
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSheet extends ConsumerWidget {
  final List<AppointmentData> appointments;

  const _NotificationSheet({required this.appointments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(LucideIcons.bell, size: 20, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  'En attente de confirmation',
                  style: AppTextStyles.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Aucune notification',
                style: AppTextStyles.bodyMedium,
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  return _NotificationItem(appointment: appointments[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  final AppointmentData appointment;

  const _NotificationItem({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr =
        '${appointment.startTime.day}/${appointment.startTime.month}/${appointment.startTime.year}';
    final timeStr =
        '${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.user, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(appointment.patientName, style: AppTextStyles.labelLarge),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'En ligne',
                  style: AppTextStyles.badge.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('$dateStr à $timeStr', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(doctorProvider.notifier)
                        .cancelAppointmentStatus(appointment.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Rendez-vous annulé'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Erreur lors de l\'annulation'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(doctorProvider.notifier)
                        .confirmAppointment(appointment.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Rendez-vous confirmé'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Confirmer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppointmentWrapper extends Appointment {
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

  _AppointmentWrapper({
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

class _CalendarDataSource extends CalendarDataSource {
  _CalendarDataSource(List<Appointment> appointments) {
    this.appointments = appointments;
  }

  void updateAppointments(List<Appointment> appointments) {
    this.appointments = appointments;
    notifyListeners(CalendarDataSourceAction.reset, appointments);
  }
}
