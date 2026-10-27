import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradeflow_mobile/data/trade_repository.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';

import 'support/fakes.dart' show MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryRepository repo;
  late TradeStore store;
  late String product, client, supplier;
  setUp(() async {
    repo = MemoryRepository();
    store = TradeStore(repo);
    await store.load();
    await store.addProduct(
      name: 'Riz',
      sku: 'RIZ',
      quantity: 20,
      threshold: 3,
      price: 1000,
      purchasePrice: 600,
      unit: 'sac',
    );
    await store.addContact(
      name: 'Client',
      kind: ContactKind.client,
      country: 'Bénin',
      email: '',
      phone: '',
    );
    await store.addContact(
      name: 'Fournisseur',
      kind: ContactKind.supplier,
      country: 'Togo',
      email: '',
      phone: '',
    );
    product = store.data.products.single.id;
    client = store.data.contacts.first.id;
    supplier = store.data.contacts.last.id;
  });
  Future<String> quote({int quantity = 5, int price = 900}) => store.saveQuote(
    customerId: client,
    productId: product,
    quantity: quantity,
    unitPrice: price,
    destination: 'Cotonou',
    expiresAt: DateTime.now().add(const Duration(days: 30)),
  );
  Future<void> accept(String id) async {
    await store.changeQuoteStatus(
      id,
      QuoteStatus.sent,
      expectedRevision: store.data.quotes
          .firstWhere((q) => q.id == id)
          .revision,
    );
    await store.changeQuoteStatus(
      id,
      QuoteStatus.accepted,
      expectedRevision: store.data.quotes
          .firstWhere((q) => q.id == id)
          .revision,
    );
  }

  Future<String> purchase({int quantity = 8}) => store.savePurchase(
    supplierId: supplier,
    productId: product,
    quantity: quantity,
    unitPrice: 600,
    destination: 'Dépôt',
  );
  Future<void> orderPurchase(String id) => store.changePurchaseStatus(
    id,
    PurchaseStatus.ordered,
    expectedRevision: store.data.purchases
        .firstWhere((p) => p.id == id)
        .revision,
  );
  Future<String> sale({int quantity = 5}) async {
    await store.createOrder(
      productId: product,
      customerId: client,
      quantity: quantity,
      destination: 'Cotonou',
    );
    return store.data.orders.first.id;
  }

  test('quote lifecycle never reserves stock and conversion atomically preserves agreed price and names', () async {
    final id = await quote();
    expect(store.data.products.single.quantity, 20);
    expect(store.data.orders, isEmpty);
    await accept(id);
    await store.updateProduct(
      store.data.products.single.copyWith(price: 1500, name: 'Riz premium'),
    );
    await store.updateContact(
      store.data.contacts.first.copyWith(name: 'Client renommé'),
    );
    final orderId = await store.convertQuote(id, expectedRevision: 2);
    final order = store.data.orders.single;
    expect(order.id, orderId);
    expect(order.unitPrice, 900);
    expect(order.productName, 'Riz');
    expect(order.customerName, 'Client');
    expect(order.quoteId, id);
    expect(store.data.products.single.quantity, 15);
    expect(store.data.quotes.single.status, QuoteStatus.converted);
    expect(store.data.movements.first.delta, -5);
    expect(await store.convertQuote(id, expectedRevision: 2), orderId);
    expect(store.data.orders.length, 1);
    expect(store.data.products.single.quantity, 15);
  });
  test('only accepted valid quotes with available stock convert and all failures preserve state', () async {
    final id = await quote(quantity: 25);
    final before = store.data;
    await expectLater(
      store.convertQuote(id, expectedRevision: 0),
      throwsStateError,
    );
    expect(store.data, same(before));
    await accept(id);
    final accepted = store.data;
    await expectLater(
      store.convertQuote(id, expectedRevision: 2),
      throwsArgumentError,
    );
    expect(store.data, same(accepted));
    await store.adjustStock(product, 10, 'Réception');
    await store.convertQuote(id, expectedRevision: 2);
    expect(store.data.products.single.quantity, 5);
  });
  test(
    'quote rejects expiry, invalid transitions and edits after sending',
    () async {
      await expectLater(
        store.saveQuote(
          customerId: client,
          productId: product,
          quantity: 1,
          unitPrice: 1,
          destination: 'Cotonou',
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        throwsArgumentError,
      );
      final id = await quote();
      await expectLater(
        store.changeQuoteStatus(id, QuoteStatus.accepted, expectedRevision: 0),
        throwsArgumentError,
      );
      await store.changeQuoteStatus(id, QuoteStatus.sent, expectedRevision: 0);
      await expectLater(
        store.saveQuote(
          id: id,
          expectedRevision: 1,
          customerId: client,
          productId: product,
          quantity: 1,
          unitPrice: 1,
          destination: 'Cotonou',
          expiresAt: DateTime.now().add(const Duration(days: 2)),
        ),
        throwsStateError,
      );
      final json = store.data.toJson();
      final quotes = json['quotes'] as List;
      (quotes.single as Map<String, dynamic>)['expiresAt'] = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      repo.snapshot = TradeData.fromJson(json);
      await store.load();
      await expectLater(
        store.changeQuoteStatus(id, QuoteStatus.accepted, expectedRevision: 1),
        throwsStateError,
      );
    },
  );
  test('stale drafts cannot overwrite a saved quote or purchase', () async {
    final id = await quote();
    final q = store.data.quotes.single;
    await store.saveQuote(
      id: id,
      expectedRevision: 0,
      customerId: client,
      productId: product,
      quantity: 2,
      unitPrice: 800,
      destination: 'Porto-Novo',
      expiresAt: q.expiresAt,
    );
    await expectLater(
      store.saveQuote(
        id: id,
        expectedRevision: 0,
        customerId: client,
        productId: product,
        quantity: 1,
        unitPrice: 1,
        destination: 'Lomé',
        expiresAt: q.expiresAt,
      ),
      throwsStateError,
    );
    final pid = await purchase();
    await store.savePurchase(
      id: pid,
      expectedRevision: 0,
      supplierId: supplier,
      productId: product,
      quantity: 3,
      unitPrice: 500,
      destination: 'Dépôt B',
    );
    await expectLater(
      store.changePurchaseStatus(
        pid,
        PurchaseStatus.ordered,
        expectedRevision: 0,
      ),
      throwsStateError,
    );
  });
  test('purchases enter stock only through bounded partial receipts and cannot cancel after receipt', () async {
    final id = await purchase();
    expect(store.data.products.single.quantity, 20);
    await expectLater(
      store.receivePurchase(id, 2, 'BL', expectedRevision: 0),
      throwsArgumentError,
    );
    await orderPurchase(id);
    expect(store.data.products.single.quantity, 20);
    await store.receivePurchase(id, 3, 'BL-1', expectedRevision: 1);
    expect(store.data.products.single.quantity, 23);
    expect(store.data.purchases.single.receivedQuantity, 3);
    expect(store.data.purchases.single.status, PurchaseStatus.ordered);
    await expectLater(
      store.receivePurchase(id, 6, 'Trop', expectedRevision: 2),
      throwsArgumentError,
    );
    await expectLater(
      store.changePurchaseStatus(
        id,
        PurchaseStatus.cancelled,
        expectedRevision: 2,
      ),
      throwsArgumentError,
    );
    await store.receivePurchase(id, 5, 'BL-2', expectedRevision: 2);
    expect(store.data.products.single.quantity, 28);
    expect(store.data.purchases.single.status, PurchaseStatus.received);
    expect(store.data.commercialEvents.length, 2);
    expect(store.data.movements.first.kind, StockMovementKind.purchaseReceipt);
  });
  test('partial deliveries do not deduct stock again, returns only restock delivered quantities once', () async {
    final id = await sale();
    expect(store.data.products.single.quantity, 15);
    await expectLater(
      store.recordDelivery(id, 1, 'BL', expectedRevision: 0),
      throwsArgumentError,
    );
    await store.changeOrderStatus(id, OrderStatus.shipped);
    await store.recordDelivery(id, 2, 'BL-1', expectedRevision: 1);
    expect(store.data.products.single.quantity, 15);
    expect(store.data.orders.single.deliveredQuantity, 2);
    expect(store.data.orders.single.status, OrderStatus.shipped);
    await expectLater(
      store.returnCustomer(id, 3, 'Trop', expectedRevision: 2),
      throwsArgumentError,
    );
    await store.returnCustomer(id, 1, 'Défaut constaté', expectedRevision: 2);
    expect(store.data.products.single.quantity, 16);
    await store.recordDelivery(id, 3, 'BL-2', expectedRevision: 3);
    expect(store.data.orders.single.status, OrderStatus.delivered);
    await store.returnCustomer(
      id,
      4,
      'Retour du solde livré',
      expectedRevision: 4,
    );
    expect(store.data.products.single.quantity, 20);
    expect(store.data.orders.single.returnedQuantity, 5);
    await expectLater(
      store.returnCustomer(id, 1, 'Double', expectedRevision: 5),
      throwsArgumentError,
    );
    expect(store.data.commercialEvents.length, 4);
  });
  test('legacy mark-delivered action records remaining quantity after partial delivery', () async {
    final id = await sale();
    await store.changeOrderStatus(id, OrderStatus.shipped);
    await store.recordDelivery(
      id,
      2,
      'Livraison partielle',
      expectedRevision: 1,
    );
    await store.changeOrderStatus(id, OrderStatus.delivered);
    expect(store.data.orders.single.deliveredQuantity, 5);
    expect(store.data.commercialEvents.first.quantity, 3);
    expect(store.data.products.single.quantity, 15);
  });
  test('supplier returns respect received quantity and current stock without reopening receipts', () async {
    final id = await purchase(quantity: 3);
    await orderPurchase(id);
    await store.receivePurchase(id, 3, 'BL', expectedRevision: 1);
    await store.adjustStock(product, -22, 'Sortie');
    await expectLater(
      store.returnSupplier(id, 2, 'Stock insuffisant', expectedRevision: 2),
      throwsArgumentError,
    );
    await store.returnSupplier(
      id,
      1,
      'Retour fournisseur',
      expectedRevision: 2,
    );
    expect(store.data.products.single.quantity, 0);
    expect(store.data.purchases.single.remainingQuantity, 0);
    expect(store.data.purchases.single.receivedQuantity, 3);
    expect(store.data.purchases.single.returnedQuantity, 1);
    await expectLater(
      store.receivePurchase(
        id,
        1,
        'Ne rouvre pas le solde',
        expectedRevision: 3,
      ),
      throwsArgumentError,
    );
  });
  test('stale quantity forms cannot create duplicate receipts, deliveries or returns', () async {
    final id = await purchase();
    await orderPurchase(id);
    await store.receivePurchase(id, 2, 'BL', expectedRevision: 1);
    final before = store.data;
    await expectLater(
      store.receivePurchase(id, 2, 'Double', expectedRevision: 1),
      throwsStateError,
    );
    expect(store.data, same(before));
    final sid = await sale();
    await store.changeOrderStatus(sid, OrderStatus.shipped);
    await store.recordDelivery(sid, 2, 'BL', expectedRevision: 1);
    await expectLater(
      store.recordDelivery(sid, 2, 'Double', expectedRevision: 1),
      throwsStateError,
    );
    await store.returnCustomer(sid, 1, 'Retour', expectedRevision: 2);
    await expectLater(
      store.returnCustomer(sid, 1, 'Double', expectedRevision: 2),
      throwsStateError,
    );
  });
  test('archived partners block new documents, historical receipts remain usable, units cannot drift', () async {
    final id = await purchase();
    await orderPurchase(id);
    final c = store.data.contacts.last;
    await store.setContactArchived(c.id, true, expectedRevision: 0);
    await expectLater(purchase(), throwsArgumentError);
    await store.receivePurchase(id, 1, 'Ancien achat', expectedRevision: 1);
    await store.updateProduct(store.data.products.single.copyWith(unit: 'kg'));
    await expectLater(
      store.receivePurchase(id, 1, 'Mauvaise unité', expectedRevision: 2),
      throwsStateError,
    );
    await expectLater(
      store.returnSupplier(id, 1, 'Mauvaise unité', expectedRevision: 2),
      throwsStateError,
    );
    await store.updateContact(
      store.data.contacts.first.copyWith(kind: ContactKind.supplier),
    );
  });
  test(
    'partner type is frozen by quotes and purchases before any sale exists',
    () async {
      await quote();
      await purchase();
      await expectLater(
        store.updateContact(
          store.data.contacts.first.copyWith(kind: ContactKind.supplier),
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.updateContact(
          store.data.contacts.last.copyWith(kind: ContactKind.client),
        ),
        throwsArgumentError,
      );
    },
  );
  test('failed conversion and reception preserve documents, stock and all histories', () async {
    final id = await quote();
    await accept(id);
    final before = store.data;
    repo.failSave = true;
    await expectLater(
      store.convertQuote(id, expectedRevision: 2),
      throwsStateError,
    );
    expect(store.data, same(before));
    repo.failSave = false;
    final pid = await purchase();
    await orderPurchase(pid);
    final previous = store.data;
    repo.failSave = true;
    await expectLater(
      store.receivePurchase(pid, 1, 'BL', expectedRevision: 1),
      throwsStateError,
    );
    expect(store.data, same(previous));
    expect(repo.snapshot, same(previous));
  });
  test('amount validation rejects negative values, missing destinations and inexact Web totals', () async {
    await expectLater(quote(quantity: 0), throwsArgumentError);
    await expectLater(quote(price: -1), throwsArgumentError);
    await expectLater(
      quote(quantity: 1000000000, price: 1000000000),
      throwsArgumentError,
    );
    await expectLater(
      store.savePurchase(
        supplierId: supplier,
        productId: product,
        quantity: 1,
        unitPrice: 1,
        destination: ' ',
      ),
      throwsArgumentError,
    );
    expect(store.data.quotes, isEmpty);
    expect(store.data.purchases, isEmpty);
  });
  test('old delivered orders infer full delivery and old snapshots default commercial lists to empty', () {
    final old = {
      'id': 'OLD',
      'customerId': client,
      'customerName': 'Client',
      'productId': product,
      'productName': 'Riz',
      'quantity': 5,
      'unitPrice': 1000,
      'status': 'delivered',
      'createdAt': DateTime.now().toIso8601String(),
      'destination': 'Cotonou',
    };
    final o = TradeOrder.fromJson(old);
    expect(o.deliveredQuantity, 5);
    expect(o.returnedQuantity, 0);
    expect(o.unit, isEmpty);
    final data = store.data.toJson()
      ..remove('quotes')
      ..remove('purchases')
      ..remove('commercialEvents');
    expect(TradeData.fromJson(data).quotes, isEmpty);
    expect(TradeData.fromJson(data).purchases, isEmpty);
  });
  test(
    'complete commercial snapshot survives real local repository restart',
    () async {
      final id = await quote();
      await accept(id);
      final sid = await store.convertQuote(id, expectedRevision: 2);
      await store.changeOrderStatus(sid, OrderStatus.shipped);
      await store.recordDelivery(sid, 2, 'BL', expectedRevision: 1);
      final pid = await purchase();
      await orderPurchase(pid);
      await store.receivePurchase(pid, 2, 'BR', expectedRevision: 1);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await LocalTradeRepository(prefs).save(store.data);
      final restored = TradeStore(LocalTradeRepository(prefs));
      await restored.load();
      expect(
        restored.data.toJson(),
        jsonDecode(jsonEncode(store.data.toJson())),
      );
      expect(restored.data.commercialEvents.length, 2);
    },
  );
  test('unit and direct-sale price changes while forms are open require reviewing current data', () async {
    final before = store.data.products.single;
    await store.updateProduct(before.copyWith(unit: 'kg', price: 1100));
    await expectLater(
      store.saveQuote(
        customerId: client,
        productId: product,
        quantity: 1,
        unitPrice: 900,
        destination: 'Cotonou',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        expectedUnit: 'sac',
      ),
      throwsStateError,
    );
    await expectLater(
      store.savePurchase(
        supplierId: supplier,
        productId: product,
        quantity: 1,
        unitPrice: 600,
        destination: 'Dépôt',
        expectedUnit: 'sac',
      ),
      throwsStateError,
    );
    await expectLater(
      store.createOrder(
        productId: product,
        customerId: client,
        quantity: 1,
        destination: 'Cotonou',
        expectedPrice: 1000,
        expectedUnit: 'kg',
      ),
      throwsStateError,
    );
    await expectLater(
      store.createOrder(
        productId: product,
        customerId: client,
        quantity: 1,
        destination: 'Cotonou',
        expectedUnit: 'sac',
      ),
      throwsStateError,
    );
    expect(store.data.orders, isEmpty);
    expect(store.data.quotes, isEmpty);
    expect(store.data.purchases, isEmpty);
  });
  test('failed delivery and return do not change fulfilment, stock, or audit records', () async {
    final id = await sale();
    await store.changeOrderStatus(id, OrderStatus.shipped);
    final before = store.data;
    repo.failSave = true;
    await expectLater(
      store.recordDelivery(id, 1, 'BL', expectedRevision: 1),
      throwsStateError,
    );
    expect(store.data, same(before));
    repo.failSave = false;
    await store.recordDelivery(id, 1, 'BL', expectedRevision: 1);
    final delivered = store.data;
    repo.failSave = true;
    await expectLater(
      store.returnCustomer(id, 1, 'Défaut', expectedRevision: 2),
      throwsStateError,
    );
    expect(store.data, same(delivered));
  });
  test(
    'receipts and customer returns cannot overflow the stock limit',
    () async {
      final sid = await sale(quantity: 1);
      await store.changeOrderStatus(sid, OrderStatus.shipped);
      await store.changeOrderStatus(sid, OrderStatus.delivered);
      final pid = await purchase(quantity: 1);
      await orderPurchase(pid);
      await store.adjustStock(product, 999999981, 'Stock maximal');
      final before = store.data;
      await expectLater(
        store.receivePurchase(pid, 1, 'Surplus', expectedRevision: 1),
        throwsArgumentError,
      );
      await expectLater(
        store.returnCustomer(sid, 1, 'Surplus', expectedRevision: 2),
        throwsArgumentError,
      );
      expect(store.data, same(before));
    },
  );
  test(
    'cancelled quotes and purchases are terminal and leave stock unchanged',
    () async {
      final id = await quote();
      await store.changeQuoteStatus(
        id,
        QuoteStatus.cancelled,
        expectedRevision: 0,
      );
      await expectLater(
        store.changeQuoteStatus(id, QuoteStatus.sent, expectedRevision: 1),
        throwsArgumentError,
      );
      await expectLater(
        store.convertQuote(id, expectedRevision: 1),
        throwsStateError,
      );
      final pid = await purchase();
      await orderPurchase(pid);
      await store.changePurchaseStatus(
        pid,
        PurchaseStatus.cancelled,
        expectedRevision: 1,
      );
      await expectLater(
        store.receivePurchase(pid, 1, 'BL', expectedRevision: 2),
        throwsArgumentError,
      );
      expect(store.data.products.single.quantity, 20);
    },
  );
  test('archived historical products can receive customer returns but cannot enter a new purchase receipt', () async {
    final sid = await sale(quantity: 1);
    await store.changeOrderStatus(sid, OrderStatus.shipped);
    await store.changeOrderStatus(sid, OrderStatus.delivered);
    final pid = await purchase();
    await orderPurchase(pid);
    await store.setProductStatus(product, ProductStatus.archived);
    await expectLater(
      store.receivePurchase(pid, 1, 'BL', expectedRevision: 1),
      throwsArgumentError,
    );
    await store.returnCustomer(
      sid,
      1,
      'Retour historique',
      expectedRevision: 2,
    );
    expect(store.data.products.single.quantity, 20);
    expect(store.data.products.single.status, ProductStatus.archived);
  });
}
