import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/ui/app.dart';
import 'package:tradeflow_mobile/ui/partners/partners_page.dart';
import 'package:tradeflow_mobile/ui/partners/partner_editor.dart';
import 'package:tradeflow_mobile/ui/design_system/theme.dart';

import 'support/fakes.dart' show MemoryRepository;
import 'support/navigation.dart' show chooseDemoProfile;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });
  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'create edit archive restore and filter partners at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = TradeStore(MemoryRepository());
        await store.load();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTradeFlowTheme(),
            home: PartnersPage(store: store),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nouveau partenaire'));
        await tester.pumpAndSettle();
        expect(find.byType(PartnerEditor), findsOneWidget);
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
        expect(find.text('Ce champ est obligatoire.'), findsWidgets);
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Comptoir Étoile',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'Bénin');
        await tester.enterText(find.byType(TextFormField).at(2), 'invalid');
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
        expect(
          find.text('Adresse e-mail invalide.').hitTestable(),
          findsOneWidget,
        );
        expect(store.data.contacts, isEmpty);
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'contact@example.com',
        );
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
        expect(store.data.contacts.single.name, 'Comptoir Étoile');
        await tester.enterText(find.byType(TextField).first, 'etoile');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Ouvrir la fiche'));
        await tester.tap(find.text('Ouvrir la fiche'));
        await tester.pumpAndSettle();
        expect(find.text('contact@example.com'), findsOneWidget);
        await tester.tap(find.text('Modifier'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Comptoir Étoile Export',
        );
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
        expect(store.data.contacts.single.revision, 1);
        await tester.tap(find.text('Archiver'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Archiver').last);
        await tester.pumpAndSettle();
        expect(store.data.contacts.single.archived, isTrue);
        expect(find.text('Modifier'), findsNothing);
        await tester.tap(find.text('Restaurer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Restaurer').last);
        await tester.pumpAndSettle();
        expect(store.data.contacts.single.archived, isFalse);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Fournisseurs'));
        await tester.pumpAndSettle();
        expect(find.text('Aucun partenaire à afficher'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'customer detail keeps original order name and selects the right customer for a new order',
    (tester) async {
      final store = TradeStore(MemoryRepository());
      await store.load();
      for (final name in ['Autre', 'Client ciblé']) {
        await store.addContact(
          name: name,
          kind: ContactKind.client,
          country: 'Bénin',
          email: '',
          phone: '',
        );
      }
      final id = store.data.contacts.last.id;
      await store.addProduct(
        name: 'Riz',
        sku: 'RIZ',
        quantity: 10,
        threshold: 2,
        price: 500,
      );
      await store.createOrder(
        productId: store.data.products.single.id,
        customerId: id,
        quantity: 1,
        destination: 'Cotonou',
      );
      await store.updateContact(
        store.data.contacts.last.copyWith(name: 'Client renommé'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTradeFlowTheme(),
          home: PartnerDetailPage(store: store, contactId: id),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Client à la commande : Client ciblé'), findsOneWidget);
      await tester.tap(find.text('Nouvelle commande'));
      await tester.pumpAndSettle();
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).first,
      );
      expect(dropdown.initialValue, id);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('commercial profile opens the real partner directory', (
    tester,
  ) async {
    final store = TradeStore(MemoryRepository());
    await store.load();
    await tester.pumpWidget(TradeFlowApp(store: store));
    await tester.pumpAndSettle();
    await chooseDemoProfile(tester, 'Commercial');
    await tester.tap(find.text('Clients').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ouvrir les partenaires'));
    await tester.tap(find.text('Ouvrir les partenaires'));
    await tester.pumpAndSettle();
    expect(find.text('Clients et fournisseurs'), findsOneWidget);
    expect(find.text('Nouveau partenaire'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
