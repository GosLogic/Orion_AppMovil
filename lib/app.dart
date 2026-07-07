import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/core/auth/session_expired_notifier.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/theme/orion_theme.dart';
import 'package:orion_app/core/widgets/orion_logo.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:orion_app/features/auth/presentation/pages/login_page.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/home/presentation/pages/main_navigation_page.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:orion_app/injection_container.dart';

class OrionApp extends StatefulWidget {
  const OrionApp({super.key});

  @override
  State<OrionApp> createState() => _OrionAppState();
}

class _OrionAppState extends State<OrionApp> {
  StreamSubscription<void>? _sessionExpiredSub;
  AuthBloc? _authBloc;

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) {
            _authBloc = sl.get<AuthBloc>()..add(const AuthCheckRequested());
            _sessionExpiredSub ??=
                SessionExpiredNotifier.instance.stream.listen((_) {
              _authBloc?.add(const AuthSessionExpired());
            });
            return _authBloc!;
          },
        ),
        BlocProvider<DispatchBloc>(
          create: (_) => sl.get<DispatchBloc>(),
        ),
        BlocProvider<TelemetryBloc>(
          create: (_) => sl.get<TelemetryBloc>(),
        ),
        BlocProvider<IncidentsBloc>(
          create: (_) => sl.get<IncidentsBloc>(),
        ),
        BlocProvider<NotificationsBloc>(
          create: (_) => sl.get<NotificationsBloc>(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.status == AuthStatus.authenticated &&
            current.status == AuthStatus.unauthenticated &&
            current.isSessionExpired,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ??
                      'Tu sesión ha expirado. Inicia jornada nuevamente.',
                ),
                backgroundColor: OrionColors.warning,
                margin: const EdgeInsets.all(16),
              ),
            );
        },
        child: MaterialApp(
          title: 'Orion Driver',
          debugShowCheckedModeBanner: false,
          theme: OrionTheme.light,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return switch (state.status) {
                AuthStatus.authenticated => const MainNavigationPage(),
                AuthStatus.initial || AuthStatus.checkingSession =>
                  const _SplashScreen(),
                _ => const LoginPage(),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: OrionColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const OrionLogo(size: 120, showShadow: false),
              const SizedBox(height: 28),
              Text(
                'Orion Driver',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cargando tu sesión...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
