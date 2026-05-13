import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/widgets/buttons/primary_button.dart';
import 'package:eyadati/core/widgets/inputs/app_text_field.dart';
import '../providers/doctor_provider.dart';
import 'package:eyadati/models/schedule_slot_model.dart';

class DoctorAddAppointmentDialog extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final int initialHour;

  const DoctorAddAppointmentDialog({
    super.key,
    required this.initialDate,
    required this.initialHour,
  });

  @override
  ConsumerState<DoctorAddAppointmentDialog> createState() => _DoctorAddAppointmentDialogState();
}

class _DoctorAddAppointmentDialogState extends ConsumerState<DoctorAddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _selectedSlot;
  List<ScheduleSlot> _loadedSlots = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlotsForCurrentDay());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSlotsForCurrentDay() async {
    final dayOfWeek = _selectedDate.weekday % 7;
    await ref.read(doctorProvider.notifier).loadScheduleForDay(dayOfWeek);
    if (mounted) {
      setState(() {
        _loadedSlots = ref.read(doctorProvider).scheduleSlots;
      });
    }
  }

  int _getDayOfWeek(DateTime date) {
    final day = date.weekday;
    return day == 7 ? 0 : day;
  }

  List<TimeOfDay> _computeAvailableSlots(List<ScheduleSlot> slots, int interval) {
    final dayOfWeek = _getDayOfWeek(_selectedDate);
    final daySlots = slots.where((s) => s.dayOfWeek == dayOfWeek).toList();

    if (daySlots.isEmpty) return [];

    final List<TimeOfDay> available = [];
    for (final slot in daySlots) {
      final cleanStart = slot.startTime.split('.').first;
      final cleanEnd = slot.endTime.split('.').first;
      final startParts = cleanStart.split(':');
      final endParts = cleanEnd.split(':');
      
      int startMinutes;
      int endMinutes;
      
      try {
        startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      } catch (e) {
        continue;
      }

      for (int m = startMinutes; m + interval <= endMinutes; m += interval) {
        available.add(TimeOfDay(hour: m ~/ 60, minute: m % 60));
      }
    }

    available.sort((a, b) {
      final aMins = a.hour * 60 + a.minute;
      final bMins = b.hour * 60 + b.minute;
      return aMins.compareTo(bMins);
    });

    return available;
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
      final dayOfWeek = _getDayOfWeek(picked);
      await ref.read(doctorProvider.notifier).loadScheduleForDay(dayOfWeek);
      if (mounted) {
        setState(() {
          _loadedSlots = ref.read(doctorProvider).scheduleSlots;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner un créneau', style: TextStyle(color: AppColors.white)),
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

    final success = await ref.read(doctorProvider.notifier).createAppointment(
      scheduledAt: scheduledAt,
      patientName: _nameController.text.trim(),
      patientPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rendez-vous créé', style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création', style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorProvider);
    final slots = _computeAvailableSlots(_loadedSlots, doctorState.appointmentDuration);

    return Dialog(
      backgroundColor: AppColors.white,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nouveau rendez-vous',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
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
                prefixIcon: Icons.person_outline,
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
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Date',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
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
                      Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(_selectedDate),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Créneau horaire',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              if (doctorState.isLoading)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chargement des créneaux...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: AppColors.textSecondary,
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
                      Icon(Icons.info_outline, size: 16, color: AppColors.textHint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aucun créneau disponible pour ce jour',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 2,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final isSelected = _selectedSlot?.hour == slot.hour && _selectedSlot?.minute == slot.minute;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSlot = slot),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12,
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
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                onPressed: doctorState.isLoading ? null : _save,
                label: 'Créer le rendez-vous',
              ),
            ],
          ),
        ),
      ),
    );
  }
}