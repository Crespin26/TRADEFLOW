import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';
import 'package:tradeflow_mobile/ui/app.dart';
import 'package:tradeflow_mobile/ui/catalog/product_widgets.dart';

import 'trade_store_test.dart' show MemoryRepository;

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('public catalogue filtering and detail at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = TradeStore(MemoryRepository());
      await tester.pumpWidget(TradeFlowApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('Des produits pour\nvos ambitions.'), findsOneWidget);
      await tester.tap(find.text('Catalogue').last);
      await tester.pumpAndSettle();
      expect(find.byType(PublicProductTile), findsNWidgets(8));
      await tester.enterText(find.byType(TextField), 'parfume');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byType(PublicProductTile), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Voir le produit'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voir le produit'));
      await tester.pumpAndSettle();
      expect(find.text('Fiche produit'), findsOneWidget);
      expect(find.text('Réf. PUB-RIZ-025'), findsOneWidget);
      await tester.tap(find.text('Conditionnement'));
      await tester.pumpAndSettle();
      expect(find.text('Ajouter au panier'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      // The catalogue keeps the search when returning from a product.
      expect(find.byType(PublicProductTile), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byTooltip('Effacer la recherche'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Effacer la recherche'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'aucun-produit-123');
      await tester.pumpAndSettle();
      expect(find.byType(PublicProductTile), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Afficher tous les produits'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Afficher tous les produits'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicProductTile), findsNWidgets(8));
      expect(store.loaded, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('home category opens the matching catalogue without login', (
    tester,
  ) async {
    await tester.pumpWidget(
      TradeFlowApp(store: TradeStore(MemoryRepository())),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Textile'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Textile'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicProductTile), findsNWidgets(2));
    expect(find.text('Tissu coton uni'), findsOneWidget);
    expect(find.text('Authentification non connectée'), findsOneWidget);
  });
}
