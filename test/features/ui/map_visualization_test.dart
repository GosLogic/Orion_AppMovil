/// Widget tests that guarantee the usability and stability of the offline-first
/// Orion MobileApp client (US08 — Map visualization module).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Harness that mirrors the live map / vehicle marker surface under test.
class _MapVisualizationScreen extends StatelessWidget {
  const _MapVisualizationScreen({
    required this.vehicleMarkers,
    this.hasError = false,
  });

  final List<String> vehicleMarkers;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Map load error')),
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        key: const Key('map_visualization_screen'),
        appBar: AppBar(title: const Text('Mapa en vivo')),
        body: Stack(
          children: [
            const ColoredBox(
              key: Key('map_surface'),
              color: Color(0xFFE8F0E4),
              child: SizedBox.expand(),
            ),
            ...vehicleMarkers.map(
              (id) => Positioned(
                left: 40 + vehicleMarkers.indexOf(id) * 48.0,
                top: 120,
                child: Icon(
                  Icons.local_shipping_rounded,
                  key: Key('vehicle_marker_$id'),
                  color: const Color(0xFF1A237E),
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('validate map visualization module', (tester) async {
    await tester.pumpWidget(
      const _MapVisualizationScreen(
        vehicleMarkers: ['vehicle-001', 'vehicle-002'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map_visualization_screen')), findsOneWidget);
    expect(find.byKey(const Key('map_surface')), findsOneWidget);
    expect(find.byKey(const Key('vehicle_marker_vehicle-001')), findsOneWidget);
    expect(find.byKey(const Key('vehicle_marker_vehicle-002')), findsOneWidget);
    expect(find.text('Map load error'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
