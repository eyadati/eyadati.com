import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/inputs/app_dropdown.dart';
import '../../../../core/widgets/feedback/app_snackbar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/doctor_provider.dart';

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
  final _addressController = TextEditingController();

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
    'Alger', 'Oran', 'Constantine', 'Annaba', 'Blida', 'Batna', 'Djelfa',
    'Sétif', 'Sidi Bel Abbès', 'Biskra', 'Tébessa', 'Ouargla', 'Béjaïa',
    'Tlemcen', 'Béchar', 'Mascara', 'Tiaret', 'Bordj Bou Arréridj',
    'Souk Ahras', 'Mila', 'Skikda', 'Bouira', 'Médéa', 'Laghouat',
    'Ghardaia', 'Relizane', 'El Oued', 'Khenchela', 'Msila', 'BBA',
    'Boumerdès', 'Sidi Aïssa', 'Tipaza', 'Aïn Témouchent', 'Bejaïa',
    'Tizi Ouzou', 'Bouira', 'Djurdjura', 'Médéa', 'Blida', 'Cherchell',
    'Tipasa', 'Mascara', 'Saïda', 'Tafraoui', 'Moulay Slissen',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String _formatTimeForDb(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      AppSnackbar.showError(context, message: 'Sélectionnez au moins un jour de travail');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('[DoctorSetupPage] Starting setup submission...');
      
      await ref.read(doctorProvider.notifier).saveSetup(
        workingDays: _selectedDays.toList(),
        startTime: _formatTimeForDb(_startTime),
        endTime: _formatTimeForDb(_endTime),
        consultationDuration: _consultationDuration,
        appointmentDuration: _appointmentDuration,
        specialty: _specialty!,
        city: _city!,
        address: _addressController.text.trim(),
      );

      print('[DoctorSetupPage] Setup saved, checking state...');

      if (!mounted) return;

      final authState = ref.read(authProvider);
      print('[DoctorSetupPage] Auth state after save - setupCompleted: ${authState.setupCompleted}');
      
      final doctorState = ref.read(doctorProvider);
      print('[DoctorSetupPage] Doctor state - setupCompleted: ${doctorState.setupCompleted}');

      if (!mounted) return;

      if (doctorState.setupCompleted) {
        AppSnackbar.showSuccess(context, message: 'Configuration enregistrée !');
        
        print('[DoctorSetupPage] Refreshing setup status...');
        await ref.read(authProvider.notifier).refreshSetupStatus();
        
        if (!mounted) return;
        
        final updatedAuthState = ref.read(authProvider);
        print('[DoctorSetupPage] Updated auth state - setupCompleted: ${updatedAuthState.setupCompleted}');
        
        if (updatedAuthState.setupCompleted) {
          print('[DoctorSetupPage] Navigating to dashboard...');
          context.go('/doctor/dashboard');
        } else {
          print('[DoctorSetupPage] Setup still not completed after refresh');
          AppSnackbar.showError(context, message: 'Erreur lors de la configuration');
        }
      } else {
        print('[DoctorSetupPage] Setup not marked as completed, showing error');
        AppSnackbar.showError(context, message: 'Erreur lors de la configuration');
      }
    } catch (e) {
      print('[DoctorSetupPage] Error: $e');
      if (!mounted) return;
      AppSnackbar.showError(context, message: 'Erreur: $e');
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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoBanner(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionCard(
                          title: 'Horaires de travail',
                          icon: Icons.schedule_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('Jours de travail'),
                              const SizedBox(height: AppSpacing.sm),
                              _buildDaySelector(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildSectionLabel('Heures'),
                              const SizedBox(height: AppSpacing.sm),
                              _buildTimeSelectors(),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSectionCard(
                          title: 'Durées de consultation',
                          icon: Icons.timer_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('Durée des consultations'),
                              const SizedBox(height: AppSpacing.sm),
                              _buildDurationSelector(
                                options: [15, 20, 30, 45, 60],
                                selected: _consultationDuration,
                                onChanged: (v) => setState(() => _consultationDuration = v),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _buildSectionLabel('Durée des rendez-vous'),
                              const SizedBox(height: AppSpacing.sm),
                              _buildDurationSelector(
                                options: [10, 15, 20, 30],
                                selected: _appointmentDuration,
                                onChanged: (v) => setState(() => _appointmentDuration = v),
                                isSecondary: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSectionCard(
                          title: 'Informations du cabinet',
                          icon: Icons.local_hospital_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppDropdown(
                                label: 'Spécialité',
                                value: _specialty,
                                items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (value) => setState(() => _specialty = value),
                                validator: (value) => value == null || value.isEmpty ? 'Spécialité requise' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                label: 'Adresse du cabinet',
                                hint: '123 Rue Didouche Mourad, Alger Centre',
                                controller: _addressController,
                                keyboardType: TextInputType.streetAddress,
                                prefixIcon: Icons.location_on_outlined,
                                validator: (value) => value == null || value.isEmpty ? 'Adresse requise' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppDropdown(
                                label: 'Ville',
                                value: _city,
                                items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (value) => setState(() => _city = value),
                                validator: (value) => value == null || value.isEmpty ? 'Ville requise' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            label: 'Terminer la configuration',
                            isLoading: _isLoading,
                            onPressed: _handleSubmit,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showExitDialog(),
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Configuration du cabinet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Complétez votre profil pour commencer à recevoir des patients.',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildDaySelector() {
    return Wrap(
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              day.substring(0, 3).toUpperCase(),
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSelectors() {
    return Row(
      children: [
        Expanded(
          child: _TimeSelector(
            label: 'Début',
            time: _formatTime(_startTime),
            onTap: () => _selectTime(true),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Icon(Icons.arrow_forward, color: AppColors.textHint, size: 16),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TimeSelector(
            label: 'Fin',
            time: _formatTime(_endTime),
            onTap: () => _selectTime(false),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector({
    required List<int> options,
    required int selected,
    required ValueChanged<int> onChanged,
    bool isSecondary = false,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((minutes) {
        final isSelected = selected == minutes;
        final color = isSecondary ? AppColors.secondary : AppColors.primary;
        return GestureDetector(
          onTap: () => onChanged(minutes),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : AppColors.border,
              ),
            ),
            child: Text(
              '$minutes min',
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 15,
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
