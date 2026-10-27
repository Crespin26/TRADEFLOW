import 'dart:async';

import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/repositories.dart';
import 'package:tradeflow_mobile/domain/shopping_models.dart';

class MemoryRepository implements TradeRepository {
  TradeData snapshot = TradeData();
  bool failSave = false;
  Completer<void>? gate;
  @override
  Future<TradeData> load() async => snapshot;
  @override
  Future<void> save(TradeData data) async {
    if (gate != null) await gate!.future;
    if (failSave) throw StateError('Storage unavailable');
    snapshot = data;
  }
}

class MemoryCartRepository implements PublicCartRepository {
  Map<String, int> saved = {};
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<Map<String, int>> load() async => Map.of(saved);
  @override
  Future<void> save(Map<String, int> quantities) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('Storage unavailable');
    saved = Map.of(quantities);
  }
}

const exampleAddress = DeliveryAddress(
  name: 'Client exemple',
  phone: '00000000',
  street: 'Rue exemple',
  city: 'Cotonou',
  country: 'Bénin',
);
