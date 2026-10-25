import 'public_catalog.dart';

class CartLine {
  const CartLine(this.product, this.quantity);
  final PublicProduct product;
  final int quantity;
  int get total => product.price * quantity;
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.country,
  });
  final String name, phone, street, city, country;
  bool get complete =>
      [name, phone, street, city, country].every((v) => v.trim().isNotEmpty);
  String get label => '$name\n$phone\n$street\n$city, $country';
}

class DemoReceipt {
  DemoReceipt({
    required this.id,
    required List<CartLine> lines,
    required this.email,
    required this.address,
    required this.createdAt,
  }) : lines = List.unmodifiable(lines);
  final String id, email;
  final List<CartLine> lines;
  final DeliveryAddress address;
  final DateTime createdAt;
  int get total => lines.fold(0, (sum, line) => sum + line.total);
}
