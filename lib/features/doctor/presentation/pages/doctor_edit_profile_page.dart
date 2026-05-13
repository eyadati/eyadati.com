import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/widgets/buttons/primary_button.dart';
import 'package:eyadati/core/widgets/inputs/app_text_field.dart';
import 'package:eyadati/core/widgets/inputs/app_dropdown.dart';
import '../providers/doctor_provider.dart';
import '../../../../core/utils/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorEditProfilePage extends ConsumerStatefulWidget {
  const DoctorEditProfilePage({super.key});

  @override
  ConsumerState<DoctorEditProfilePage> createState() => _DoctorEditProfilePageState();
}

class _DoctorEditProfilePageState extends ConsumerState<DoctorEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String _selectedCity = '';
  String _selectedSpecialty = '';
  bool _isLoading = false;

  final List<String> _algerianCities = [
    'Alger', 'Oran', 'Constantine', 'Annaba', 'Blida', 'Batna', 'Djelfa',
    'Sétif', 'Saïda', 'Sidi Bel Abbès', 'Biskra', 'Tébessa', 'Ouargla',
    'Kénitra', 'Tlemcen', 'Béjaïa', 'Adrar', 'Mostaganem', 'Souk Ahras',
    'Médéa', 'Tizi Ouzou', 'Boumahdes', 'Mosta', 'Skikda', 'Souk Ahras',
    'Jijel', 'Alger', 'Blida', 'Bouira', 'Tizi Ouzou', 'Boumerdès',
  ];

  final List<String> _specialties = [
    'Médecin généraliste',
    'Cardiologue',
    'Dermatologue',
    'Pédiatre',
    'Gynécologue',
    'Orthopédiste',
    'Neurologue',
    'Ophtalmologue',
    'Psychiatre',
    'Dentiste',
    'Ostéopathe',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(doctorProvider);
    _nameController = TextEditingController(text: state.name);
    _phoneController = TextEditingController(text: state.phone);
    _addressController = TextEditingController(text: '');
    _selectedCity = state.city;
    _selectedSpecialty = state.specialty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(doctorProvider).userId;
      if (userId == null) throw Exception('Not authenticated');

      final client = SupabaseInitializer.client;

      await client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }).eq('id', userId);

      await client.from('doctors').update({
        'specialty': _selectedSpecialty,
        'city': _selectedCity,
      }).eq('id', userId);

      await ref.read(doctorProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil mis à jour', style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: TextStyle(color: AppColors.white)),
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
        title: Text('Modifier le profil', style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        )),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
              _buildSectionTitle('Informations personnelles'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _nameController,
                label: 'Nom complet',
                hint: 'Entrez votre nom',
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phoneController,
                label: 'Téléphone',
                hint: '0555 00 00 00',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionTitle('Informations professionnelles'),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<String>(
                label: 'Spécialité',
                hint: 'Sélectionnez votre spécialité',
                value: _selectedSpecialty.isNotEmpty ? _selectedSpecialty : null,
                items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedSpecialty = v ?? ''),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<String>(
                label: 'Ville',
                hint: 'Sélectionnez votre ville',
                value: _selectedCity.isNotEmpty ? _selectedCity : null,
                items: _algerianCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}