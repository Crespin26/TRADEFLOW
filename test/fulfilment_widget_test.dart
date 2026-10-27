import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';
import 'package:tradeflow_mobile/ui/fulfilment/fulfilment_page.dart';
import 'package:tradeflow_mobile/ui/design_system/theme.dart';

import 'trade_store_test.dart' show MemoryRepository;
import 'commercial_widget_test.dart' show confirmAction, quantityOperation;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });
  for (final width in [320.0, 1440.0]) {
    testWidgets('carrier, overdue deliveries and damaged returns at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = TradeStore(MemoryRepository());
      await store.load();
      await store.addProduct(
        name: 'Riz',
        sku: 'R',
        quantity: 10,
        threshold: 1,
        price: 100,
        unit: 'sac',
      );
      await store.addContact(
        name: 'Client',
        kind: ContactKind.client,
        country: 'Bénin',
        email: '',
        phone: '',
      );
      await store.createOrder(
        productId: store.data.products.single.id,
        customerId: store.data.contacts.single.id,
        quantity: 4,
        destination: 'Cotonou',
      );
      final order = store.data.orders.single.id;
      await store.saveDeliveryPlan(
        order,
        carrier: 'Initial',
        trackingNumber: 'REF',
        notes: '',
        expectedDate: DateTime.now().subtract(const Duration(days: 1)),
        expectedRevision: 0,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTradeFlowTheme(),
          home: FulfilmentPage(store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 en retard'), findsOneWidget);
      await tester.tap(find.text('En retard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ouvrir le suivi'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Transporteur et suivi'));
      await tester.tap(find.text('Transporteur et suivi'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Transport A');
      await tester.enterText(find.byType(TextFormField).at(1), 'REF-2');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await confirmAction(tester, 'Expédier');
      await quantityOperation(tester, 'Enregistrer une livraison', 1);
      expect(store.data.commercialEvents.first.carrier, 'Transport A');
      await tester.ensureVisible(find.text('Retour client').last);
      await tester.tap(find.text('Retour client').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'Abîmé');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(store.data.products.single.quantity, 6);
      expect(store.data.commercialEvents.first.restocked, isFalse);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Historique'));
      await tester.pumpAndSettle();
      expect(find.text('Hors stock disponible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
