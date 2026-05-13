import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/widgets/buttons/primary_button.dart';
import 'package:eyadati/core/widgets/inputs/app_text_field.dart';
import 'package:eyadati/core/widgets/inputs/app_dropdown.dart';
import '../providers/doctor_provider.dart';
import '../../../../core/utils/supabase_client.dart';

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
  late TextEditingController _mapsLinkController;
  String _selectedCity = '';
  String _selectedSpecialty = '';
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;

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
    _addressController = TextEditingController(text: state.address);
    _mapsLinkController = TextEditingController(text: state.mapsLink ?? '');
    _selectedCity = state.city;
    _selectedSpecialty = state.specialty;
    _photoUrl = state.avatarUrl.isNotEmpty ? state.avatarUrl : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _mapsLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await image.readAsBytes();
      final fileName = '${const Uuid().v4()}.jpg';
      final path = 'avatars/$fileName';

      await Supabase.instance.client.storage.from('avatars').uploadBinary(path, bytes);
      final url = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);

      setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload de la photo'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
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
        'avatar_url': _photoUrl,
      }).eq('id', userId);

      await client.from('doctors').update({
        'specialty': _selectedSpecialty,
        'city': _selectedCity,
        'address': _addressController.text.trim(),
        'maps_link': _mapsLinkController.text.trim().isEmpty ? null : _mapsLinkController.text.trim(),
        'photo_url': _photoUrl,
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
              _buildPhotoUpload(),
              const SizedBox(height: AppSpacing.xl),
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
              AppTextField(
                controller: _addressController,
                label: 'Adresse du cabinet',
                hint: '123 Rue Didouche Mourad, Alger Centre',
                prefixIcon: Icons.location_on_outlined,
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _mapsLinkController,
                label: 'Lien Google Maps',
                hint: 'https://maps.google.com/...',
                prefixIcon: Icons.map_outlined,
                keyboardType: TextInputType.url,
              ),
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

  Widget _buildPhotoUpload() {
    return Center(
      child: GestureDetector(
        onTap: _isUploadingPhoto ? null : _pickImage,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
                image: _photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _photoUrl == null
                  ? Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.textHint)
                  : null,
            ),
            if (_isUploadingPhoto)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
              ),
            if (_photoUrl != null && !_isUploadingPhoto)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.edit, size: 12, color: Colors.white),
                ),
              ),
          ],
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