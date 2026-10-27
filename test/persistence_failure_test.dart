import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:tradeflow_mobile/data/trade_repository.dart';
import 'package:tradeflow_mobile/data/public_cart_repository.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/application/shopping_session.dart';
import 'package:tradeflow_mobile/domain/models.dart';

class FailingPreferencesStore extends InMemorySharedPreferencesStore {
  FailingPreferencesStore() : super.empty();
  bool reject = false, throwWrite = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (throwWrite) throw StateError('Platform write rejected');
    if (reject) return false;
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FailingPreferencesStore platform;
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    platform = FailingPreferencesStore();
    SharedPreferencesStorePlatform.instance = platform;
    preferences = await SharedPreferences.getInstance();
  });
  tearDown(() => SharedPreferences.setMockInitialValues({}));
  for (final throws in [false, true]) {
    test(
      'failed snapshot write (throw=$throws) is absent from state, cache and reload',
      () async {
        final store = TradeStore(LocalTradeRepository(preferences));
        await store.load();
        await store.addProduct(
          name: 'Riz',
          sku: 'R',
          quantity: 2,
          threshold: 1,
          price: 100,
        );
        final before = store.data;
        final raw = preferences.getString(LocalTradeRepository.storageKey);
        platform.reject = !throws;
        platform.throwWrite = throws;
        await expectLater(
          store.adjustStock(before.products.single.id, 1, 'Entrée'),
          throwsStateError,
        );
        expect(store.data, same(before));
        expect(preferences.getString(LocalTradeRepository.storageKey), raw);
        await store.load();
        expect(store.loaded, isTrue);
        expect(store.data.toJson(), before.toJson());
      },
    );
  }
  test(
    'failed cart write cannot reappear through SharedPreferences cache',
    () async {
      final cart = ShoppingSession(
        repository: LocalPublicCartRepository(preferences),
      );
      await cart.load();
      await cart.add('rice');
      platform.reject = true;
      await expectLater(cart.add('oil'), throwsStateError);
      expect(cart.quantities, {'rice': 1});
      await cart.load();
      expect(cart.quantities, {'rice': 1});
      expect(cart.ready, isTrue);
    },
  );
  test('loads refresh values changed outside the preference cache', () async {
    final repository = LocalTradeRepository(preferences);
    await repository.load();
    final external = TradeData(
      products: const [
        Product(
          id: 'external',
          name: 'Externe',
          sku: 'EXT',
          quantity: 4,
          threshold: 1,
          price: 100,
        ),
      ],
    );
    await platform.setValue(
      'String',
      'flutter.${LocalTradeRepository.storageKey}',
      jsonEncode(external.toJson()),
    );
    expect(preferences.getString(LocalTradeRepository.storageKey), isNull);
    expect((await repository.load()).products.single.id, 'external');
  });
}
