import 'business_documents.dart';
import 'catalog_photos.dart';
import 'models.dart';

/// Validate persisted aggregates before they become application state.
/// Historical names/units and undated legacy movements are deliberately preserved.
void validateTradeData(TradeData data) {
  Never invalid(String path) =>
      throw FormatException('Sauvegarde incohérente : $path.');
  void ensure(bool value, String path) {
    if (!value) invalid(path);
  }

  bool quantity(int n) => n >= 0 && n <= 1000000000;
  void unique(Iterable<String> values, String path) {
    final ids = values.toList();
    ensure(
      ids.every((id) => id.trim().isNotEmpty) &&
          ids.toSet().length == ids.length,
      path,
    );
  }

  unique(data.categories, 'categories');
  unique(data.units, 'units');
  ensure(data.categories.isNotEmpty && data.units.isNotEmpty, 'references');
  unique(data.products.map((p) => p.id), 'products.id');
  unique(data.products.map((p) => p.sku.trim().toLowerCase()), 'products.sku');
  unique(data.contacts.map((c) => c.id), 'contacts.id');
  unique(data.orders.map((o) => o.id), 'orders.id');
  unique(data.quotes.map((q) => q.id), 'quotes.id');
  unique(data.purchases.map((p) => p.id), 'purchases.id');
  unique(data.movements.map((m) => m.id), 'movements.id');
  unique(data.inventories.map((i) => i.id), 'inventories.id');
  unique(data.commercialEvents.map((e) => e.id), 'events.id');
  unique(data.deliveryPlans.map((p) => p.orderId), 'deliveryPlans.orderId');
  unique(
    data.issuedDocuments.map((d) => d.reference),
    'issuedDocuments.reference',
  );
  final products = {for (final p in data.products) p.id: p};
  final contacts = {for (final c in data.contacts) c.id: c};
  final orders = {for (final o in data.orders) o.id: o};
  final quotes = {for (final q in data.quotes) q.id: q};
  final purchases = {for (final p in data.purchases) p.id: p};
  final events = {for (final e in data.commercialEvents) e.id: e};
  final assets = catalogPhotos.values.map((p) => p.asset).toSet();
  var photoBytes = 0;
  for (final p in data.products) {
    ensure(
      p.name.trim().isNotEmpty &&
          quantity(p.quantity) &&
          quantity(p.threshold) &&
          quantity(p.price) &&
          quantity(p.purchasePrice),
      'products.${p.id}.values',
    );
    ensure(
      data.categories.contains(p.category) && data.units.contains(p.unit),
      'products.${p.id}.references',
    );
    ensure(p.photos.length <= 3, 'products.${p.id}.photos');
    for (final photo in p.photos) {
      if (photo.bytes == null) {
        ensure(assets.contains(photo.asset), 'products.${p.id}.photo.asset');
      } else {
        ensure(
          photo.bytes!.isNotEmpty && photo.bytes!.length <= 350000,
          'products.${p.id}.photo.bytes',
        );
        photoBytes += photo.bytes!.length;
      }
    }
    if (p.status == ProductStatus.published) {
      ensure(
        p.description.trim().isNotEmpty && p.photos.isNotEmpty,
        'products.${p.id}.publication',
      );
    }
  }
  ensure(photoBytes <= 2000000, 'products.photos.total');
  for (final c in data.contacts) {
    ensure(
      c.name.trim().isNotEmpty &&
          c.country.trim().isNotEmpty &&
          c.revision >= 0,
      'contacts.${c.id}.values',
    );
  }
  for (final o in data.orders) {
    ensure(
      products.containsKey(o.productId) &&
          contacts[o.customerId]?.kind == ContactKind.client,
      'orders.${o.id}.references',
    );
    ensure(
      o.quantity > 0 &&
          quantity(o.quantity) &&
          quantity(o.unitPrice) &&
          o.revision >= 0,
      'orders.${o.id}.values',
    );
    ensure(
      o.deliveredQuantity >= 0 &&
          o.deliveredQuantity <= o.quantity &&
          o.returnedQuantity >= 0 &&
          o.returnedQuantity <= o.deliveredQuantity,
      'orders.${o.id}.fulfilment',
    );
    if (o.status == OrderStatus.confirmed ||
        o.status == OrderStatus.cancelled) {
      ensure(
        o.deliveredQuantity == 0 && o.returnedQuantity == 0,
        'orders.${o.id}.status',
      );
    }
    if (o.status == OrderStatus.delivered) {
      ensure(o.deliveredQuantity == o.quantity, 'orders.${o.id}.delivered');
    }
    if (o.status == OrderStatus.shipped) {
      ensure(o.deliveredQuantity < o.quantity, 'orders.${o.id}.shipped');
    }
    if (o.quoteId != null) {
      ensure(quotes[o.quoteId]?.orderId == o.id, 'orders.${o.id}.quote');
    }
  }
  for (final q in data.quotes) {
    ensure(
      products.containsKey(q.productId) &&
          contacts[q.customerId]?.kind == ContactKind.client,
      'quotes.${q.id}.references',
    );
    ensure(
      q.quantity > 0 &&
          quantity(q.quantity) &&
          quantity(q.unitPrice) &&
          q.revision >= 0,
      'quotes.${q.id}.values',
    );
    if (q.status == QuoteStatus.converted) {
      final o = orders[q.orderId];
      ensure(
        o != null &&
            o.quoteId == q.id &&
            o.productId == q.productId &&
            o.customerId == q.customerId &&
            o.quantity == q.quantity &&
            o.unitPrice == q.unitPrice,
        'quotes.${q.id}.conversion',
      );
    } else {
      ensure(q.orderId == null, 'quotes.${q.id}.orderId');
    }
  }
  for (final p in data.purchases) {
    ensure(
      products.containsKey(p.productId) &&
          contacts[p.supplierId]?.kind == ContactKind.supplier,
      'purchases.${p.id}.references',
    );
    ensure(
      p.quantity > 0 &&
          quantity(p.quantity) &&
          quantity(p.unitPrice) &&
          p.revision >= 0,
      'purchases.${p.id}.values',
    );
    ensure(
      p.receivedQuantity >= 0 &&
          p.receivedQuantity <= p.quantity &&
          p.returnedQuantity >= 0 &&
          p.returnedQuantity <= p.receivedQuantity,
      'purchases.${p.id}.fulfilment',
    );
    if (p.status == PurchaseStatus.draft ||
        p.status == PurchaseStatus.cancelled) {
      ensure(
        p.receivedQuantity == 0 && p.returnedQuantity == 0,
        'purchases.${p.id}.status',
      );
    }
    if (p.status == PurchaseStatus.received) {
      ensure(p.receivedQuantity == p.quantity, 'purchases.${p.id}.received');
    }
    if (p.status == PurchaseStatus.ordered) {
      ensure(p.receivedQuantity < p.quantity, 'purchases.${p.id}.ordered');
    }
  }
  for (final m in data.movements) {
    ensure(
      m.delta != 0 && m.delta.abs() <= 1000000000,
      'movements.${m.id}.delta',
    );
    if (m.productId != null) {
      ensure(products.containsKey(m.productId), 'movements.${m.id}.product');
    }
    ensure(
      (m.beforeQuantity == null) == (m.afterQuantity == null),
      'movements.${m.id}.history',
    );
    if (m.beforeQuantity != null) {
      ensure(
        quantity(m.beforeQuantity!) &&
            quantity(m.afterQuantity!) &&
            m.afterQuantity! - m.beforeQuantity! == m.delta,
        'movements.${m.id}.quantities',
      );
    }
  }
  for (final inventory in data.inventories) {
    ensure(inventory.counts.isNotEmpty, 'inventories.${inventory.id}.counts');
    unique(
      inventory.counts.map((c) => c.productId),
      'inventories.${inventory.id}.products',
    );
    for (final c in inventory.counts) {
      ensure(
        products.containsKey(c.productId) &&
            quantity(c.expectedQuantity) &&
            quantity(c.countedQuantity),
        'inventories.${inventory.id}.values',
      );
    }
  }
  final delivered = <String, int>{},
      customerReturned = <String, int>{},
      received = <String, int>{},
      supplierReturned = <String, int>{};
  for (final e in data.commercialEvents) {
    ensure(
      e.quantity > 0 &&
          quantity(e.quantity) &&
          products.containsKey(e.productId),
      'events.${e.id}.values',
    );
    final purchaseEvent =
        e.kind == CommercialEventKind.receipt ||
        e.kind == CommercialEventKind.supplierReturn;
    ensure(
      purchaseEvent
          ? purchases[e.documentId]?.productId == e.productId
          : orders[e.documentId]?.productId == e.productId,
      'events.${e.id}.document',
    );
    final counts = switch (e.kind) {
      CommercialEventKind.delivery => delivered,
      CommercialEventKind.customerReturn => customerReturned,
      CommercialEventKind.receipt => received,
      CommercialEventKind.supplierReturn => supplierReturned,
    };
    counts.update(
      e.documentId,
      (v) => v + e.quantity,
      ifAbsent: () => e.quantity,
    );
  }
  for (final o in data.orders) {
    // Old delivered orders may have no dated delivery events; returns are always explicit.
    ensure(
      (delivered[o.id] ?? 0) <= o.deliveredQuantity &&
          (customerReturned[o.id] ?? 0) == o.returnedQuantity,
      'orders.${o.id}.events',
    );
  }
  for (final p in data.purchases) {
    ensure(
      (received[p.id] ?? 0) == p.receivedQuantity &&
          (supplierReturned[p.id] ?? 0) == p.returnedQuantity,
      'purchases.${p.id}.events',
    );
  }
  for (final plan in data.deliveryPlans) {
    ensure(
      orders.containsKey(plan.orderId) && plan.revision >= 1,
      'deliveryPlans.${plan.orderId}',
    );
  }
  ensure(
    data.company.revision >= 0 &&
        (data.company.revision == 0 || data.company.name.trim().isNotEmpty),
    'company',
  );
  for (final d in data.issuedDocuments) {
    ensure(
      d.company.name.trim().isNotEmpty &&
          d.revision >= 0 &&
          d.quantity > 0 &&
          quantity(d.quantity) &&
          (d.unitPrice == null || quantity(d.unitPrice!)) &&
          d.issuedAt != null,
      'issuedDocuments.${d.reference}.values',
    );
    final exists = switch (d.kind) {
      BusinessDocumentKind.quote => quotes.containsKey(d.sourceId),
      BusinessDocumentKind.sale ||
      BusinessDocumentKind.proforma => orders.containsKey(d.sourceId),
      BusinessDocumentKind.purchase => purchases.containsKey(d.sourceId),
      _ => events.containsKey(d.sourceId),
    };
    ensure(exists, 'issuedDocuments.${d.reference}.source');
  }
}
