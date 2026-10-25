import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';
import 'package:tradeflow_mobile/domain/shopping_session.dart';
import 'package:tradeflow_mobile/ui/app.dart';

import 'trade_store_test.dart' show MemoryRepository;
import 'shopping_widget_test.dart' show tapVisible, screen;
import 'widget_test.dart' show chooseDemoProfile;

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'customer delivery, request and document preview at width $width',
      (tester) async {
        screen(tester, width);
        final session = ShoppingSession()
          ..signInDemo('client@example.com')
          ..loadCustomerExamples();
        await tester.pumpWidget(
          TradeFlowApp(
            store: TradeStore(MemoryRepository()),
            shoppingSession: session,
          ),
        );
        await tester.pumpAndSettle();
        await chooseDemoProfile(tester, 'Client');
        expect(find.text('Bienvenue dans votre espace client'), findsOneWidget);
        await tester.tap(find.text('Commandes').last);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Livrée'));
        await tapVisible(tester, find.text('DEMO-EXEMPLE-DELIVERED'));
        expect(find.text('Suivi de livraison'), findsOneWidget);
        await tapVisible(tester, find.text('Faire une demande'));
        await tester.tap(
          find.byType(DropdownButtonFormField<CustomerRequestKind>),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Retour').last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          'Retour de démonstration pour vérifier le parcours.',
        );
        await tapVisible(tester, find.text('Joindre un justificatif fictif'));
        await tapVisible(tester, find.text('Enregistrer'));
        expect(session.requests.first.attachmentName, 'justificatif-demo.txt');
        expect(
          session.requests.any(
            (r) => r.kind == CustomerRequestKind.returnGoods,
          ),
          isTrue,
        );
        await tapVisible(tester, find.text('Suivre mes demandes'));
        await tapVisible(tester, find.text('Voir le justificatif fictif'));
        expect(find.text('justificatif-demo.txt'), findsOneWidget);
        await tester.tap(find.text('Fermer'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('Documents de cette commande'));
        await tapVisible(tester, find.text('Facture — spécimen'));
        expect(find.text('SPÉCIMEN · SANS VALEUR COMPTABLE'), findsOneWidget);
        session.signOut();
        await tester.pumpAndSettle();
        expect(find.text('Ouvrez votre espace client'), findsOneWidget);
        expect(find.byType(SelectableText), findsNothing);
      },
    );
  }
  testWidgets(
    'address form is reused by checkout and retains historical data',
    (tester) async {
      screen(tester, 390);
      final session = ShoppingSession()..signInDemo('client@example.com');
      await session.add('oil');
      await tester.pumpWidget(
        TradeFlowApp(
          store: TradeStore(MemoryRepository()),
          shoppingSession: session,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mon compte de démonstration'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Mes adresses'));
      await tapVisible(tester, find.text('Ajouter une adresse'));
      final fields = find.byType(TextFormField);
      for (final entry in [
        'Boutique',
        'Client Démo',
        '00000000',
        'Rue fictive',
        'Cotonou',
        'Bénin',
      ].asMap().entries) {
        await tester.enterText(fields.at(entry.key), entry.value);
      }
      await tapVisible(tester, find.text('Enregistrer'));
      expect(session.addresses.single.label, 'Boutique');
      expect(find.text('Livraison par défaut'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Panier').last);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Préparer la commande'));
      final checkout = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(checkout.at(0)).controller!.text,
        'Client Démo',
      );
      expect(
        tester.widget<TextFormField>(checkout.at(2)).controller!.text,
        'Rue fictive',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('notifications read state and customer profile are actionable', (
    tester,
  ) async {
    screen(tester, 390);
    final session = ShoppingSession()
      ..signInDemo('client@example.com')
      ..loadCustomerExamples();
    await tester.pumpWidget(
      TradeFlowApp(
        store: TradeStore(MemoryRepository()),
        shoppingSession: session,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mon compte de démonstration'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Modifier mon profil'));
    await tester.enterText(find.byType(TextFormField).at(0), 'Client Démo');
    await tester.enterText(find.byType(TextFormField).at(1), '00000000');
    await tapVisible(tester, find.text('Enregistrer'));
    expect(session.displayName, 'Client Démo');
    await tapVisible(tester, find.text('Mes notifications'));
    await tapVisible(tester, find.text('Tout marquer comme lu'));
    expect(session.unreadNoticeCount, 0);
    expect(tester.takeException(), isNull);
  });
}
