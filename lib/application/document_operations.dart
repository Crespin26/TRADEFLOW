part of 'trade_store.dart';

extension DocumentOperations on TradeStore {
  Future<void> saveCompanyProfile(
    CompanyProfile profile, {
    required int expectedRevision,
  }) async {
    _revision(_data.company.revision, expectedRevision);
    _checkText(profile.name, 'Le nom de l’entreprise');
    if ([
          profile.name,
          profile.country,
          profile.email,
          profile.registration,
        ].any((v) => v.trim().length > 160) ||
        profile.address.trim().length > 500 ||
        profile.phone.trim().length > 40) {
      throw ArgumentError(
        'Coordonnées trop longues : nom, pays, e-mail et registre 160 ; adresse 500 ; téléphone 40.',
      );
    }
    if (profile.email.trim().isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(profile.email.trim())) {
      throw ArgumentError('Adresse e-mail invalide.');
    }
    await _commit(
      _data.copyWith(
        company: CompanyProfile(
          name: profile.name.trim(),
          address: profile.address.trim(),
          country: profile.country.trim(),
          email: profile.email.trim().toLowerCase(),
          phone: profile.phone.trim(),
          registration: profile.registration.trim(),
          revision: _data.company.revision + 1,
        ),
      ),
    );
  }

  Future<void> archiveBusinessDocument(BusinessDocument doc) async {
    if (doc.company.name.isEmpty) {
      throw ArgumentError('Renseignez l’entreprise avant d’exporter.');
    }
    if (_data.issuedDocuments.any((d) => d.reference == doc.reference)) return;
    final json = doc.toJson()..['issuedAt'] = DateTime.now().toIso8601String();
    await _commit(
      _data.copyWith(
        issuedDocuments: [
          BusinessDocument.fromJson(json),
          ..._data.issuedDocuments,
        ],
      ),
    );
  }
}
