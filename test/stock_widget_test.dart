import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';
import 'package:tradeflow_mobile/ui/stock/stock_page.dart';
import 'package:tradeflow_mobile/ui/design_system/theme.dart';

import 'trade_store_test.dart' show MemoryRepository;
import 'widget_test.dart' show chooseDemoProfile, openManagement;

import 'package:tradeflow_mobile/ui/app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });
  for (final width in [320.0, 1440.0]) {
    testWidgets('receipt, issue guard and physical count at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = TradeStore(MemoryRepository());
      await store.load();
      await store.addProduct(
        name: 'Riz',
        sku: 'RIZ',
        quantity: 10,
        threshold: 3,
        price: 500,
        unit: 'sac',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTradeFlowTheme(),
          home: StockPage(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Entrée'));
      await tester.tap(find.text('Entrée'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '2');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Réception fournisseur',
      );
      expect(find.text('Stock après mouvement : 12 sac'), findsOneWidget);
      await tester.tap(find.text('Enregistrer'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(store.data.products.single.quantity, 10);
      expect(find.text('Ajuster le stock'), findsOneWidget);
      await tester.tap(find.text('Enregistrer'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(store.data.products.single.quantity, 12);
      await tester.ensureVisible(find.text('Sortie'));
      await tester.tap(find.text('Sortie'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '20');
      await tester.enterText(find.byType(TextFormField).at(1), 'Perte');
      await tester.tap(find.text('Enregistrer'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Stock insuffisant ou quantité maximale dépassée.'),
        findsOneWidget,
      );
      expect(store.data.products.single.quantity, 12);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Faire un inventaire'));
      await tester.tap(find.text('Faire un inventaire'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Comptage physique',
      );
      await tester.enterText(
        find.byKey(ValueKey('count-${store.data.products.single.id}')),
        '0',
      );
      await tester.tap(find.text('Vérifier et valider'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider l’inventaire'));
      await tester.pumpAndSettle();
      expect(store.data.products.single.quantity, 0);
      expect(store.data.inventories.length, 1);
      await tester.tap(find.text('Inventaires'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voir le comptage'));
      await tester.pumpAndSettle();
      expect(find.text('Théorique : 12 · Compté : 0'), findsOneWidget);
      expect(find.text('Écart : -12 sac'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mouvements'));
      await tester.pumpAndSettle();
      expect(find.text('3 mouvement(s)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('inventory refuses to erase a receipt made during counting', (
    tester,
  ) async {
    final store = TradeStore(MemoryRepository());
    await store.load();
    await store.addProduct(
      name: 'Riz',
      sku: 'RIZ',
      quantity: 10,
      threshold: 3,
      price: 500,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTradeFlowTheme(),
        home: StockPage(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Faire un inventaire'));
    await tester.tap(find.text('Faire un inventaire'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Comptage');
    await tester.enterText(
      find.byKey(ValueKey('count-${store.data.products.single.id}')),
      '5',
    );
    await store.adjustStock(
      store.data.products.single.id,
      2,
      'Réception simultanée',
    );
    await tester.tap(find.text('Vérifier et valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider l’inventaire'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Le stock ou l’unité de Riz a changé.'),
      findsOneWidget,
    );
    expect(store.data.products.single.quantity, 12);
    expect(store.data.inventories, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('warehouse and management both open stock module at width 320', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = TradeStore(MemoryRepository());
    await store.load();
    await tester.pumpWidget(TradeFlowApp(store: store));
    await tester.pumpAndSettle();
    await chooseDemoProfile(tester, 'Magasinier');
    await tester.tap(find.text('Stocks').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ouvrir les stocks'));
    await tester.tap(find.text('Ouvrir les stocks'));
    await tester.pumpAndSettle();
    expect(find.text('Gestion des stocks'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await openManagement(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Gérer les stocks'));
    await tester.pumpAndSettle();
    expect(find.text('Gestion des stocks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
