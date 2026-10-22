import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

abstract interface class TradeRepository {
  Future<TradeData> load();
  Future<void> save(TradeData data);
}

/// One versioned snapshot keeps orders, stock and history together.
/// This is a local prototype store, not a multi-user business database.
class LocalTradeRepository implements TradeRepository {
  LocalTradeRepository(this.preferences);
  final SharedPreferences preferences;
  static const storageKey = 'tradeflow.snapshot.v1';

  @override
  Future<TradeData> load() async {
    final raw = preferences.getString(storageKey);
    if (raw == null) return TradeData();
    return TradeData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(TradeData data) async {
    final success = await preferences.setString(
      storageKey,
      jsonEncode(data.toJson()),
    );
    if (!success) throw StateError('La sauvegarde locale a échoué.');
  }
}
