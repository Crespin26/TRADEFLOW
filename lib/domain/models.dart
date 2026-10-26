import 'catalog_photos.dart';

enum ContactKind { client, supplier }

enum OrderStatus { confirmed, shipped, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.confirmed => 'Confirmée',
    OrderStatus.shipped => 'Expédiée',
    OrderStatus.delivered => 'Livrée',
    OrderStatus.cancelled => 'Annulée',
  };
}

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

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.kind,
    required this.country,
    required this.email,
    required this.phone,
  });
  final String id, name, country, email, phone;
  final ContactKind kind;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'country': country,
    'email': email,
    'phone': phone,
  };
  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
    id: j['id'] as String,
    name: j['name'] as String,
    kind: ContactKind.values.byName(j['kind'] as String),
    country: j['country'] as String,
    email: j['email'] as String,
    phone: j['phone'] as String,
  );
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
  });
  final String id,
      customerId,
      customerName,
      productId,
      productName,
      destination;
  final int quantity, unitPrice;
  final OrderStatus status;
  final DateTime createdAt;
  int get total => quantity * unitPrice;
  TradeOrder withStatus(OrderStatus value) => TradeOrder(
    id: id,
    customerId: customerId,
    customerName: customerName,
    productId: productId,
    productName: productName,
    quantity: quantity,
    unitPrice: unitPrice,
    status: value,
    createdAt: createdAt,
    destination: destination,
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
  };
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
  );
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productName,
    required this.delta,
    required this.reason,
    required this.createdAt,
  });
  final String id, productName, reason;
  final int delta;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'productName': productName,
    'delta': delta,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
  };
  factory StockMovement.fromJson(Map<String, dynamic> j) => StockMovement(
    id: j['id'] as String,
    productName: j['productName'] as String,
    delta: j['delta'] as int,
    reason: j['reason'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

class TradeData {
  TradeData({
    List<Product> products = const [],
    this.catalogEnabled = false,
    List<String> categories = const [
      'Sans catégorie',
      'Agroalimentaire',
      'Textile',
      'Équipement',
    ],
    List<String> units = const [
      'pièce',
      'sac',
      'bidon',
      'carton',
      'kg',
      'litre',
    ],
    List<Contact> contacts = const [],
    List<TradeOrder> orders = const [],
    List<StockMovement> movements = const [],
  }) : categories = List.unmodifiable(categories),
       units = List.unmodifiable(units),
       products = List.unmodifiable(products),
       contacts = List.unmodifiable(contacts),
       orders = List.unmodifiable(orders),
       movements = List.unmodifiable(movements);
  final bool catalogEnabled;
  final List<String> categories, units;
  final List<Product> products;
  final List<Contact> contacts;
  final List<TradeOrder> orders;
  final List<StockMovement> movements;
  TradeData copyWith({
    bool? catalogEnabled,
    List<String>? categories,
    List<String>? units,
    List<Product>? products,
    List<Contact>? contacts,
    List<TradeOrder>? orders,
    List<StockMovement>? movements,
  }) => TradeData(
    catalogEnabled: catalogEnabled ?? this.catalogEnabled,
    categories: categories ?? this.categories,
    units: units ?? this.units,
    products: products ?? this.products,
    contacts: contacts ?? this.contacts,
    orders: orders ?? this.orders,
    movements: movements ?? this.movements,
  );
  Map<String, dynamic> toJson() => {
    'version': 2,
    'catalogEnabled': catalogEnabled,
    'categories': categories,
    'units': units,
    'products': products.map((e) => e.toJson()).toList(),
    'contacts': contacts.map((e) => e.toJson()).toList(),
    'orders': orders.map((e) => e.toJson()).toList(),
    'movements': movements.map((e) => e.toJson()).toList(),
  };
  factory TradeData.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1 && j['version'] != 2) {
      throw const FormatException('Version de sauvegarde non prise en charge.');
    }
    return TradeData(
      catalogEnabled: j['catalogEnabled'] as bool? ?? false,
      categories:
          (j['categories'] as List?)?.cast<String>() ??
          const ['Sans catégorie', 'Agroalimentaire', 'Textile', 'Équipement'],
      units:
          (j['units'] as List?)?.cast<String>() ??
          const ['pièce', 'sac', 'bidon', 'carton', 'kg', 'litre'],
      products: (j['products'] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      contacts: (j['contacts'] as List)
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList(),
      orders: (j['orders'] as List)
          .map((e) => TradeOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      movements: (j['movements'] as List)
          .map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
