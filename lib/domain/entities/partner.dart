enum ContactKind { client, supplier }

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
