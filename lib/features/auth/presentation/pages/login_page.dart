import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_decorations.dart';
import 'package:orion_app/core/widgets/orion_logo.dart';
import 'package:orion_app/features/auth/domain/entities/auth_credentials.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:orion_app/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:orion_app/features/auth/presentation/widgets/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
          AuthLoginRequested(
            AuthCredentials(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          ),
        );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: OrionHeroBackground(
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.errorMessage != current.errorMessage,
            listener: (context, state) {
              if (state.status == AuthStatus.error &&
                  state.errorMessage != null) {
                _showSnackBar(context, state.errorMessage!, OrionColors.error);
              } else if (state.status == AuthStatus.unauthenticated &&
                  state.isSessionExpired) {
                _showSnackBar(
                  context,
                  'Tu sesión ha expirado. Inicia jornada nuevamente.',
                  OrionColors.warning,
                );
              }
            },
            builder: (context, state) {
              final isLoading = state.status == AuthStatus.loading;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const OrionLogo(size: 108),
                      const SizedBox(height: 20),
                      Text(
                        'Orion Driver',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: OrionColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tu jornada, bajo control',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: OrionColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      OrionSurfaceCard(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Iniciar sesión',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ingresa tus credenciales de conductor',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              CustomTextField(
                                controller: _emailController,
                                label: 'Correo electrónico',
                                hint: 'conductor@empresa.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !isLoading,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa tu correo electrónico';
                                  }
                                  if (!_isValidEmail(value.trim())) {
                                    return 'Formato de correo inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                enabled: !isLoading,
                                textInputAction: TextInputAction.done,
                                onEditingComplete: _submit,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: OrionColors.primary,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa tu contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              PrimaryButton(
                                label: 'Iniciar Jornada',
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: OrionColors.textMuted.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Conexión segura vía Orion Gateway',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: OrionColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
