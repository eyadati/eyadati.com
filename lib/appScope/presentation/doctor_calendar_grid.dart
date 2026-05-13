import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'doctor_appointment_card.dart';

SupabaseClient get _supabase => Supabase.instance.client;

class AppointmentData {
  final String id;
  final String patientName;
  final String phone;
  final DateTime date;
  final String status;
  final bool isConsultation;
  final int? duration;
  final String? doctorId;
  final String? doctorName;

  AppointmentData({
    required this.id,
    required this.patientName,
    required this.phone,
    required this.date,
    required this.status,
    this.isConsultation = false,
    this.duration,
    this.doctorId,
    this.doctorName,
  });

  factory AppointmentData.fromMap(Map<String, dynamic> map) {
    return AppointmentData(
      id: map['id']?.toString() ?? '',
      patientName: map['patient_name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      status: map['status']?.toString() ?? 'upcoming',
      isConsultation: map['is_consultation'] ?? false,
      duration: map['duration'] as int?,
      doctorId: map['doctor_id']?.toString(),
      doctorName: map['doctor_name']?.toString(),
    );
  }
}

class DoctorCalendarGrid extends StatefulWidget {
  final String clinicId;
  final DateTime focusedDay;
  final bool isWeekView;
  final Function(AppointmentData)? onAppointmentTap;
  final Function(AppointmentData, String)? onStatusChange;

  const DoctorCalendarGrid({
    super.key,
    required this.clinicId,
    required this.focusedDay,
    required this.isWeekView,
    this.onAppointmentTap,
    this.onStatusChange,
  });

  @override
  State<DoctorCalendarGrid> createState() => _DoctorCalendarGridState();
}

class _DoctorCalendarGridState extends State<DoctorCalendarGrid> {
  Map<String, List<AppointmentData>> _appointmentsByDay = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void didUpdateWidget(DoctorCalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedDay != widget.focusedDay || 
        oldWidget.clinicId != widget.clinicId ||
        oldWidget.isWeekView != widget.isWeekView) {
      _loadAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    
    try {
      DateTime startDate;
      DateTime endDate;

      if (widget.isWeekView) {
        final weekStart = widget.focusedDay.subtract(Duration(days: widget.focusedDay.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = startDate.add(const Duration(days: 7));
      } else {
        startDate = DateTime(widget.focusedDay.year, widget.focusedDay.month, 1);
        endDate = DateTime(widget.focusedDay.year, widget.focusedDay.month + 1, 0);
      }

      final response = await _supabase
          .from('appointments')
          .select()
          .eq('clinic_id', widget.clinicId)
          .gte('date', startDate.toIso8601String())
          .lt('date', endDate.toIso8601String())
          .order('date');

      final Map<String, List<AppointmentData>> grouped = {};
      
      for (var doc in response) {
        final apt = AppointmentData.fromMap(doc);
        final dayKey = '${apt.date.year}-${apt.date.month.toString().padLeft(2, '0')}-${apt.date.day.toString().padLeft(2, '0')}';
        
        if (!grouped.containsKey(dayKey)) {
          grouped[dayKey] = [];
        }
        grouped[dayKey]!.add(apt);
      }

      if (mounted) {
        setState(() {
          _appointmentsByDay = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DateTime> _getDaysToShow() {
    if (widget.isWeekView) {
      final weekStart = widget.focusedDay.subtract(Duration(days: widget.focusedDay.weekday - 1));
      return List.generate(7, (i) => weekStart.add(Duration(days: i)));
    } else {
      final firstDay = DateTime(widget.focusedDay.year, widget.focusedDay.month, 1);
      final lastDay = DateTime(widget.focusedDay.year, widget.focusedDay.month + 1, 0);
      return List.generate(lastDay.day, (i) => firstDay.add(Duration(days: i)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysToShow();
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        if (isWide && widget.isWeekView) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: days.map((day) {
              return Expanded(
                child: _buildDayColumn(day, theme),
              );
            }).toList(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: days.length,
          itemBuilder: (context, index) {
            return _buildDayCard(days[index], theme);
          },
        );
      },
    );
  }

  Widget _buildDayColumn(DateTime day, ThemeData theme) {
    final dayKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final dayAppointments = _appointmentsByDay[dayKey] ?? [];
    final isToday = _isToday(day);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(8),
        color: isToday ? theme.colorScheme.primaryContainer.withAlpha(30) : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isToday ? theme.colorScheme.primary : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Column(
                children: [
                  Text(
                    _getWeekdayName(day.weekday),
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isToday ? theme.colorScheme.onPrimary : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: dayAppointments.length,
              itemBuilder: (context, index) {
                return DoctorAppointmentCard(
                  appointment: {
                    'id': dayAppointments[index].id,
                    'patient_name': dayAppointments[index].patientName,
                    'phone': dayAppointments[index].phone,
                    'date': dayAppointments[index].date.toIso8601String(),
                    'status': dayAppointments[index].status,
                    'is_consultation': dayAppointments[index].isConsultation,
                    'doctor_name': dayAppointments[index].doctorName,
                  },
                  onTap: () => widget.onAppointmentTap?.call(dayAppointments[index]),
                );
              },
            ),
          ),
          if (_hasMultipleDoctors(dayAppointments))
            Padding(
              padding: const EdgeInsets.all(4),
              child: _buildDoctorAvatarsRow(dayAppointments),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DateTime day, ThemeData theme) {
    final dayKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final dayAppointments = _appointmentsByDay[dayKey] ?? [];
    final isToday = _isToday(day);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isToday ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_getWeekdayName(day.weekday)}, ${day.day} ${_getMonthName(day.month)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? theme.colorScheme.onPrimary : null,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${dayAppointments.length} ${'appointments'.tr()}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (dayAppointments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.calendarOff, size: 32, color: theme.colorScheme.outline),
                      const SizedBox(height: 8),
                      Text(
                        'no_appointments'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...dayAppointments.map((apt) => DoctorAppointmentCard(
                appointment: {
                  'id': apt.id,
                  'patient_name': apt.patientName,
                  'phone': apt.phone,
                  'date': apt.date.toIso8601String(),
                  'status': apt.status,
                  'is_consultation': apt.isConsultation,
                  'doctor_name': apt.doctorName,
                },
                onTap: () => widget.onAppointmentTap?.call(apt),
                onComplete: apt.status == 'upcoming' 
                    ? () => widget.onStatusChange?.call(apt, 'completed')
                    : null,
                onCancel: apt.status == 'upcoming'
                    ? () => widget.onStatusChange?.call(apt, 'cancelled')
                    : null,
                onAbsent: apt.status == 'upcoming'
                    ? () => widget.onStatusChange?.call(apt, 'absent')
                    : null,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAvatarsRow(List<AppointmentData> appointments) {
    final doctors = <String, int>{};
    for (var apt in appointments) {
      if (apt.doctorName != null) {
        doctors[apt.doctorName!] = (doctors[apt.doctorName!] ?? 0) + 1;
      }
    }

    if (doctors.length <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: doctors.entries.take(3).map((e) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Text(
            e.key.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  bool _hasMultipleDoctors(List<AppointmentData> appointments) {
    final doctors = <String>{};
    for (var apt in appointments) {
      if (apt.doctorName != null) {
        doctors.add(apt.doctorName!);
      }
    }
    return doctors.length > 1;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getWeekdayName(int weekday) {
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[weekday - 1].tr();
  }

  String _getMonthName(int month) {
    final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    return months[month - 1].tr();
  }
}