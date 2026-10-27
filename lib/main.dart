import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/trade_repository.dart';
import 'data/public_cart_repository.dart';
import 'application/shopping_session.dart';
import 'application/trade_store.dart';
import 'ui/app.dart';
import 'ui/design_system/theme.dart';
import 'ui/design_system/components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final preferences = await SharedPreferences.getInstance();
    final store = TradeStore(LocalTradeRepository(preferences));
    final shopping = ShoppingSession(
      repository: LocalPublicCartRepository(preferences),
    );
    await store.load();
    await shopping.load();
    runApp(TradeFlowApp(store: store, shoppingSession: shopping));
  } catch (_) {
    runApp(
      MaterialApp(
        theme: buildTradeFlowTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FlowStateView(
                title: 'Stockage local indisponible',
                description: 'Vérifiez les autorisations de votre appareil puis relancez TradeFlow.',
                icon: Icons.storage_outlined,
                tone: FlowTone.error,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
