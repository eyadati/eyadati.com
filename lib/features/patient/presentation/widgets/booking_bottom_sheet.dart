import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/utils/supabase_client.dart';
import '../../../../core/engine/availability_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:eyadati/models/doctor.dart';
import 'package:eyadati/models/schedule_slot_model.dart';
import 'package:eyadati/models/appointment_data.dart';
import '../providers/patient_provider.dart';
import 'package:eyadati/l10n/app_localizations.dart';

class BookingBottomSheet extends ConsumerStatefulWidget {
  final Doctor doctor;

  const BookingBottomSheet({super.key, required this.doctor});

  @override
  ConsumerState<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends ConsumerState<BookingBottomSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedSlot;
  bool _isLoading = false;
  int _noShowCount = 0;
  bool _noShowCheckDone = false;
  double? _attendanceRate;
  bool _hasSufficientHistory = false;
  String? _doctorPhone;
  List<ValidStart> _availableSlots = [];

  List<DateTime> get _next14Days {
    final today = DateTime.now();
    return List.generate(
      14,
      (index) => DateTime(today.year, today.month, today.day + index + 1),
    );
  }

  Future<void> _loadNoShowCount() async {
    final userId = SupabaseInitializer.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final attendanceData = await SupabaseInitializer.client
          .from('appointments')
          .select('attendance_status')
          .eq('patient_id', userId)
          .not('attendance_status', 'is', null);

      int present = 0;
      int noShow = 0;
      for (final row in attendanceData as List) {
        final status = row['attendance_status'] as String;
        if (status == 'present') present++;
        else if (status == 'no_show') noShow++;
      }

      final profileData = await SupabaseInitializer.client
          .from('profiles')
          .select('phone')
          .eq('id', widget.doctor.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _noShowCount = noShow;
          final total = present + noShow;
          _hasSufficientHistory = total >= 3;
          if (total > 0) {
            _attendanceRate = (present + 1.0) / (total + 1.0);
          } else {
            _attendanceRate = null;
          }
          _doctorPhone = profileData?['phone'] as String?;
          _noShowCheckDone = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _noShowCheckDone = true);
    }
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final appointmentsData = await SupabaseInitializer.client
          .from('appointments')
          .select('''
            id, scheduled_at, duration, status, is_consultation, booking_type, notes,
            patient_name_snapshot, patient_phone_snapshot
          ''')
          .eq('doctor_id', widget.doctor.id)
          .gte('scheduled_at', DateTime(date.year, date.month, date.day).toIso8601String())
          .lt('scheduled_at', DateTime(date.year, date.month, date.day).add(const Duration(days: 1)).toIso8601String());

      final List<AppointmentData> appointments = (appointmentsData as List).map((a) {
        final start = DateTime.parse(a['scheduled_at'] as String);
        final dur = a['duration'] as int;
        return AppointmentData(
          id: a['id'] as String,
          startTime: start,
          endTime: start.add(Duration(minutes: dur)),
          patientName: a['patient_name_snapshot'] as String? ?? l10n.rolePatient,
          status: a['status'] as String,
          isConsultation: a['is_consultation'] as bool? ?? false,
          duration: dur,
          bookingType: a['booking_type'] as String? ?? 'online',
        );
      }).toList();

      final scheduleData = await SupabaseInitializer.client
          .from('doctor_schedule')
          .select()
          .eq('doctor_id', widget.doctor.id)
          .eq('is_active', true);

      final List<ScheduleSlot> scheduleSlots = (scheduleData as List)
          .map((s) => ScheduleSlot.fromDbMap(s))
          .toList();

      final doctorData = await SupabaseInitializer.client
          .from('doctors')
          .select('consultation_duration, appointment_duration')
          .eq('id', widget.doctor.id)
          .single();

      final effectiveDuration = (doctorData['appointment_duration'] as int? ?? 20);

      final availabilityService = AvailabilityService(
        scheduleSlots: scheduleSlots,
        appointmentDuration: effectiveDuration,
      );

      setState(() {
        _availableSlots = availabilityService.getValidStarts(date, appointments);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _availableSlots = [];
        _isLoading = false;
      });
    }
  }

  bool get _isBlocked => _noShowCount >= 3 || (_attendanceRate != null && _attendanceRate! < 0.50);

  Widget _buildAttendanceRateBar(double rate) {
    final l10n = AppLocalizations.of(context)!;
    final pct = (rate * 100).round();
    final Color barColor;
    if (rate > 0.75) {
      barColor = const Color(0xFF16A34A);
    } else if (rate >= 0.50) {
      barColor = const Color(0xFFD97706);
    } else {
      barColor = const Color(0xFFDC2626);
    }
    final String label;
    if (rate > 0.75) {
      label = l10n.attendanceGood;
    } else if (rate >= 0.50) {
      label = l10n.attendanceAverage;
    } else {
      label = l10n.attendanceLow;
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: barColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: barColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: barColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.bookingReliabilityLabel(pct, label),
              style: TextStyle(fontSize: 11, color: barColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bookingSelectDateError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final userId = authState.userId;
      final patientName = authState.userName;

      if (userId == null) {
        throw Exception(l10n.bookingUserNotConnectedError);
      }

      final scheduledAt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedSlot!.hour,
        _selectedSlot!.minute,
      );

      final duration = widget.doctor.appointmentDuration;

      final response = await SupabaseInitializer.client.from('appointments').insert({
        'doctor_id': widget.doctor.id,
        'patient_id': userId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration': duration,
        'status': 'upcoming',
        'booking_type': 'online',
        'patient_name_snapshot': (patientName?.isNotEmpty == true) ? patientName! : l10n.rolePatient,
      }).select('id');

      final newAppointmentId = (response as List).first['id'] as String;

      ref.read(patientProvider.notifier).scheduleReminders(
        appointmentId: newAppointmentId,
        scheduledAt: scheduledAt,
      );

      ref.invalidate(patientProvider);

      if (!mounted) return;

      Navigator.pop(context);
      Navigator.pop(context);

      _showSuccessDialog(scheduledAt, duration);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bookingError(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog(DateTime scheduledAt, int duration) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 48,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.bookingSuccess,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.bookingSuccessWithDoctor(widget.doctor.name),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: l10n.bookingBackHome,
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadNoShowCount();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Center(
                        child: Text(
                          widget.doctor.name.isNotEmpty
                              ? widget.doctor.name.substring(0, 2).toUpperCase()
                              : 'DR',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.doctor.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.doctor.specialty,
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
                if (_hasSufficientHistory && _attendanceRate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: _buildAttendanceRateBar(_attendanceRate!),
                  ),
                if (_noShowCheckDone && _isBlocked)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.block, color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.bookingUnavailableTitle,
                                  style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.bookingUnavailableMessage,
                            style: TextStyle(fontSize: 11, color: AppColors.error),
                          ),
                          if (_doctorPhone != null) ...[
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.phone, size: 14),
                                label: Text(l10n.bookingCallOffice, style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size.fromHeight(32),
                                ),
                                onPressed: () => launchUrl(Uri.parse('tel:$_doctorPhone')),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else if (_noShowCheckDone && _noShowCount == 2)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.bookingWarningMessage(_noShowCount),
                              style: const TextStyle(fontSize: 11, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bookingSelectDate,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _next14Days.length,
                    itemBuilder: (context, index) {
                      final date = _next14Days[index];
                      final isSelected = _selectedDate != null &&
                          date.year == _selectedDate!.year &&
                          date.month == _selectedDate!.month &&
                          date.day == _selectedDate!.day;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _selectedSlot = null;
                          });
                          _loadSlotsForDate(date);
                        },
                        child: Container(
                          width: 56,
                          margin: const EdgeInsets.only(right: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('EEE').format(date).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd').format(date),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                DateFormat('MMM').format(date),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? AppColors.white.withValues(alpha: 0.8)
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_selectedDate != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bookingSelectTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _availableSlots.isEmpty
                              ? Center(
                                  child: Text(
                                    l10n.bookingNoSlotsAvailable,
                                    style: TextStyle(color: AppColors.textHint),
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    childAspectRatio: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: _availableSlots.length,
                                  itemBuilder: (context, index) {
                                    final slot = _availableSlots[index];
                                    final slotTime = TimeOfDay(
                                      hour: slot.minute ~/ 60,
                                      minute: slot.minute % 60,
                                    );
                                    final isSelected = _selectedSlot != null &&
                                        _selectedSlot!.hour == slotTime.hour &&
                                        _selectedSlot!.minute == slotTime.minute;

                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedSlot = slotTime),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.background,
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.border,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${slotTime.hour.toString().padLeft(2, '0')}:${slotTime.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.white
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  l10n.bookingSelectDateHint,
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          Container(
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
                label: _isLoading
                    ? l10n.bookingLoading
                    : l10n.bookingConfirmButton,
                isLoading: _isLoading,
                onPressed: _selectedDate != null && _selectedSlot != null && !_isBlocked
                    ? _confirmBooking
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
