part of 'trade_store.dart';

extension CatalogOperations on TradeStore {
  Future<void> addProduct({
    required String name,
    required String sku,
    required int quantity,
    required int threshold,
    required int price,
    int purchasePrice = 0,
    String category = 'Sans catégorie',
    String unit = 'pièce',
    String description = '',
    String origin = '',
    List<CatalogPhoto> photos = const [],
    bool featured = false,
    bool allowBackorder = false,
  }) async {
    _checkText(name, 'Le nom');
    _checkText(sku, 'La référence');
    if (quantity < 0 || threshold < 0 || price < 0) {
      throw ArgumentError('Les valeurs doivent être positives ou nulles.');
    }
    if (_data.products.any(
      (p) => p.sku.toLowerCase() == sku.trim().toLowerCase(),
    )) {
      throw ArgumentError('Cette référence produit existe déjà.');
    }
    final p = Product(
      id: _id('PRD'),
      name: name.trim(),
      sku: sku.trim(),
      quantity: quantity,
      threshold: threshold,
      price: price,
      purchasePrice: purchasePrice,
      category: category,
      unit: unit,
      description: description.trim(),
      origin: origin.trim(),
      photos: List.unmodifiable(photos),
      featured: featured,
      allowBackorder: allowBackorder,
    );
    _validateProduct(p);
    await _commit(
      _data.copyWith(
        products: [..._data.products, p],
        movements: [
          if (quantity > 0)
            StockMovement(
              id: _id('MVT'),
              productName: p.name,
              delta: quantity,
              productId: p.id,
              sku: p.sku,
              unit: p.unit,
              kind: StockMovementKind.initial,
              beforeQuantity: 0,
              afterQuantity: quantity,
              reason: 'Stock initial',
              createdAt: DateTime.now(),
            ),
          ..._data.movements,
        ],
      ),
    );
  }

  void _validateProduct(Product p) {
    _checkText(p.name, 'Le nom');
    _checkText(p.sku, 'La référence');
    if ([
      p.quantity,
      p.threshold,
      p.price,
      p.purchasePrice,
    ].any((v) => v < 0 || v > 1000000000)) {
      throw ArgumentError('Valeurs autorisées : 0 à 1 000 000 000.');
    }
    if (_data.products.any(
      (other) =>
          other.id != p.id &&
          other.sku.toLowerCase() == p.sku.trim().toLowerCase(),
    )) {
      throw ArgumentError('Cette référence produit existe déjà.');
    }
    if (!_data.categories.contains(p.category) ||
        !_data.units.contains(p.unit)) {
      throw ArgumentError('Choisissez une catégorie et une unité existantes.');
    }
    if (p.photos.length > 3 ||
        p.photos.any(
          (photo) => photo.bytes == null
              ? !catalogPhotos.values.any((asset) => asset.asset == photo.asset)
              : photo.bytes!.length > 350000,
        )) {
      throw ArgumentError('Trois photos maximum, de 350 Ko maximum chacune.');
    }
    final bytes = [..._data.products.where((other) => other.id != p.id), p]
        .expand((item) => item.photos)
        .fold<int>(0, (sum, photo) => sum + (photo.bytes?.length ?? 0));
    if (bytes > 2000000) {
      throw ArgumentError(
        'La limite locale de photos (2 Mo) est atteinte. Retirez des photos inutilisées.',
      );
    }
    if (p.status == ProductStatus.published &&
        (p.description.trim().isEmpty || p.photos.isEmpty)) {
      throw ArgumentError(
        'Ajoutez une description et au moins une photo avant de publier.',
      );
    }
  }

  Future<void> updateProduct(Product product) async {
    final original = _data.products.firstWhere((p) => p.id == product.id);
    if (original.status == ProductStatus.archived) {
      throw StateError('Restaurez ce produit avant de le modifier.');
    }
    if (product.quantity != original.quantity ||
        product.status != original.status) {
      throw ArgumentError(
        'Utilisez les actions de stock et de publication dédiées.',
      );
    }
    _validateProduct(product);
    await _commit(
      _data.copyWith(
        products: [
          for (final p in _data.products)
            if (p.id == product.id) product.copyWith() else p,
        ],
      ),
    );
  }

  Future<void> setProductStatus(String id, ProductStatus status) async {
    final p = _data.products.firstWhere((p) => p.id == id);
    if (p.status == ProductStatus.archived && status != ProductStatus.draft) {
      throw ArgumentError(
        'Un produit archivé doit être restauré en brouillon.',
      );
    }
    final next = p.copyWith(status: status);
    _validateProduct(next);
    await _commit(
      _data.copyWith(
        catalogEnabled:
            _data.catalogEnabled || status == ProductStatus.published,
        products: [
          for (final item in _data.products)
            if (item.id == id) next else item,
        ],
      ),
    );
  }

  Future<void> saveReference({
    required bool category,
    String? previous,
    required String value,
  }) async {
    final name = value.trim();
    _checkText(name, category ? 'La catégorie' : 'L’unité');
    if (name.length > 60) throw ArgumentError('60 caractères maximum.');
    final source = category ? _data.categories : _data.units;
    if (previous != null && !source.contains(previous)) {
      throw ArgumentError('Référence introuvable.');
    }
    if (source.any(
      (item) => item != previous && item.toLowerCase() == name.toLowerCase(),
    )) {
      throw ArgumentError('Ce nom existe déjà.');
    }
    final updated = [
      for (final item in source)
        if (item == previous) name else item,
      if (previous == null) name,
    ];
    await _commit(
      _data.copyWith(
        categories: category ? updated : null,
        units: category ? null : updated,
        products: [
          for (final p in _data.products)
            p.copyWith(
              category: category && p.category == previous ? name : null,
              unit: !category && p.unit == previous ? name : null,
            ),
        ],
      ),
    );
  }

  Future<void> deleteReference({
    required bool category,
    required String value,
  }) async {
    final source = category ? _data.categories : _data.units;
    if (source.length <= 1 ||
        _data.products.any((p) => (category ? p.category : p.unit) == value)) {
      throw ArgumentError(
        'Référence utilisée ou dernière référence disponible.',
      );
    }
    await _commit(
      _data.copyWith(
        categories: category ? source.where((v) => v != value).toList() : null,
        units: category ? null : source.where((v) => v != value).toList(),
      ),
    );
  }
}
