import 'models.dart';

/// Storage ports: implementations belong to infrastructure, never to the domain.
abstract interface class TradeRepository {
  Future<TradeData> load();
  Future<void> save(TradeData data);
}

abstract interface class PublicCartRepository {
  Future<Map<String, int>> load();
  Future<void> save(Map<String, int> quantities);
}
