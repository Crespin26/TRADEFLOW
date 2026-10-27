enum StockMovementKind {
  legacy,
  initial,
  receipt,
  issue,
  sale,
  cancellation,
  inventory,
  purchaseReceipt,
  customerReturn,
  supplierReturn,
}

extension StockMovementKindLabel on StockMovementKind {
  String get label => switch (this) {
    StockMovementKind.legacy => 'Ancien mouvement',
    StockMovementKind.initial => 'Stock initial',
    StockMovementKind.receipt => 'Entrée',
    StockMovementKind.issue => 'Sortie',
    StockMovementKind.sale => 'Commande',
    StockMovementKind.cancellation => 'Annulation',
    StockMovementKind.inventory => 'Inventaire',
    StockMovementKind.purchaseReceipt => 'Réception achat',
    StockMovementKind.customerReturn => 'Retour client',
    StockMovementKind.supplierReturn => 'Retour fournisseur',
  };
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productName,
    required this.delta,
    required this.reason,
    required this.createdAt,
    this.productId,
    this.sku = '',
    this.unit = '',
    this.kind = StockMovementKind.legacy,
    this.beforeQuantity,
    this.afterQuantity,
    this.reference,
  });
  final String id, productName, reason, sku, unit;
  final String? productId, reference;
  final int delta;
  final int? beforeQuantity, afterQuantity;
  final StockMovementKind kind;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'productName': productName,
    'delta': delta,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'productId': productId,
    'sku': sku,
    'unit': unit,
    'kind': kind.name,
    'beforeQuantity': beforeQuantity,
    'afterQuantity': afterQuantity,
    'reference': reference,
  };
  factory StockMovement.fromJson(Map<String, dynamic> j) => StockMovement(
    id: j['id'] as String,
    productName: j['productName'] as String,
    delta: j['delta'] as int,
    reason: j['reason'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    productId: j['productId'] as String?,
    sku: j['sku'] as String? ?? '',
    unit: j['unit'] as String? ?? '',
    kind: StockMovementKind.values.byName(j['kind'] as String? ?? 'legacy'),
    beforeQuantity: j['beforeQuantity'] as int?,
    afterQuantity: j['afterQuantity'] as int?,
    reference: j['reference'] as String?,
  );
}

/// A physical count keeps its opening quantity so stale counts cannot erase newer movements.
class StockCount {
  const StockCount({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unit,
    required this.expectedQuantity,
    required this.countedQuantity,
  });
  final String productId, productName, sku, unit;
  final int expectedQuantity, countedQuantity;
  int get delta => countedQuantity - expectedQuantity;
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'sku': sku,
    'unit': unit,
    'expectedQuantity': expectedQuantity,
    'countedQuantity': countedQuantity,
  };
  factory StockCount.fromJson(Map<String, dynamic> j) => StockCount(
    productId: j['productId'] as String,
    productName: j['productName'] as String,
    sku: j['sku'] as String,
    unit: j['unit'] as String,
    expectedQuantity: j['expectedQuantity'] as int,
    countedQuantity: j['countedQuantity'] as int,
  );
}

/// Immutable audit of validated counts, including products with no discrepancy.
class StockInventory {
  StockInventory({
    required this.id,
    required this.reason,
    required this.createdAt,
    required List<StockCount> counts,
  }) : counts = List.unmodifiable(counts);
  final String id, reason;
  final DateTime createdAt;
  final List<StockCount> counts;
  int get correctedProducts => counts.where((c) => c.delta != 0).length;
  Map<String, dynamic> toJson() => {
    'id': id,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'counts': counts.map((c) => c.toJson()).toList(),
  };
  factory StockInventory.fromJson(Map<String, dynamic> j) => StockInventory(
    id: j['id'] as String,
    reason: j['reason'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    counts: (j['counts'] as List)
        .map((c) => StockCount.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
