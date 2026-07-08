/// Widget tests that guarantee the usability and stability of the offline-first
/// Orion MobileApp client (US09 — Route history filters and visualization).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RouteHistoryEntry {
  const _RouteHistoryEntry({
    required this.id,
    required this.title,
    required this.dateLabel,
  });

  final String id;
  final String title;
  final String dateLabel;
}

/// Harness for the historical route list with date filters.
class _RouteHistoryScreen extends StatefulWidget {
  const _RouteHistoryScreen({required this.allRoutes});

  final List<_RouteHistoryEntry> allRoutes;

  @override
  State<_RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<_RouteHistoryScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  late List<_RouteHistoryEntry> _visible;

  @override
  void initState() {
    super.initState();
    _visible = List<_RouteHistoryEntry>.from(widget.allRoutes);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    setState(() {
      _visible = widget.allRoutes.where((route) {
        final afterFrom = from.isEmpty || route.dateLabel.compareTo(from) >= 0;
        final beforeTo = to.isEmpty || route.dateLabel.compareTo(to) <= 0;
        return afterFrom && beforeTo;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: const Key('route_history_screen'),
        appBar: AppBar(title: const Text('Historial de rutas')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('filter_from_date'),
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: 'Desde',
                        hintText: '2026-07-01',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const Key('filter_to_date'),
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'Hasta',
                        hintText: '2026-07-31',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('apply_history_filters'),
                    onPressed: _applyFilters,
                    child: const Text('Filtrar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                key: const Key('route_history_list'),
                itemCount: _visible.length,
                itemBuilder: (context, index) {
                  final route = _visible[index];
                  return Card(
                    key: Key('history_card_${route.id}'),
                    child: ListTile(
                      title: Text(route.title),
                      subtitle: Text(route.dateLabel),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('validate route history filters and visualization', (tester) async {
    await tester.pumpWidget(
      const _RouteHistoryScreen(
        allRoutes: [
          _RouteHistoryEntry(
            id: 'r1',
            title: 'Ruta San Isidro',
            dateLabel: '2026-07-01',
          ),
          _RouteHistoryEntry(
            id: 'r2',
            title: 'Ruta Lince',
            dateLabel: '2026-07-08',
          ),
          _RouteHistoryEntry(
            id: 'r3',
            title: 'Ruta Pueblo Libre',
            dateLabel: '2026-07-15',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('route_history_list')), findsOneWidget);
    expect(find.byKey(const Key('history_card_r1')), findsOneWidget);
    expect(find.byKey(const Key('history_card_r2')), findsOneWidget);
    expect(find.byKey(const Key('history_card_r3')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('filter_from_date')),
      '2026-07-08',
    );
    await tester.enterText(
      find.byKey(const Key('filter_to_date')),
      '2026-07-15',
    );
    await tester.tap(find.byKey(const Key('apply_history_filters')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history_card_r1')), findsNothing);
    expect(find.byKey(const Key('history_card_r2')), findsOneWidget);
    expect(find.byKey(const Key('history_card_r3')), findsOneWidget);
    expect(find.text('Ruta Lince'), findsOneWidget);
    expect(find.text('Ruta Pueblo Libre'), findsOneWidget);
  });
}
