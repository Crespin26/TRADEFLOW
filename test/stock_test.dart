import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradeflow_mobile/data/trade_repository.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';

import 'trade_store_test.dart' show MemoryRepository;

StockCount count(Product p, int value) => StockCount(
  productId: p.id,
  productName: p.name,
  sku: p.sku,
  unit: p.unit,
  expectedQuantity: p.quantity,
  countedQuantity: value,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryRepository repo;
  late TradeStore store;
  setUp(() async {
    repo = MemoryRepository();
    store = TradeStore(repo);
    await store.load();
    await store.addProduct(
      name: 'Riz',
      sku: 'RIZ',
      quantity: 10,
      threshold: 3,
      price: 500,
      unit: 'sac',
    );
    await store.addProduct(
      name: 'Huile',
      sku: 'HUI',
      quantity: 4,
      threshold: 2,
      price: 700,
      unit: 'bidon',
    );
  });
  test(
    'initial, receipt and issue capture stable identity and before/after',
    () async {
      final p = store.data.products.first;
      final initial = store.data.movements.last;
      expect(initial.kind, StockMovementKind.initial);
      expect(initial.productId, p.id);
      expect(initial.beforeQuantity, 0);
      expect(initial.afterQuantity, 10);
      await store.adjustStock(p.id, 5, 'Réception');
      final incoming = store.data.movements.first;
      expect(incoming.kind, StockMovementKind.receipt);
      expect(incoming.beforeQuantity, 10);
      expect(incoming.afterQuantity, 15);
      await store.adjustStock(p.id, -2, 'Perte');
      final outgoing = store.data.movements.first;
      expect(outgoing.kind, StockMovementKind.issue);
      expect(outgoing.afterQuantity, 13);
      await store.updateProduct(
        store.data.products.first.copyWith(name: 'Autre nom', sku: 'NEW'),
      );
      expect(store.data.movements.first.productName, 'Riz');
      expect(store.data.movements.first.sku, 'RIZ');
    },
  );
  test(
    'inventory commits multiple counts and linked corrections in one snapshot',
    () async {
      final products = [...store.data.products];
      await store.performInventory(
        counts: [count(products[0], 8), count(products[1], 0)],
        reason: 'Comptage du soir',
      );
      expect(store.data.products.map((p) => p.quantity), [8, 0]);
      final inventory = store.data.inventories.single;
      expect(inventory.correctedProducts, 2);
      expect(inventory.counts.map((c) => c.delta), [-2, -4]);
      expect(
        store.data.movements
            .take(2)
            .every(
              (m) =>
                  m.kind == StockMovementKind.inventory &&
                  m.reference == inventory.id,
            ),
        isTrue,
      );
      expect(repo.snapshot, same(store.data));
      expect(store.data.products.last.lowStock, isTrue);
      await store.updateProduct(
        store.data.products.first.copyWith(name: 'Renommé'),
      );
      expect(store.data.inventories.single.counts.first.productName, 'Riz');
    },
  );
  test('unchanged counts remain audited without creating zero movements and omitted products are untouched', () async {
    final before = store.data.movements.length;
    await store.performInventory(
      counts: [count(store.data.products.first, 10)],
      reason: 'Contrôle',
    );
    expect(store.data.inventories.single.correctedProducts, 0);
    expect(store.data.movements.length, before);
    expect(store.data.products.last.quantity, 4);
  });
  test(
    'stale stock or unit and archived products cannot overwrite newer values',
    () async {
      final p = store.data.products.first;
      final entry = count(p, 2);
      await store.adjustStock(p.id, 1, 'Réception');
      final before = store.data;
      await expectLater(
        store.performInventory(counts: [entry], reason: 'Comptage'),
        throwsStateError,
      );
      await expectLater(
        store.adjustStock(p.id, -1, 'Sortie', expectedQuantity: p.quantity),
        throwsStateError,
      );
      expect(store.data, same(before));
      final fresh = store.data.products.first;
      await store.updateProduct(fresh.copyWith(unit: 'kg'));
      await expectLater(
        store.performInventory(counts: [count(fresh, 2)], reason: 'Comptage'),
        throwsStateError,
      );
      await store.setProductStatus(p.id, ProductStatus.archived);
      await expectLater(
        store.performInventory(
          counts: [count(store.data.products.first, 2)],
          reason: 'Comptage',
        ),
        throwsStateError,
      );
    },
  );
  test('empty, duplicate, negative or oversized inventories leave all products untouched', () async {
    final p = store.data.products.first;
    final previous = store.data;
    for (final entries in <List<StockCount>>[
      [],
      [count(p, 1), count(p, 2)],
      [count(p, -1)],
      [count(p, 1000000001)],
    ]) {
      await expectLater(
        store.performInventory(counts: entries, reason: 'Comptage'),
        throwsArgumentError,
      );
    }
    await expectLater(
      store.performInventory(counts: [count(p, 1)], reason: ' '),
      throwsArgumentError,
    );
    await expectLater(
      store.adjustStock(p.id, 1000000000, 'Surplus'),
      throwsArgumentError,
    );
    expect(store.data, same(previous));
  });
  test(
    'save failure rolls back stock, corrections and inventory together',
    () async {
      final previous = store.data;
      repo.failSave = true;
      await expectLater(
        store.performInventory(
          counts: [
            count(previous.products.first, 0),
            count(previous.products.last, 1),
          ],
          reason: 'Comptage',
        ),
        throwsStateError,
      );
      expect(store.data, same(previous));
      expect(store.data.inventories, isEmpty);
      expect(store.busy, isFalse);
    },
  );
  test('sales and cancellation produce traceable movements including archived products', () async {
    final p = store.data.products.first;
    await store.addContact(
      name: 'Client',
      kind: ContactKind.client,
      country: 'Bénin',
      email: '',
      phone: '',
    );
    await store.createOrder(
      productId: p.id,
      customerId: store.data.contacts.single.id,
      quantity: 3,
      destination: 'Cotonou',
    );
    final order = store.data.orders.single;
    final sale = store.data.movements.first;
    expect(sale.kind, StockMovementKind.sale);
    expect(sale.reference, order.id);
    expect(sale.beforeQuantity, 10);
    expect(sale.afterQuantity, 7);
    await store.setProductStatus(p.id, ProductStatus.archived);
    await store.changeOrderStatus(order.id, OrderStatus.cancelled);
    final returned = store.data.movements.first;
    expect(returned.kind, StockMovementKind.cancellation);
    expect(returned.afterQuantity, 10);
    expect(returned.productId, p.id);
  });
  test('old movements load without inventing historical quantities or product identity', () {
    final old = {
      'id': 'OLD',
      'productName': 'Riz',
      'delta': 2,
      'reason': 'Ancien',
      'createdAt': DateTime(2025).toIso8601String(),
    };
    final m = StockMovement.fromJson(old);
    expect(m.productId, isNull);
    expect(m.beforeQuantity, isNull);
    expect(m.afterQuantity, isNull);
    expect(m.kind, StockMovementKind.legacy);
    final snapshot = store.data.toJson()..remove('inventories');
    expect(TradeData.fromJson(snapshot).inventories, isEmpty);
  });
  test(
    'inventory and movement details survive JSON and local repository restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final local = TradeStore(LocalTradeRepository(prefs));
      await local.load();
      await local.addProduct(
        name: 'Produit',
        sku: 'PROD',
        quantity: 5,
        threshold: 1,
        price: 10,
      );
      await local.performInventory(
        counts: [count(local.data.products.single, 3)],
        reason: 'Inventaire physique',
      );
      final next = TradeStore(LocalTradeRepository(prefs));
      await next.load();
      expect(next.data.inventories.single.counts.single.delta, -2);
      expect(next.data.movements.first.afterQuantity, 3);
      expect(next.data.toJson(), jsonDecode(jsonEncode(local.data.toJson())));
    },
  );
  test('cancellation cannot overflow the stock limit or partially change its order', () async {
    final p = store.data.products.first;
    await store.addContact(
      name: 'Client',
      kind: ContactKind.client,
      country: 'Bénin',
      email: '',
      phone: '',
    );
    await store.createOrder(
      productId: p.id,
      customerId: store.data.contacts.single.id,
      quantity: 3,
      destination: 'Cotonou',
    );
    await store.adjustStock(p.id, 999999993, 'Réception exceptionnelle');
    final previous = store.data;
    await expectLater(
      store.changeOrderStatus(previous.orders.single.id, OrderStatus.cancelled),
      throwsArgumentError,
    );
    expect(store.data, same(previous));
    expect(store.data.products.first.quantity, 1000000000);
    expect(store.data.orders.single.status, OrderStatus.confirmed);
  });
}
