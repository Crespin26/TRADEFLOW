part of 'trade_store.dart';

extension StockOperations on TradeStore {
  /// Enregistre une variation motivée sans écraser un stock modifié depuis l’ouverture du formulaire.
  Future<void> adjustStock(
    String productId,
    int delta,
    String reason, {
    int? expectedQuantity,
    String? expectedUnit,
  }) async {
    _checkText(reason, 'Le motif');
    final p = _data.products.firstWhere((p) => p.id == productId);
    if (p.status == ProductStatus.archived) {
      throw ArgumentError('Ce produit est archivé.');
    }
    if ((expectedQuantity != null && p.quantity != expectedQuantity) ||
        (expectedUnit != null && p.unit != expectedUnit)) {
      throw StateError(
        'Le stock ou l’unité a changé. Fermez le formulaire et recommencez avec les données actuelles.',
      );
    }
    if (delta.abs() > 1000000000 || p.quantity + delta > 1000000000) {
      throw ArgumentError(
        'Le stock doit rester compris entre 0 et 1 000 000 000.',
      );
    }
    if (delta == 0) {
      throw ArgumentError('La quantité doit être différente de zéro.');
    }
    if (p.quantity + delta < 0) {
      throw ArgumentError('Stock disponible insuffisant.');
    }
    await _commit(
      _data.copyWith(
        products: [
          for (final item in _data.products)
            if (item.id == p.id) p.withQuantity(p.quantity + delta) else item,
        ],
        movements: [
          StockMovement(
            id: _id('MVT'),
            productName: p.name,
            delta: delta,
            productId: p.id,
            sku: p.sku,
            unit: p.unit,
            kind: delta > 0
                ? StockMovementKind.receipt
                : StockMovementKind.issue,
            beforeQuantity: p.quantity,
            afterQuantity: p.quantity + delta,
            reason: reason.trim(),
            createdAt: DateTime.now(),
          ),
          ..._data.movements,
        ],
      ),
    );
  }

  /// Valide tous les comptages avant de sauvegarder stock, inventaire et mouvements ensemble.
  Future<void> performInventory({
    required List<StockCount> counts,
    required String reason,
  }) async {
    _checkText(reason, 'Le motif de l’inventaire');
    if (counts.isEmpty ||
        counts.map((c) => c.productId).toSet().length != counts.length) {
      throw ArgumentError('Sélectionnez des produits distincts à compter.');
    }
    // Validate every count before building a single atomic stock/history update.
    final canonical = <StockCount>[];
    for (final count in counts) {
      final p = _data.products
          .where((p) => p.id == count.productId)
          .firstOrNull;
      if (p == null || p.status == ProductStatus.archived) {
        throw StateError(
          'Un produit est archivé ou absent. Recommencez l’inventaire.',
        );
      }
      // A concurrent receipt, sale or unit change invalidates the opening snapshot.
      if (p.quantity != count.expectedQuantity || p.unit != count.unit) {
        throw StateError(
          'Le stock ou l’unité de ${p.name} a changé. Fermez cet inventaire et recommencez avec les données actuelles.',
        );
      }
      if (count.countedQuantity < 0 || count.countedQuantity > 1000000000) {
        throw ArgumentError(
          'Le comptage doit être compris entre 0 et 1 000 000 000.',
        );
      }
      canonical.add(
        StockCount(
          productId: p.id,
          productName: p.name,
          sku: p.sku,
          unit: p.unit,
          expectedQuantity: p.quantity,
          countedQuantity: count.countedQuantity,
        ),
      );
    }
    final inventory = StockInventory(
      id: _id('INV'),
      reason: reason.trim(),
      createdAt: DateTime.now(),
      counts: canonical,
    );
    final byId = {for (final c in canonical) c.productId: c};
    await _commit(
      _data.copyWith(
        products: [
          for (final p in _data.products)
            if (byId.containsKey(p.id))
              p.withQuantity(byId[p.id]!.countedQuantity)
            else
              p,
        ],
        inventories: [inventory, ..._data.inventories],
        movements: [
          for (final c in canonical)
            // Counts without discrepancies stay in the audit, without a zero movement.
            if (c.delta != 0)
              StockMovement(
                id: _id('MVT'),
                productId: c.productId,
                productName: c.productName,
                sku: c.sku,
                unit: c.unit,
                delta: c.delta,
                beforeQuantity: c.expectedQuantity,
                afterQuantity: c.countedQuantity,
                kind: StockMovementKind.inventory,
                reference: inventory.id,
                reason: inventory.reason,
                createdAt: inventory.createdAt,
              ),
          ..._data.movements,
        ],
      ),
    );
  }
}
