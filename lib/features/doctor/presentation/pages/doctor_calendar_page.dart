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
import 'doctor_settings_page.dart';

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
  int _appointmentCount = -1;
  bool _initialSyncDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateDataSource(ref.read(doctorProvider));
      _initialSyncDone = true;
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
    return (earliest ~/ 60, (latest ~/ 60).ceil());
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
    _appointmentCount = doctorState.allAppointments.length;
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
    return apt.isConsultation
        ? AppColors.consultationColor
        : AppColors.primary;
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
    final upcomingList = doctorState.upcomingAppointments;
    
    final weekCount = doctorState.weekAppointments;
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
          Expanded(
            child: _buildNextAppointmentCard(nextAppointment),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
              child: Icon(LucideIcons.clock, color: AppColors.primary, size: 16),
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

    final timeStr = '${appointment.startTime.hour.toString().padLeft(2, '0')}:${appointment.startTime.minute.toString().padLeft(2, '0')}';
    final dateStr = '${appointment.startTime.day}/${appointment.startTime.month}';
    final typeColor = appointment.isConsultation ? AppColors.consultationColor : AppColors.primary;
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
    final isWideScreen = screenWidth >= 900;
    final intervalHeight = _getTimeIntervalHeight(screenWidth);
    final (startHour, endHour) = _getVisibleHours(doctorState);

    if (_appointmentCount == -1 ||
        doctorState.allAppointments.length != _appointmentCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateDataSource(doctorState);
      });
    }

    final breakRegions = _buildBreakRegions(
      doctorState.scheduleSlots,
      _focusedDay,
    );
    final isScheduleView = _currentView == CalendarView.schedule;
    final isDayView = _currentView == CalendarView.day;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        title: isScheduleView
            ? null
            : Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 22),
                    onPressed: isDayView ? _previousDay : _previousWeeks,
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _goToToday,
                      child: Text(
                        isDayView ? _formatDayRange() : _formatWeekRange(),
                        style: AppTextStyles.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 22),
                    onPressed: isDayView ? _nextDay : _nextWeeks,
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorSettingsPage()),
              );
            },
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          _buildNotificationBell(doctorState),
          const SizedBox(width: 8),
          if (!isScheduleView)
            _ViewToggle(
              currentView: _currentView,
              onWeekTap: () => _switchView(CalendarView.week),
              onDayTap: () => _switchView(CalendarView.day),
              onScheduleTap: () => _switchView(CalendarView.schedule),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildCardsRow(doctorState),
          Expanded(
            child: isScheduleView
          ? _buildScheduleView(doctorState)
          : SfCalendarTheme(
              data: SfCalendarThemeData(
                backgroundColor: AppColors.white,
                todayHighlightColor: AppColors.primary,
                selectionBorderColor: AppColors.primary,
                cellBorderColor: AppColors.border,
                allDayPanelColor: AppColors.white,
                viewHeaderBackgroundColor: AppColors.white,
                agendaBackgroundColor: AppColors.white,
                headerBackgroundColor: AppColors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 17.0),
                child: SfCalendar(
                  controller: _calendarController,
                  dataSource: _dataSource,
                  view: _currentView,
                  initialDisplayDate: _focusedDay,
                  showCurrentTimeIndicator: true,
                  showDatePickerButton: false,
                  showNavigationArrow: false,
                  headerHeight: 0,
                  allowDragAndDrop: false,
                  allowAppointmentResize: false,
                  todayHighlightColor: AppColors.primary,
                  specialRegions: breakRegions,
                  cellEndPadding: 4,

                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: 8.0,
                    endHour: endHour.toDouble(),
                    nonWorkingDays: const [],
                    timeInterval: const Duration(hours: 1),
                    timeIntervalHeight: intervalHeight * 1.3,
                    timeFormat: 'HH:mm',
                    dayFormat: 'EEE',
                    dateFormat: 'd',
                    timeRulerSize: 56,
                    timeTextStyle: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  viewHeaderStyle: ViewHeaderStyle(
                    dayTextStyle: AppTextStyles.labelMedium,
                    dateTextStyle: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AppColors.white,
                  ),
                  appointmentBuilder: (context, details) {
                    if (details.appointments.isEmpty) return const SizedBox();
                    final apt =
                        details.appointments.first as _AppointmentWrapper;
                    final color = _getStatusColor(apt);
                    final bounds = details.bounds;
                    final startTimeStr =
                        '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}';

                    return Container(
                      width: bounds.width - 4,
                      height: bounds.height - 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            startTimeStr,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          if (bounds.height > 28)
                            Expanded(
                              child: Text(
                                apt.patientName,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  onViewChanged: (ViewChangedDetails details) {
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
                  onTap: (CalendarTapDetails details) {
                    if (details.appointments != null &&
                        details.appointments!.isNotEmpty) {
                      final apt =
                          details.appointments!.first as _AppointmentWrapper;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (c) => AppointmentDetailsSheet(
                          appointment: _toAppointmentData(apt),
                        ),
                      );
                    } else if (details.date != null) {
                      final doctorState = ref.read(doctorProvider);
                      final validStarts = doctorState.availabilityService.getValidStarts(
                        details.date!,
                        doctorState.allAppointments,
                      );
                      if (validStarts.isNotEmpty) {
                        _showAddAppointmentDialog(
                          details.date!,
                          initialTime: details.date,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Aucun créneau disponible pour ce jour',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView(DoctorState state) {
    final upcoming = state.upcomingAppointments;
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
                  onPressed: () {
                    ref
                        .read(doctorProvider.notifier)
                        .cancelAppointmentStatus(appointment.id);
                    Navigator.pop(context);
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
                  onPressed: () {
                    ref
                        .read(doctorProvider.notifier)
                        .confirmAppointment(appointment.id);
                    Navigator.pop(context);
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
      return AppColors.error.withValues(alpha: 0.5);
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
