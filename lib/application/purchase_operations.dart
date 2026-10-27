part of 'trade_store.dart';

extension PurchaseOperations on TradeStore {
  Future<String> savePurchase({
    String? id,
    int? expectedRevision,
    required String supplierId,
    required String productId,
    required int quantity,
    required int unitPrice,
    required String destination,
    String notes = '',
    String? expectedUnit,
  }) async {
    final previous = id == null
        ? null
        : _data.purchases.firstWhere((p) => p.id == id);
    if (previous != null) {
      _revision(previous.revision, expectedRevision);
      if (previous.status != PurchaseStatus.draft) {
        throw StateError('Seul un achat brouillon peut être modifié.');
      }
    }
    final c = _commercialContact(supplierId, ContactKind.supplier);
    final p = _commercialProduct(productId);
    if (expectedUnit != null) {
      _sameUnit(p, expectedUnit);
    }
    _validateCommercialAmount(quantity, unitPrice);
    _commercialText(destination, notes);
    final now = DateTime.now();
    final purchase = PurchaseOrder(
      id: id ?? _id('ACH'),
      supplierId: c.id,
      supplierName: c.name,
      productId: p.id,
      productName: p.name,
      sku: p.sku,
      unit: p.unit,
      quantity: quantity,
      unitPrice: unitPrice,
      destination: destination.trim(),
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
      notes: notes.trim(),
      revision: previous == null ? 0 : previous.revision + 1,
    );
    await _commit(
      _data.copyWith(
        purchases: [
          purchase,
          ..._data.purchases.where((p) => p.id != purchase.id),
        ],
      ),
    );
    return purchase.id;
  }

  Future<void> changePurchaseStatus(
    String id,
    PurchaseStatus status, {
    required int expectedRevision,
  }) async {
    final p = _data.purchases.firstWhere((p) => p.id == id);
    _revision(p.revision, expectedRevision);
    final allowed = p.status == PurchaseStatus.draft
        ? [PurchaseStatus.ordered, PurchaseStatus.cancelled]
        : p.status == PurchaseStatus.ordered && p.receivedQuantity == 0
        ? [PurchaseStatus.cancelled]
        : <PurchaseStatus>[];
    if (!allowed.contains(status)) {
      throw ArgumentError(
        'Un achat reçu, même partiellement, ne peut pas être annulé.',
      );
    }
    if (status == PurchaseStatus.ordered) {
      _commercialContact(p.supplierId, ContactKind.supplier);
      _sameUnit(_commercialProduct(p.productId), p.unit);
    }
    await _commit(
      _data.copyWith(
        purchases: [
          for (final item in _data.purchases)
            if (item.id == id) p.copyWith(status: status) else item,
        ],
      ),
    );
  }

  Future<void> receivePurchase(
    String id,
    int quantity,
    String reason, {
    required int expectedRevision,
  }) async {
    final purchase = _data.purchases.firstWhere((p) => p.id == id);
    _revision(purchase.revision, expectedRevision);
    if (purchase.status != PurchaseStatus.ordered ||
        quantity < 1 ||
        quantity > purchase.remainingQuantity) {
      throw ArgumentError(
        'Quantité supérieure au solde à recevoir ou achat non commandé.',
      );
    }
    final p = _commercialProduct(purchase.productId);
    _sameUnit(p, purchase.unit);
    final event = _event(
      documentId: id,
      product: p,
      productName: purchase.productName,
      partnerName: purchase.supplierName,
      unit: purchase.unit,
      quantity: quantity,
      reason: reason,
      kind: CommercialEventKind.receipt,
    );
    final received = purchase.receivedQuantity + quantity;
    final next = _data.copyWith(
      purchases: [
        for (final item in _data.purchases)
          if (item.id == id)
            purchase.copyWith(
              receivedQuantity: received,
              status: received == purchase.quantity
                  ? PurchaseStatus.received
                  : PurchaseStatus.ordered,
            )
          else
            item,
      ],
    );
    await _commit(
      _stockOperation(
        next,
        p,
        quantity,
        event,
        StockMovementKind.purchaseReceipt,
      ),
    );
  }

  Future<void> returnSupplier(
    String id,
    int quantity,
    String reason, {
    required int expectedRevision,
  }) async {
    final purchase = _data.purchases.firstWhere((p) => p.id == id);
    _revision(purchase.revision, expectedRevision);
    if (quantity < 1 ||
        quantity > purchase.returnableQuantity ||
        purchase.status == PurchaseStatus.cancelled) {
      throw ArgumentError(
        'Le retour dépasse la quantité reçue non encore retournée.',
      );
    }
    final p = _commercialProduct(purchase.productId, active: false);
    _sameUnit(p, purchase.unit);
    final event = _event(
      documentId: id,
      product: p,
      productName: purchase.productName,
      partnerName: purchase.supplierName,
      unit: purchase.unit,
      quantity: quantity,
      reason: reason,
      kind: CommercialEventKind.supplierReturn,
    );
    final next = _data.copyWith(
      purchases: [
        for (final item in _data.purchases)
          if (item.id == id)
            purchase.copyWith(
              returnedQuantity: purchase.returnedQuantity + quantity,
            )
          else
            item,
      ],
    );
    await _commit(
      _stockOperation(
        next,
        p,
        -quantity,
        event,
        StockMovementKind.supplierReturn,
      ),
    );
  }
}
