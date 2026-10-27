import '../catalog_photos.dart';

enum ProductStatus { draft, published, archived }

extension ProductStatusLabel on ProductStatus {
  String get label => switch (this) {
    ProductStatus.draft => 'Brouillon',
    ProductStatus.published => 'Publié',
    ProductStatus.archived => 'Archivé',
  };
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.threshold,
    required this.price,
    this.purchasePrice = 0,
    this.category = 'Sans catégorie',
    this.unit = 'pièce',
    this.description = '',
    this.origin = '',
    this.photos = const [],
    this.featured = false,
    this.allowBackorder = false,
    this.status = ProductStatus.draft,
  });
  final String id, name, sku, category, unit, description, origin;
  final int quantity, threshold, price, purchasePrice;
  final List<CatalogPhoto> photos;
  final bool featured, allowBackorder;
  final ProductStatus status;
  bool get lowStock =>
      status != ProductStatus.archived && quantity <= threshold;
  Product copyWith({
    String? name,
    String? sku,
    int? quantity,
    int? threshold,
    int? price,
    int? purchasePrice,
    String? category,
    String? unit,
    String? description,
    String? origin,
    List<CatalogPhoto>? photos,
    bool? featured,
    bool? allowBackorder,
    ProductStatus? status,
  }) => Product(
    id: id,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    quantity: quantity ?? this.quantity,
    threshold: threshold ?? this.threshold,
    price: price ?? this.price,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    category: category ?? this.category,
    unit: unit ?? this.unit,
    description: description ?? this.description,
    origin: origin ?? this.origin,
    photos: List.unmodifiable(photos ?? this.photos),
    featured: featured ?? this.featured,
    allowBackorder: allowBackorder ?? this.allowBackorder,
    status: status ?? this.status,
  );
  Product withQuantity(int value) => copyWith(quantity: value);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'quantity': quantity,
    'threshold': threshold,
    'price': price,
    'purchasePrice': purchasePrice,
    'category': category,
    'unit': unit,
    'description': description,
    'origin': origin,
    'photos': photos.map((p) => p.toJson()).toList(),
    'featured': featured,
    'allowBackorder': allowBackorder,
    'status': status.name,
  };
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String,
    name: j['name'] as String,
    sku: j['sku'] as String,
    quantity: j['quantity'] as int,
    threshold: j['threshold'] as int,
    price: j['price'] as int,
    purchasePrice: j['purchasePrice'] as int? ?? 0,
    category: j['category'] as String? ?? 'Sans catégorie',
    unit: j['unit'] as String? ?? 'pièce',
    description: j['description'] as String? ?? '',
    origin: j['origin'] as String? ?? '',
    photos: List.unmodifiable(
      (j['photos'] as List? ?? []).map(
        (p) => CatalogPhoto.fromJson(p as Map<String, dynamic>),
      ),
    ),
    featured: j['featured'] as bool? ?? false,
    allowBackorder: j['allowBackorder'] as bool? ?? false,
    status: ProductStatus.values.byName(j['status'] as String? ?? 'draft'),
  );
}
