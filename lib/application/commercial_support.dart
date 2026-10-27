part of 'trade_store.dart';

extension CommercialSupport on TradeStore {
  void _validateCommercialAmount(int quantity, int price) {
    if (quantity < 1 ||
        quantity > 1000000000 ||
        price < 0 ||
        price > 1000000000 ||
        quantity * price > 9007199254740991) {
      throw ArgumentError(
        'Quantité et prix invalides, ou total supérieur à la limite de calcul exact.',
      );
    }
  }

  Product _commercialProduct(String id, {bool active = true}) {
    final p = _data.products.where((p) => p.id == id).firstOrNull;
    if (p == null || (active && p.status == ProductStatus.archived)) {
      throw ArgumentError('Choisissez un produit actif.');
    }
    return p;
  }

  Contact _commercialContact(String id, ContactKind kind) {
    final c = _data.contacts.where((c) => c.id == id).firstOrNull;
    if (c == null || c.archived || c.kind != kind) {
      throw ArgumentError('Choisissez un ${kind.label.toLowerCase()} actif.');
    }
    return c;
  }

  void _commercialText(String destination, String notes) {
    _checkText(destination, 'La destination');
    if (destination.trim().length > 160 || notes.trim().length > 2000) {
      throw ArgumentError(
        'Destination : 160 caractères ; notes : 2 000 maximum.',
      );
    }
  }

  void _sameUnit(Product p, String unit) {
    if (unit.isNotEmpty && p.unit != unit) {
      throw StateError(
        'L’unité du produit a changé. Rétablissez l’unité du document avant cette opération.',
      );
    }
  }

  void _revision(int current, int? expected) {
    if (current != expected) {
      throw StateError(
        'Ce document a changé. Fermez le formulaire puis ouvrez sa version actuelle.',
      );
    }
  }

  CommercialEvent _event({
    required String documentId,
    required Product product,
    required String productName,
    required String partnerName,
    required String unit,
    required int quantity,
    required String reason,
    required CommercialEventKind kind,
    bool restocked = true,
  }) {
    _checkText(reason, 'Le motif ou la référence');
    if (reason.trim().length > 500) {
      throw ArgumentError('Le motif est limité à 500 caractères.');
    }
    final plan = _data.deliveryPlans
        .where((p) => p.orderId == documentId)
        .firstOrNull;
    return CommercialEvent(
      restocked: restocked,
      carrier: kind == CommercialEventKind.delivery ? plan?.carrier ?? '' : '',
      trackingNumber: kind == CommercialEventKind.delivery
          ? plan?.trackingNumber ?? ''
          : '',
      id: _id('OP'),
      documentId: documentId,
      productId: product.id,
      productName: productName,
      partnerName: partnerName,
      unit: unit.isEmpty ? product.unit : unit,
      quantity: quantity,
      reason: reason.trim(),
      kind: kind,
      createdAt: DateTime.now(),
    );
  }

  TradeData _stockOperation(
    TradeData next,
    Product p,
    int delta,
    CommercialEvent event,
    StockMovementKind kind,
  ) {
    if (p.quantity + delta < 0 || p.quantity + delta > 1000000000) {
      throw ArgumentError('Stock insuffisant ou quantité maximale dépassée.');
    }
    return next.copyWith(
      products: [
        for (final item in _data.products)
          if (item.id == p.id) p.withQuantity(p.quantity + delta) else item,
      ],
      movements: [
        StockMovement(
          id: _id('MVT'),
          productId: p.id,
          productName: event.productName,
          sku: p.sku,
          unit: event.unit,
          delta: delta,
          beforeQuantity: p.quantity,
          afterQuantity: p.quantity + delta,
          kind: kind,
          reference: event.documentId,
          reason: event.reason,
          createdAt: event.createdAt,
        ),
        ..._data.movements,
      ],
      commercialEvents: [event, ..._data.commercialEvents],
    );
  }
}
