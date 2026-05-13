import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'doctor_calendar_header.dart';
import 'doctor_calendar_grid.dart';

SupabaseClient get _supabase => Supabase.instance.client;

class DoctorCalendarView extends StatefulWidget {
  final String clinicId;
  final Map<String, dynamic>? clinicData;

  const DoctorCalendarView({
    super.key,
    required this.clinicId,
    this.clinicData,
  });

  @override
  State<DoctorCalendarView> createState() => _DoctorCalendarViewState();
}

class _DoctorCalendarViewState extends State<DoctorCalendarView> {
  DateTime _focusedDay = DateTime.now();
  bool _isWeekView = true;
  bool _isLoading = false;

  int get _duration => (widget.clinicData?['duration'] as int?) ?? 30;
  int get _consultationDuration => (widget.clinicData?['consultation_duration'] as int?) ?? 30;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DoctorCalendarHeader(
          focusedDay: _focusedDay,
          isWeekView: _isWeekView,
          onDaySelected: (day) {
            setState(() => _focusedDay = day);
          },
          onViewModeChanged: (isWeek) {
            setState(() => _isWeekView = isWeek);
          },
          onPrevious: () {
            setState(() {
              if (_isWeekView) {
                _focusedDay = _focusedDay.subtract(const Duration(days: 7));
              } else {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
              }
            });
          },
          onNext: () {
            setState(() {
              if (_isWeekView) {
                _focusedDay = _focusedDay.add(const Duration(days: 7));
              } else {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
              }
            });
          },
          onTodayPressed: () {
            setState(() => _focusedDay = DateTime.now());
          },
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : DoctorCalendarGrid(
                  clinicId: widget.clinicId,
                  focusedDay: _focusedDay,
                  isWeekView: _isWeekView,
                  onAppointmentTap: (appointment) {
                    _showAppointmentDetails(context, appointment);
                  },
                  onStatusChange: (appointment, newStatus) async {
                    await _updateAppointmentStatus(appointment.id, newStatus);
                  },
                ),
        ),
      ],
    );
  }

  void _showAppointmentDetails(BuildContext context, AppointmentData appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 12),
                  Text(
                    appointment.patientName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('phone'.tr(), appointment.phone),
              _detailRow('date'.tr(), '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}'),
              _detailRow('time'.tr(), '${appointment.date.hour}:${appointment.date.minute.toString().padLeft(2, '0')}'),
              _detailRow('status'.tr(), appointment.status),
              if (appointment.doctorName != null)
                _detailRow('doctor'.tr(), appointment.doctorName!),
              if (appointment.isConsultation)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Consultation', style: TextStyle(color: Colors.purple)),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _updateAppointmentStatus(appointment.id, 'completed');
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: Text('completed'.tr()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _updateAppointmentStatus(appointment.id, 'cancelled');
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: Text('cancel'.tr()),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': newStatus})
          .eq('id', appointmentId);
      setState(() {});
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }
}