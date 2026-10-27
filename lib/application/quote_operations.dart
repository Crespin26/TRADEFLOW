part of 'trade_store.dart';

extension QuoteOperations on TradeStore {
  Future<String> saveQuote({
    String? id,
    int? expectedRevision,
    required String customerId,
    required String productId,
    required int quantity,
    required int unitPrice,
    required String destination,
    required DateTime expiresAt,
    String notes = '',
    String? expectedUnit,
  }) async {
    final previous = id == null
        ? null
        : _data.quotes.firstWhere((q) => q.id == id);
    if (previous != null) {
      _revision(previous.revision, expectedRevision);
      if (previous.status != QuoteStatus.draft) {
        throw StateError('Seul un devis brouillon peut être modifié.');
      }
    }
    final c = _commercialContact(customerId, ContactKind.client);
    final p = _commercialProduct(productId);
    if (expectedUnit != null) {
      _sameUnit(p, expectedUnit);
    }
    _validateCommercialAmount(quantity, unitPrice);
    _commercialText(destination, notes);
    final now = DateTime.now();
    final q = TradeQuote(
      id: id ?? _id('DEV'),
      customerId: c.id,
      customerName: c.name,
      productId: p.id,
      productName: p.name,
      sku: p.sku,
      unit: p.unit,
      quantity: quantity,
      unitPrice: unitPrice,
      destination: destination.trim(),
      expiresAt: expiresAt,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
      notes: notes.trim(),
      revision: previous == null ? 0 : previous.revision + 1,
    );
    if (q.isExpiredAt(now)) {
      throw ArgumentError(
        'La date de validité ne peut pas être antérieure à aujourd’hui.',
      );
    }
    await _commit(
      _data.copyWith(
        quotes: [q, ..._data.quotes.where((item) => item.id != q.id)],
      ),
    );
    return q.id;
  }

  Future<void> changeQuoteStatus(
    String id,
    QuoteStatus status, {
    required int expectedRevision,
  }) async {
    final q = _data.quotes.firstWhere((q) => q.id == id);
    _revision(q.revision, expectedRevision);
    final allowed = switch (q.status) {
      QuoteStatus.draft => [QuoteStatus.sent, QuoteStatus.cancelled],
      QuoteStatus.sent => [
        QuoteStatus.accepted,
        QuoteStatus.rejected,
        QuoteStatus.cancelled,
      ],
      QuoteStatus.accepted => [QuoteStatus.cancelled],
      _ => <QuoteStatus>[],
    };
    if (!allowed.contains(status)) {
      throw ArgumentError('Transition de devis non autorisée.');
    }
    if (status == QuoteStatus.sent || status == QuoteStatus.accepted) {
      if (q.isExpiredAt(DateTime.now())) {
        throw StateError('Le devis est expiré.');
      }
      _commercialContact(q.customerId, ContactKind.client);
      _sameUnit(_commercialProduct(q.productId), q.unit);
    }
    await _commit(
      _data.copyWith(
        quotes: [
          for (final item in _data.quotes)
            if (item.id == id) q.withStatus(status) else item,
        ],
      ),
    );
  }

  /// A single commit links the quote, creates its order and deducts stock exactly once.
  Future<String> convertQuote(
    String id, {
    required int expectedRevision,
  }) async {
    final q = _data.quotes.firstWhere((q) => q.id == id);
    if (q.status == QuoteStatus.converted && q.orderId != null) {
      return q.orderId!;
    }
    _revision(q.revision, expectedRevision);
    if (q.status != QuoteStatus.accepted || q.isExpiredAt(DateTime.now())) {
      throw StateError('Un devis accepté et encore valide est requis.');
    }
    _commercialContact(q.customerId, ContactKind.client);
    final p = _commercialProduct(q.productId);
    _sameUnit(p, q.unit);
    if (q.quantity > p.quantity) {
      throw ArgumentError('Stock insuffisant pour convertir ce devis.');
    }
    final order = TradeOrder(
      id: _id('CMD'),
      customerId: q.customerId,
      customerName: q.customerName,
      productId: q.productId,
      productName: q.productName,
      quantity: q.quantity,
      unitPrice: q.unitPrice,
      unit: q.unit,
      status: OrderStatus.confirmed,
      createdAt: DateTime.now(),
      destination: q.destination,
      quoteId: q.id,
    );
    await _commit(
      _data.copyWith(
        products: [
          for (final item in _data.products)
            if (item.id == p.id)
              p.withQuantity(p.quantity - q.quantity)
            else
              item,
        ],
        orders: [order, ..._data.orders],
        quotes: [
          for (final item in _data.quotes)
            if (item.id == id)
              q.withStatus(QuoteStatus.converted, orderId: order.id)
            else
              item,
        ],
        movements: [
          StockMovement(
            id: _id('MVT'),
            productId: p.id,
            productName: q.productName,
            sku: q.sku,
            unit: q.unit,
            delta: -q.quantity,
            beforeQuantity: p.quantity,
            afterQuantity: p.quantity - q.quantity,
            kind: StockMovementKind.sale,
            reference: order.id,
            reason: 'Conversion du devis ${q.id}',
            createdAt: order.createdAt,
          ),
          ..._data.movements,
        ],
      ),
    );
    return order.id;
  }
}
