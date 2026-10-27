import 'fulfilment_models.dart';
export 'fulfilment_models.dart';
import 'commercial_models.dart';
export 'commercial_models.dart';
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

extension ContactKindLabel on ContactKind {
  String get label => this == ContactKind.client ? 'Client' : 'Fournisseur';
}

/// Internal business partner; this record does not create an authenticated account.
class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.kind,
    required this.country,
    required this.email,
    required this.phone,
    this.contactPerson = '',
    this.address = '',
    this.city = '',
    this.postalCode = '',
    this.taxId = '',
    this.website = '',
    this.notes = '',
    this.archived = false,
    this.revision = 0,
  });
  final String id,
      name,
      country,
      email,
      phone,
      contactPerson,
      address,
      city,
      postalCode,
      taxId,
      website,
      notes;
  final ContactKind kind;
  final bool archived;
  // Monotonic revision also detects an archive/restore cycle while an editor is open.
  final int revision;
  Contact copyWith({
    String? name,
    ContactKind? kind,
    String? country,
    String? email,
    String? phone,
    String? contactPerson,
    String? address,
    String? city,
    String? postalCode,
    String? taxId,
    String? website,
    String? notes,
    bool? archived,
    int? revision,
  }) => Contact(
    id: id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    country: country ?? this.country,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    contactPerson: contactPerson ?? this.contactPerson,
    address: address ?? this.address,
    city: city ?? this.city,
    postalCode: postalCode ?? this.postalCode,
    taxId: taxId ?? this.taxId,
    website: website ?? this.website,
    notes: notes ?? this.notes,
    archived: archived ?? this.archived,
    revision: revision ?? this.revision,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'country': country,
    'email': email,
    'phone': phone,
    'contactPerson': contactPerson,
    'address': address,
    'city': city,
    'postalCode': postalCode,
    'taxId': taxId,
    'website': website,
    'notes': notes,
    'archived': archived,
    'revision': revision,
  };
  // Optional defaults preserve partners loaded from versions 1 and 2 of the local snapshot.
  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
    id: j['id'] as String,
    name: j['name'] as String,
    kind: ContactKind.values.byName(j['kind'] as String),
    country: j['country'] as String,
    email: j['email'] as String,
    phone: j['phone'] as String,
    contactPerson: j['contactPerson'] as String? ?? '',
    address: j['address'] as String? ?? '',
    city: j['city'] as String? ?? '',
    postalCode: j['postalCode'] as String? ?? '',
    taxId: j['taxId'] as String? ?? '',
    website: j['website'] as String? ?? '',
    notes: j['notes'] as String? ?? '',
    archived: j['archived'] as bool? ?? false,
    revision: j['revision'] as int? ?? 0,
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
    List<StockInventory> inventories = const [],
    List<TradeQuote> quotes = const [],
    List<PurchaseOrder> purchases = const [],
    List<CommercialEvent> commercialEvents = const [],
    List<DeliveryPlan> deliveryPlans = const [],
  }) : categories = List.unmodifiable(categories),
       units = List.unmodifiable(units),
       products = List.unmodifiable(products),
       contacts = List.unmodifiable(contacts),
       orders = List.unmodifiable(orders),
       movements = List.unmodifiable(movements),
       inventories = List.unmodifiable(inventories),
       quotes = List.unmodifiable(quotes),
       purchases = List.unmodifiable(purchases),
       commercialEvents = List.unmodifiable(commercialEvents),
       deliveryPlans = List.unmodifiable(deliveryPlans);
  final bool catalogEnabled;
  final List<String> categories, units;
  final List<Product> products;
  final List<Contact> contacts;
  final List<TradeOrder> orders;
  final List<StockMovement> movements;
  final List<StockInventory> inventories;
  final List<TradeQuote> quotes;
  final List<PurchaseOrder> purchases;
  final List<CommercialEvent> commercialEvents;
  final List<DeliveryPlan> deliveryPlans;
  TradeData copyWith({
    bool? catalogEnabled,
    List<String>? categories,
    List<String>? units,
    List<Product>? products,
    List<Contact>? contacts,
    List<TradeOrder>? orders,
    List<StockMovement>? movements,
    List<StockInventory>? inventories,
    List<TradeQuote>? quotes,
    List<PurchaseOrder>? purchases,
    List<CommercialEvent>? commercialEvents,
    List<DeliveryPlan>? deliveryPlans,
  }) => TradeData(
    catalogEnabled: catalogEnabled ?? this.catalogEnabled,
    categories: categories ?? this.categories,
    units: units ?? this.units,
    products: products ?? this.products,
    contacts: contacts ?? this.contacts,
    orders: orders ?? this.orders,
    movements: movements ?? this.movements,
    inventories: inventories ?? this.inventories,
    quotes: quotes ?? this.quotes,
    purchases: purchases ?? this.purchases,
    commercialEvents: commercialEvents ?? this.commercialEvents,
    deliveryPlans: deliveryPlans ?? this.deliveryPlans,
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
    'inventories': inventories.map((e) => e.toJson()).toList(),
    'quotes': quotes.map((e) => e.toJson()).toList(),
    'purchases': purchases.map((e) => e.toJson()).toList(),
    'commercialEvents': commercialEvents.map((e) => e.toJson()).toList(),
    'deliveryPlans': deliveryPlans.map((e) => e.toJson()).toList(),
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
      deliveryPlans: (j['deliveryPlans'] as List? ?? [])
          .map((e) => DeliveryPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      quotes: (j['quotes'] as List? ?? [])
          .map((e) => TradeQuote.fromJson(e as Map<String, dynamic>))
          .toList(),
      purchases: (j['purchases'] as List? ?? [])
          .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      commercialEvents: (j['commercialEvents'] as List? ?? [])
          .map((e) => CommercialEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      inventories: (j['inventories'] as List? ?? [])
          .map((e) => StockInventory.fromJson(e as Map<String, dynamic>))
          .toList(),
      movements: (j['movements'] as List)
          .map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
