/// Commercial documents snapshot agreed names, quantities, units and XOF prices.
enum QuoteStatus { draft, sent, accepted, rejected, cancelled, converted }

extension QuoteStatusLabel on QuoteStatus {
  String get label => switch (this) {
    QuoteStatus.draft => 'Brouillon',
    QuoteStatus.sent => 'Envoyé',
    QuoteStatus.accepted => 'Accepté',
    QuoteStatus.rejected => 'Refusé',
    QuoteStatus.cancelled => 'Annulé',
    QuoteStatus.converted => 'Converti',
  };
}

enum PurchaseStatus { draft, ordered, received, cancelled }

extension PurchaseStatusLabel on PurchaseStatus {
  String get label => switch (this) {
    PurchaseStatus.draft => 'Brouillon',
    PurchaseStatus.ordered => 'Commandé',
    PurchaseStatus.received => 'Reçu',
    PurchaseStatus.cancelled => 'Annulé',
  };
}

enum CommercialEventKind { receipt, delivery, customerReturn, supplierReturn }

extension CommercialEventKindLabel on CommercialEventKind {
  String get label => switch (this) {
    CommercialEventKind.receipt => 'Réception fournisseur',
    CommercialEventKind.delivery => 'Livraison client',
    CommercialEventKind.customerReturn => 'Retour client',
    CommercialEventKind.supplierReturn => 'Retour fournisseur',
  };
}

class TradeQuote {
  const TradeQuote({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.destination,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.status = QuoteStatus.draft,
    this.revision = 0,
    this.orderId,
  });
  final String id,
      customerId,
      customerName,
      productId,
      productName,
      sku,
      unit,
      destination,
      notes;
  final int quantity, unitPrice, revision;
  final QuoteStatus status;
  final DateTime expiresAt, createdAt, updatedAt;
  final String? orderId;
  int get total => quantity * unitPrice;
  bool isExpiredAt(DateTime now) => DateTime(
    expiresAt.year,
    expiresAt.month,
    expiresAt.day,
  ).isBefore(DateTime(now.year, now.month, now.day));
  TradeQuote withStatus(QuoteStatus value, {String? orderId}) => TradeQuote(
    id: id,
    customerId: customerId,
    customerName: customerName,
    productId: productId,
    productName: productName,
    sku: sku,
    unit: unit,
    quantity: quantity,
    unitPrice: unitPrice,
    destination: destination,
    expiresAt: expiresAt,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    notes: notes,
    status: value,
    revision: revision + 1,
    orderId: orderId ?? this.orderId,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'productId': productId,
    'productName': productName,
    'sku': sku,
    'unit': unit,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'destination': destination,
    'expiresAt': expiresAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'notes': notes,
    'status': status.name,
    'revision': revision,
    'orderId': orderId,
  };
  factory TradeQuote.fromJson(Map<String, dynamic> j) => TradeQuote(
    id: j['id'] as String,
    customerId: j['customerId'] as String,
    customerName: j['customerName'] as String,
    productId: j['productId'] as String,
    productName: j['productName'] as String,
    sku: j['sku'] as String,
    unit: j['unit'] as String,
    quantity: j['quantity'] as int,
    unitPrice: j['unitPrice'] as int,
    destination: j['destination'] as String,
    expiresAt: DateTime.parse(j['expiresAt'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    notes: j['notes'] as String,
    status: QuoteStatus.values.byName(j['status'] as String),
    revision: j['revision'] as int,
    orderId: j['orderId'] as String?,
  );
}

class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.destination,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.status = PurchaseStatus.draft,
    this.receivedQuantity = 0,
    this.returnedQuantity = 0,
    this.revision = 0,
  });
  final String id,
      supplierId,
      supplierName,
      productId,
      productName,
      sku,
      unit,
      destination,
      notes;
  final int quantity, unitPrice, receivedQuantity, returnedQuantity, revision;
  final PurchaseStatus status;
  final DateTime createdAt, updatedAt;
  int get total => quantity * unitPrice;
  int get remainingQuantity => quantity - receivedQuantity;
  int get returnableQuantity => receivedQuantity - returnedQuantity;
  PurchaseOrder copyWith({
    PurchaseStatus? status,
    int? receivedQuantity,
    int? returnedQuantity,
  }) => PurchaseOrder(
    id: id,
    supplierId: supplierId,
    supplierName: supplierName,
    productId: productId,
    productName: productName,
    sku: sku,
    unit: unit,
    quantity: quantity,
    unitPrice: unitPrice,
    destination: destination,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    notes: notes,
    status: status ?? this.status,
    receivedQuantity: receivedQuantity ?? this.receivedQuantity,
    returnedQuantity: returnedQuantity ?? this.returnedQuantity,
    revision: revision + 1,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'productId': productId,
    'productName': productName,
    'sku': sku,
    'unit': unit,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'destination': destination,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'notes': notes,
    'status': status.name,
    'receivedQuantity': receivedQuantity,
    'returnedQuantity': returnedQuantity,
    'revision': revision,
  };
  factory PurchaseOrder.fromJson(Map<String, dynamic> j) => PurchaseOrder(
    id: j['id'] as String,
    supplierId: j['supplierId'] as String,
    supplierName: j['supplierName'] as String,
    productId: j['productId'] as String,
    productName: j['productName'] as String,
    sku: j['sku'] as String,
    unit: j['unit'] as String,
    quantity: j['quantity'] as int,
    unitPrice: j['unitPrice'] as int,
    destination: j['destination'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    notes: j['notes'] as String,
    status: PurchaseStatus.values.byName(j['status'] as String),
    receivedQuantity: j['receivedQuantity'] as int,
    returnedQuantity: j['returnedQuantity'] as int,
    revision: j['revision'] as int,
  );
}

/// Each receipt, delivery or return is append-only; correcting it requires a new operation.
class CommercialEvent {
  const CommercialEvent({
    required this.id,
    required this.documentId,
    required this.productId,
    required this.productName,
    required this.partnerName,
    required this.unit,
    required this.quantity,
    required this.reason,
    required this.kind,
    required this.createdAt,
    this.restocked = true,
    this.carrier = '',
    this.trackingNumber = '',
  });
  final String id,
      documentId,
      productId,
      productName,
      partnerName,
      unit,
      reason;
  final bool restocked;
  final String carrier, trackingNumber;
  final int quantity;
  final CommercialEventKind kind;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'restocked': restocked,
    'carrier': carrier,
    'trackingNumber': trackingNumber,
    'id': id,
    'documentId': documentId,
    'productId': productId,
    'productName': productName,
    'partnerName': partnerName,
    'unit': unit,
    'quantity': quantity,
    'reason': reason,
    'kind': kind.name,
    'createdAt': createdAt.toIso8601String(),
  };
  factory CommercialEvent.fromJson(Map<String, dynamic> j) => CommercialEvent(
    restocked: j['restocked'] as bool? ?? true,
    carrier: j['carrier'] as String? ?? '',
    trackingNumber: j['trackingNumber'] as String? ?? '',
    id: j['id'] as String,
    documentId: j['documentId'] as String,
    productId: j['productId'] as String,
    productName: j['productName'] as String,
    partnerName: j['partnerName'] as String,
    unit: j['unit'] as String,
    quantity: j['quantity'] as int,
    reason: j['reason'] as String,
    kind: CommercialEventKind.values.byName(j['kind'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
