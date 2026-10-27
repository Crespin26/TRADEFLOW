export 'company_profile.dart';
import 'company_profile.dart';

enum BusinessDocumentKind {
  quote,
  sale,
  proforma,
  purchase,
  delivery,
  receipt,
  customerReturn,
  supplierReturn,
}

extension BusinessDocumentKindLabel on BusinessDocumentKind {
  String get label => switch (this) {
    BusinessDocumentKind.quote => 'Devis',
    BusinessDocumentKind.sale => 'Confirmation de commande',
    BusinessDocumentKind.proforma => 'Facture pro forma',
    BusinessDocumentKind.purchase => 'Bon de commande fournisseur',
    BusinessDocumentKind.delivery => 'Bon de livraison',
    BusinessDocumentKind.receipt => 'Bon de réception',
    BusinessDocumentKind.customerReturn => 'Bon de retour client',
    BusinessDocumentKind.supplierReturn => 'Bon de retour fournisseur',
  };
}

/// Captured projection: editing business data after opening a preview cannot mutate this document.
class BusinessDocument {
  BusinessDocument({
    required this.kind,
    required this.sourceId,
    required this.revision,
    required this.date,
    required this.partner,
    required this.product,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.company,
    this.issuedAt,
    this.unitPrice,
    this.destination = '',
    this.notes = '',
    List<String> details = const [],
  }) : details = List.unmodifiable(details);
  final BusinessDocumentKind kind;
  final String sourceId, partner, product, unit, status, destination, notes;
  final int quantity, revision;
  final int? unitPrice;
  final DateTime date;
  final DateTime? issuedAt;
  final CompanyProfile company;
  final List<String> details;
  int? get total => unitPrice == null ? null : quantity * unitPrice!;
  String get reference =>
      '${kind.name}-$sourceId-r$revision-e${company.revision}';
  String get filename =>
      '${reference.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_')}.pdf';
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'sourceId': sourceId,
    'revision': revision,
    'date': date.toIso8601String(),
    'partner': partner,
    'product': product,
    'quantity': quantity,
    'unit': unit,
    'status': status,
    'company': company.toJson(),
    'unitPrice': unitPrice,
    'destination': destination,
    'notes': notes,
    'details': details,
    'issuedAt': issuedAt?.toIso8601String(),
  };
  factory BusinessDocument.fromJson(Map<String, dynamic> j) => BusinessDocument(
    kind: BusinessDocumentKind.values.byName(j['kind'] as String),
    sourceId: j['sourceId'] as String,
    revision: j['revision'] as int,
    date: DateTime.parse(j['date'] as String),
    partner: j['partner'] as String,
    product: j['product'] as String,
    quantity: j['quantity'] as int,
    unit: j['unit'] as String,
    status: j['status'] as String,
    company: CompanyProfile.fromJson(j['company'] as Map<String, dynamic>),
    unitPrice: j['unitPrice'] as int?,
    destination: j['destination'] as String,
    notes: j['notes'] as String,
    details: (j['details'] as List).cast<String>(),
    issuedAt: j['issuedAt'] == null
        ? null
        : DateTime.parse(j['issuedAt'] as String),
  );
}
