part of 'trade_store.dart';

extension PartnerOperations on TradeStore {
  Contact _cleanContact(Contact c) => c.copyWith(
    name: c.name.trim(),
    country: c.country.trim(),
    email: c.email.trim().toLowerCase(),
    phone: c.phone.trim(),
    contactPerson: c.contactPerson.trim(),
    address: c.address.trim(),
    city: c.city.trim(),
    postalCode: c.postalCode.trim(),
    taxId: c.taxId.trim(),
    website: c.website.trim(),
    notes: c.notes.trim(),
  );

  void _validateContact(Contact c) {
    _checkText(c.name, 'Le nom');
    _checkText(c.country, 'Le pays');
    if ([
          c.name,
          c.country,
          c.email,
          c.contactPerson,
          c.address,
          c.city,
          c.postalCode,
          c.taxId,
          c.website,
        ].any((v) => v.length > 160) ||
        c.phone.length > 40 ||
        c.notes.length > 3000) {
      throw ArgumentError(
        'Respectez les limites des champs : 160 caractères, téléphone 40 et notes 3 000.',
      );
    }
    if (c.email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(c.email)) {
      throw ArgumentError('Adresse e-mail invalide.');
    }
    final website = Uri.tryParse(c.website);
    if (c.website.isNotEmpty &&
        (website == null ||
            !['http', 'https'].contains(website.scheme) ||
            website.host.isEmpty ||
            c.website.contains(RegExp(r'\s')))) {
      throw ArgumentError(
        'Le site doit être une adresse complète commençant par https:// ou http://.',
      );
    }
    // Keep archived partners in duplicate checks to encourage restoring their history.
    if (_data.contacts.any(
      (other) =>
          other.id != c.id &&
          other.kind == c.kind &&
          normalizeCatalogText(other.name) == normalizeCatalogText(c.name) &&
          normalizeCatalogText(other.country) ==
              normalizeCatalogText(c.country),
    )) {
      throw ArgumentError(
        'Un partenaire de ce type porte déjà ce nom dans ce pays. Vérifiez aussi les archives.',
      );
    }
  }

  Future<void> addContact({
    required String name,
    required ContactKind kind,
    required String country,
    required String email,
    required String phone,
    String contactPerson = '',
    String address = '',
    String city = '',
    String postalCode = '',
    String taxId = '',
    String website = '',
    String notes = '',
  }) async {
    final c = _cleanContact(
      Contact(
        id: _id('CT'),
        name: name,
        kind: kind,
        country: country,
        email: email,
        phone: phone,
        contactPerson: contactPerson,
        address: address,
        city: city,
        postalCode: postalCode,
        taxId: taxId,
        website: website,
        notes: notes,
      ),
    );
    _validateContact(c);
    await _commit(_data.copyWith(contacts: [..._data.contacts, c]));
  }

  Future<void> updateContact(Contact contact) async {
    final original = _data.contacts.firstWhere((c) => c.id == contact.id);
    if (original.archived) {
      throw StateError('Restaurez ce partenaire avant de le modifier.');
    }
    if (original.revision != contact.revision ||
        original.archived != contact.archived) {
      throw StateError(
        'Cette fiche a changé. Fermez le formulaire puis ouvrez la version actuelle.',
      );
    }
    // Orders retain their original customer name; only their stable ID links this record.
    if (contact.kind != original.kind &&
        (_data.orders.any((o) => o.customerId == original.id) ||
            _data.quotes.any((q) => q.customerId == original.id) ||
            _data.purchases.any((p) => p.supplierId == original.id))) {
      throw ArgumentError(
        'Le type d’un partenaire lié à des documents commerciaux ne peut pas être modifié.',
      );
    }
    final next = _cleanContact(contact)
        .copyWith(revision: original.revision + 1);
    _validateContact(next);
    await _commit(
      _data.copyWith(
        contacts: [
          for (final c in _data.contacts)
            if (c.id == next.id) next else c,
        ],
      ),
    );
  }

  Future<void> setContactArchived(
    String id,
    bool archived, {
    required int expectedRevision,
  }) async {
    final c = _data.contacts.firstWhere((c) => c.id == id);
    if (c.revision != expectedRevision || c.archived == archived) {
      throw StateError(
        'Cette fiche a changé. Actualisez-la avant de recommencer.',
      );
    }
    await _commit(
      _data.copyWith(
        contacts: [
          for (final item in _data.contacts)
            if (item.id == id)
              c.copyWith(archived: archived, revision: c.revision + 1)
            else
              item,
        ],
      ),
    );
  }
}
