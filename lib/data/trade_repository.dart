import 'local_preferences.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import '../domain/repositories.dart';

/// One versioned snapshot keeps orders, stock and history together.
/// This is a local prototype store, not a multi-user business database.
class LocalTradeRepository implements TradeRepository {
  LocalTradeRepository(this.preferences);
  final SharedPreferences preferences;
  static const storageKey = 'tradeflow.snapshot.v1';

  @override
  Future<TradeData> load() async {
    final raw = await readLocalString(preferences, storageKey);
    if (raw == null) return TradeData();
    return TradeData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(TradeData data) async {
    final encoded = jsonEncode(data.toJson());
    if (utf8.encode(encoded).length > 4000000) {
      throw StateError(
        'Sauvegarde locale trop volumineuse (4 Mo maximum). Retirez des photos inutilisées.',
      );
    }
    await writeLocalString(
      preferences,
      storageKey,
      encoded,
      failureMessage: 'La sauvegarde locale a échoué.',
    );
  }
}
