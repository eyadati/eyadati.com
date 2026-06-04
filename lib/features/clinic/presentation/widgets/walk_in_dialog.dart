import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import '../providers/clinic_provider.dart';
import '../../data/clinic_booking_service.dart';

class WalkInDialog extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final List<ClinicGroupMember> members;
  final String? lastSelectedDoctorId;
  final String? suggestedDoctorId;

  const WalkInDialog({
    super.key,
    required this.initialDate,
    required this.members,
    this.lastSelectedDoctorId,
    this.suggestedDoctorId,
  });

  @override
  ConsumerState<WalkInDialog> createState() => _WalkInDialogState();
}

class _WalkInDialogState extends ConsumerState<WalkInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedDoctorId;
  int _duration = 20;
  bool _isConsultation = false;
  bool _isLoading = false;
  String? _realtimeWarning;
  bool? _slotValid;
  bool _revalidating = false;
  int _appointmentSnapshotHash = 0;
  int _memberSnapshotHash = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDate);
    _initDoctorSelection();
    _appointmentSnapshotHash = _computeAppointmentHash();
    _memberSnapshotHash = _computeMemberHash();
    _revalidateSlot();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });
  }

  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _submitFocusNode = FocusNode();

  void _initDoctorSelection() {
    final available = widget.members.where((m) => m.isAvailable).toList();
    if (widget.lastSelectedDoctorId != null &&
        available.any((m) => m.doctorId == widget.lastSelectedDoctorId)) {
      _selectedDoctorId = widget.lastSelectedDoctorId;
    } else if (widget.suggestedDoctorId != null &&
        available.any((m) => m.doctorId == widget.suggestedDoctorId)) {
      _selectedDoctorId = widget.suggestedDoctorId;
    } else if (available.isNotEmpty) {
      _selectedDoctorId = available.first.doctorId;
    } else if (widget.members.isNotEmpty) {
      _selectedDoctorId = widget.members.first.doctorId;
    }
  }

  int _computeAppointmentHash() {
    final state = ref.read(clinicProvider);
    return state.appointments
        .map((a) => '${a.id}:${a.status}:${a.startTime}')
        .join(',')
        .hashCode;
  }

  int _computeMemberHash() {
    return widget.members
        .map((m) => '${m.doctorId}:${m.isAvailable}')
        .join(',')
        .hashCode;
  }

  void _checkForChanges() {
    if (!mounted) return;
    final newHash = _computeAppointmentHash();
    final newMemberHash = _computeMemberHash();
    if (newHash != _appointmentSnapshotHash || newMemberHash != _memberSnapshotHash) {
      _appointmentSnapshotHash = newHash;
      _memberSnapshotHash = newMemberHash;
      setState(() {
        _realtimeWarning = 'Modification détectée. Vérifiez la disponibilité du créneau.';
        _slotValid = null;
      });
    }
  }

  Map<String, int> _computeDayAppointmentCounts() {
    final state = ref.read(clinicProvider);
    final counts = <String, int>{};
    for (final apt in state.appointments) {
      if (apt.startTime.year == _selectedDate.year &&
          apt.startTime.month == _selectedDate.month &&
          apt.startTime.day == _selectedDate.day &&
          apt.status != 'cancelled') {
        counts[apt.doctorId] = (counts[apt.doctorId] ?? 0) + 1;
      }
    }
    return counts;
  }

  void _revalidateSlot() {
    if (_selectedDoctorId == null) return;
    setState(() => _revalidating = true);
    final state = ref.read(clinicProvider);
    final error = ClinicBookingService.validateWalkInSlot(
      members: state.members,
      appointments: state.appointments,
      doctorId: _selectedDoctorId!,
      scheduledAt: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      duration: _duration,
    );
    setState(() {
      _slotValid = error == null;
      _revalidating = false;
      _realtimeWarning = null;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctorId == null) return;

    setState(() => _isLoading = true);

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      await ref.read(clinicProvider.notifier).createWalkIn(
        doctorId: _selectedDoctorId!,
        patientName: _nameCtrl.text.trim(),
        patientPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        scheduledAt: scheduledAt,
        duration: _duration,
        isConsultation: _isConsultation,
      );

      ref.read(clinicProvider.notifier).lastSelectedDoctorId = _selectedDoctorId;

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rendez-vous créé', style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is Exception
            ? e.toString().replaceFirst(RegExp(r'^(Exception|Error):?\s*'), '')
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ClinicState>(clinicProvider, (previous, next) {
      _checkForChanges();
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Nouveau rendez-vous', style: AppTextStyles.sectionTitle),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (_realtimeWarning != null || _slotValid != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _slotValid == true
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _slotValid == true
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _slotValid == true
                            ? LucideIcons.checkCircle
                            : LucideIcons.alertTriangle,
                        size: 16,
                        color: _slotValid == true ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _slotValid == true
                              ? 'Créneau disponible'
                              : (_realtimeWarning ?? 'Vérifiez la disponibilité du créneau'),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _slotValid == true ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_slotValid == false || _realtimeWarning != null) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            onPressed: _revalidating ? null : _revalidateSlot,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              textStyle: AppTextStyles.badge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: _revalidating
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.white,
                                    ),
                                  )
                                : const Text('Vérifier'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text('Médecin', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(
                    '${widget.members.where((m) => m.isAvailable).length}/${widget.members.length} disponibles',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: () {
                  final dayApptCounts = _computeDayAppointmentCounts();
                  return widget.members.map((m) {
                  final unavailable = !m.isAvailable;
                  final isSelected = _selectedDoctorId == m.doctorId;
                  final isSuggested = widget.suggestedDoctorId == m.doctorId && !unavailable;
                  final dayCount = dayApptCounts[m.doctorId] ?? 0;

                  return GestureDetector(
                    onTap: unavailable ? null : () {
                      setState(() => _selectedDoctorId = m.doctorId);
                      _revalidateSlot();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: (MediaQuery.of(context).size.width - 48) / 2 - 12,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? m.color.withValues(alpha: 0.1)
                            : unavailable
                                ? AppColors.border.withValues(alpha: 0.3)
                                : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? m.color
                              : unavailable
                                  ? AppColors.border.withValues(alpha: 0.5)
                                  : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: unavailable ? AppColors.textSecondary : m.color,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: isSelected
                                ? const Icon(LucideIcons.check, size: 18, color: Colors.white)
                                : Text(
                                    m.doctorName.isNotEmpty ? m.doctorName[0].toUpperCase() : 'D',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            m.doctorName,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: unavailable ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (isSuggested) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Suggestions',
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.success,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (!unavailable && dayCount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$dayCount RDV',
                              style: AppTextStyles.badge.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                          if (unavailable && m.unavailabilityReason != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              m.unavailabilityReason!,
                              style: AppTextStyles.badge.copyWith(
                                color: AppColors.error,
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList();
              }(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Patient', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                focusNode: _nameFocusNode,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Nom du patient',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Téléphone (optionnel)', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                focusNode: _phoneFocusNode,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Numéro de téléphone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                              _revalidateSlot();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.white,
                            ),
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Heure', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (time != null) {
                              setState(() => _selectedTime = time);
                              _revalidateSlot();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.white,
                            ),
                            child: Text(
                              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Type', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('RDV'), icon: Icon(LucideIcons.user, size: 16)),
                  ButtonSegment(value: true, label: Text('Visio'), icon: Icon(LucideIcons.video, size: 16)),
                ],
                selected: {_isConsultation},
                onSelectionChanged: (v) {
                  setState(() => _isConsultation = v.first);
                  _revalidateSlot();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Durée', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [10, 20, 30, 40, 50, 60].map((d) {
                  final selected = _duration == d;
                  return ChoiceChip(
                    label: Text('$d min'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _duration = d);
                      _revalidateSlot();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Text('Créer le rendez-vous', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
