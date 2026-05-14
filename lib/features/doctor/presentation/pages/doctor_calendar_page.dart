import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/models/appointment_data.dart';
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
      builder: (ctx) => DoctorAddAppointmentDialog(
        initialDate: day,
        initialHour: 9,
      ),
    );
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
              final hours = doctorState.getWorkingHoursForDay(day);
              return Expanded(
                child: Center(
                  child: Text(
                    '${hours}h',
                    style: const TextStyle(
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
          child: _buildDayColumn(day, doctorState),
        )),
      ],
    );
  }

  Widget _buildDayColumn(DateTime day, DoctorState doctorState) {
    final isToday = _isToday(day);
    final isScheduled = doctorState.hasScheduleForDay(day);
    final appointments = doctorState.getAppointmentsForDay(day);
    final intervalMins = doctorState.appointmentDuration;

    return GestureDetector(
      onTap: () => _showDayAppointmentsDialog(day),
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.05)
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
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2, bottom: 1),
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isToday ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            if (appointments.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 1, 2, 2),
                  child: Column(
                    children: _buildAppointmentBlocks(appointments, intervalMins),
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isScheduled
                          ? AppColors.primary.withValues(alpha: 0.2)
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

  List<Widget> _buildAppointmentBlocks(List<AppointmentData> appointments, int intervalMins) {
    final sorted = [...appointments]..sort((a, b) => a.startTime.compareTo(b.startTime));
    final maxDisplay = 4;
    final display = sorted.take(maxDisplay).toList();
    final remaining = sorted.length - maxDisplay;

    final children = <Widget>[];
    for (int i = 0; i < display.length; i++) {
      final apt = display[i];
      final ratio = apt.duration / intervalMins;
      final heightFactor = ratio.clamp(0.5, 3.0);

      final isConsult = apt.isConsultation;
      final color = isConsult ? AppColors.consultationColor : AppColors.primary;

      children.add(
        Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          height: (12 * heightFactor).clamp(10, 28),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
            border: Border(
              left: BorderSide(color: color, width: 2),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 6, fontWeight: FontWeight.w700, color: color),
              ),
              if (heightFactor >= 0.8) ...[
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    apt.patientName.split(' ').first,
                    style: TextStyle(fontSize: 6, fontWeight: FontWeight.w500, color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (remaining > 0) {
      children.add(
        Container(
          height: 12,
          alignment: Alignment.center,
          child: Text(
            '+$remaining',
            style: const TextStyle(fontSize: 7, color: AppColors.textHint, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return children;
  }

  Widget _buildAppointmentIndicators(List<AppointmentData> appointments) {
    final displayAppts = appointments.take(3).toList();
    final remaining = appointments.length - 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...displayAppts.map((apt) => Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: apt.isConsultation
                  ? AppColors.consultationColor.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.w600,
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
              style: const TextStyle(
                fontSize: 6,
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    );
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
    const months = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    const days = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 380,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.circleCheck, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Planifié',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: AppColors.textSecondary, size: 20),
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
                    Icon(LucideIcons.calendarX, size: 40, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    const Text(
                      'Aucun rendez-vous ce jour',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: apt.isConsultation
                                    ? AppColors.consultationColor.withValues(alpha: 0.15)
                                    : AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${apt.startTime.hour.toString().padLeft(2, '0')}:${apt.startTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: apt.isConsultation ? AppColors.consultationColor : AppColors.primary,
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
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    apt.isConsultation ? 'Consultation • ${apt.duration} min' : 'Rendez-vous • ${apt.duration} min',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusBg(apt.status),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _getStatusLabel(apt.status),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getStatusColor(apt.status)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textHint),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      case 'confirmed': return const Color(0xFFE8F5E9);
      case 'pending': return const Color(0xFFFFF3E0);
      case 'cancelled': return const Color(0xFFFFEBEE);
      default: return AppColors.background;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return AppColors.secondary;
      case 'pending': return const Color(0xFFFF9800);
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return 'Confirmé';
      case 'pending': return 'En attente';
      case 'cancelled': return 'Annulé';
      default: return status;
    }
  }
}