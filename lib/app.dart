import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:orion_app/features/auth/presentation/pages/login_page.dart';
import 'package:orion_app/features/dispatch/presentation/bloc/dispatch_bloc.dart';
import 'package:orion_app/features/dispatch/presentation/pages/route_sheets_list_page.dart';
import 'package:orion_app/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:orion_app/features/incidents/presentation/bloc/incidents_bloc.dart';
import 'package:orion_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:orion_app/injection_container.dart';

class OrionApp extends StatelessWidget {
  const OrionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl.get<AuthBloc>()..add(const AuthCheckRequested()),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: const Color(0xFFE65100),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
        },
        child: MaterialApp(
          title: 'Orion Driver',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A237E),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFECEFF1),
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return switch (state.status) {
                AuthStatus.authenticated => const RouteSheetsListPage(),
                AuthStatus.initial || AuthStatus.loading =>
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
    return const Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_rounded,
              size: 72,
              color: Color(0xFF1A237E),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: Color(0xFF1A237E),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Verificando sesión...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF455A64),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
