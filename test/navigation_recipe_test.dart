import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/application/shopping_session.dart';
import 'package:tradeflow_mobile/ui/app.dart';

import 'support/fakes.dart' show MemoryRepository;
import 'support/navigation.dart' show chooseDemoProfile;

void main() {
  testWidgets(
    'session changes select the client space and logout leaves a valid public destination',
    (tester) async {
      final session = ShoppingSession();
      await tester.pumpWidget(
        TradeFlowApp(
          store: TradeStore(MemoryRepository()),
          shoppingSession: session,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Démonstration · Visiteur'), findsOneWidget);
      session.signInDemo('client@example.com');
      await tester.pumpAndSettle();
      expect(find.text('Démonstration · Client'), findsOneWidget);
      expect(find.text('Bienvenue dans votre espace client'), findsOneWidget);
      await tester.tap(find.text('Profil').last);
      await tester.pumpAndSettle();
      session.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Démonstration · Visiteur'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'manual profile preview is retained without granting authentication',
    (tester) async {
      final session = ShoppingSession();
      await tester.pumpWidget(
        TradeFlowApp(
          store: TradeStore(MemoryRepository()),
          shoppingSession: session,
        ),
      );
      await tester.pumpAndSettle();
      await chooseDemoProfile(tester, 'Magasinier');
      session.signInDemo('client@example.com');
      await tester.pumpAndSettle();
      expect(find.text('Démonstration · Magasinier'), findsOneWidget);
      session.signOut();
      await tester.pumpAndSettle();
      expect(session.customerReady, isFalse);
      expect(find.text('Démonstration · Magasinier'), findsOneWidget);
    },
  );
}
