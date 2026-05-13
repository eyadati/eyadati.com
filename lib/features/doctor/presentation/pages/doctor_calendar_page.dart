import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/models/schedule_slot_model.dart';
import '../providers/doctor_provider.dart';
import '../widgets/doctor_add_appointment_dialog.dart';
import '../widgets/appointment_details_sheet.dart';

class DoctorCalendarPage extends ConsumerStatefulWidget {
  const DoctorCalendarPage({super.key});

  @override
  ConsumerState<DoctorCalendarPage> createState() => DoctorCalendarPageState();
}

class DoctorCalendarPageState extends ConsumerState<DoctorCalendarPage> {
  DateTime _currentDate = DateTime.now();
  bool _isWeekView = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);

    return Column(
      children: [
        _buildCompactControls(),
        Expanded(
          child: _isWeekView
              ? _buildWeekView(doctorState)
              : _buildMonthView(doctorState),
        ),
      ],
    );
  }

  Widget _buildCompactControls() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => navigateDate(-1),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: GestureDetector(
              onTap: pickDate,
              child: Text(
                _isWeekView ? weekLabel : monthLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () => navigateDate(1),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: goToToday,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Aujourd'hui",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildToggle('Semaine', _isWeekView, () => setView(true)),
          const SizedBox(width: AppSpacing.xs),
          _buildToggle('Mois', !_isWeekView, () => setView(false)),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekView(DoctorState doctorState) {
    final weekDays = _getWeekDays();
    final openingParts = doctorState.startTime.split(':');
    final closingParts = doctorState.endTime.split(':');
    final openHour = int.tryParse(openingParts[0]) ?? 9;
    final closeHour = int.tryParse(closingParts[0]) ?? 17;

    return Column(
      children: [
        _buildWeekHeader(weekDays, openHour, closeHour),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildDayColumns(weekDays, doctorState),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekHeader(List<DateTime> weekDays, int openHour, int closeHour) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                '$openHour-$closeHour',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ...weekDays.map((day) {
            final isToday = _isSameDay(day, DateTime.now());
            final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary.withValues(alpha: 0.08) : null,
                ),
                child: Column(
                  children: [
                    Text(
                      _getDayName(day.weekday),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isWeekend ? AppColors.textHint : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isToday ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _onSlotTapped(DateTime day, int hour, int minute) {
    final doctorState = ref.read(doctorProvider);
    final dayOfWeek = day.weekday % 7;

    if (!_isSlotAvailable(day, hour, doctorState.scheduleSlots)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Créneau non disponible pour ce jour', style: TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DoctorAddAppointmentDialog(
        initialDate: day,
        initialHour: hour,
      ),
    );
  }

  bool _isSlotAvailable(DateTime day, int hour, List<ScheduleSlot> scheduleSlots) {
    final dayOfWeek = day.weekday % 7;
    final daySlots = scheduleSlots.where((s) => s.dayOfWeek == dayOfWeek && s.isActive).toList();
    if (daySlots.isEmpty) return false;

    for (final slot in daySlots) {
      final cleanStart = slot.startTime.split('.').first.split(':');
      final cleanEnd = slot.endTime.split('.').first.split(':');
      final slotStartHour = int.tryParse(cleanStart[0]) ?? 0;
      final slotEndHour = int.tryParse(cleanEnd[0]) ?? 24;

      if (hour >= slotStartHour && hour < slotEndHour) {
        return true;
      }
    }
    return false;
  }

  bool _isDayScheduled(DateTime day, List<ScheduleSlot> scheduleSlots) {
    final dayOfWeek = day.weekday % 7;
    return scheduleSlots.any((s) => s.dayOfWeek == dayOfWeek && s.isActive);
  }

  Widget _buildDayColumns(List<DateTime> weekDays, DoctorState doctorState) {
    final interval = 15;
    final slotsPerHour = 60 ~/ interval;

    final openingParts = doctorState.startTime.split(':');
    final closingParts = doctorState.endTime.split(':');
    final openHour = int.tryParse(openingParts[0]) ?? 9;
    final closeHour = int.tryParse(closingParts[0]) ?? 17;

    final hours = List.generate(closeHour - openHour, (i) => openHour + i);
    final slotsPerDay = hours.length * slotsPerHour;
    final scheduleSlots = doctorState.scheduleSlots;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  ...hours.map((hour) {
                    return SizedBox(
                      height: slotsPerHour * 36.0,
                      child: Center(
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            ...weekDays.map((day) {
              final isToday = _isSameDay(day, DateTime.now());
              final isDayScheduled = _isDayScheduled(day, scheduleSlots);
              final appointments = doctorState.upcomingAppointments
                  .where((apt) => _isSameDay(apt.startTime, day))
                  .toList();

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: !isDayScheduled
                        ? AppColors.background
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.04)
                            : null,
                    border: Border(
                      right: BorderSide(color: AppColors.border, width: 0.5),
                    ),
                  ),
                  child: Column(
                    children: List.generate(slotsPerDay, (idx) {
                      final hour = hours[idx ~/ slotsPerHour];
                      final minute = (idx % slotsPerHour) * interval;
                      final slotTime = DateTime(
                        day.year,
                        day.month,
                        day.day,
                        hour,
                        minute,
                      );

                      final slotAppointments = appointments.where((apt) {
                        final aptStart = apt.startTime;
                        final aptEnd = apt.endTime;
                        final slotEnd = slotTime.add(
                          Duration(minutes: interval),
                        );
                        return !aptStart.isAfter(slotEnd) &&
                            !aptEnd.isBefore(slotTime);
                      }).toList();

                      final isFirstSlotOfHour = minute == 0;
                      final isHourAvailable = isDayScheduled
                          ? _isSlotAvailable(day, hour, scheduleSlots)
                          : false;

                      return GestureDetector(
                        onTap: isHourAvailable ? () => _onSlotTapped(day, hour, minute) : null,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: !isHourAvailable && isDayScheduled
                                ? AppColors.border.withValues(alpha: 0.1)
                                : null,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.border.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: slotAppointments.isEmpty
                              ? Stack(
                                  children: [
                                    if (isFirstSlotOfHour)
                                      Positioned(
                                        top: 2,
                                        left: 4,
                                        child: Text(
                                          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w300,
                                            color: AppColors.textHint
                                                .withValues(alpha: isHourAvailable ? 0.5 : 0.2),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    ...slotAppointments.take(1).map((apt) {
                                      final isTopAligned =
                                          minute ==
                                          (apt.startTime.hour - 7) *
                                                  slotsPerHour +
                                              (apt.startTime.minute ~/
                                                  interval);
                                      if (!isTopAligned) {
                                        return const SizedBox();
                                      }
                                      return GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (ctx) =>
                                                AppointmentDetailsSheet(
                                                  appointment: apt,
                                                ),
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 1,
                                            vertical: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: apt.isConsultation
                                                ? AppColors.consultationColor
                                                      .withValues(alpha: 0.15)
                                                : AppColors.primary.withValues(
                                                    alpha: 0.15,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: apt.isConsultation
                                                  ? AppColors.consultationColor
                                                        .withValues(alpha: 0.3)
                                                  : AppColors.primary
                                                        .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            apt.patientName,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w300,
                                              color: apt.isConsultation
                                                  ? AppColors.consultationColor
                                                  : AppColors.primary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthView(DoctorState doctorState) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      headerVisible: false,
      daysOfWeekHeight: 48,
      rowHeight: 80,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        defaultTextStyle: TextStyle(
          fontWeight: FontWeight.w300,
          color: AppColors.textPrimary,
        ),
        weekendTextStyle: TextStyle(
          fontWeight: FontWeight.w300,
          color: AppColors.textSecondary,
        ),
        outsideTextStyle: TextStyle(
          fontWeight: FontWeight.w300,
          color: AppColors.textHint,
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        selectedDecoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        markerDecoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerSize: 6,
        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        weekendStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
          fontSize: 12,
        ),
      ),
      eventLoader: (day) {
        return _getAppointmentsForDay(doctorState, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        _showDayAppointments(selectedDay, doctorState);
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }

  void _showDayAppointments(DateTime day, DoctorState doctorState) {
    final appointments = _getAppointmentsForDay(doctorState, day);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${day.day} ${_getMonthName(day.month)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add, color: AppColors.primary),
                          onPressed: () {
                            Navigator.pop(context);
                            _onSlotTapped(day, day.hour == 0 ? 9 : day.hour, 0);
                          },
                          tooltip: 'Ajouter un rendez-vous',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (appointments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 32,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Aucun rendez-vous',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...appointments.map(
                  (apt) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        apt.isConsultation
                            ? Icons.video_call_outlined
                            : Icons.person_outline,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      apt.patientName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: apt.status == 'confirmed'
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        apt.status == 'confirmed' ? 'Confirmé' : 'En attente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: apt.status == 'confirmed'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: this.context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) =>
                            AppointmentDetailsSheet(appointment: apt),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  List<DateTime> _getWeekDays() {
    final weekday = _currentDate.weekday % 7;
    final monday = _currentDate.subtract(Duration(days: weekday));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month];
  }

  String _getDayName(int weekday) {
    const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    return days[weekday % 7];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<AppointmentData> _getAppointmentsForDay(
    DoctorState state,
    DateTime day,
  ) {
    return state.upcomingAppointments
        .where((apt) => _isSameDay(apt.startTime, day))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void navigateDate(int direction) {
    setState(() {
      if (_isWeekView) {
        _currentDate = _currentDate.add(Duration(days: 7 * direction));
      } else {
        _focusedDay = DateTime(
          _focusedDay.year,
          _focusedDay.month + direction,
          1,
        );
      }
    });
  }

  void goToToday() {
    setState(() {
      _currentDate = DateTime.now();
      _focusedDay = DateTime.now();
    });
  }

  void setView(bool isWeek) {
    setState(() => _isWeekView = isWeek);
  }

  String get weekLabel {
    final weekDays = _getWeekDays();
    final start = weekDays.first;
    final end = weekDays.last;
    if (start.month == end.month) {
      return '${start.day} - ${end.day} ${_getMonthName(start.month)}';
    }
    return '${start.day} ${_getMonthName(start.month)} - ${end.day} ${_getMonthName(end.month)}';
  }

  String get monthLabel {
    return '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}';
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _isWeekView ? _currentDate : _focusedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _currentDate = picked;
        _focusedDay = picked;
      });
    }
  }
}
