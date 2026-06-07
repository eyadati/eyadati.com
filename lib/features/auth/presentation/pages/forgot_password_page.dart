import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/inputs/password_field.dart';
import '../../../../core/widgets/feedback/app_snackbar.dart';
import '../../../../core/utils/input_validator.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    final phone = InputValidator.formatPhoneForE164(
      _phoneController.text.trim(),
    );

    final success = await ref.read(authProvider.notifier).sendResetOtp(phone);
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

    final token = _otpController.text.trim();

    final success = await ref.read(authProvider.notifier).verifyResetOtp(
          token,
          _newPasswordController.text,
        );
    if (!mounted) return;

    if (success) {
      setState(() {});
    } else {
      final error = ref.read(authProvider).errorMessage;
      AppSnackbar.showError(
        context,
        message: error ?? 'Code invalide',
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildStepContent(authState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(AppAuthState authState) {
    if (authState.verificationStep == VerificationStep.verified) {
      return _buildSuccessView();
    }

    if (authState.verificationStep == VerificationStep.otpSent) {
      return _buildOtpAndPasswordForm(authState);
    }

    return _buildPhoneForm(authState);
  }

  Widget _buildPhoneForm(AppAuthState authState) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mot de passe oublié',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Entrez votre numéro de téléphone pour recevoir un code de réinitialisation.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Téléphone',
            hint: '+213 5 55 12 34 56',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: (value) => InputValidator.validateAlgerianPhone(value),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Envoyer le code',
            isLoading: authState.isLoading,
            onPressed: _handleSendOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpAndPasswordForm(AppAuthState authState) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Code de vérification',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Un code à 6 chiffres vous a été envoyé par SMS.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Code',
            hint: '123456',
            controller: _otpController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.pin_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Code requis';
              if (value.length < 6) return 'Code incomplet';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          PasswordField(
            label: 'Nouveau mot de passe',
            hint: '••••••••',
            controller: _newPasswordController,
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
            onSubmitted: (_) => _handleVerifyOtp(),
            validator: (value) {
              if (value != _newPasswordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Réinitialiser',
            isLoading: authState.isLoading,
            onPressed: _handleVerifyOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 48,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Mot de passe réinitialisé',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Votre mot de passe a été modifié avec succès.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(
          label: 'Retour à la connexion',
          onPressed: () => context.go(RouteNames.login),
        ),
      ],
    );
  }
}
