import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/inputs/app_dropdown.dart';
import '../providers/providers.dart';

class PatientEditProfilePage extends ConsumerStatefulWidget {
  const PatientEditProfilePage({super.key});

  @override
  ConsumerState<PatientEditProfilePage> createState() => _PatientEditProfilePageState();
}

class _PatientEditProfilePageState extends ConsumerState<PatientEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _selectedCity = '';
  bool _isLoading = false;

  static const List<String> algerianCities = [
    'Adrar', 'Ain Defla', 'Ain Temouchent', 'Alger', 'Annaba', 'Batna',
    'Bechar', 'Bejaia', 'Biskra', 'Blida', 'Bordj Bou Arreridj', 'Bouira',
    'Boumerdes', 'Chlef', 'Constantine', 'Djelfa', 'El Bayadh', 'El Oued',
    'El Tarf', 'Ghardaia', 'Guelma', 'Illizi', 'Jijel', 'Khenchela',
    'Laghouat', 'Mascara', 'Medea', 'Mila', 'Mostaganem', 'Msila',
    'Naama', 'Oran', 'Ouargla', 'Oum El Bouaghi', 'Relizane', 'Saida',
    'Setif', 'Sidi Bel Abbes', 'Skikda', 'Souk Ahras', 'Tamanghasset',
    'Tebessa', 'Tiaret', 'Tindouf', 'Tipaza', 'Tissemsilt', 'Tizi Ouzou',
    'Tlemcen',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(patientProvider);
    _nameController = TextEditingController(text: state.name);
    _phoneController = TextEditingController(text: state.phone);
    _selectedCity = state.city;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final success = await ref.read(patientProvider.notifier).updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _selectedCity,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profil mis à jour'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Erreur lors de la mise à jour'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations personnelles',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _nameController,
                label: 'Nom complet',
                hint: 'Entrez votre nom',
                prefixIcon: LucideIcons.user,
                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phoneController,
                label: 'Téléphone',
                hint: '0555 00 00 00',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<String>(
                label: 'Ville',
                hint: 'Sélectionnez votre ville',
                value: _selectedCity.isNotEmpty ? _selectedCity : null,
                items: algerianCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCity = v ?? ''),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                onPressed: _isLoading ? null : _save,
                label: 'Enregistrer',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
