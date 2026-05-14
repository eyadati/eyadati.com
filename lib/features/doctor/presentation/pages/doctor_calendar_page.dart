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
    final months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    if (startOfWeek.month == endOfWeek.month) {
      return '${startOfWeek.day} - ${endOfWeek.day} ${months[startOfWeek.month]} ${startOfWeek.year}';
    } else if (startOfWeek.year == endOfWeek.year) {
      return '${startOfWeek.day} ${months[startOfWeek.month]} - ${endOfWeek.day} ${months[endOfWeek.month]} ${startOfWeek.year}';
    }
    return '${startOfWeek.day} ${months[startOfWeek.month]} ${startOfWeek.year} - ${endOfWeek.day} ${months[endOfWeek.month]} ${endOfWeek.year}';
  }

  String _formatDayRange() {
    final months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
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
        .map((apt) => _AppointmentWrapper(
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
            ))
        .toList();
    _dataSource.updateAppointments(appointments);
  }

  void _showAddAppointmentDialog(DateTime day, {DateTime? initialTime}) {
    showDialog(
      context: context,
      builder: (ctx) => DoctorAddAppointmentDialog(
        initialDate: day,
        initialHour: initialTime?.hour ?? 9,
        initialMinute: initialTime?.minute,
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
    switch (apt.status) {
      case 'cancelled':
        return AppColors.error.withValues(alpha: 0.5);
      case 'absent':
        return AppColors.textHint;
      case 'completed':
        return AppColors.success;
      default:
        return apt.isConsultation ? AppColors.consultationColor : AppColors.primary;
    }
  }

  List<TimeRegion> _buildBreakRegions(List<ScheduleSlot> slots, DateTime focusedDay) {
    final regions = <TimeRegion>[];
    final startOfWeek = focusedDay.subtract(Duration(days: focusedDay.weekday % 7));

    for (final slot in slots) {
      if (!slot.hasBreak) continue;
      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        if (day.weekday % 7 != slot.dayOfWeek) continue;
        if (!day.isAfter(DateTime.now().subtract(const Duration(days: 1)))) continue;

        final breakStart = DateTime(day.year, day.month, day.day, slot.breakStart! ~/ 60, slot.breakStart! % 60);
        final breakEnd = DateTime(day.year, day.month, day.day, slot.breakEnd! ~/ 60, slot.breakEnd! % 60);

        regions.add(TimeRegion(
          startTime: breakStart,
          endTime: breakEnd,
          color: AppColors.textHint.withValues(alpha: 0.08),
          enablePointerInteraction: false,
          text: 'Pause',
          textStyle: AppTextStyles.labelSmall,
        ));
      }
    }
    return regions;
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 900;
    final intervalHeight = _getTimeIntervalHeight(screenWidth);
    final (startHour, endHour) = _getVisibleHours(doctorState);

    if (_appointmentCount == -1 || doctorState.allAppointments.length != _appointmentCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateDataSource(doctorState);
      });
    }

    final breakRegions = _buildBreakRegions(doctorState.scheduleSlots, _focusedDay);
    final isScheduleView = _currentView == CalendarView.schedule;
    final isDayView = _currentView == CalendarView.day;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
        centerTitle: false,
        actions: [
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
      body: isScheduleView
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
                selectionDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                timeSlotViewSettings: TimeSlotViewSettings(
                  startHour: startHour.toDouble(),
                  endHour: endHour.toDouble(),
                  nonWorkingDays: const [],
                  timeInterval: const Duration(hours: 1),
                  timeIntervalHeight: intervalHeight,
                  timeFormat: 'HH:mm',
                  dayFormat: 'EEE',
                  dateFormat: 'd',
                  timeRulerSize: 56,
                  timeTextStyle: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                viewHeaderStyle: ViewHeaderStyle(
                  dayTextStyle: AppTextStyles.labelMedium,
                  dateTextStyle: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  backgroundColor: AppColors.white,
                ),
                appointmentBuilder: (context, details) {
                  if (details.appointments.isEmpty) return const SizedBox();
                  final apt = details.appointments.first as _AppointmentWrapper;
                  final color = _getStatusColor(apt);
                  final bounds = details.bounds;
                  final startTimeStr = '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}';

                  return Container(
                    width: bounds.width - 4,
                    height: bounds.height - 2,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border(left: BorderSide(color: color, width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          startTimeStr,
                          style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: color),
                        ),
                        if (bounds.height > 28)
                          Expanded(
                            child: Text(
                              apt.patientName,
                              style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: color),
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
                        _focusedDay = details.visibleDates[details.visibleDates.length ~/ 2];
                      });
                    });
                  }
                },
                onTap: (CalendarTapDetails details) {
                  if (details.appointments != null && details.appointments!.isNotEmpty) {
                    final apt = details.appointments!.first as _AppointmentWrapper;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (c) => AppointmentDetailsSheet(appointment: _toAppointmentData(apt)),
                    );
                  } else if (details.date != null) {
                    final doctorState = ref.read(doctorProvider);
                    final slots = doctorState.getAvailableSlotsForDay(details.date!);
                    if (slots.isNotEmpty) {
                      _showAddAppointmentDialog(details.date!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Aucun créneau disponible pour ce jour')),
                      );
                    }
                  }
                },
              ),
            ),
      floatingActionButton: !isScheduleView
          ? FloatingActionButton(
              onPressed: () => _showAddAppointmentDialog(DateTime.now()),
              backgroundColor: AppColors.primary,
              child: const Icon(LucideIcons.plus, color: Colors.white),
            )
          : null,
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
        final color = apt.isConsultation ? AppColors.consultationColor : AppColors.primary;
        final dateStr = '${apt.startTime.day}/${apt.startTime.month}/${apt.startTime.year}';
        final timeStr = '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(apt.patientName, style: AppTextStyles.titleSmall),
            subtitle: Text('$dateStr à $timeStr • ${apt.duration} min', style: AppTextStyles.bodySmall),
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
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
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
          color: isConsultation ? AppColors.consultationColor : AppColors.primary,
        );

  @override
  Color get color {
    switch (status) {
      case 'cancelled':
        return AppColors.error.withValues(alpha: 0.5);
      case 'absent':
        return AppColors.textHint;
      case 'completed':
        return AppColors.success;
      default:
        return isConsultation ? AppColors.consultationColor : AppColors.primary;
    }
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