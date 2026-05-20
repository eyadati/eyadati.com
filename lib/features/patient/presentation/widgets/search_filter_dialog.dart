import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../providers/doctors_provider.dart';
import '../widgets/doctor_results_sheet.dart';

class SearchFilterDialog extends ConsumerStatefulWidget {
  const SearchFilterDialog({super.key});

  @override
  ConsumerState<SearchFilterDialog> createState() => _SearchFilterDialogState();
}

class _SearchFilterDialogState extends ConsumerState<SearchFilterDialog> {
  String? _selectedCity;
  String? _selectedSpecialty;
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

  final List<String> _cities = algerianCities;

  final List<String> _specialties = [
    'Médecine générale',
    'Dentiste',
    'Cardiologue',
    'Dermatologue',
    'Ophtalmologue',
    'Pédiatre',
    'Neurologue',
    'Orthopédiste',
    'Gynécologue',
    'Urologue',
    'Psychiatre',
    'Otorhinolaryngologue',
    'Radiologue',
    'Anesthésiste',
  ];

  void _search() {
    if (_selectedCity == null && _selectedSpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une ville ou une spécialité'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    ref.read(doctorsProvider.notifier).setCity(_selectedCity);
    ref.read(doctorsProvider.notifier).setSpecialty(_selectedSpecialty ?? '');

    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DoctorResultsSheet(
        city: _selectedCity,
        specialty: _selectedSpecialty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      backgroundColor: AppColors.card,
      title: const Text(
        'Rechercher un médecin',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ville',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: InputBorder.none,
              ),
              hint: const Text('Sélectionner une ville'),
              items: _cities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCity = value),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Spécialité',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedSpecialty,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: InputBorder.none,
              ),
              hint: const Text('Sélectionner une spécialité'),
              items: _specialties.map((specialty) {
                return DropdownMenuItem(
                  value: specialty,
                  child: Text(specialty),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSpecialty = value),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        SizedBox(
          width: 140,
          child: PrimaryButton(
            label: 'Rechercher',
            isLoading: _isLoading,
            onPressed: _search,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.all(AppSpacing.md),
    );
  }
}