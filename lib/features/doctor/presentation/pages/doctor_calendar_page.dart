import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late DateTime _startOfTwoWeeks;

  @override
  void initState() {
    super.initState();
    _startOfTwoWeeks = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - weekday);
  }

  List<DateTime> _getTwoWeekDays() {
    return List.generate(14, (i) => _startOfTwoWeeks.add(Duration(days: i)));
  }

  void _previousWeeks() {
    setState(() {
      _startOfTwoWeeks = _startOfTwoWeeks.subtract(const Duration(days: 14));
    });
  }

  void _nextWeeks() {
    setState(() {
      _startOfTwoWeeks = _startOfTwoWeeks.add(const Duration(days: 14));
    });
  }

  void _goToToday() {
    setState(() {
      _startOfTwoWeeks = _getStartOfWeek(DateTime.now());
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime day) {
    return _isSameDay(day, DateTime.now());
  }

  String _formatWeekRange() {
    final end = _startOfTwoWeeks.add(const Duration(days: 13));
    final months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    
    if (_startOfTwoWeeks.month == end.month) {
      return '${_startOfTwoWeeks.day} - ${end.day} ${months[_startOfTwoWeeks.month]} ${_startOfTwoWeeks.year}';
    } else if (_startOfTwoWeeks.year == end.year) {
      return '${_startOfTwoWeeks.day} ${months[_startOfTwoWeeks.month]} - ${end.day} ${months[end.month]} ${end.year}';
    } else {
      return '${_startOfTwoWeeks.day} ${months[_startOfTwoWeeks.month]} ${_startOfTwoWeeks.year} - ${end.day} ${months[end.month]} ${end.year}';
    }
  }

  List<AppointmentData> _getAppointmentsForDay(DateTime day, List<AppointmentData> allAppointments) {
    return allAppointments.where((apt) => _isSameDay(apt.startTime, day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _showDayAppointments(DateTime day) {
    final doctorState = ref.read(doctorProvider);
    final dayAppointments = _getAppointmentsForDay(day, doctorState.allAppointments);
    final isScheduled = _isDayScheduled(day, doctorState.scheduleSlots);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DayAppointmentsSheet(
        day: day,
        appointments: dayAppointments,
        isScheduled: isScheduled,
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
      builder: (ctx) => DoctorAddAppointmentDialog(
        initialDate: day,
        initialHour: 9,
      ),
    );
  }

  bool _isDayScheduled(DateTime day, List<ScheduleSlot> scheduleSlots) {
    final dayOfWeek = day.weekday % 7;
    return scheduleSlots.any((s) => s.dayOfWeek == dayOfWeek && s.isActive);
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final twoWeekDays = _getTwoWeekDays();

    return Stack(
      children: [
        Column(
          children: [
            _buildCalendarHeader(),
            _buildWeekDaysHeader(),
            Expanded(
              child: _buildCalendarGrid(twoWeekDays, doctorState),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showAddAppointmentDialog(DateTime.now()),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
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
            icon: const Icon(Icons.chevron_left, size: 24),
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
            icon: const Icon(Icons.chevron_right, size: 24),
            onPressed: _nextWeeks,
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48),
          ...days.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> twoWeekDays, DoctorState doctorState) {
    final week1 = twoWeekDays.sublist(0, 7);
    final week2 = twoWeekDays.sublist(7, 14);

    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          Expanded(child: _buildWeekRow(week1, doctorState)),
          Divider(height: 1, color: AppColors.border),
          Expanded(child: _buildWeekRow(week2, doctorState)),
        ],
      ),
    );
  }

  Widget _buildWeekRow(List<DateTime> weekDays, DoctorState doctorState) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: weekDays.map((day) {
              final hours = _getWorkingHours(day, doctorState);
              return Expanded(
                child: Center(
                  child: Text(
                    '${hours}h',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        ...weekDays.map((day) => Expanded(
          child: _buildDayCell(day, doctorState),
        )),
      ],
    );
  }

  int _getWorkingHours(DateTime day, DoctorState doctorState) {
    final dayOfWeek = day.weekday % 7;
    final daySlots = doctorState.scheduleSlots.where((s) => s.dayOfWeek == dayOfWeek && s.isActive).toList();
    if (daySlots.isEmpty) return 0;
    
    int totalMinutes = 0;
    for (final slot in daySlots) {
      try {
        final startParts = slot.startTime.split('.').first.split(':');
        final endParts = slot.endTime.split('.').first.split(':');
        final startMins = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        totalMinutes += endMins - startMins;
      } catch (e) {}
    }
    return totalMinutes ~/ 60;
  }

  Widget _buildDayCell(DateTime day, DoctorState doctorState) {
    final isToday = _isToday(day);
    final isScheduled = _isDayScheduled(day, doctorState.scheduleSlots);
    final appointments = _getAppointmentsForDay(day, doctorState.allAppointments);

    return GestureDetector(
      onTap: () => _showDayAppointments(day),
      child: Container(
        decoration: BoxDecoration(
          color: isToday 
              ? AppColors.primary.withValues(alpha: 0.08)
              : isScheduled 
                  ? AppColors.white 
                  : AppColors.background,
          border: Border(
            left: BorderSide(color: AppColors.border.withValues(alpha: 0.3), width: 0.5),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isToday ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            if (appointments.isNotEmpty)
              Expanded(
                child: _buildAppointmentIndicators(appointments),
              )
            else
              Expanded(
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isScheduled 
                          ? AppColors.primary.withValues(alpha: 0.3) 
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentIndicators(List<AppointmentData> appointments) {
    final displayAppts = appointments.take(3).toList();
    final remaining = appointments.length - 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...displayAppts.map((apt) => Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: apt.isConsultation 
                  ? AppColors.consultationColor.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')} ${apt.patientName.split(' ').first}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: apt.isConsultation 
                    ? AppColors.consultationColor 
                    : AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
          if (remaining > 0)
            Text(
              '+$remaining',
              style: TextStyle(
                fontSize: 8,
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayAppointmentsSheet extends StatelessWidget {
  final DateTime day;
  final List<AppointmentData> appointments;
  final bool isScheduled;
  final VoidCallback onAddAppointment;
  final Function(AppointmentData) onViewAppointment;

  const _DayAppointmentsSheet({
    required this.day,
    required this.appointments,
    required this.isScheduled,
    required this.onAddAppointment,
    required this.onViewAppointment,
  });

  @override
  Widget build(BuildContext context) {
    final months = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${days[day.weekday % 7]}, ${day.day} ${months[day.month]}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appointments.length} rendez-vous',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isScheduled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Planifié',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun rendez-vous ce jour',
                    style: TextStyle(
                      fontSize: 14,
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
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final apt = appointments[index];
                  return ListTile(
                    onTap: () => onViewAppointment(apt),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: apt.isConsultation 
                            ? AppColors.consultationColor.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: apt.isConsultation 
                                ? AppColors.consultationColor 
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      apt.patientName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      apt.isConsultation ? 'Consultation' : 'Rendez-vous',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(apt.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        apt.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(apt.status),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddAppointment,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un rendez-vous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmé':
      case 'confirmed':
        return AppColors.success;
      case 'en attente':
      case 'pending':
        return AppColors.warning;
      case 'annulé':
      case 'cancelled':
        return AppColors.error;
      case 'terminé':
      case 'completed':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }
}