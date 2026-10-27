import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/ui/pilotage/pilotage_page.dart';
import 'package:tradeflow_mobile/ui/demo_profile.dart';
import 'package:tradeflow_mobile/ui/design_system/theme.dart';

import 'support/fakes.dart' show MemoryRepository;

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('responsive pilotage and selectable period report at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = TradeStore(MemoryRepository());
      await store.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTradeFlowTheme(),
          home: PilotagePage(store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ventes confirmées'), findsOneWidget);
      await tester.tap(find.text('Toutes dates'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Rapport CSV'));
      await tester.pumpAndSettle();
      expect(find.text('Rapport CSV · Toutes dates'), findsOneWidget);
      expect(find.text('Copier le rapport CSV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'warehouse view exposes operational counts without financial cards',
    (tester) async {
      final store = TradeStore(MemoryRepository());
      await store.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTradeFlowTheme(),
          home: PilotagePage(store: store, profile: DemoProfile.warehouse),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Commandes à livrer'), findsOneWidget);
      expect(find.text('Ventes confirmées'), findsNothing);
      expect(find.text('Achats engagés'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
