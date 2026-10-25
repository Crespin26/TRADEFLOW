import 'shopping_models.dart';

enum CustomerOrderStatus {
  confirmed('Confirmée'),
  preparing('En préparation'),
  shipped('Expédiée'),
  delivered('Livrée'),
  cancelled('Annulée');

  const CustomerOrderStatus(this.label);
  final String label;
}

enum CustomerRequestKind {
  cancellation('Annulation'),
  returnGoods('Retour'),
  assistance('Assistance');

  const CustomerRequestKind(this.label);
  final String label;
}

enum CustomerRequestStatus {
  received('Reçue'),
  reviewing('En cours d’examen'),
  accepted('Acceptée'),
  rejected('Refusée');

  const CustomerRequestStatus(this.label);
  final String label;
}

enum CustomerDocumentKind {
  confirmation('Confirmation de commande'),
  quote('Devis — spécimen'),
  delivery('Bon de livraison — spécimen'),
  invoice('Facture — spécimen');

  const CustomerDocumentKind(this.label);
  final String label;
}

class CustomerOrder {
  const CustomerOrder({
    required this.receipt,
    required this.status,
    this.carrier = '',
    this.tracking = '',
    this.expectedDelivery,
    this.fromExample = false,
  });
  final DemoReceipt receipt;
  final CustomerOrderStatus status;
  final String carrier, tracking;
  final DateTime? expectedDelivery;
  final bool fromExample;
  String get id => receipt.id;
  bool get canRequestCancellation =>
      status == CustomerOrderStatus.confirmed ||
      status == CustomerOrderStatus.preparing;
  bool get canRequestReturn => status == CustomerOrderStatus.delivered;
  List<CustomerDocumentKind> get documentKinds => [
    CustomerDocumentKind.confirmation,
    if (fromExample) CustomerDocumentKind.quote,
    if (status == CustomerOrderStatus.shipped ||
        status == CustomerOrderStatus.delivered)
      CustomerDocumentKind.delivery,
    if (status == CustomerOrderStatus.delivered) CustomerDocumentKind.invoice,
  ];
}

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.address,
  });
  final String id, label;
  final DeliveryAddress address;
}

class CustomerRequest {
  const CustomerRequest({
    required this.id,
    required this.orderId,
    required this.kind,
    required this.message,
    required this.createdAt,
    this.status = CustomerRequestStatus.received,
    this.response = '',
    this.attachmentName = '',
  });
  final String id, orderId, message, response, attachmentName;
  final CustomerRequestKind kind;
  final CustomerRequestStatus status;
  final DateTime createdAt;
}

class CustomerNotice {
  const CustomerNotice({
    required this.id,
    required this.orderId,
    required this.title,
    required this.description,
    required this.date,
  });
  final String id, orderId, title, description;
  final DateTime date;
}
