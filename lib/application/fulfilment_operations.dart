part of 'trade_store.dart';

extension FulfilmentOperations on TradeStore {
  /// Confirmation already deducted the stock: recording a delivery only updates fulfilment.
  Future<void> recordDelivery(
    String id,
    int quantity,
    String reason, {
    required int expectedRevision,
  }) async {
    final order = _data.orders.firstWhere((o) => o.id == id);
    _revision(order.revision, expectedRevision);
    if (order.status != OrderStatus.shipped ||
        quantity < 1 ||
        quantity > order.remainingQuantity) {
      throw ArgumentError(
        'Expédiez la commande et respectez la quantité restant à livrer.',
      );
    }
    final p = _commercialProduct(order.productId, active: false);
    final event = _event(
      documentId: id,
      product: p,
      productName: order.productName,
      partnerName: order.customerName,
      unit: order.unit,
      quantity: quantity,
      reason: reason,
      kind: CommercialEventKind.delivery,
    );
    final delivered = order.deliveredQuantity + quantity;
    await _commit(
      _data.copyWith(
        orders: [
          for (final item in _data.orders)
            if (item.id == id)
              order.copyWith(
                deliveredQuantity: delivered,
                status: delivered == order.quantity
                    ? OrderStatus.delivered
                    : OrderStatus.shipped,
              )
            else
              item,
        ],
        commercialEvents: [event, ..._data.commercialEvents],
      ),
    );
  }

  Future<void> returnCustomer(
    String id,
    int quantity,
    String reason, {
    required int expectedRevision,
    bool restock = true,
  }) async {
    final order = _data.orders.firstWhere((o) => o.id == id);
    _revision(order.revision, expectedRevision);
    if (quantity < 1 ||
        quantity > order.returnableQuantity ||
        order.status == OrderStatus.cancelled) {
      throw ArgumentError(
        'Le retour dépasse la quantité livrée non encore retournée.',
      );
    }
    final p = _commercialProduct(order.productId, active: false);
    if (restock) {
      _sameUnit(p, order.unit);
    }
    final event = _event(
      documentId: id,
      product: p,
      productName: order.productName,
      partnerName: order.customerName,
      unit: order.unit,
      quantity: quantity,
      reason: reason,
      kind: CommercialEventKind.customerReturn,
      restocked: restock,
    );
    final next = _data.copyWith(
      orders: [
        for (final item in _data.orders)
          if (item.id == id)
            order.copyWith(returnedQuantity: order.returnedQuantity + quantity)
          else
            item,
      ],
    );
    await _commit(
      restock
          ? _stockOperation(
              next,
              p,
              quantity,
              event,
              StockMovementKind.customerReturn,
            )
          : next.copyWith(commercialEvents: [event, ..._data.commercialEvents]),
    );
  }

  Future<void> saveDeliveryPlan(
    String orderId, {
    required String carrier,
    required String trackingNumber,
    required String notes,
    DateTime? expectedDate,
    required int expectedRevision,
  }) async {
    final order = _data.orders.firstWhere((o) => o.id == orderId);
    if (order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.delivered) {
      throw StateError(
        'Le suivi d’une commande terminée ou annulée est conservé en lecture seule.',
      );
    }
    final original = _data.deliveryPlans
        .where((p) => p.orderId == orderId)
        .firstOrNull;
    _revision(original?.revision ?? 0, expectedRevision);
    if (carrier.trim().length > 160 ||
        trackingNumber.trim().length > 160 ||
        notes.trim().length > 1000) {
      throw ArgumentError(
        'Transporteur et suivi : 160 caractères ; notes : 1 000 maximum.',
      );
    }
    final plan = DeliveryPlan(
      orderId: orderId,
      carrier: carrier.trim(),
      trackingNumber: trackingNumber.trim(),
      notes: notes.trim(),
      expectedDate: expectedDate,
      updatedAt: DateTime.now(),
      revision: (original?.revision ?? 0) + 1,
    );
    await _commit(
      _data.copyWith(
        deliveryPlans: [
          plan,
          ..._data.deliveryPlans.where((p) => p.orderId != orderId),
        ],
      ),
    );
  }
}
