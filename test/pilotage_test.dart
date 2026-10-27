import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/pilotage.dart';

void main() {
  final now = DateTime(2026, 10, 27, 14);
  TradeOrder order(
    String id,
    DateTime date, {
    int qty = 4,
    int delivered = 0,
    int returned = 0,
    OrderStatus status = OrderStatus.shipped,
    int price = 100,
  }) => TradeOrder(
    id: id,
    customerId: 'C',
    customerName: 'Client',
    productId: 'P',
    productName: 'Riz',
    quantity: qty,
    unitPrice: price,
    status: status,
    createdAt: date,
    destination: 'Cotonou',
    deliveredQuantity: delivered,
    returnedQuantity: returned,
  );
  CommercialEvent event(
    String id,
    String doc,
    DateTime date,
    CommercialEventKind kind,
    int qty, {
    bool restocked = true,
  }) => CommercialEvent(
    id: id,
    documentId: doc,
    productId: 'P',
    productName: 'Riz',
    partnerName: 'Client',
    unit: 'sac',
    quantity: qty,
    reason: 'Motif',
    kind: kind,
    createdAt: date,
    restocked: restocked,
  );
  test('period includes its first local midnight, excludes older/future orders and cancellations from amounts', () {
    final data = TradeData(
      orders: [
        order('start', DateTime(2026, 10, 21)),
        order('old', DateTime(2026, 10, 20, 23, 59)),
        order('future', DateTime(2026, 10, 28)),
        order('cancel', now, status: OrderStatus.cancelled),
      ],
    );
    final snapshot = PilotageSnapshot(
      data,
      now: now,
      period: PilotagePeriod.week,
    );
    expect(snapshot.orders.length, 2);
    expect(snapshot.bookedSales, BigInt.from(400));
    expect(snapshot.cancelledSales, 1);
    expect(
      snapshot
          .metrics(PilotageView.sales)
          .any((m) => m.scope == 'Situation actuelle'),
      isTrue,
    );
  });
  test('delivery and return period follows event dates, not old order dates, including damaged returns', () {
    final data = TradeData(
      orders: [order('O', DateTime(2025), delivered: 4, returned: 1)],
      commercialEvents: [
        event('old', 'O', DateTime(2025), CommercialEventKind.delivery, 2),
        event('new', 'O', now, CommercialEventKind.delivery, 2),
        event(
          'ret',
          'O',
          now,
          CommercialEventKind.customerReturn,
          1,
          restocked: false,
        ),
      ],
    );
    final summary = PilotageSnapshot(
      data,
      now: now,
      period: PilotagePeriod.week,
    );
    expect(summary.bookedSales, BigInt.zero);
    expect(summary.netDelivered, BigInt.from(100));
    expect(summary.nonRestockedReturns, 1);
    expect(
      PilotageSnapshot(data, now: now, period: PilotagePeriod.all).netDelivered,
      BigInt.from(300),
    );
  });
  test('legacy deliveries are counted all-time without fabricating a recent delivery date', () {
    final data = TradeData(
      orders: [
        order(
          'old',
          DateTime(2025),
          delivered: 4,
          status: OrderStatus.delivered,
        ),
      ],
    );
    final recent = PilotageSnapshot(data, now: now);
    expect(recent.legacyDeliveries, 1);
    expect(recent.netDelivered, BigInt.zero);
    expect(
      PilotageSnapshot(data, now: now, period: PilotagePeriod.all).netDelivered,
      BigInt.from(400),
    );
  });
  test('receipts and supplier returns use the agreed purchase price and actual event date', () {
    final purchase = PurchaseOrder(
      id: 'A',
      supplierId: 'F',
      supplierName: 'Fournisseur',
      productId: 'P',
      productName: 'Riz',
      sku: 'R',
      unit: 'sac',
      quantity: 4,
      unitPrice: 60,
      destination: 'Dépôt',
      createdAt: DateTime(2025),
      updatedAt: now,
      status: PurchaseStatus.received,
      receivedQuantity: 4,
      returnedQuantity: 1,
    );
    final data = TradeData(
      purchases: [purchase],
      commercialEvents: [
        event('rec', 'A', now, CommercialEventKind.receipt, 2),
        event('ret', 'A', now, CommercialEventKind.supplierReturn, 1),
      ],
    );
    final summary = PilotageSnapshot(data, now: now);
    expect(summary.committedPurchases, BigInt.zero);
    expect(summary.netReceived, BigInt.from(60));
    expect(
      PilotageSnapshot(data, now: now, period: PilotagePeriod.all).netReceived,
      BigInt.from(180),
    );
  });
  test('stock and late order alerts are current balances independent of the period', () {
    final data = TradeData(
      products: const [
        Product(
          id: 'P',
          name: 'Riz',
          sku: 'R',
          quantity: 0,
          threshold: 2,
          price: 100,
        ),
        Product(
          id: 'X',
          name: 'Archive',
          sku: 'X',
          quantity: 0,
          threshold: 2,
          price: 100,
          status: ProductStatus.archived,
        ),
      ],
      orders: [
        order('O', DateTime(2025)),
        order('cancel', DateTime(2025), status: OrderStatus.cancelled),
      ],
      deliveryPlans: [
        DeliveryPlan(
          orderId: 'O',
          carrier: 'A',
          trackingNumber: '',
          notes: '',
          expectedDate: DateTime(2026, 10, 26),
          updatedAt: now,
        ),
        DeliveryPlan(
          orderId: 'cancel',
          carrier: 'A',
          trackingNumber: '',
          notes: '',
          expectedDate: DateTime(2026, 10, 26),
          updatedAt: now,
        ),
      ],
    );
    final s = PilotageSnapshot(data, now: now, period: PilotagePeriod.week);
    expect(s.orders, isEmpty);
    expect(s.pendingDeliveries, 1);
    expect(s.lateDeliveries, 1);
    expect(s.stockOuts, 1);
    expect(s.lowStocks, 1);
  });
  test('aggregation is exact beyond JavaScript safe integer totals and reports do not expose money in warehouse view', () {
    final data = TradeData(
      orders: [
        order('1', now, qty: 1000000000, price: 1000000000),
        order('2', now, qty: 1000000000, price: 1000000000),
      ],
    );
    final s = PilotageSnapshot(data, now: now);
    expect(s.bookedSales, BigInt.parse('2000000000000000000'));
    expect(pilotageMoney(s.bookedSales), '2 000 000 000 000 000 000 F CFA');
    expect(
      s.reportCsv(PilotageView.administrator),
      contains('2000000000000000000'),
    );
    expect(s.reportCsv(PilotageView.warehouse), isNot(contains('XOF')));
    expect(s.topProducts.single.value, s.bookedSales);
  });
  test('empty activity, reports and conversion rate remain valid without divisions by zero', () {
    final s = PilotageSnapshot(TradeData(), now: now);
    expect(s.quoteConversion, 0);
    expect(s.activity.length, 7);
    expect(s.activity.every((d) => d.salesValue == BigInt.zero), isTrue);
    expect(
      s.reportCsv(PilotageView.sales),
      startsWith('indicateur;valeur;unite;perimetre;debut;fin'),
    );
    expect(s.topProducts, isEmpty);
    expect(
      s.reportCsv(PilotageView.sales).split('\r\n').first.split(';').length,
      7,
    );
  });
}
