enum OrderStatus { confirmed, shipped, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.confirmed => 'Confirmée',
    OrderStatus.shipped => 'Expédiée',
    OrderStatus.delivered => 'Livrée',
    OrderStatus.cancelled => 'Annulée',
  };
}

class TradeOrder {
  const TradeOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.status,
    required this.createdAt,
    required this.destination,
    this.unit = '',
    int? deliveredQuantity,
    this.returnedQuantity = 0,
    this.revision = 0,
    this.quoteId,
  }) : deliveredQuantity =
           deliveredQuantity ??
           (status == OrderStatus.delivered ? quantity : 0);
  final String id,
      customerId,
      customerName,
      productId,
      productName,
      destination,
      unit;
  final String? quoteId;
  final int quantity, unitPrice, deliveredQuantity, returnedQuantity, revision;
  final OrderStatus status;
  final DateTime createdAt;
  int get total => quantity * unitPrice;
  int get remainingQuantity => quantity - deliveredQuantity;
  int get returnableQuantity => deliveredQuantity - returnedQuantity;
  TradeOrder copyWith({
    OrderStatus? status,
    int? deliveredQuantity,
    int? returnedQuantity,
  }) => TradeOrder(
    id: id,
    customerId: customerId,
    customerName: customerName,
    productId: productId,
    productName: productName,
    quantity: quantity,
    unitPrice: unitPrice,
    status: status ?? this.status,
    createdAt: createdAt,
    destination: destination,
    unit: unit,
    quoteId: quoteId,
    deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
    returnedQuantity: returnedQuantity ?? this.returnedQuantity,
    revision: revision + 1,
  );
  TradeOrder withStatus(OrderStatus value) => copyWith(
    status: value,
    deliveredQuantity: value == OrderStatus.delivered ? quantity : null,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'destination': destination,
    'unit': unit,
    'deliveredQuantity': deliveredQuantity,
    'returnedQuantity': returnedQuantity,
    'revision': revision,
    'quoteId': quoteId,
  };
  // Old delivered orders are fully delivered; missing historical events are never fabricated.
  factory TradeOrder.fromJson(Map<String, dynamic> j) => TradeOrder(
    id: j['id'] as String,
    customerId: j['customerId'] as String,
    customerName: j['customerName'] as String,
    productId: j['productId'] as String,
    productName: j['productName'] as String,
    quantity: j['quantity'] as int,
    unitPrice: j['unitPrice'] as int,
    status: OrderStatus.values.byName(j['status'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String),
    destination: j['destination'] as String,
    unit: j['unit'] as String? ?? '',
    deliveredQuantity: j['deliveredQuantity'] as int?,
    returnedQuantity: j['returnedQuantity'] as int? ?? 0,
    revision: j['revision'] as int? ?? 0,
    quoteId: j['quoteId'] as String?,
  );
}
