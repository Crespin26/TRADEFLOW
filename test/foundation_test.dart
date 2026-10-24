import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';
import 'package:tradeflow_mobile/ui/app.dart';
import 'package:tradeflow_mobile/ui/demo_profile.dart';
import 'package:tradeflow_mobile/ui/design_system/components.dart';

import 'trade_store_test.dart' show MemoryRepository;
import 'widget_test.dart' show chooseDemoProfile;

void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'public entry does not expose local business data or require storage',
    (tester) async {
      final store = TradeStore(MemoryRepository());
      await tester.pumpWidget(TradeFlowApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('Démonstration · Visiteur'), findsOneWidget);
      expect(find.text('Authentification non connectée'), findsOneWidget);
      expect(find.text('Produits & stocks'), findsNothing);
      await tester.tap(find.text('Catalogue').last);
      await tester.pumpAndSettle();
      expect(find.text('Catalogue : interface à venir'), findsOneWidget);
      expect(store.loaded, isFalse);
    },
  );

  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('all profile navigations at width $width preserve local data', (
      tester,
    ) async {
      viewport(tester, Size(width, 900));
      final repository = MemoryRepository();
      final store = TradeStore(repository);
      await store.load();
      await store.loadDemo();
      final original = store.data.toJson();
      await tester.pumpWidget(TradeFlowApp(store: store));
      await tester.pumpAndSettle();
      expect(
        find.byType(width >= 900 ? NavigationRail : NavigationBar),
        findsOneWidget,
      );
      for (final role in DemoProfile.values) {
        await chooseDemoProfile(tester, role.label);
        expect(find.text('Démonstration · ${role.label}'), findsOneWidget);
        final destinations = destinationsFor(role);
        for (var i = 1; i < destinations.length; i++) {
          await tester.tap(find.text(destinations[i].label).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      expect(store.data.toJson(), original);
      expect(repository.snapshot.toJson(), original);
    });
  }

  testWidgets(
    'large text and component examples remain usable on small screens',
    (tester) async {
      viewport(tester, const Size(320, 900));
      final store = TradeStore(MemoryRepository());
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: TradeFlowApp(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Guide des composants'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Vérifier le champ'),
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('foundation-gallery-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Vérifier le champ'));
      await tester.pumpAndSettle();
      expect(find.text('Renseignez un nom de produit.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'Erreur'),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('foundation-gallery-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final chip = find.widgetWithText(ChoiceChip, 'Erreur');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Réessayer'),
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('foundation-gallery-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('Opération réussie'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('confirmation supports cancellation and confirmation', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FlowButton(
              label: 'Tester',
              onPressed: () async {
                result = await showFlowConfirmation(
                  context,
                  title: 'Confirmer ?',
                  description: 'Exemple sans écriture.',
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tester'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.text('Tester'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
