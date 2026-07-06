import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadati/core/routing/route_names.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/widgets/buttons/primary_button.dart';
import 'package:eyadati/core/utils/supabase_client.dart';
import 'package:eyadati/features/auth/presentation/providers/auth_provider.dart';
import 'package:eyadati/features/patient/presentation/providers/doctors_provider.dart';
import 'package:eyadati/features/patient/presentation/providers/patient_provider.dart';
import 'package:eyadati/models/doctor.dart';
import 'package:eyadati/core/engine/availability_service.dart';
import 'package:eyadati/models/schedule_slot_model.dart';
import 'package:eyadati/models/appointment_data.dart';
import 'package:eyadati/services/calendar_service.dart';

class BookingPage extends ConsumerStatefulWidget {
  final String doctorId;

  const BookingPage({super.key, required this.doctorId});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _addToCalendar = true;
  int _noShowCount = 0;
  bool _noShowCheckDone = false;

  List<ValidStart> _availableSlots = [];

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    try {
      final appointmentsData = await SupabaseInitializer.client
          .from('appointments')
          .select('''
            id, scheduled_at, duration, status, is_consultation, booking_type, notes,
            patient_name_snapshot, patient_phone_snapshot
          ''')
          .eq('doctor_id', widget.doctorId)
          .gte(
            'scheduled_at',
            DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            ).toIso8601String(),
          )
          .lt(
            'scheduled_at',
            DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            ).add(const Duration(days: 1)).toIso8601String(),
          );

      final List<AppointmentData> appointments = (appointmentsData as List).map(
        (a) {
          final start = DateTime.parse(a['scheduled_at'] as String);
          final dur = a['duration'] as int;
          return AppointmentData(
            id: a['id'] as String,
            startTime: start,
            endTime: start.add(Duration(minutes: dur)),
            patientName: a['patient_name_snapshot'] as String? ?? 'Patient',
            status: a['status'] as String,
            isConsultation: a['is_consultation'] as bool? ?? false,
            duration: dur,
            bookingType: a['booking_type'] as String? ?? 'online',
          );
        },
      ).toList();

      final scheduleData = await SupabaseInitializer.client
          .from('doctor_schedule')
          .select()
          .eq('doctor_id', widget.doctorId)
          .eq('is_active', true);

      final List<ScheduleSlot> scheduleSlots = (scheduleData as List)
          .map((s) => ScheduleSlot.fromDbMap(s))
          .toList();

      final doctorData = await SupabaseInitializer.client
          .from('doctors')
          .select('consultation_duration, appointment_duration')
          .eq('id', widget.doctorId)
          .single();

      final effectiveDuration = doctorData['appointment_duration'] as int? ?? 20;

      final availabilityService = AvailabilityService(
        scheduleSlots: scheduleSlots,
        appointmentDuration: effectiveDuration,
      );

      setState(() {
        _availableSlots = availabilityService.getValidStarts(
          _selectedDate,
          appointments,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNoShowCount() async {
    final userId = SupabaseInitializer.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await SupabaseInitializer.client
          .from('appointments')
          .select('id')
          .eq('patient_id', userId)
          .eq('attendance_status', 'no_show');
      if (mounted) {
        setState(() {
          _noShowCount = (data as List).length;
          _noShowCheckDone = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _noShowCheckDone = true);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    _loadNoShowCount();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAvailability();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.isEmpty || name.length < 2) return 'DR';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool get _isBlocked => _noShowCount >= 3;

  String _reminderSubtitle() {
    if (_selectedTime == null) return 'Rappel 6h avant';
    final now = DateTime.now();
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final delta = scheduledAt.difference(now).inMinutes;
    if (delta > 420) return 'Rappel 6h avant';
    if (delta > 180) return 'Rappel 3h avant';
    if (delta > 60) return 'Rappel 1h avant';
    if (delta > 30) return 'Rappel 30min avant';
    return 'Rappel 15min avant';
  }

  Future<void> _confirmBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une heure')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final userId = authState.userId;
      final patientName = authState.userName;
      if (userId == null) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: utilisateur non connecté')),
        );
        return;
      }

      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final doctorsState = ref.read(doctorsProvider);
      final doctor = doctorsState.doctors.firstWhere(
        (d) => d.id == widget.doctorId,
        orElse: () => Doctor(
          id: widget.doctorId,
          name: 'Docteur',
          specialty: 'Spécialité',
          address: '',
        ),
      );
      final duration = doctor.appointmentDuration;

      final response = await SupabaseInitializer.client.from('appointments').insert({
        'doctor_id': widget.doctorId,
        'patient_id': userId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration': duration,
        'status': 'upcoming',
        'booking_type': 'online',
        'is_consultation': false,
        'patient_name_snapshot': patientName ?? 'Patient',
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      }).select('id');

      final newAppointmentId = (response as List).first['id'] as String;

      ref.read(patientProvider.notifier).scheduleReminders(
        appointmentId: newAppointmentId,
        scheduledAt: scheduledAt,
      );

      ref.invalidate(patientProvider);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 48,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rendez-vous confirmé !',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Votre rendez-vous a été enregistré avec succès.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _addToCalendar,
                  onChanged: (v) => setDialogState(() => _addToCalendar = v ?? true),
                  title: const Text(
                    'Ajouter au calendrier',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    _reminderSubtitle(),
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      if (_addToCalendar) {
                        final timeStr = '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
                        final reminderMinutes = CalendarService.computeReminderMinutes(scheduledAt);
                        await CalendarService.addAppointmentEvent(
                          doctorName: doctor.name,
                          timeFormatted: timeStr,
                          location: doctor.address,
                          startDate: scheduledAt,
                          durationMinutes: duration,
                          notes: _notesController.text,
                          reminderMinutes: reminderMinutes,
                        );
                      }
                      if (context.mounted) {
                        context.go(RouteNames.patientAppointments);
                      }
                    },
                    child: const Text('Voir mes rendez-vous'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorsState = ref.watch(doctorsProvider);
    final doctor = doctorsState.doctors.firstWhere(
      (d) => d.id == widget.doctorId,
      orElse: () =>
          Doctor(id: widget.doctorId, name: 'Docteur', specialty: 'Spécialité', address: ''),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prendre rendez-vous'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_noShowCheckDone && _isBlocked)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Vous avez été absent à $_noShowCount rendez-vous sans préavis. Pour réserver, veuillez contacter directement le cabinet.',
                        style: const TextStyle(fontSize: 13, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              )
            else if (_noShowCheckDone && _noShowCount == 2)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Attention : vous avez $_noShowCount absences non justifiées. Après 3 absences, vous ne pourrez plus réserver en ligne.',
                        style: const TextStyle(fontSize: 13, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      _getInitials(doctor.name),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          doctor.specialty,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Choisir une date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isToday(_selectedDate) ? AppColors.primary : AppColors.border,
                    width: _isToday(_selectedDate) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _isToday(_selectedDate) ? AppColors.primary : AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isToday(_selectedDate) ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    if (_isToday(_selectedDate)) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Aujourd\'hui',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Choisir une heure',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_availableSlots.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isToday(_selectedDate) ? Icons.access_time : Icons.event_busy,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _isToday(_selectedDate)
                            ? 'Aucun créneau disponible aujourd\'hui (délai minimum 30min)'
                            : 'Aucun créneau disponible pour cette date',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _availableSlots.map((slot) {
                final isSelected =
                    _selectedTime?.hour == (slot.minute ~/ 60) &&
                    _selectedTime?.minute == (slot.minute % 60);
                final time = TimeOfDay(
                  hour: slot.minute ~/ 60,
                  minute: slot.minute % 60,
                );
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Notes (optionnel)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ajoutez des notes pour le médecin...',
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: PrimaryButton(
            label: _isLoading ? 'En cours...' : 'Confirmer le rendez-vous',
            onPressed: _isLoading || _isBlocked ? null : _confirmBooking,
          ),
        ),
      ),
    );
  }
}
