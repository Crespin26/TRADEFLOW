import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/ui/documents/documents_page.dart';
import 'package:tradeflow_mobile/ui/design_system/theme.dart';

import 'support/fakes.dart' show MemoryRepository;

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('document preview, PDF export and archive at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = TradeStore(MemoryRepository());
      await store.load();
      await store.saveCompanyProfile(
        const CompanyProfile(name: 'Entreprise'),
        expectedRevision: 0,
      );
      await store.addProduct(
        name: 'Riz',
        sku: 'R',
        quantity: 10,
        threshold: 1,
        price: 100,
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
        quantity: 1,
        destination: 'Cotonou',
      );
      final completed = Completer<void>();
      Uint8List? exported;
      String? filename;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTradeFlowTheme(),
          home: DocumentsPage(
            store: store,
            exporter: (bytes, name) async {
              exported = bytes;
              filename = name;
              completed.complete();
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aperçu et PDF').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exporter / partager le PDF'));
      await tester.runAsync(() async {
        await completed.future.timeout(const Duration(seconds: 20));
      });
      await tester.pumpAndSettle();
      expect(exported, isNotNull);
      expect(filename, endsWith('.pdf'));
      expect(store.data.issuedDocuments.length, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
