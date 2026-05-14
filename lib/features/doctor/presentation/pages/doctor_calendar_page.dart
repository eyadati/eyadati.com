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
      return '${startOfWeek.day} ${months[startOfWeek.month]} - ${endOfWeek.day} ${months[endOfWeek.month]} ${endOfWeek.year}';
    } else {
      return '${startOfWeek.day} ${months[startOfWeek.month]} ${startOfWeek.year} - ${endOfWeek.day} ${months[endOfWeek.month]} ${endOfWeek.year}';
    }
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

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _focusedDay = today;
    });
    _calendarController.displayDate = today;
  }

  void _showAddAppointmentDialog(DateTime day) {
    showDialog(
      context: context,
      builder: (ctx) =>
          DoctorAddAppointmentDialog(initialDate: day, initialHour: 9),
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

  int _appointmentCount = -1;

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
    print('[DoctorCalendarPage] Data source updated with ${appointments.length} appointments');
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    
    // Initial sync and subsequent updates
    if (_appointmentCount == -1 || doctorState.allAppointments.length != _appointmentCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateDataSource(doctorState);
      });
    }

    print(
      '[DoctorCalendarPage] Current schedule slots count: ${doctorState.scheduleSlots.length}',
    );
    print(
      '[DoctorCalendarPage] Current appointments count in state: ${doctorState.allAppointments.length}',
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 900;

    final breakRegions = _buildBreakRegions(
      doctorState.scheduleSlots,
      _focusedDay,
    );

    return Stack(
      children: [
        Column(
          children: [
            _buildCalendarHeader(isWideScreen),
            Expanded(
              child: SfCalendarTheme(
                data: SfCalendarThemeData(
                  backgroundColor: AppColors.background,
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
                  view: isWideScreen ? CalendarView.week : CalendarView.day,
                  initialDisplayDate: _focusedDay,
                  showCurrentTimeIndicator: true,
                  showDatePickerButton: false,
                  showNavigationArrow: false,
                  headerHeight: 0,
                  allowDragAndDrop: false,
                  allowAppointmentResize: false,
                  todayHighlightColor: AppColors.primary,
                  specialRegions: breakRegions,
                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: 8,
                    endHour: 20,
                    nonWorkingDays: const [],
                    timeInterval: const Duration(hours: 2),
                    timeIntervalHeight: 70,
                    timeFormat: 'HH:mm',
                    dayFormat: 'EEE',
                    dateFormat: 'd',
                    timeRulerSize: 56,
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
                    final isConsult = apt.isConsultation;
                    final color = isConsult
                        ? AppColors.consultationColor
                        : AppColors.primary;
                    final startTimeStr =
                        '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}';

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border(
                          left: BorderSide(color: color, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            startTimeStr,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Expanded(
                            child: Text(
                              apt.patientName,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
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
                      // Defer the state update to the next frame
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
                      // Use the engine's check instead of the provider's wrapper
                      final slots = doctorState.getAvailableSlotsForDay(
                        details.date!,
                      );

                      if (slots.isNotEmpty) {
                        _showAddAppointmentDialog(details.date!);
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
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddAppointmentDialog(DateTime.now()),
            backgroundColor: AppColors.primary,
            child: const Icon(LucideIcons.plus, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, size: 24),
            onPressed: _previousWeeks,
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _goToToday,
              child: Text(
                _formatWeekRange(),
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, size: 24),
            onPressed: _nextWeeks,
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
    String? notes,
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
