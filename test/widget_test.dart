import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';
import 'package:tradeflow_mobile/ui/app.dart';

import 'trade_store_test.dart' show MemoryRepository;

void main() {
  testWidgets('mobile navigation, product validation and stock alerts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = TradeStore(MemoryRepository());
    await store.load();
    await tester.pumpWidget(TradeFlowApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Vue d’ensemble'), findsOneWidget);
    await tester.tap(find.text('Produits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouveau produit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Ce champ est obligatoire.'), findsWidgets);
    final inputs = find.byType(TextFormField);
    await tester.enterText(inputs.at(0), 'Riz');
    await tester.enterText(inputs.at(1), 'RIZ-001');
    await tester.enterText(inputs.at(2), '15000');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(store.data.products.single.name, 'Riz');
    expect(find.text('Riz'), findsOneWidget);
    await tester.tap(find.byTooltip('Alertes de stock'));
    await tester.pumpAndSettle();
    expect(find.text('Alertes de stock'), findsOneWidget);
    expect(find.text('0 disponible(s) · seuil : 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop navigation renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = TradeStore(MemoryRepository());
    await store.load();
    await store.loadDemo();
    await tester.pumpWidget(TradeFlowApp(store: store));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    for (final title in [
      'Produits',
      'Commandes',
      'Contacts',
      'Historique',
      'Accueil',
    ]) {
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
