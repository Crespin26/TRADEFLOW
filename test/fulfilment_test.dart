import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/trade_store.dart';

import 'trade_store_test.dart' show MemoryRepository;

void main() {
  late TradeStore store;
  late MemoryRepository repo;
  late String order;
  setUp(() async {
    repo = MemoryRepository();
    store = TradeStore(repo);
    await store.load();
    await store.addProduct(
      name: 'Riz',
      sku: 'R',
      quantity: 10,
      threshold: 1,
      price: 100,
      unit: 'sac',
    );
    await store.addContact(
      name: 'Client',
      kind: ContactKind.client,
      country: 'Bénin',
      email: '',
      phone: '',
    );
    await store.createOrder(
      productId: store.data.products.single.id,
      customerId: store.data.contacts.single.id,
      quantity: 4,
      destination: 'Cotonou',
    );
    order = store.data.orders.single.id;
  });
  test(
    'planning is revisioned, persisted and does not change quantities',
    () async {
      await store.saveDeliveryPlan(
        order,
        carrier: 'Transport A',
        trackingNumber: 'REF-1',
        notes: 'Matin',
        expectedDate: DateTime.now().subtract(const Duration(days: 1)),
        expectedRevision: 0,
      );
      final plan = store.data.deliveryPlans.single;
      expect(plan.lateAt(DateTime.now()), isTrue);
      expect(store.data.products.single.quantity, 6);
      expect(store.data.orders.single.revision, 0);
      await expectLater(
        store.saveDeliveryPlan(
          order,
          carrier: 'Autre',
          trackingNumber: '',
          notes: '',
          expectedRevision: 0,
        ),
        throwsStateError,
      );
      final restored = TradeData.fromJson(store.data.toJson());
      expect(restored.deliveryPlans.single.toJson(), plan.toJson());
    },
  );
  test(
    'deliveries snapshot their carrier and completed tracking is read-only',
    () async {
      await store.saveDeliveryPlan(
        order,
        carrier: 'Transport A',
        trackingNumber: 'REF-1',
        notes: '',
        expectedRevision: 0,
      );
      await store.changeOrderStatus(order, OrderStatus.shipped);
      await store.recordDelivery(order, 2, 'BL', expectedRevision: 1);
      await store.saveDeliveryPlan(
        order,
        carrier: 'Transport B',
        trackingNumber: 'REF-2',
        notes: '',
        expectedRevision: 1,
      );
      expect(store.data.commercialEvents.single.carrier, 'Transport A');
      expect(store.data.commercialEvents.single.trackingNumber, 'REF-1');
      await store.recordDelivery(order, 2, 'Solde', expectedRevision: 2);
      await expectLater(
        store.saveDeliveryPlan(
          order,
          carrier: 'C',
          trackingNumber: '',
          notes: '',
          expectedRevision: 2,
        ),
        throwsStateError,
      );
    },
  );
  test('non-resellable returns are audited without adding available stock or a zero movement', () async {
    await store.changeOrderStatus(order, OrderStatus.shipped);
    await store.changeOrderStatus(order, OrderStatus.delivered);
    final movements = store.data.movements.length;
    await store.returnCustomer(
      order,
      2,
      'Marchandise abîmée',
      expectedRevision: 2,
      restock: false,
    );
    expect(store.data.orders.single.returnedQuantity, 2);
    expect(store.data.products.single.quantity, 6);
    expect(store.data.movements.length, movements);
    expect(store.data.commercialEvents.first.restocked, isFalse);
    await store.returnCustomer(order, 2, 'Bon état', expectedRevision: 3);
    expect(store.data.products.single.quantity, 8);
    await expectLater(
      store.returnCustomer(
        order,
        1,
        'Double',
        expectedRevision: 4,
        restock: false,
      ),
      throwsArgumentError,
    );
  });
  test(
    'failed planning and damaged return leave the full snapshot untouched',
    () async {
      final previous = store.data;
      repo.failSave = true;
      await expectLater(
        store.saveDeliveryPlan(
          order,
          carrier: 'A',
          trackingNumber: 'B',
          notes: '',
          expectedRevision: 0,
        ),
        throwsStateError,
      );
      expect(store.data, same(previous));
      repo.failSave = false;
      await store.changeOrderStatus(order, OrderStatus.shipped);
      await store.changeOrderStatus(order, OrderStatus.delivered);
      final delivered = store.data;
      repo.failSave = true;
      await expectLater(
        store.returnCustomer(
          order,
          1,
          'Abîmé',
          expectedRevision: 2,
          restock: false,
        ),
        throwsStateError,
      );
      expect(store.data, same(delivered));
    },
  );
  test('old events infer restocked returns and snapshots without plans stay readable', () async {
    await store.changeOrderStatus(order, OrderStatus.shipped);
    await store.changeOrderStatus(order, OrderStatus.delivered);
    final json = store.data.commercialEvents.single.toJson()
      ..remove('restocked')
      ..remove('carrier')
      ..remove('trackingNumber');
    expect(CommercialEvent.fromJson(json).restocked, isTrue);
    final snapshot = store.data.toJson()..remove('deliveryPlans');
    expect(TradeData.fromJson(snapshot).deliveryPlans, isEmpty);
  });
}
