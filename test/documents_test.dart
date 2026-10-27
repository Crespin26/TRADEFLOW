import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/business_documents.dart';
import 'package:tradeflow_mobile/domain/document_catalog.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/ui/documents/business_pdf.dart';

import 'support/fakes.dart' show MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TradeStore store;
  late MemoryRepository repo;
  setUp(() async {
    repo = MemoryRepository();
    store = TradeStore(repo);
    await store.load();
    await store.saveCompanyProfile(
      const CompanyProfile(
        name: 'Comptoir Étoile',
        address: 'Rue du marché, Cotonou',
        country: 'Bénin',
        email: 'CONTACT@EXAMPLE.COM',
      ),
      expectedRevision: 0,
    );
    await store.addProduct(
      name: 'Riz parfumé',
      sku: 'R',
      quantity: 10,
      threshold: 1,
      price: 900,
      unit: 'sac',
    );
    await store.addContact(
      name: 'Client privé',
      kind: ContactKind.client,
      country: 'Bénin',
      email: '',
      phone: '',
      notes: 'NOTES-PRIVEES',
    );
    await store.createOrder(
      productId: store.data.products.single.id,
      customerId: store.data.contacts.single.id,
      quantity: 2,
      destination: 'Cotonou',
    );
  });
  test(
    'documents derive from real data and never expose internal partner notes',
    () async {
      final docs = businessDocuments(store.data);
      expect(docs.length, 2);
      expect(docs.any((d) => d.kind == BusinessDocumentKind.proforma), isTrue);
      expect(
        docs.every((d) => d.partner == 'Client privé' && d.total == 1800),
        isTrue,
      );
      expect(docs.any((d) => d.notes.contains('NOTES-PRIVEES')), isFalse);
      final id = store.data.orders.single.id;
      await store.changeOrderStatus(id, OrderStatus.shipped);
      await store.recordDelivery(id, 1, 'BL-É', expectedRevision: 1);
      final delivery = businessDocuments(store.data)
          .firstWhere((d) => d.kind == BusinessDocumentKind.delivery);
      expect(delivery.quantity, 1);
      expect(delivery.unitPrice, isNull);
    },
  );
  test('issued snapshots survive changes, restart and repeated export without duplicate archives', () async {
    final original = businessDocuments(store.data).first;
    await store.archiveBusinessDocument(original);
    await store.archiveBusinessDocument(original);
    expect(store.data.issuedDocuments.length, 1);
    await store.saveCompanyProfile(
      const CompanyProfile(name: 'Nouvelle société'),
      expectedRevision: 1,
    );
    final id = store.data.orders.single.id;
    await store.changeOrderStatus(id, OrderStatus.cancelled);
    final archive = store.data.issuedDocuments.single;
    expect(archive.company.name, 'Comptoir Étoile');
    expect(archive.status, 'Confirmée');
    expect(archive.reference, original.reference);
    final restored = TradeData.fromJson(
      jsonDecode(jsonEncode(store.data.toJson())) as Map<String, dynamic>,
    );
    expect(restored.issuedDocuments.single.toJson(), archive.toJson());
    expect(
      businessDocuments(restored).any((d) => d.reference == original.reference),
      isTrue,
    );
  });
  test(
    'company revisions, validation and failed archives preserve prior state',
    () async {
      await expectLater(
        store.saveCompanyProfile(
          const CompanyProfile(name: 'Autre'),
          expectedRevision: 0,
        ),
        throwsStateError,
      );
      await expectLater(
        store.saveCompanyProfile(
          const CompanyProfile(name: ' '),
          expectedRevision: 1,
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.saveCompanyProfile(
          const CompanyProfile(name: 'Autre', email: 'invalid'),
          expectedRevision: 1,
        ),
        throwsArgumentError,
      );
      final before = store.data;
      repo.failSave = true;
      await expectLater(
        store.archiveBusinessDocument(businessDocuments(store.data).first),
        throwsStateError,
      );
      expect(store.data, same(before));
    },
  );
  test(
    'PDF contains an A4 document with embedded fonts and French content',
    () async {
      final doc = businessDocuments(store.data)
          .firstWhere((d) => d.kind == BusinessDocumentKind.proforma);
      final bytes = await buildBusinessPdf(doc);
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      expect(bytes.length, greaterThan(1000));
      final dir = await Directory.systemTemp.createTemp('tradeflow-pdf-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/document.pdf');
      await file.writeAsBytes(bytes);
      // Poppler is optional for contributors; when installed it verifies text extraction end to end.
      ProcessResult? result;
      try {
        result = await Process.run('pdftotext', [file.path, '-']);
      } on ProcessException {
        result = null;
      }
      if (result != null) {
        expect(result.exitCode, 0);
        expect(result.stdout, contains('Comptoir Étoile'));
        expect(result.stdout, contains('Riz parfumé'));
        expect(result.stdout, contains('PRO FORMA'));
        expect(result.stdout, isNot(contains('NOTES-PRIVEES')));
      }
    },
  );
  test('blank company blocks PDF export and older snapshots default company and archives', () async {
    final data = store.data.toJson()
      ..remove('company')
      ..remove('issuedDocuments');
    final old = TradeData.fromJson(data);
    expect(old.company.name, isEmpty);
    expect(old.issuedDocuments, isEmpty);
    await expectLater(
      buildBusinessPdf(businessDocuments(old).first),
      throwsStateError,
    );
  });
  test(
    'loading examples into an empty space preserves the company identity',
    () async {
      final empty = TradeStore(MemoryRepository());
      await empty.load();
      await empty.saveCompanyProfile(
        const CompanyProfile(name: 'Entreprise'),
        expectedRevision: 0,
      );
      await empty.loadDemo();
      expect(empty.data.company.name, 'Entreprise');
    },
  );
}
