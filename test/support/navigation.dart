import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> chooseDemoProfile(WidgetTester tester, String role) async {
  await tester.tap(find.byTooltip('Changer de profil de démonstration'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(role),
    180,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('demo-profiles-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
}

Future<void> openManagement(WidgetTester tester) async {
  await chooseDemoProfile(tester, 'Administrateur');
  await tester.tap(find.text('Gestion').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ouvrir la gestion locale'));
  await tester.pumpAndSettle();
}
