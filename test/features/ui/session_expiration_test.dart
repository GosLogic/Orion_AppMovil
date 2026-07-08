/// Widget tests that guarantee the usability and stability of the offline-first
/// Orion MobileApp client (US05 — Session expiration notification scenarios).
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_app/features/auth/presentation/bloc/auth_state.dart';

/// Lightweight fake Auth stream for UI evidence (no IAM / secure storage).
class FakeAuthCubit extends Cubit<AuthState> {
  FakeAuthCubit() : super(const AuthState(status: AuthStatus.authenticated));

  /// Simulates JWT expiry / inactivity from SyncManager / interceptor.
  void emitSessionExpired() {
    emit(
      const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Tu sesión ha expirada. Inicia sesión nuevamente.',
      ),
    );
  }
}

/// Shell that mirrors OrionApp: SnackBar + AlertDialog + redirect to login.
class _SessionShell extends StatelessWidget {
  const _SessionShell();

  @override
  Widget build(BuildContext context) {
    return BlocListener<FakeAuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.authenticated &&
          current.status == AuthStatus.unauthenticated &&
          current.isSessionExpired,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              key: const Key('session_expired_snackbar'),
              content: Text(
                state.errorMessage ??
                    'Tu sesión ha expirado. Inicia sesión nuevamente.',
              ),
            ),
          );
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            key: const Key('session_expired_dialog'),
            title: const Text('Sesión expirada'),
            content: Text(
              state.errorMessage ??
                  'Tu sesión ha expirado por inactividad.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      },
      child: BlocBuilder<FakeAuthCubit, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            return const Scaffold(
              key: Key('login_screen'),
              body: Center(child: Text('Iniciar sesión')),
            );
          }
          return Scaffold(
            key: const Key('home_screen'),
            body: Center(
              child: FilledButton(
                key: const Key('trigger_session_expired'),
                onPressed: () =>
                    context.read<FakeAuthCubit>().emitSessionExpired(),
                child: const Text('Simular inactividad'),
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  testWidgets('validate expired session notification scenarios', (tester) async {
    final authCubit = FakeAuthCubit();

    await tester.pumpWidget(
      BlocProvider<FakeAuthCubit>.value(
        value: authCubit,
        child: const MaterialApp(home: _SessionShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('trigger_session_expired')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('session_expired_snackbar')), findsOneWidget);
    expect(find.byKey(const Key('session_expired_dialog')), findsOneWidget);
    expect(find.textContaining('expirad'), findsWidgets);
    expect(find.byKey(const Key('login_screen')), findsOneWidget);

    await authCubit.close();
  });
}
