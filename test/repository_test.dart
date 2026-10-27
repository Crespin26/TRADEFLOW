import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradeflow_mobile/data/trade_repository.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('local snapshot survives a new store instance', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = TradeStore(LocalTradeRepository(prefs));
    await first.load();
    await first.loadDemo();
    final second = TradeStore(LocalTradeRepository(prefs));
    await second.load();
    expect(second.data.toJson(), first.data.toJson());
  });

  test(
    'corrupt storage blocks writes and preserves original content',
    () async {
      SharedPreferences.setMockInitialValues({
        LocalTradeRepository.storageKey: '{broken',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = TradeStore(LocalTradeRepository(prefs));
      await store.load();
      expect(store.loaded, isFalse);
      expect(store.loadError, isNotNull);
      await expectLater(
        store.addContact(
          name: 'Client',
          kind: ContactKind.client,
          country: 'Bénin',
          email: '',
          phone: '',
        ),
        throwsStateError,
      );
      expect(prefs.getString(LocalTradeRepository.storageKey), '{broken');
    },
  );
  test(
    'loading examples preserves renamed category and unit references',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = TradeStore(LocalTradeRepository(prefs));
      await store.load();
      await store.saveReference(
        category: true,
        previous: 'Sans catégorie',
        value: 'Personnalisé',
      );
      await store.saveReference(
        category: false,
        previous: 'pièce',
        value: 'lot',
      );
      final categories = store.data.categories, units = store.data.units;
      await store.loadDemo();
      expect(store.data.categories, categories);
      expect(store.data.units, units);
      expect(
        store.data.products.every(
          (p) => categories.contains(p.category) && units.contains(p.unit),
        ),
        isTrue,
      );
    },
  );
}
