import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/shopping_session.dart';

class LocalPublicCartRepository implements PublicCartRepository {
  LocalPublicCartRepository(this.preferences);
  final SharedPreferences preferences;
  static const key = 'tradeflow.publicCart.v1';
  @override
  Future<Map<String, int>> load() async {
    final raw = preferences.getString(key);
    if (raw == null) return {};
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 1) throw const FormatException('Version inconnue');
    return (json['quantities'] as Map<String, dynamic>).map(
      (id, quantity) => MapEntry(id, quantity as int),
    );
  }

  @override
  Future<void> save(Map<String, int> quantities) async {
    if (!await preferences.setString(
      key,
      jsonEncode({'version': 1, 'quantities': quantities}),
    )) {
      throw StateError('Impossible de sauvegarder le panier.');
    }
  }
}
