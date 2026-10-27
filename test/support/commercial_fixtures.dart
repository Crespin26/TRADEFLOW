import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/domain/models.dart';

import 'fakes.dart';

Future<TradeStore> seededStore() async {
  final store = TradeStore(MemoryRepository());
  await store.load();
  await store.addProduct(
    name: 'Riz',
    sku: 'RIZ',
    quantity: 20,
    threshold: 3,
    price: 1000,
    purchasePrice: 600,
    unit: 'sac',
  );
  await store.addContact(
    name: 'Client',
    kind: ContactKind.client,
    country: 'Bénin',
    email: '',
    phone: '',
  );
  await store.addContact(
    name: 'Fournisseur',
    kind: ContactKind.supplier,
    country: 'Togo',
    email: '',
    phone: '',
  );
  return store;
}

Future<void> confirmAction(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Confirmer'));
  await tester.pumpAndSettle();
}

Future<void> quantityOperation(
  WidgetTester tester,
  String label,
  int quantity,
) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), '$quantity');
  await tester.enterText(
    find.byType(TextFormField).at(1),
    'Justificatif local',
  );
  await tester.tap(find.text('Enregistrer'));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text('Confirmer'));
  await tester.pumpAndSettle();
}
