import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eyadati/core/routing/route_names.dart';
import 'package:eyadati/core/constants/app_colors.dart';
import 'package:eyadati/core/constants/app_spacing.dart';
import 'package:eyadati/core/widgets/buttons/primary_button.dart';
import 'package:eyadati/core/widgets/inputs/app_text_field.dart';
import 'package:eyadati/core/widgets/inputs/password_field.dart';
import 'package:eyadati/core/widgets/feedback/app_snackbar.dart';
import 'package:eyadati/core/utils/input_validator.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_footer.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = InputValidator.formatPhoneForE164(
      _phoneController.text.trim(),
    );

    final success = await ref.read(authProvider.notifier).loginWithPhone(
      phone,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final authState = ref.read(authProvider);
      if (authState.isDoctor) {
        context.go(RouteNames.doctorDashboard);
      } else {
        context.go(RouteNames.patientHome);
      }
    } else {
      final error = ref.read(authProvider).errorMessage;
      AppSnackbar.showError(
        context,
        message: error ?? 'Erreur de connexion',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                const AuthHeader(
                  title: 'Bienvenue',
                  subtitle: 'Connectez-vous à votre compte',
                ),
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Téléphone',
                        hint: '+213 5 55 12 34 56',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.phone_outlined,
                        validator: (value) =>
                            InputValidator.validateAlgerianPhone(value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PasswordField(
                        label: 'Mot de passe',
                        hint: '••••••••',
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mot de passe requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const Text('Se souvenir'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              context.push(RouteNames.forgotPassword);
                            },
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: 'Se connecter',
                        isLoading: authState.isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthFooter(
                  text: "Vous n'avez pas de compte ? ",
                  actionText: "S'inscrire",
                  onAction: () => context.push(RouteNames.register),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
