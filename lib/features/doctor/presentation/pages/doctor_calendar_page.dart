import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/models/appointment_data.dart';
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
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _showDayAppointmentsDialog(selectedDay);
  }

  void _showDayAppointmentsDialog(DateTime day) {
    final doctorState = ref.read(doctorProvider);
    final dayAppointments = doctorState.getAppointmentsForDay(day);
    final isScheduled = doctorState.hasScheduleForDay(day);

    showDialog(
      context: context,
      builder: (ctx) => _DayAppointmentsDialog(
        day: day,
        appointments: dayAppointments,
        isScheduled: isScheduled,
        availableSlots: doctorState.getAvailableSlotsForDay(day).length,
        onAddAppointment: () {
          Navigator.pop(ctx);
          _showAddAppointmentDialog(day);
        },
        onViewAppointment: (apt) {
          Navigator.pop(ctx);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (c) => AppointmentDetailsSheet(appointment: apt),
          );
        },
      ),
    );
  }

  void _showAddAppointmentDialog(DateTime day) {
    showDialog(
      context: context,
      builder: (ctx) =>
          DoctorAddAppointmentDialog(initialDate: day, initialHour: 9),
    );
  }

  void _previousWeeks() {
    setState(() {
      _focusedDay = _focusedDay.subtract(const Duration(days: 14));
    });
  }

  void _nextWeeks() {
    setState(() {
      _focusedDay = _focusedDay.add(const Duration(days: 14));
    });
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
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
    final endOfWeek = startOfWeek.add(const Duration(days: 13));

    if (startOfWeek.month == endOfWeek.month) {
      return '${startOfWeek.day} - ${endOfWeek.day} ${months[startOfWeek.month]} ${startOfWeek.year}';
    } else if (startOfWeek.year == endOfWeek.year) {
      return '${startOfWeek.day} ${months[startOfWeek.month]} - ${endOfWeek.day} ${months[endOfWeek.month]} ${endOfWeek.year}';
    } else {
      return '${startOfWeek.day} ${months[startOfWeek.month]} ${startOfWeek.year} - ${endOfWeek.day} ${months[endOfWeek.month]} ${endOfWeek.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);

    return Stack(
      children: [
        Column(
          children: [
            _buildCalendarHeader(),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    _isSameDay(day, _selectedDay ?? DateTime.now()),
                onDaySelected: _onDaySelected,
                calendarFormat: CalendarFormat.twoWeeks,
                headerVisible: false,
                daysOfWeekHeight: 32,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  cellMargin: EdgeInsets.all(2),
                  cellPadding: EdgeInsets.zero,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) =>
                      _buildDayCell(doctorState, day, false, false),
                  todayBuilder: (context, day, focusedDay) =>
                      _buildDayCell(doctorState, day, false, true),
                  selectedBuilder: (context, day, focusedDay) =>
                      _buildDayCell(doctorState, day, true, false),
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

  Widget _buildCalendarHeader() {
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
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

  Widget _buildDayCell(
    DoctorState doctorState,
    DateTime day,
    bool isSelected,
    bool isToday,
  ) {
    final isScheduled = doctorState.hasScheduleForDay(day);
    final appointments = doctorState.getAppointmentsForDay(day);

    Color bgColor;
    if (isSelected) {
      bgColor = AppColors.primary;
    } else if (isToday) {
      bgColor = AppColors.primary.withValues(alpha: 0.1);
    } else if (isScheduled) {
      bgColor = AppColors.white;
    } else {
      bgColor = AppColors.background;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isToday ? AppColors.primary : Colors.transparent),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isToday ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          if (appointments.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildAppointmentDots(appointments),
            )
          else
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isScheduled
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildAppointmentDots(List<AppointmentData> appointments) {
    final sorted = [...appointments]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final display = sorted.take(3).toList();

    return display.map((apt) {
      final color = apt.isConsultation
          ? AppColors.consultationColor
          : AppColors.primary;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
      );
    }).toList();
  }
}

class _DayAppointmentsDialog extends StatelessWidget {
  final DateTime day;
  final List<AppointmentData> appointments;
  final bool isScheduled;
  final int availableSlots;
  final VoidCallback onAddAppointment;
  final Function(AppointmentData) onViewAppointment;

  const _DayAppointmentsDialog({
    required this.day,
    required this.appointments,
    required this.isScheduled,
    required this.availableSlots,
    required this.onAddAppointment,
    required this.onViewAppointment,
  });

  @override
  Widget build(BuildContext context) {
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
    const days = [
      'Dimanche',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
    ];

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 380,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${days[day.weekday % 7]}, ${day.day} ${months[day.month]}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${appointments.length} rdv${isScheduled ? ' • $availableSlots créneaux' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isScheduled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.circleCheck,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Planifié',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (appointments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.calendarX,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aucun rendez-vous ce jour',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: appointments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final apt = appointments[index];
                    return InkWell(
                      onTap: () => onViewAppointment(apt),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: apt.isConsultation
                                    ? AppColors.consultationColor.withValues(
                                        alpha: 0.15,
                                      )
                                    : AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: apt.isConsultation
                                        ? AppColors.consultationColor
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    apt.patientName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    apt.isConsultation
                                        ? 'Consultation • ${apt.duration} min'
                                        : 'Rendez-vous • ${apt.duration} min',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusBg(apt.status),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _getStatusLabel(apt.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(apt.status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isScheduled ? onAddAppointment : null,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Ajouter un rendez-vous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFFE8F5E9);
      case 'pending':
        return const Color(0xFFFFF3E0);
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return AppColors.background;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.secondary;
      case 'pending':
        return const Color(0xFFFF9800);
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }
}
