import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradeflow_mobile/data/trade_repository.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';

import 'support/fakes.dart' show MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryRepository repo;
  late TradeStore store;
  setUp(() async {
    repo = MemoryRepository();
    store = TradeStore(repo);
    await store.load();
    await store.addContact(
      name: ' Comptoir Étoile ',
      kind: ContactKind.client,
      country: ' Bénin ',
      email: ' INFO@EXAMPLE.COM ',
      phone: '+229 12345678',
      contactPerson: 'Mme A',
      address: 'Rue du marché',
      city: 'Cotonou',
      taxId: 'IFU-001',
      website: 'https://example.com',
      notes: 'Livrer le matin',
    );
  });
  Future<void> createOrder() async {
    await store.addProduct(
      name: 'Riz',
      sku: 'RIZ',
      quantity: 10,
      threshold: 2,
      price: 500,
    );
    await store.createOrder(
      productId: store.data.products.single.id,
      customerId: store.data.contacts.first.id,
      quantity: 2,
      destination: 'Cotonou',
    );
  }

  test('new records normalize coordinates and old records load with compatible defaults', () {
    final c = store.data.contacts.single;
    expect(c.name, 'Comptoir Étoile');
    expect(c.country, 'Bénin');
    expect(c.email, 'info@example.com');
    expect(c.revision, 0);
    expect(c.archived, isFalse);
    final old = Contact.fromJson({
      'id': 'OLD',
      'name': 'Ancien',
      'kind': 'supplier',
      'country': 'Togo',
      'email': '',
      'phone': '',
    });
    expect(old.archived, isFalse);
    expect(old.notes, isEmpty);
    expect(old.revision, 0);
    expect(
      Contact.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
      ).toJson(),
      c.toJson(),
    );
  });
  test('normalized same-name partners include archived records in duplicate checks', () async {
    final c = store.data.contacts.single;
    await store.setContactArchived(c.id, true, expectedRevision: c.revision);
    await expectLater(
      store.addContact(
        name: 'comptoir etoile',
        kind: ContactKind.client,
        country: 'benin',
        email: '',
        phone: '',
      ),
      throwsArgumentError,
    );
    await store.addContact(
      name: 'Comptoir Étoile',
      kind: ContactKind.supplier,
      country: 'Bénin',
      email: '',
      phone: '',
    );
    await store.addContact(
      name: 'Comptoir Étoile',
      kind: ContactKind.client,
      country: 'Togo',
      email: '',
      phone: '',
    );
    expect(store.data.contacts.length, 3);
  });
  test('invalid coordinates, excessive notes and duplicate edits do not mutate data', () async {
    final c = store.data.contacts.single;
    final before = store.data;
    for (final invalid in [
      c.copyWith(name: ' '),
      c.copyWith(country: ''),
      c.copyWith(email: 'invalid'),
      c.copyWith(website: 'javascript:alert(1)'),
      c.copyWith(website: 'example.com'),
      c.copyWith(notes: 'a' * 3001),
      c.copyWith(phone: '1' * 41),
    ]) {
      await expectLater(store.updateContact(invalid), throwsArgumentError);
    }
    expect(store.data, same(before));
    await store.addContact(
      name: 'Autre',
      kind: ContactKind.client,
      country: 'Bénin',
      email: '',
      phone: '',
    );
    await expectLater(
      store.updateContact(store.data.contacts.last.copyWith(name: c.name)),
      throwsArgumentError,
    );
  });
  test(
    'renaming preserves order snapshots and linked client type cannot change',
    () async {
      await createOrder();
      final c = store.data.contacts.first;
      await store.updateContact(
        c.copyWith(name: 'Comptoir Nouveau', address: 'Nouvelle adresse'),
      );
      expect(store.data.orders.single.customerName, 'Comptoir Étoile');
      expect(store.data.orders.single.customerId, c.id);
      expect(store.data.contacts.first.revision, 1);
      await expectLater(
        store.updateContact(
          store.data.contacts.first.copyWith(kind: ContactKind.supplier),
        ),
        throwsArgumentError,
      );
    },
  );
  test('archive excludes new orders while existing orders remain operable; restore keeps identity', () async {
    await createOrder();
    final c = store.data.contacts.first;
    await store.setContactArchived(c.id, true, expectedRevision: c.revision);
    final before = store.data;
    await expectLater(
      store.createOrder(
        productId: before.products.single.id,
        customerId: c.id,
        quantity: 1,
        destination: 'Cotonou',
      ),
      throwsArgumentError,
    );
    expect(store.data, same(before));
    await store.changeOrderStatus(
      before.orders.single.id,
      OrderStatus.cancelled,
    );
    expect(store.data.products.single.quantity, 10);
    await store.setContactArchived(
      c.id,
      false,
      expectedRevision: store.data.contacts.first.revision,
    );
    expect(store.data.contacts.first.id, c.id);
    expect(store.data.contacts.first.archived, isFalse);
  });
  test('revision prevents stale edits and archive/restore cycles from erasing newer changes', () async {
    final c = store.data.contacts.single;
    await store.updateContact(c.copyWith(city: 'Porto-Novo'));
    await expectLater(
      store.updateContact(c.copyWith(city: 'Lomé')),
      throwsStateError,
    );
    await expectLater(
      store.setContactArchived(c.id, true, expectedRevision: c.revision),
      throwsStateError,
    );
    final latest = store.data.contacts.single;
    await store.setContactArchived(
      c.id,
      true,
      expectedRevision: latest.revision,
    );
    await expectLater(store.updateContact(latest), throwsStateError);
    await store.setContactArchived(
      c.id,
      false,
      expectedRevision: store.data.contacts.single.revision,
    );
    await expectLater(
      store.updateContact(latest.copyWith(city: 'Lomé')),
      throwsStateError,
    );
    expect(store.data.contacts.single.city, 'Porto-Novo');
  });
  test('supplier type may change before any order and supplier is rejected as a sales customer', () async {
    final c = store.data.contacts.single;
    await store.updateContact(c.copyWith(kind: ContactKind.supplier));
    await store.addProduct(
      name: 'Riz',
      sku: 'RIZ',
      quantity: 10,
      threshold: 2,
      price: 500,
    );
    await expectLater(
      store.createOrder(
        productId: store.data.products.single.id,
        customerId: c.id,
        quantity: 1,
        destination: 'Cotonou',
      ),
      throwsArgumentError,
    );
    await store.updateContact(
      store.data.contacts.single.copyWith(kind: ContactKind.client),
    );
    expect(store.data.contacts.single.kind, ContactKind.client);
  });
  test(
    'failed edit or archive keeps both business and persisted state unchanged',
    () async {
      final c = store.data.contacts.single;
      final before = store.data;
      repo.failSave = true;
      await expectLater(
        store.updateContact(c.copyWith(name: 'Nouveau')),
        throwsStateError,
      );
      await expectLater(
        store.setContactArchived(c.id, true, expectedRevision: c.revision),
        throwsStateError,
      );
      expect(store.data, same(before));
      expect(repo.snapshot, same(before));
      expect(store.busy, isFalse);
    },
  );
  test(
    'extended and archived partner fields survive local repository restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final local = TradeStore(LocalTradeRepository(prefs));
      await local.load();
      final c = store.data.contacts.single;
      await local.addContact(
        name: c.name,
        kind: c.kind,
        country: c.country,
        email: c.email,
        phone: c.phone,
        contactPerson: c.contactPerson,
        address: c.address,
        city: c.city,
        postalCode: '00229',
        taxId: c.taxId,
        website: c.website,
        notes: c.notes,
      );
      final saved = local.data.contacts.single;
      await local.setContactArchived(saved.id, true, expectedRevision: 0);
      final restored = TradeStore(LocalTradeRepository(prefs));
      await restored.load();
      expect(
        restored.data.contacts.single.toJson(),
        local.data.contacts.single.toJson(),
      );
      expect(restored.data.contacts.single.archived, isTrue);
      expect(restored.data.contacts.single.revision, 1);
    },
  );
}
