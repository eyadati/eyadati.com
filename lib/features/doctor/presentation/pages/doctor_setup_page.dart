import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/inputs/app_dropdown.dart';
import '../../../../core/widgets/feedback/app_snackbar.dart';

class DoctorSetupPage extends ConsumerStatefulWidget {
  const DoctorSetupPage({super.key});

  @override
  ConsumerState<DoctorSetupPage> createState() => _DoctorSetupPageState();
}

class _DoctorSetupPageState extends ConsumerState<DoctorSetupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<String> _weekDays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
  final Set<String> _selectedDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _consultationDuration = 30;
  int _appointmentDuration = 20;
  String? _specialty;
  String? _city;
  final _phoneController = TextEditingController();

  final List<String> _specialties = [
    'Médecin généraliste',
    'Cardiologue',
    'Dermatologue',
    'Pédiatre',
    'Gynécologue',
    'Orthopédiste',
    'Neurologue',
    'Ophtalmologue',
    'Dentiste',
    'Psychiatre',
    'Autres',
  ];

  final List<String> _cities = [
    'Casablanca',
    'Rabat',
    'Marrakech',
    'Fès',
    'Agadir',
    'Tanger',
    'Meknès',
    'Oujda',
    'Kénitra',
    'Tetouan',
    'Safí',
    'Beni Mellal',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      AppSnackbar.showError(context, message: 'Sélectionnez au moins un jour de travail');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;

      AppSnackbar.showSuccess(context, message: 'Configuration enregistrée avec succès');
      context.go(RouteNames.doctorDashboard);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, message: 'Erreur lors de la sauvegarde');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      helpText: isStart ? 'Heure de début' : 'Heure de fin',
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Configuration du cabinet',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _showExitDialog(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Complétez votre profil pour commencer à recevoir des patients.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text(
                  'Jours de travail *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _weekDays.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedDays.remove(day);
                          } else {
                            _selectedDays.add(day);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          day.substring(0, 3).toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text(
                  'Horaires de travail *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _TimeSelector(
                        label: 'Heure de début',
                        time: _formatTime(_startTime),
                        onTap: () => _selectTime(true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Icon(Icons.arrow_forward, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _TimeSelector(
                        label: 'Heure de fin',
                        time: _formatTime(_endTime),
                        onTap: () => _selectTime(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text(
                  'Durée des consultations *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [15, 20, 30, 45, 60].map((minutes) {
                    final isSelected = _consultationDuration == minutes;
                    return GestureDetector(
                      onTap: () => setState(() => _consultationDuration = minutes),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '$minutes min',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text(
                  'Durée des rendez-vous *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [10, 15, 20, 30].map((minutes) {
                    final isSelected = _appointmentDuration == minutes;
                    return GestureDetector(
                      onTap: () => setState(() => _appointmentDuration = minutes),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '$minutes min',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text(
                  'Spécialité *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppDropdown(
                  label: 'Sélectionnez votre spécialité',
                  value: _specialty,
                  items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (value) => setState(() => _specialty = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Spécialité requise';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                const Text(
                  'Ville *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppDropdown(
                  label: 'Sélectionnez votre ville',
                  value: _city,
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) => setState(() => _city = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ville requise';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  label: 'Téléphone du cabinet',
                  hint: '06 12 34 56 78',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Téléphone requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                PrimaryButton(
                  label: 'Terminer la configuration',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter la configuration ?'),
        content: const Text(
          'Vous devrez compléter votre profil avant de pouvoir utiliser l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(RouteNames.login);
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}