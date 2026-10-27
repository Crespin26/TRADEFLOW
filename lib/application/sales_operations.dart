part of 'trade_store.dart';

extension SalesOperations on TradeStore {
  Future<void> createOrder({
    required String productId,
    required String customerId,
    required int quantity,
    required String destination,
    String? expectedUnit,
    int? expectedPrice,
  }) async {
    _checkText(destination, 'La destination');
    final p = _data.products.firstWhere((p) => p.id == productId);
    if (p.status == ProductStatus.archived) {
      throw ArgumentError('Ce produit est archivé.');
    }
    if (expectedUnit != null) {
      _sameUnit(p, expectedUnit);
    }
    if (expectedPrice != null && expectedPrice != p.price) {
      throw StateError(
        'Le prix du produit a changé. Fermez le formulaire et vérifiez le prix actuel.',
      );
    }
    final c = _data.contacts.firstWhere((c) => c.id == customerId);
    if (c.archived) throw ArgumentError('Ce client est archivé.');
    if (c.kind != ContactKind.client) {
      throw ArgumentError('Sélectionnez un client.');
    }
    _validateCommercialAmount(quantity, p.price);
    if (quantity <= 0 || quantity > p.quantity) {
      throw ArgumentError('Quantité invalide ou stock insuffisant.');
    }
    final now = DateTime.now();
    final order = TradeOrder(
      id: _id('CMD'),
      customerId: c.id,
      customerName: c.name,
      productId: p.id,
      productName: p.name,
      quantity: quantity,
      unitPrice: p.price,
      unit: p.unit,
      status: OrderStatus.confirmed,
      createdAt: now,
      destination: destination.trim(),
    );
    await _commit(
      _data.copyWith(
        products: [
          for (final item in _data.products)
            if (item.id == p.id)
              p.withQuantity(p.quantity - quantity)
            else
              item,
        ],
        orders: [order, ..._data.orders],
        movements: [
          StockMovement(
            id: _id('MVT'),
            productName: p.name,
            delta: -quantity,
            productId: p.id,
            sku: p.sku,
            unit: p.unit,
            kind: StockMovementKind.sale,
            reference: order.id,
            beforeQuantity: p.quantity,
            afterQuantity: p.quantity - quantity,
            reason: 'Commande ${order.id}',
            createdAt: now,
          ),
          ..._data.movements,
        ],
      ),
    );
  }

  Future<void> changeOrderStatus(String id, OrderStatus status) async {
    final order = _data.orders.firstWhere((o) => o.id == id);
    if (status == OrderStatus.delivered &&
        order.status == OrderStatus.shipped) {
      await recordDelivery(
        id,
        order.remainingQuantity,
        'Livraison du solde',
        expectedRevision: order.revision,
      );
      return;
    }
    final allowed = switch (order.status) {
      OrderStatus.confirmed => [OrderStatus.shipped, OrderStatus.cancelled],
      OrderStatus.shipped => [OrderStatus.delivered],
      _ => <OrderStatus>[],
    };
    if (!allowed.contains(status)) {
      throw ArgumentError('Changement de statut non autorisé.');
    }
    var products = _data.products;
    var movements = _data.movements;
    if (status == OrderStatus.cancelled) {
      final original = _data.products.firstWhere(
        (p) => p.id == order.productId,
      );
      _sameUnit(original, order.unit);
      if (original.quantity + order.quantity > 1000000000) {
        throw ArgumentError('Le retour dépasserait le stock maximal autorisé.');
      }
      products = [
        for (final p in products)
          if (p.id == order.productId)
            p.withQuantity(p.quantity + order.quantity)
          else
            p,
      ];
      movements = [
        StockMovement(
          id: _id('MVT'),
          productName: order.productName,
          delta: order.quantity,
          productId: original.id,
          sku: original.sku,
          unit: original.unit,
          kind: StockMovementKind.cancellation,
          reference: order.id,
          beforeQuantity: original.quantity,
          afterQuantity: original.quantity + order.quantity,
          reason: 'Annulation ${order.id}',
          createdAt: DateTime.now(),
        ),
        ...movements,
      ];
    }
    await _commit(
      _data.copyWith(
        products: products,
        movements: movements,
        orders: [
          for (final o in _data.orders)
            if (o.id == id) o.withStatus(status) else o,
        ],
      ),
    );
  }
}
