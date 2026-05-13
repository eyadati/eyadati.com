import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import '../providers/doctor_provider.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
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

    return Column(
      children: [
        _buildWeekHeader(weekDays),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildDayColumns(weekDays, doctorState),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekHeader(List<DateTime> weekDays) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
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

  Widget _buildDayColumns(List<DateTime> weekDays, DoctorState doctorState) {
    final hours = List.generate(14, (i) => i + 7);

    return Column(
      children: hours.map((hour) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ...weekDays.map((day) {
              final appointments = _getAppointmentsForHour(doctorState, day, hour);

              return Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      right: BorderSide(color: AppColors.border, width: 0.5),
                      bottom: BorderSide(color: AppColors.border, width: 0.5),
                    ),
                  ),
                  child: appointments.isEmpty
                      ? null
                      : Column(
                          children: appointments.map((apt) {
                            return Container(
                              margin: const EdgeInsets.all(2),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                apt.patientName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                ),
              );
            }),
          ],
        );
      }).toList(),
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
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (appointments.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.event_available, size: 32, color: AppColors.textHint),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Aucun rendez-vous',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...appointments.map((apt) {
                  final timeStr = '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}';
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person, color: AppColors.primary, size: 18),
                    ),
                    title: Text(
                      apt.patientName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(timeStr),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          color: apt.status == 'confirmed' ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  );
                }),
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
    const months = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return months[month];
  }

  String _getDayName(int weekday) {
    const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    return days[weekday % 7];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<AppointmentData> _getAppointmentsForHour(DoctorState state, DateTime day, int hour) {
    return state.upcomingAppointments.where((apt) {
      return _isSameDay(apt.startTime, day) && apt.startTime.hour == hour;
    }).toList();
  }

  List<AppointmentData> _getAppointmentsForDay(DoctorState state, DateTime day) {
    return state.upcomingAppointments.where((apt) => _isSameDay(apt.startTime, day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void navigateDate(int direction) {
    setState(() {
      if (_isWeekView) {
        _currentDate = _currentDate.add(Duration(days: 7 * direction));
      } else {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + direction, 1);
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
