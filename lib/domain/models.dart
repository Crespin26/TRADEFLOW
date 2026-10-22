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

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.threshold,
    required this.price,
  });
  final String id, name, sku;
  final int quantity, threshold, price;
  bool get lowStock => quantity <= threshold;
  Product withQuantity(int value) => Product(
    id: id,
    name: name,
    sku: sku,
    quantity: value,
    threshold: threshold,
    price: price,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'quantity': quantity,
    'threshold': threshold,
    'price': price,
  };
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as String,
    name: j['name'] as String,
    sku: j['sku'] as String,
    quantity: j['quantity'] as int,
    threshold: j['threshold'] as int,
    price: j['price'] as int,
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
    List<Contact> contacts = const [],
    List<TradeOrder> orders = const [],
    List<StockMovement> movements = const [],
  }) : products = List.unmodifiable(products),
       contacts = List.unmodifiable(contacts),
       orders = List.unmodifiable(orders),
       movements = List.unmodifiable(movements);
  final List<Product> products;
  final List<Contact> contacts;
  final List<TradeOrder> orders;
  final List<StockMovement> movements;
  TradeData copyWith({
    List<Product>? products,
    List<Contact>? contacts,
    List<TradeOrder>? orders,
    List<StockMovement>? movements,
  }) => TradeData(
    products: products ?? this.products,
    contacts: contacts ?? this.contacts,
    orders: orders ?? this.orders,
    movements: movements ?? this.movements,
  );
  Map<String, dynamic> toJson() => {
    'version': 1,
    'products': products.map((e) => e.toJson()).toList(),
    'contacts': contacts.map((e) => e.toJson()).toList(),
    'orders': orders.map((e) => e.toJson()).toList(),
    'movements': movements.map((e) => e.toJson()).toList(),
  };
  factory TradeData.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Version de sauvegarde non prise en charge.');
    }
    return TradeData(
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
