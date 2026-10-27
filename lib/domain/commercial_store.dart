part of 'trade_store.dart';

extension CommercialOperations on TradeStore {
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

  Future<void> saveCompanyProfile(
    CompanyProfile profile, {
    required int expectedRevision,
  }) async {
    _revision(_data.company.revision, expectedRevision);
    _checkText(profile.name, 'Le nom de l’entreprise');
    if ([
          profile.name,
          profile.country,
          profile.email,
          profile.registration,
        ].any((v) => v.trim().length > 160) ||
        profile.address.trim().length > 500 ||
        profile.phone.trim().length > 40) {
      throw ArgumentError(
        'Coordonnées trop longues : nom, pays, e-mail et registre 160 ; adresse 500 ; téléphone 40.',
      );
    }
    if (profile.email.trim().isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(profile.email.trim())) {
      throw ArgumentError('Adresse e-mail invalide.');
    }
    await _commit(
      _data.copyWith(
        company: CompanyProfile(
          name: profile.name.trim(),
          address: profile.address.trim(),
          country: profile.country.trim(),
          email: profile.email.trim().toLowerCase(),
          phone: profile.phone.trim(),
          registration: profile.registration.trim(),
          revision: _data.company.revision + 1,
        ),
      ),
    );
  }

  Future<void> archiveBusinessDocument(BusinessDocument doc) async {
    if (doc.company.name.isEmpty) {
      throw ArgumentError('Renseignez l’entreprise avant d’exporter.');
    }
    if (_data.issuedDocuments.any((d) => d.reference == doc.reference)) return;
    final json = doc.toJson()..['issuedAt'] = DateTime.now().toIso8601String();
    await _commit(
      _data.copyWith(
        issuedDocuments: [
          BusinessDocument.fromJson(json),
          ..._data.issuedDocuments,
        ],
      ),
    );
  }
}
