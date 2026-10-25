import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradeflow_mobile/data/public_cart_repository.dart';
import 'package:tradeflow_mobile/domain/shopping_session.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('multi-line cart merges products and computes integer totals', () async {
    final session = ShoppingSession();
    await session.add('rice', quantity: 2);
    await session.add('rice');
    await session.add('oil');
    expect(session.lines.length, 2);
    expect(session.itemCount, 4);
    expect(session.total, 63000);
    await session.setQuantity('rice', 1);
    await session.remove('oil');
    expect(session.total, 18500);
  });
  test(
    'unavailable products and invalid quantities cannot enter the cart',
    () async {
      final session = ShoppingSession();
      await expectLater(session.add('workwear'), throwsArgumentError);
      await expectLater(session.add('rice', quantity: 0), throwsArgumentError);
      await session.add('rice', quantity: 999);
      await expectLater(session.add('rice'), throwsArgumentError);
      await expectLater(session.setQuantity('rice', 0), throwsArgumentError);
      await expectLater(session.setQuantity('rice', 1000), throwsArgumentError);
      expect(session.itemCount, 999);
    },
  );
  test('login, pending verification and logout preserve the cart', () async {
    final session = ShoppingSession();
    await session.add('cocoa');
    await expectLater(session.confirmDemo(exampleAddress), throwsStateError);
    session.signInDemo('client@example.com', registration: true);
    await expectLater(session.confirmDemo(exampleAddress), throwsStateError);
    session.verifyDemo();
    expect(session.verified, isTrue);
    session.signOut();
    expect(session.signedIn, isFalse);
    expect(session.itemCount, 1);
  });
  test('confirmation takes a snapshot and clears cart once', () async {
    final session = ShoppingSession();
    await session.add('rice', quantity: 2);
    session.signInDemo('client@example.com');
    final receipt = await session.confirmDemo(exampleAddress);
    expect(receipt.total, 37000);
    expect(receipt.lines.single.quantity, 2);
    expect(session.lines, isEmpty);
    await expectLater(session.confirmDemo(exampleAddress), throwsStateError);
    expect(session.receipts.length, 1);
    session.signOut();
    expect(session.receipts, isEmpty);
  });
  test(
    'persistence failure preserves cart and does not create confirmation',
    () async {
      final repo = MemoryCartRepository();
      final session = ShoppingSession(repository: repo);
      await session.load();
      await session.add('oil');
      session.signInDemo('client@example.com');
      repo.fail = true;
      await expectLater(session.confirmDemo(exampleAddress), throwsStateError);
      expect(session.itemCount, 1);
      expect(session.receipts, isEmpty);
      expect(session.busy, isFalse);
    },
  );
  test(
    'concurrent writes and logout during persistence are rejected',
    () async {
      final repo = MemoryCartRepository();
      final session = ShoppingSession(repository: repo);
      await session.load();
      repo.gate = Completer<void>();
      final pending = session.add('rice');
      await expectLater(session.add('oil'), throwsStateError);
      expect(session.signOut, throwsStateError);
      repo.gate!.complete();
      await pending;
      expect(session.lines.single.product.id, 'rice');
    },
  );
  test(
    'local storage survives restart and contains no session or password',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = ShoppingSession(
        repository: LocalPublicCartRepository(prefs),
      );
      await first.load();
      await first.add('rice');
      first.signInDemo('client@example.com');
      final second = ShoppingSession(
        repository: LocalPublicCartRepository(prefs),
      );
      await second.load();
      expect(second.itemCount, 1);
      expect(second.signedIn, isFalse);
      expect(
        prefs.getString(LocalPublicCartRepository.key),
        '{"version":1,"quantities":{"rice":1}}',
      );
    },
  );
  test('corrupt cart is preserved until explicit reset', () async {
    SharedPreferences.setMockInitialValues({
      LocalPublicCartRepository.key: 'broken',
    });
    final prefs = await SharedPreferences.getInstance();
    final session = ShoppingSession(
      repository: LocalPublicCartRepository(prefs),
    );
    await session.load();
    expect(session.ready, isFalse);
    await expectLater(session.add('rice'), throwsStateError);
    expect(prefs.getString(LocalPublicCartRepository.key), 'broken');
    await session.reset();
    expect(session.ready, isTrue);
    expect(session.itemCount, 0);
  });
}
