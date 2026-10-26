import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/catalog_photos.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';
import 'package:tradeflow_mobile/ui/catalog/catalog_page.dart';
import 'package:tradeflow_mobile/ui/catalog/product_detail.dart';
import 'package:tradeflow_mobile/ui/products/product_editor.dart';
import 'package:tradeflow_mobile/ui/products/products_management.dart';
import 'package:tradeflow_mobile/ui/shopping/shopping_scope.dart';
import 'package:tradeflow_mobile/ui/design_system/theme.dart';

import 'trade_store_test.dart' show MemoryRepository;

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('edit, preview, publish, archive and restore at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = TradeStore(MemoryRepository());
      await store.load();
      await store.addProduct(
        name: 'Riz local',
        sku: 'LOCAL',
        quantity: 5,
        threshold: 1,
        price: 500,
        description: 'Riz en sac',
        photos: [catalogPhotos['rice']!],
      );
      await tester.pumpWidget(
        ShoppingHost(
          store: store,
          child: MaterialApp(
            theme: buildTradeFlowTheme(),
            home: Scaffold(
              body: ListenableBuilder(
                listenable: store,
                builder: (context, _) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ProductsManagement(store: store),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Modifier'));
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductEditor), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Riz nouveau');
      await tester.enterText(find.byType(TextFormField).at(2), '700');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(store.data.products.single.name, 'Riz nouveau');
      expect(store.data.products.single.price, 700);
      await tester.ensureVisible(find.text('Aperçu'));
      await tester.tap(find.text('Aperçu'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailPage), findsOneWidget);
      expect(find.text('Ajouter au panier'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Publier'));
      await tester.tap(find.text('Publier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(store.data.products.single.status, ProductStatus.published);
      await tester.ensureVisible(find.text('Archiver'));
      await tester.tap(find.text('Archiver'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(store.data.products.single.status, ProductStatus.archived);
      expect(find.text('Modifier'), findsNothing);
      await tester.ensureVisible(find.text('Restaurer'));
      await tester.tap(find.text('Restaurer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();
      expect(store.data.products.single.status, ProductStatus.draft);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'public catalogue follows managed publications and keeps withdrawal empty',
    (tester) async {
      final store = TradeStore(MemoryRepository());
      await store.load();
      await store.addProduct(
        name: 'Produit entreprise',
        sku: 'ENT',
        quantity: 1,
        threshold: 0,
        price: 100,
        description: 'Description réelle',
        photos: [catalogPhotos['rice']!],
      );
      final id = store.data.products.single.id;
      await store.setProductStatus(id, ProductStatus.published);
      await tester.pumpWidget(
        ShoppingHost(
          store: store,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: const CatalogPage()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Produit entreprise'), findsOneWidget);
      expect(find.text('Catalogue fictif · Prix indicatifs'), findsNothing);
      await store.setProductStatus(id, ProductStatus.draft);
      await tester.pumpAndSettle();
      expect(find.text('Aucun produit publié'), findsOneWidget);
      expect(find.text('Produit entreprise'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
