import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';
import 'package:tradeflow_mobile/domain/shopping_session.dart';
import 'package:tradeflow_mobile/ui/app.dart';

import 'trade_store_test.dart' show MemoryRepository;

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void screen(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('cart to simulated confirmation at width $width', (
      tester,
    ) async {
      screen(tester, width);
      final session = ShoppingSession();
      await session.add('rice', quantity: 2);
      await session.add('oil');
      final store = TradeStore(MemoryRepository());
      await store.load();
      await store.loadDemo();
      final internal = store.data.toJson();
      await tester.pumpWidget(
        TradeFlowApp(store: store, shoppingSession: session),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Panier').last);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Se connecter pour continuer'));
      await tapVisible(tester, find.text('Simuler la connexion'));
      expect(find.text('Saisissez une adresse e-mail valide.'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'client@example.com');
      await tester.enterText(fields.at(1), 'exemple123');
      await tapVisible(tester, find.text('Simuler la connexion'));
      expect(find.text('Où livrer votre commande ?'), findsOneWidget);
      expect(session.itemCount, 3);
      final addressFields = find.byType(TextFormField);
      for (final entry in [
        'Client Exemple',
        '00000000',
        'Rue fictive',
        'Cotonou',
        'Bénin',
      ].asMap().entries) {
        await tester.enterText(addressFields.at(entry.key), entry.value);
      }
      await tapVisible(
        tester,
        find.text('Mémoriser cette adresse pour la session'),
      );
      await tapVisible(tester, find.text('Voir le récapitulatif'));
      expect(find.text('Récapitulatif'), findsOneWidget);
      await tapVisible(
        tester,
        find.text('Je comprends qu’il s’agit d’une commande de démonstration.'),
      );
      await tapVisible(tester, find.text('Confirmer la commande simulée'));
      expect(find.text('Parcours de commande terminé'), findsOneWidget);
      expect(session.lines, isEmpty);
      expect(session.receipts.single.total, 44500);
      expect(session.addresses.single.address.city, 'Cotonou');
      expect(session.customerOrders.single.id, session.receipts.single.id);
      expect(store.data.toJson(), internal);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'registration verification and password recovery are visibly simulated',
    (tester) async {
      screen(tester, 390);
      final session = ShoppingSession();
      await session.add('oil');
      await tester.pumpWidget(
        TradeFlowApp(
          store: TradeStore(MemoryRepository()),
          shoppingSession: session,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Panier').last);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Se connecter pour continuer'));
      await tapVisible(tester, find.text('Mot de passe oublié'));
      await tester.enterText(find.byType(TextFormField), 'client@example.com');
      await tapVisible(tester, find.text('Simuler la récupération'));
      expect(find.text('Demande simulée'), findsOneWidget);
      expect(session.signedIn, isFalse);
      await tapVisible(tester, find.text('Retour à la connexion'));
      await tapVisible(tester, find.text('Inscription'));
      final fields = find.byType(TextFormField);
      for (final entry in [
        'Client Exemple',
        'client@example.com',
        'exemple123',
        'exemple123',
      ].asMap().entries) {
        await tester.enterText(fields.at(entry.key), entry.value);
      }
      await tapVisible(tester, find.text('Simuler l’inscription'));
      expect(find.text('Vérifiez votre adresse e-mail'), findsOneWidget);
      expect(session.verified, isFalse);
      await tapVisible(tester, find.text('Simuler la vérification'));
      expect(session.verified, isTrue);
      expect(find.text('Où livrer votre commande ?'), findsOneWidget);
      expect(session.itemCount, 1);
    },
  );
  testWidgets('cancel login keeps cart and product detail adds quantities', (
    tester,
  ) async {
    screen(tester, 390);
    final session = ShoppingSession();
    await tester.pumpWidget(
      TradeFlowApp(
        store: TradeStore(MemoryRepository()),
        shoppingSession: session,
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Voir le produit').first);
    await tapVisible(tester, find.byTooltip('Augmenter la quantité'));
    await tapVisible(tester, find.text('Ajouter au panier'));
    expect(session.itemCount, 2);
    await tester.tap(find.byTooltip('Voir mon panier'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Se connecter pour continuer'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(session.signedIn, isFalse);
    expect(session.itemCount, 2);
    expect(find.text('Se connecter pour continuer'), findsOneWidget);
  });
}
