import 'models.dart';

enum PilotagePeriod { week, month, quarter, all }

extension PilotagePeriodLabel on PilotagePeriod {
  String get label => switch (this) {
    PilotagePeriod.week => '7 jours',
    PilotagePeriod.month => '30 jours',
    PilotagePeriod.quarter => '90 jours',
    PilotagePeriod.all => 'Toutes dates',
  };
}

enum PilotageView { administrator, sales, warehouse, accounting }

class PilotageMetric {
  const PilotageMetric(
    this.label,
    this.value, {
    this.money = false,
    this.scope = 'Période',
  });
  final String label, scope;
  final BigInt value;
  final bool money;
}

class ProductRanking {
  ProductRanking(this.productId, this.name, this.value);
  final String productId, name;
  final BigInt value;
}

class ActivityDay {
  const ActivityDay(this.date, this.salesValue, this.operations);
  final DateTime date;
  final BigInt salesValue;
  final int operations;
}

String pilotageMoney(BigInt value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value.isNegative ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[i]);
  }
  return '$buffer F CFA';
}

/// Period flows and current balances are separate. BigInt keeps aggregation exact on Web.
class PilotageSnapshot {
  PilotageSnapshot(
    this.data, {
    required this.now,
    this.period = PilotagePeriod.month,
  });
  final TradeData data;
  final DateTime now;
  final PilotagePeriod period;
  DateTime? get start => switch (period) {
    PilotagePeriod.week => DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6)),
    PilotagePeriod.month => DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29)),
    PilotagePeriod.quarter => DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 89)),
    PilotagePeriod.all => null,
  };
  bool includes(DateTime date) =>
      !date.isAfter(now) && (start == null || !date.isBefore(start!));
  BigInt amount(int quantity, int price) =>
      BigInt.from(quantity) * BigInt.from(price);
  List<TradeOrder> get orders =>
      data.orders.where((o) => includes(o.createdAt)).toList();
  List<TradeQuote> get quotes =>
      data.quotes.where((q) => includes(q.createdAt)).toList();
  List<PurchaseOrder> get purchases =>
      data.purchases.where((p) => includes(p.createdAt)).toList();
  List<CommercialEvent> get events =>
      data.commercialEvents.where((e) => includes(e.createdAt)).toList();
  BigInt get bookedSales => orders
      .where((o) => o.status != OrderStatus.cancelled)
      .fold(BigInt.zero, (sum, o) => sum + amount(o.quantity, o.unitPrice));
  BigInt get committedPurchases => purchases
      .where(
        (p) =>
            p.status == PurchaseStatus.ordered ||
            p.status == PurchaseStatus.received,
      )
      .fold(BigInt.zero, (sum, p) => sum + amount(p.quantity, p.unitPrice));
  BigInt get netDelivered {
    if (period == PilotagePeriod.all) {
      return data.orders
          .where(
            (o) => includes(o.createdAt) && o.status != OrderStatus.cancelled,
          )
          .fold(
            BigInt.zero,
            (sum, o) =>
                sum +
                amount(o.deliveredQuantity - o.returnedQuantity, o.unitPrice),
          );
    }
    var value = BigInt.zero;
    for (final e in events) {
      if (e.kind != CommercialEventKind.delivery &&
          e.kind != CommercialEventKind.customerReturn) {
        continue;
      }
      final order = data.orders.where((o) => o.id == e.documentId).firstOrNull;
      if (order == null) continue;
      value +=
          amount(e.quantity, order.unitPrice) *
          (e.kind == CommercialEventKind.customerReturn
              ? -BigInt.one
              : BigInt.one);
    }
    return value;
  }

  BigInt get netReceived {
    if (period == PilotagePeriod.all) {
      return data.purchases
          .where(
            (p) =>
                includes(p.createdAt) && p.status != PurchaseStatus.cancelled,
          )
          .fold(
            BigInt.zero,
            (sum, p) =>
                sum +
                amount(p.receivedQuantity - p.returnedQuantity, p.unitPrice),
          );
    }
    var value = BigInt.zero;
    for (final e in events) {
      if (e.kind != CommercialEventKind.receipt &&
          e.kind != CommercialEventKind.supplierReturn) {
        continue;
      }
      final purchase = data.purchases
          .where((p) => p.id == e.documentId)
          .firstOrNull;
      if (purchase == null) continue;
      value +=
          amount(e.quantity, purchase.unitPrice) *
          (e.kind == CommercialEventKind.supplierReturn
              ? -BigInt.one
              : BigInt.one);
    }
    return value;
  }

  int get cancelledSales =>
      orders.where((o) => o.status == OrderStatus.cancelled).length;
  int get convertedQuotes =>
      quotes.where((q) => q.status == QuoteStatus.converted).length;
  double get quoteConversion =>
      quotes.isEmpty ? 0 : convertedQuotes / quotes.length;
  List<Product> get activeProducts =>
      data.products.where((p) => p.status != ProductStatus.archived).toList();
  int get stockOuts => activeProducts.where((p) => p.quantity == 0).length;
  int get lowStocks => activeProducts.where((p) => p.lowStock).length;
  int get pendingDeliveries => data.orders
      .where(
        (o) => o.status != OrderStatus.cancelled && o.remainingQuantity > 0,
      )
      .length;
  int get lateDeliveries => data.orders
      .where(
        (o) =>
            o.status != OrderStatus.cancelled &&
            o.remainingQuantity > 0 &&
            data.deliveryPlans.any((p) => p.orderId == o.id && p.lateAt(now)),
      )
      .length;
  int get pendingPurchases => data.purchases
      .where(
        (p) => p.status == PurchaseStatus.ordered && p.remainingQuantity > 0,
      )
      .length;
  int get expiredQuotes => data.quotes
      .where(
        (q) =>
            [
              QuoteStatus.draft,
              QuoteStatus.sent,
              QuoteStatus.accepted,
            ].contains(q.status) &&
            q.isExpiredAt(now),
      )
      .length;
  int get customerReturns =>
      events.where((e) => e.kind == CommercialEventKind.customerReturn).length;
  int get supplierReturns =>
      events.where((e) => e.kind == CommercialEventKind.supplierReturn).length;
  int get nonRestockedReturns => events
      .where(
        (e) => e.kind == CommercialEventKind.customerReturn && !e.restocked,
      )
      .length;
  int get archivedDocuments => data.issuedDocuments
      .where((d) => d.issuedAt != null && includes(d.issuedAt!))
      .length;
  int get legacyDeliveries => data.orders
      .where(
        (o) =>
            o.deliveredQuantity >
            data.commercialEvents
                .where(
                  (e) =>
                      e.documentId == o.id &&
                      e.kind == CommercialEventKind.delivery,
                )
                .fold<int>(0, (s, e) => s + e.quantity),
      )
      .length;
  List<ProductRanking> get topProducts {
    final values = <String, BigInt>{};
    final names = <String, String>{};
    for (final o in orders.where((o) => o.status != OrderStatus.cancelled)) {
      values.update(
        o.productId,
        (v) => v + amount(o.quantity, o.unitPrice),
        ifAbsent: () => amount(o.quantity, o.unitPrice),
      );
      names.putIfAbsent(o.productId, () => o.productName);
    }
    final ranked =
        [
          for (final id in values.keys)
            ProductRanking(id, names[id]!, values[id]!),
        ]..sort((a, b) {
          final result = b.value.compareTo(a.value);
          return result == 0 ? a.name.compareTo(b.name) : result;
        });
    return ranked.take(5).toList();
  }

  List<ActivityDay> get activity => [
    for (var offset = 6; offset >= 0; offset--)
      _activityDay(
        DateTime(now.year, now.month, now.day).subtract(Duration(days: offset)),
      ),
  ];
  ActivityDay _activityDay(DateTime date) {
    bool same(DateTime other) =>
        other.year == date.year &&
        other.month == date.month &&
        other.day == date.day;
    final value = orders
        .where((o) => o.status != OrderStatus.cancelled && same(o.createdAt))
        .fold(BigInt.zero, (sum, o) => sum + amount(o.quantity, o.unitPrice));
    return ActivityDay(
      date,
      value,
      events.where((e) => same(e.createdAt)).length,
    );
  }

  List<PilotageMetric> metrics(PilotageView view) {
    PilotageMetric count(String label, int value, {bool current = false}) =>
        PilotageMetric(
          label,
          BigInt.from(value),
          scope: current ? 'Situation actuelle' : 'Période',
        );
    return [
      if (view != PilotageView.warehouse) ...[
        PilotageMetric('Ventes confirmées', bookedSales, money: true),
        PilotageMetric('Valeur livrée nette', netDelivered, money: true),
      ],
      if (view == PilotageView.administrator ||
          view == PilotageView.accounting) ...[
        PilotageMetric('Achats engagés', committedPurchases, money: true),
        PilotageMetric('Valeur reçue nette', netReceived, money: true),
        count('Versions PDF archivées', archivedDocuments),
      ],
      if (view != PilotageView.accounting) ...[
        count('Commandes à livrer', pendingDeliveries, current: true),
        count('Livraisons en retard', lateDeliveries, current: true),
        count('Ruptures de stock', stockOuts, current: true),
      ],
      if (view == PilotageView.warehouse ||
          view == PilotageView.administrator) ...[
        count('Achats à réceptionner', pendingPurchases, current: true),
        count('Alertes de seuil', lowStocks, current: true),
      ],
      if (view == PilotageView.sales || view == PilotageView.administrator) ...[
        count('Devis créés', quotes.length),
        count('Devis créés convertis', convertedQuotes),
        count('Devis expirés', expiredQuotes, current: true),
      ],
      count('Retours clients', customerReturns),
      count('Retours fournisseurs', supplierReturns),
      count('Retours exclus du disponible', nonRestockedReturns),
    ];
  }

  String reportCsv(PilotageView view) {
    String text(String value) {
      final clean = RegExp(r'^\s*[=+@-]').hasMatch(value) ? "'$value" : value;
      return '"${clean.replaceAll('"', '""')}"';
    }

    final rows = <String>[
      'indicateur;valeur;unite;perimetre;debut;fin;entreprise',
    ];
    final from = start?.toIso8601String() ?? '';
    final to = now.toIso8601String();
    for (final m in metrics(view)) {
      rows.add(
        '${text(m.label)};${m.value};${m.money ? 'XOF' : 'nombre'};${text(m.scope)};${m.scope == 'Situation actuelle' ? '' : from};$to;${text(data.company.name)}',
      );
    }
    if (view != PilotageView.warehouse) {
      for (final rank in topProducts) {
        rows.add(
          '${text('Produit : ${rank.name}')};${rank.value};XOF;${text('Commandes créées sur la période')};$from;$to;${text(data.company.name)}',
        );
      }
    }
    return rows.join('\r\n');
  }
}
