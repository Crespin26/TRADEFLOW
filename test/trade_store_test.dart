import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/data/trade_repository.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';

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

void main() {
  late MemoryRepository repository;
  late TradeStore store;
  setUp(() async {
    repository = MemoryRepository();
    store = TradeStore(repository);
    await store.load();
    await store.addProduct(
      name: 'Riz',
      sku: 'RIZ',
      quantity: 10,
      threshold: 3,
      price: 15000,
    );
    await store.addContact(
      name: 'Client',
      kind: ContactKind.client,
      country: 'Bénin',
      email: '',
      phone: '',
    );
  });
  Future<void> createOrder([int quantity = 4]) => store.createOrder(
    productId: store.data.products.single.id,
    customerId: store.data.contacts.single.id,
    quantity: quantity,
    destination: 'Cotonou',
  );

  test(
    'order deducts stock, captures price and records movement atomically',
    () async {
      await createOrder();
      expect(store.data.products.single.quantity, 6);
      expect(store.data.orders.single.total, 60000);
      expect(store.data.movements.first.delta, -4);
      expect(repository.snapshot, same(store.data));
    },
  );

  test('insufficient stock leaves all data untouched', () async {
    final previous = store.data;
    await expectLater(createOrder(11), throwsArgumentError);
    expect(store.data, same(previous));
    await expectLater(createOrder(0), throwsArgumentError);
    expect(store.data, same(previous));
  });

  test('cancellation restores stock exactly once', () async {
    await createOrder();
    final id = store.data.orders.single.id;
    await store.changeOrderStatus(id, OrderStatus.cancelled);
    expect(store.data.products.single.quantity, 10);
    expect(store.data.movements.first.delta, 4);
    await expectLater(
      store.changeOrderStatus(id, OrderStatus.cancelled),
      throwsArgumentError,
    );
    expect(store.data.products.single.quantity, 10);
  });

  test('shipping and delivery do not deduct stock again', () async {
    await createOrder();
    final id = store.data.orders.single.id;
    await expectLater(
      store.changeOrderStatus(id, OrderStatus.delivered),
      throwsArgumentError,
    );
    await store.changeOrderStatus(id, OrderStatus.shipped);
    await expectLater(
      store.changeOrderStatus(id, OrderStatus.cancelled),
      throwsArgumentError,
    );
    await store.changeOrderStatus(id, OrderStatus.delivered);
    expect(store.data.products.single.quantity, 6);
    expect(store.data.movements.length, 2);
  });

  test(
    'stock adjustment validates quantity, reason, and low-stock threshold',
    () async {
      final id = store.data.products.single.id;
      await expectLater(
        store.adjustStock(id, -11, 'Perte'),
        throwsArgumentError,
      );
      await expectLater(
        store.adjustStock(id, 0, 'Réception'),
        throwsArgumentError,
      );
      await expectLater(store.adjustStock(id, 1, ''), throwsArgumentError);
      await store.adjustStock(id, -7, 'Sortie');
      expect(store.data.products.single.lowStock, isTrue);
      await store.adjustStock(id, 2, 'Réception');
      expect(store.data.products.single.lowStock, isFalse);
    },
  );

  test('SKU uniqueness ignores case and whitespace', () async {
    await expectLater(
      store.addProduct(
        name: 'Autre',
        sku: ' riz ',
        quantity: 0,
        threshold: 0,
        price: 0,
      ),
      throwsArgumentError,
    );
    expect(store.data.products.length, 1);
  });

  test(
    'failed persistence does not publish partial stock or order changes',
    () async {
      final previous = store.data;
      repository.failSave = true;
      await expectLater(createOrder(), throwsStateError);
      expect(store.data, same(previous));
      expect(store.busy, isFalse);
      expect(repository.snapshot, same(previous));
    },
  );

  test('concurrent writes are rejected to prevent lost updates', () async {
    repository.gate = Completer<void>();
    final first = createOrder();
    await expectLater(createOrder(), throwsStateError);
    repository.gate!.complete();
    await first;
    expect(store.data.orders.length, 1);
    expect(store.data.products.single.quantity, 6);
  });

  test('snapshot round trip preserves all data and enum values', () async {
    await createOrder();
    final restored = TradeData.fromJson(store.data.toJson());
    expect(restored.toJson(), store.data.toJson());
    expect(() => TradeData.fromJson({'version': 999}), throwsFormatException);
  });

  test('supplier cannot be used as a customer', () async {
    await store.addContact(
      name: 'Fournisseur',
      kind: ContactKind.supplier,
      country: 'Togo',
      email: '',
      phone: '',
    );
    await expectLater(
      store.createOrder(
        productId: store.data.products.single.id,
        customerId: store.data.contacts.last.id,
        quantity: 1,
        destination: 'Lomé',
      ),
      throwsArgumentError,
    );
  });
}
