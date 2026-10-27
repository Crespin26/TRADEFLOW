import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/application/shopping_session.dart';

import 'support/fakes.dart' show exampleAddress, MemoryCartRepository;

ShoppingSession signedIn() =>
    ShoppingSession()..signInDemo('client@example.com');
void main() {
  test('phase 3 confirmation becomes a confirmed customer order', () async {
    final session = signedIn();
    await session.add('rice', quantity: 2);
    final receipt = await session.confirmDemo(exampleAddress);
    final order = session.customerOrder(receipt.id)!;
    expect(order.status, CustomerOrderStatus.confirmed);
    expect(order.receipt.total, 37000);
    expect(order.documentKinds, [CustomerDocumentKind.confirmation]);
    expect(session.unreadNoticeCount, 1);
  });
  test('customer data and actions require a verified simulated session', () {
    final session = ShoppingSession()
      ..signInDemo('client@example.com', registration: true);
    expect(session.customerOrders, isEmpty);
    expect(session.addresses, isEmpty);
    expect(session.loadCustomerExamples, throwsStateError);
    expect(
      () => session.saveAddress(label: 'Boutique', address: exampleAddress),
      throwsStateError,
    );
    expect(
      () => session.updateCustomerProfile('Client', '000'),
      throwsStateError,
    );
  });
  test('switching identity and logout clear private workspace while retaining cart', () async {
    final session = signedIn();
    session.loadCustomerExamples();
    session.saveAddress(label: 'Boutique', address: exampleAddress);
    await session.add('oil');
    session.signInDemo('other@example.com');
    expect(session.customerOrders, isEmpty);
    expect(session.requests, isEmpty);
    expect(session.addresses, isEmpty);
    expect(session.notices, isEmpty);
    expect(session.itemCount, 1);
    session.loadCustomerExamples();
    session.signOut();
    expect(session.customerOrders, isEmpty);
    expect(session.itemCount, 1);
  });
  test('same normalized identity preserves profile and current workspace', () {
    final session = signedIn();
    session.loadCustomerExamples();
    session.updateCustomerProfile('Client Démo', '000');
    session.signInDemo(' CLIENT@EXAMPLE.COM ');
    expect(session.email, 'client@example.com');
    expect(session.displayName, 'Client Démo');
    expect(session.phone, '000');
    expect(session.customerOrders.length, 3);
  });
  test('address defaults follow edits and removal without changing receipt snapshots', () async {
    final session = signedIn();
    final first = session.saveAddress(
      label: 'Boutique',
      address: exampleAddress,
    );
    final second = session.saveAddress(
      label: 'Bureau',
      address: const DeliveryAddress(
        name: 'Autre',
        phone: '111',
        street: 'Rue 2',
        city: 'Lomé',
        country: 'Togo',
      ),
    );
    expect(session.defaultDeliveryId, first.id);
    expect(session.defaultBillingId, first.id);
    await session.add('rice');
    final receipt = await session.confirmDemo(exampleAddress);
    session.saveAddress(
      id: first.id,
      label: 'Boutique modifiée',
      address: second.address,
    );
    expect(session.defaultDelivery!.city, 'Lomé');
    expect(receipt.address.city, 'Cotonou');
    session.setDefaultAddress(second.id, billing: true);
    session.removeAddress(first.id);
    expect(session.defaultDeliveryId, second.id);
    expect(session.defaultBillingId, second.id);
    session.removeAddress(second.id);
    expect(session.defaultDelivery, isNull);
    expect(session.defaultBillingId, isNull);
    expect(() => session.setDefaultAddress('unknown'), throwsArgumentError);
  });
  test('requests validate eligibility and do not change order status', () {
    final session = signedIn();
    session.loadCustomerExamples();
    final confirmed = session.customerOrders.firstWhere(
      (o) => o.status == CustomerOrderStatus.confirmed,
    );
    final shipped = session.customerOrders.firstWhere(
      (o) => o.status == CustomerOrderStatus.shipped,
    );
    final delivered = session.customerOrders.firstWhere(
      (o) => o.status == CustomerOrderStatus.delivered,
    );
    expect(
      () => session.submitRequest(
        shipped.id,
        CustomerRequestKind.cancellation,
        'Motif de démonstration',
      ),
      throwsArgumentError,
    );
    expect(
      () => session.submitRequest(
        confirmed.id,
        CustomerRequestKind.returnGoods,
        'Motif de démonstration',
      ),
      throwsArgumentError,
    );
    expect(
      () => session.submitRequest(
        delivered.id,
        CustomerRequestKind.returnGoods,
        'court',
      ),
      throwsArgumentError,
    );
    session.submitRequest(
      confirmed.id,
      CustomerRequestKind.cancellation,
      'Annulation de démonstration',
    );
    session.submitRequest(
      delivered.id,
      CustomerRequestKind.returnGoods,
      'Retour de démonstration',
    );
    expect(
      () => session.submitRequest(
        confirmed.id,
        CustomerRequestKind.cancellation,
        'Deuxième demande identique',
      ),
      throwsStateError,
    );
    expect(
      session.customerOrder(confirmed.id)!.status,
      CustomerOrderStatus.confirmed,
    );
    expect(
      () => session.submitRequest(
        'unknown',
        CustomerRequestKind.assistance,
        'Question de démonstration',
      ),
      throwsArgumentError,
    );
  });
  test(
    'examples cover deliveries and documents without altering cart',
    () async {
      final session = signedIn();
      await session.add('oil');
      session.loadCustomerExamples();
      expect(session.itemCount, 1);
      final shipped = session.customerOrders.firstWhere(
        (o) => o.status == CustomerOrderStatus.shipped,
      );
      final delivered = session.customerOrders.firstWhere(
        (o) => o.status == CustomerOrderStatus.delivered,
      );
      expect(shipped.tracking, isNotEmpty);
      expect(shipped.expectedDelivery, isNotNull);
      expect(shipped.documentKinds, contains(CustomerDocumentKind.delivery));
      expect(
        shipped.documentKinds,
        isNot(contains(CustomerDocumentKind.invoice)),
      );
      expect(delivered.documentKinds, contains(CustomerDocumentKind.invoice));
      expect(session.loadCustomerExamples, throwsStateError);
    },
  );
  test('notices can be marked read only within the active workspace', () {
    final session = signedIn();
    session.loadCustomerExamples();
    final count = session.unreadNoticeCount;
    session.markNoticeRead(session.notices.first.id);
    expect(session.unreadNoticeCount, count - 1);
    session.markAllNoticesRead();
    expect(session.unreadNoticeCount, 0);
    expect(() => session.markNoticeRead('unknown'), throwsArgumentError);
    session.signOut();
    expect(session.notices, isEmpty);
  });
  test('failed checkout does not add a customer order', () async {
    final repository = MemoryCartRepository();
    final session = ShoppingSession(repository: repository);
    await session.load();
    session.signInDemo('client@example.com');
    await session.add('rice');
    repository.fail = true;
    await expectLater(session.confirmDemo(exampleAddress), throwsStateError);
    expect(session.customerOrders, isEmpty);
    expect(session.itemCount, 1);
  });
}
