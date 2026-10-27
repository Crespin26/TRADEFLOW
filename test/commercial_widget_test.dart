import 'support/commercial_fixtures.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/ui/app.dart';
import 'package:tradeflow_mobile/ui/operations/operations_page.dart';
import 'package:tradeflow_mobile/ui/operations/document_editor.dart';
import 'package:tradeflow_mobile/ui/design_system/theme.dart';

import 'support/navigation.dart' show chooseDemoProfile;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });
  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'quote to sale, partial delivery and customer return at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = await seededStore();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTradeFlowTheme(),
            home: OperationsPage(store: store, initialTab: 1),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nouveau devis'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), '2');
        await tester.enterText(find.byType(TextFormField).at(1), '900');
        await tester.enterText(find.byType(TextFormField).at(2), 'Cotonou');
        await tester.tap(find.text('Enregistrer le brouillon'));
        await tester.pumpAndSettle();
        expect(store.data.products.single.quantity, 20);
        await tester.ensureVisible(find.text('Ouvrir le document'));
        await tester.tap(find.text('Ouvrir le document'));
        await tester.pumpAndSettle();
        await confirmAction(tester, 'Marquer envoyé');
        await confirmAction(tester, 'Marquer accepté');
        await confirmAction(tester, 'Convertir en commande');
        expect(store.data.orders.single.unitPrice, 900);
        expect(store.data.products.single.quantity, 18);
        await tester.tap(find.text('Ouvrir la commande'));
        await tester.pumpAndSettle();
        await confirmAction(tester, 'Expédier');
        await quantityOperation(tester, 'Enregistrer une livraison', 1);
        expect(store.data.products.single.quantity, 18);
        expect(store.data.orders.single.deliveredQuantity, 1);
        await quantityOperation(tester, 'Retour client', 1);
        expect(store.data.products.single.quantity, 19);
        expect(store.data.orders.single.returnedQuantity, 1);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'purchase partial receipts and supplier return at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = await seededStore();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTradeFlowTheme(),
            home: OperationsPage(store: store, initialTab: 2),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nouvel achat'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), '3');
        await tester.enterText(find.byType(TextFormField).at(2), 'Dépôt');
        await tester.tap(find.text('Enregistrer le brouillon'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Ouvrir le document'));
        await tester.tap(find.text('Ouvrir le document'));
        await tester.pumpAndSettle();
        await confirmAction(tester, 'Confirmer l’achat');
        expect(store.data.products.single.quantity, 20);
        await quantityOperation(tester, 'Réceptionner', 1);
        expect(store.data.products.single.quantity, 21);
        expect(store.data.purchases.single.receivedQuantity, 1);
        await quantityOperation(tester, 'Réceptionner', 2);
        expect(store.data.products.single.quantity, 23);
        expect(store.data.purchases.single.status, PurchaseStatus.received);
        await quantityOperation(tester, 'Retour fournisseur', 1);
        expect(store.data.products.single.quantity, 22);
        expect(store.data.purchases.single.returnedQuantity, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'editing an archived draft product preserves its selected line instead of silently switching products',
    (tester) async {
      final store = await seededStore();
      final p = store.data.products.single;
      await store.addProduct(
        name: 'Autre',
        sku: 'OTHER',
        quantity: 1,
        threshold: 0,
        price: 2,
      );
      await store.saveQuote(
        customerId: store.data.contacts.first.id,
        productId: p.id,
        quantity: 1,
        unitPrice: 1,
        destination: 'Cotonou',
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      );
      final q = store.data.quotes.single;
      await store.setProductStatus(p.id, ProductStatus.archived);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTradeFlowTheme(),
          home: CommercialDocumentEditor(store: store, quote: q),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Riz · sac'), findsOneWidget);
      await tester.tap(find.text('Enregistrer le brouillon'));
      await tester.pumpAndSettle();
      expect(find.text('Choisissez un produit actif.'), findsOneWidget);
      expect(store.data.quotes.single.productId, p.id);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('sales and warehouse profiles open the correct commercial tab', (
    tester,
  ) async {
    final store = await seededStore();
    await tester.pumpWidget(TradeFlowApp(store: store));
    await tester.pumpAndSettle();
    await chooseDemoProfile(tester, 'Commercial');
    await tester.tap(find.text('Devis').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ouvrir les opérations'));
    await tester.tap(find.text('Ouvrir les opérations'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau devis'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await chooseDemoProfile(tester, 'Magasinier');
    await tester.tap(find.text('Réceptions').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ouvrir les opérations'));
    await tester.tap(find.text('Ouvrir les opérations'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvel achat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
