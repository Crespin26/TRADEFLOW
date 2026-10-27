import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/business_documents.dart';
import 'package:tradeflow_mobile/domain/document_catalog.dart';
import 'package:tradeflow_mobile/domain/snapshot_validation.dart';

import 'support/fakes.dart';

void main() {
  late TradeStore store;
  late MemoryRepository repository;
  late TradeData valid;
  setUp(() async {
    repository = MemoryRepository();
    store = TradeStore(repository);
    await store.load();
    await store.loadDemo();
    final p = store.data.products.first;
    final client = store.data.contacts.first,
        supplier = store.data.contacts.last;
    final quote = await store.saveQuote(
      customerId: client.id,
      productId: p.id,
      quantity: 2,
      unitPrice: 1000,
      destination: 'Cotonou',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    await store.changeQuoteStatus(quote, QuoteStatus.sent, expectedRevision: 0);
    await store.changeQuoteStatus(
      quote,
      QuoteStatus.accepted,
      expectedRevision: 1,
    );
    final order = await store.convertQuote(quote, expectedRevision: 2);
    await store.changeOrderStatus(order, OrderStatus.shipped);
    await store.recordDelivery(order, 1, 'BL', expectedRevision: 1);
    await store.returnCustomer(
      order,
      1,
      'Abîmé',
      expectedRevision: 2,
      restock: false,
    );
    final purchase = await store.savePurchase(
      supplierId: supplier.id,
      productId: p.id,
      quantity: 3,
      unitPrice: 500,
      destination: 'Dépôt',
    );
    await store.changePurchaseStatus(
      purchase,
      PurchaseStatus.ordered,
      expectedRevision: 0,
    );
    await store.receivePurchase(purchase, 2, 'BR', expectedRevision: 1);
    await store.returnSupplier(purchase, 1, 'Retour', expectedRevision: 2);
    final counted = store.data.products.first;
    await store.performInventory(
      counts: [
        StockCount(
          productId: p.id,
          productName: p.name,
          sku: p.sku,
          unit: p.unit,
          expectedQuantity: counted.quantity,
          countedQuantity: counted.quantity,
        ),
      ],
      reason: 'Contrôle',
    );
    await store.saveDeliveryPlan(
      order,
      carrier: 'Transport',
      trackingNumber: 'REF',
      notes: '',
      expectedRevision: 0,
    );
    await store.saveCompanyProfile(
      const CompanyProfile(name: 'Entreprise'),
      expectedRevision: 0,
    );
    await store.archiveBusinessDocument(businessDocuments(store.data).first);
    valid = store.data;
  });
  TradeData corrupt(void Function(Map<String, dynamic>) change) {
    final json = valid.toJson();
    change(json);
    return TradeData.fromJson(json);
  }

  test('a complete commercial snapshot with archives and a damaged return validates', () {
    expect(() => validateTradeData(valid), returnsNormally);
    expect(
      () => validateTradeData(TradeData.fromJson(valid.toJson())),
      returnsNormally,
    );
  });
  test('legacy delivered orders and movements remain readable without invented event dates', () {
    final legacy = {
      'version': 1,
      'products': [
        {
          'id': 'P',
          'name': 'Riz',
          'sku': 'R',
          'quantity': 5,
          'threshold': 1,
          'price': 100,
        },
      ],
      'contacts': [
        {
          'id': 'C',
          'name': 'Client',
          'kind': 'client',
          'country': 'Bénin',
          'email': '',
          'phone': '',
        },
      ],
      'orders': [
        {
          'id': 'O',
          'productId': 'P',
          'productName': 'Riz',
          'customerId': 'C',
          'customerName': 'Client',
          'quantity': 2,
          'unitPrice': 100,
          'status': 'delivered',
          'createdAt': DateTime(2025).toIso8601String(),
          'destination': 'Cotonou',
        },
      ],
      'movements': [
        {
          'id': 'M',
          'productName': 'Riz',
          'delta': -2,
          'reason': 'Commande',
          'createdAt': DateTime(2025).toIso8601String(),
        },
      ],
    };
    expect(
      () => validateTradeData(TradeData.fromJson(legacy)),
      returnsNormally,
    );
  });
  test(
    'duplicate identifiers, SKUs and missing catalogue references are rejected',
    () {
      final samples = [
        corrupt(
          (j) => (j['products'] as List).add((j['products'] as List).first),
        ),
        corrupt(
          (j) => ((j['products'] as List)[1] as Map)['sku'] =
              ((j['products'] as List)[0] as Map)['sku'],
        ),
        corrupt(
          (j) => ((j['products'] as List).first as Map)['category'] = 'Absent',
        ),
        corrupt((j) => j['units'] = <String>[]),
      ];
      for (final sample in samples) {
        expect(() => validateTradeData(sample), throwsFormatException);
      }
    },
  );
  test('negative stock and excessive fulfilment counters are rejected', () {
    for (final sample in [
      corrupt((j) => ((j['products'] as List).first as Map)['quantity'] = -1),
      corrupt(
        (j) => ((j['orders'] as List).first as Map)['returnedQuantity'] = 3,
      ),
      corrupt(
        (j) => ((j['purchases'] as List).first as Map)['receivedQuantity'] = 4,
      ),
      corrupt(
        (j) => ((j['purchases'] as List).first as Map)['status'] = 'cancelled',
      ),
    ]) {
      expect(() => validateTradeData(sample), throwsFormatException);
    }
  });
  test(
    'orphan partners, converted quotes and operation documents are rejected',
    () {
      for (final sample in [
        corrupt(
          (j) => ((j['orders'] as List).first as Map)['customerId'] = 'missing',
        ),
        corrupt((j) => ((j['quotes'] as List).first as Map)['orderId'] = null),
        corrupt(
          (j) => ((j['commercialEvents'] as List).first as Map)['documentId'] =
              'missing',
        ),
      ]) {
        expect(() => validateTradeData(sample), throwsFormatException);
      }
    },
  );
  test(
    'movements and cumulative event quantities must agree with their documents',
    () {
      final movement = corrupt((j) {
        final m = (j['movements'] as List).first as Map;
        m['afterQuantity'] = (m['afterQuantity'] as int) + 1;
      });
      final event = corrupt((j) {
        final e = (j['commercialEvents'] as List).first as Map;
        e['quantity'] = 99;
      });
      expect(() => validateTradeData(movement), throwsFormatException);
      expect(() => validateTradeData(event), throwsFormatException);
    },
  );
  test(
    'orphan inventory, delivery plan and issued-document sources are rejected',
    () {
      for (final sample in [
        corrupt(
          (j) =>
              ((((j['inventories'] as List).first as Map)['counts'] as List)
                          .first
                      as Map)['productId'] =
                  'missing',
        ),
        corrupt(
          (j) => ((j['deliveryPlans'] as List).first as Map)['orderId'] =
              'missing',
        ),
        corrupt(
          (j) => ((j['issuedDocuments'] as List).first as Map)['sourceId'] =
              'missing',
        ),
      ]) {
        expect(() => validateTradeData(sample), throwsFormatException);
      }
    },
  );
  test('a failed validation on reload preserves the last good state and blocks writes', () async {
    final before = store.data;
    final bad = corrupt(
      (j) => ((j['orders'] as List).first as Map)['customerId'] = 'missing',
    );
    repository.snapshot = bad;
    await store.load();
    expect(store.loaded, isFalse);
    expect(store.data, same(before));
    expect(repository.snapshot, same(bad));
    expect(store.loadError, isNotNull);
    await expectLater(
      store.adjustStock(before.products.first.id, 1, 'Entrée'),
      throwsStateError,
    );
    expect(repository.snapshot, same(bad));
    repository.snapshot = before;
    await store.load();
    expect(store.loaded, isTrue);
    expect(store.loadError, isNull);
  });
  test(
    'invalid aggregates cannot be persisted through a public mutation',
    () async {
      final before = store.data;
      final forged = BusinessDocument(
        kind: BusinessDocumentKind.sale,
        sourceId: 'missing',
        revision: 0,
        date: DateTime.now(),
        partner: 'Client',
        product: 'Riz',
        quantity: 1,
        unit: 'sac',
        status: 'Confirmée',
        company: before.company,
      );
      await expectLater(
        store.archiveBusinessDocument(forged),
        throwsFormatException,
      );
      expect(store.data, same(before));
      expect(repository.snapshot, same(before));
    },
  );
  test('old same-name contacts with distinct IDs are preserved, not silently deduplicated', () {
    final c = valid.contacts.first;
    final historical = Contact(
      id: 'other',
      name: c.name,
      kind: c.kind,
      country: c.country,
      email: c.email,
      phone: c.phone,
    );
    expect(
      () => validateTradeData(
        valid.copyWith(contacts: [...valid.contacts, historical]),
      ),
      returnsNormally,
    );
  });
}
