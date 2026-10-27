import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:tradeflow_mobile/main.dart' as bootstrap;
import 'package:tradeflow_mobile/ui/app.dart';
import 'package:tradeflow_mobile/data/trade_repository.dart';

class UnavailablePreferences extends InMemorySharedPreferencesStore {
  UnavailablePreferences() : super.empty();
  @override
  Future<Map<String, Object>> getAll() async =>
      throw StateError('Storage unavailable');
}

void main() {
  tearDown(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('bootstrap composes storage and controllers without Firebase', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(bootstrap.main);
    await tester.pumpAndSettle();
    final app = tester.widget<TradeFlowApp>(find.byType(TradeFlowApp));
    expect(app.store.loaded, isTrue);
    expect(app.shoppingSession!.ready, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'bootstrap preserves an unreadable snapshot instead of resetting it',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        LocalTradeRepository.storageKey: '{broken',
      });
      await tester.runAsync(bootstrap.main);
      await tester.pumpAndSettle();
      final app = tester.widget<TradeFlowApp>(find.byType(TradeFlowApp));
      expect(app.store.loaded, isFalse);
      expect(app.store.loadError, isNotNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(LocalTradeRepository.storageKey), '{broken');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'platform initialization failure produces a recoverable startup error view',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = UnavailablePreferences();
      await tester.runAsync(bootstrap.main);
      await tester.pumpAndSettle();
      expect(find.text('Stockage local indisponible'), findsOneWidget);
      expect(find.byType(TradeFlowApp), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
