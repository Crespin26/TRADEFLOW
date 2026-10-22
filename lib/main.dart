import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/trade_repository.dart';
import 'domain/trade_store.dart';
import 'ui/app.dart';

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
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Le stockage local est indisponible. Vérifiez les autorisations de votre appareil puis relancez TradeFlow.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
