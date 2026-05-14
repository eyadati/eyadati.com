import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/theme/text_styles.dart';
import 'package:eyadati/core/widgets/buttons/primary_button.dart';
import 'package:eyadati/core/widgets/inputs/app_text_field.dart';
import '../providers/doctor_provider.dart';

class DoctorAddAppointmentDialog extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final int initialHour;

  const DoctorAddAppointmentDialog({
    super.key,
    required this.initialDate,
    required this.initialHour,
  });

  @override
  ConsumerState<DoctorAddAppointmentDialog> createState() =>
      _DoctorAddAppointmentDialogState();
}

class _DoctorAddAppointmentDialogState
    extends ConsumerState<DoctorAddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _selectedSlot = null;
      });
    }
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner un créneau',
            style: TextStyle(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedSlot!.hour,
      _selectedSlot!.minute,
    );

    final selectedSlotMinutes = _selectedSlot!.hour * 60 + _selectedSlot!.minute;
    final doctorState = ref.read(doctorProvider);
    final endMinutes = selectedSlotMinutes + doctorState.appointmentDuration;
    final conflicts = doctorState.allAppointments.where((apt) {
      if (apt.startTime.year != _selectedDate.year ||
          apt.startTime.month != _selectedDate.month ||
          apt.startTime.day != _selectedDate.day) return false;
      final aptStart = apt.startTime.hour * 60 + apt.startTime.minute;
      final aptEnd = apt.startTime.hour * 60 + apt.startTime.minute + apt.duration;
      return selectedSlotMinutes < aptEnd && endMinutes > aptStart;
    }).toList();

    if (conflicts.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ce créneau est déjà occupé par ${conflicts.first.patientName}',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    final success = await ref
        .read(doctorProvider.notifier)
        .createAppointment(
          scheduledAt: scheduledAt,
          patientName: _nameController.text.trim(),
          patientPhone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rendez-vous créé',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la création',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final hasSchedule = doctorState.hasScheduleForDay(_selectedDate);
    final slots = doctorState.getAvailableSlotsForDay(_selectedDate);

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nouveau rendez-vous', style: AppTextStyles.sectionTitle),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _nameController,
                  label: 'Nom du patient',
                  hint: 'Entrez le nom',
                  prefixIcon: LucideIcons.user,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phoneController,
                  label: 'Téléphone',
                  hint: 'Entrez le numéro',
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Date', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(_selectedDate),
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Créneau horaire', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                if (!hasSchedule)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.calendarX,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pas de planning pour ce jour',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w300),
                            ),
                          ),
                      ],
                    ),
                  )
                else if (slots.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Aucun créneau disponible pour ce jour',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w300),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 110),
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final isSelected =
                            _selectedSlot?.hour == slot.startTime.hour &&
                            _selectedSlot?.minute == slot.startTime.minute;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedSlot = TimeOfDay(
                              hour: slot.startTime.hour,
                              minute: slot.startTime.minute,
                            );
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(onPressed: _save, label: 'Créer le rendez-vous'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
