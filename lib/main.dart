import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/trade_repository.dart';
import 'domain/trade_store.dart';
import 'ui/app.dart';
import 'ui/design_system/theme.dart';
import 'ui/design_system/components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final preferences = await SharedPreferences.getInstance();
    final store = TradeStore(LocalTradeRepository(preferences));
    runApp(TradeFlowApp(store: store));
    await store.load();
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
