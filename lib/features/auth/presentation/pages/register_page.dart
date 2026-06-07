import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/inputs/password_field.dart';
import '../../../../core/widgets/feedback/app_snackbar.dart';
import '../../../../core/utils/input_validator.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_footer.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _infoFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  String _selectedRole = 'patient';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_infoFormKey.currentState!.validate()) return;

    final phone = InputValidator.formatPhoneForE164(
      _phoneController.text.trim(),
    );

    final success = await ref.read(authProvider.notifier).sendOtp(phone);
    if (!mounted) return;

    if (!success) {
      final error = ref.read(authProvider).errorMessage;
      AppSnackbar.showError(
        context,
        message: error ?? "Erreur d'envoi du code",
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(
          token: _otpController.text.trim(),
          name: _nameController.text.trim(),
          role: _selectedRole,
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      context.go(
        _selectedRole == 'doctor'
            ? RouteNames.doctorDashboard
            : RouteNames.patientHome,
      );
    } else {
      final error = ref.read(authProvider).errorMessage;
      AppSnackbar.showError(
        context,
        message: error ?? "Erreur lors de l'inscription",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (authState.verificationStep == VerificationStep.otpSent) {
              ref.read(authProvider.notifier).resetVerification();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: 'Créer un compte',
                subtitle: authState.verificationStep == VerificationStep.otpSent
                    ? 'Vérifiez votre numéro'
                    : 'Rejoignez Eyadati',
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: authState.verificationStep == VerificationStep.otpSent
                    ? _buildOtpStep()
                    : _buildInfoStep(authState),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (authState.verificationStep != VerificationStep.otpSent)
                AuthFooter(
                  text: 'Vous avez déjà un compte ? ',
                  actionText: 'Se connecter',
                  onAction: () => context.pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoStep(AppAuthState authState) {
    return Form(
      key: _infoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Je suis',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _RoleSelector(
                  label: 'Patient',
                  icon: Icons.person_outline,
                  isSelected: _selectedRole == 'patient',
                  onTap: () => setState(() => _selectedRole = 'patient'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _RoleSelector(
                  label: 'Docteur',
                  icon: Icons.medical_services_outlined,
                  isSelected: _selectedRole == 'doctor',
                  onTap: () => setState(() => _selectedRole = 'doctor'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Nom complet',
            hint: 'Votre nom',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nom requis';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Téléphone',
            hint: '+213 5 55 12 34 56',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            textInputAction: TextInputAction.next,
            validator: (value) => InputValidator.validateAlgerianPhone(value),
          ),
          const SizedBox(height: AppSpacing.md),
          PasswordField(
            label: 'Mot de passe',
            hint: '••••••••',
            controller: _passwordController,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Mot de passe requis';
              if (value.length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          PasswordField(
            label: 'Confirmer le mot de passe',
            hint: '••••••••',
            controller: _confirmPasswordController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSendOtp(),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: "S'inscrire",
            isLoading: authState.isLoading,
            onPressed: _handleSendOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Code envoyé au ${_phoneController.text.trim()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Code de vérification',
            hint: '123456',
            controller: _otpController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.pin_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Code requis';
              if (value.length < 6) return 'Code incomplet (6 chiffres)';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Vérifier',
            isLoading: ref.watch(authProvider).isLoading,
            onPressed: _handleVerifyOtp,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: _handleSendOtp,
            child: const Text(
              'Renvoyer le code',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelector({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
