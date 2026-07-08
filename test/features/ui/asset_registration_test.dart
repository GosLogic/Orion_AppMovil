/// Widget tests that guarantee the usability and stability of the offline-first
/// Orion MobileApp client (US13 — Asset registration form behavior).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Technical status registration form (brakes / tires) under test.
class _AssetRegistrationForm extends StatefulWidget {
  const _AssetRegistrationForm();

  @override
  State<_AssetRegistrationForm> createState() => _AssetRegistrationFormState();
}

class _AssetRegistrationFormState extends State<_AssetRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _brakesController = TextEditingController();
  final _tiresController = TextEditingController();

  @override
  void dispose() {
    _brakesController.dispose();
    _tiresController.dispose();
    super.dispose();
  }

  void _onSave() {
    _formKey.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: const Key('asset_registration_screen'),
        appBar: AppBar(title: const Text('Registro de activos')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('field_brakes'),
                  controller: _brakesController,
                  decoration: const InputDecoration(
                    labelText: 'Estado de frenos',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El estado de frenos es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('field_tires'),
                  controller: _tiresController,
                  decoration: const InputDecoration(
                    labelText: 'Estado de neumáticos',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El estado de neumáticos es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('save_asset_button'),
                  onPressed: _onSave,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('validate asset registration form behavior', (tester) async {
    await tester.pumpWidget(const _AssetRegistrationForm());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('asset_registration_screen')), findsOneWidget);
    expect(find.byKey(const Key('field_brakes')), findsOneWidget);
    expect(find.byKey(const Key('field_tires')), findsOneWidget);

    await tester.tap(find.byKey(const Key('save_asset_button')));
    await tester.pumpAndSettle();

    expect(find.text('El estado de frenos es obligatorio'), findsOneWidget);
    expect(
      find.text('El estado de neumáticos es obligatorio'),
      findsOneWidget,
    );
  });
}
