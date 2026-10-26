import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'public_catalog.dart';
import 'shopping_models.dart';
import 'customer_models.dart';
export 'shopping_models.dart';
export 'customer_models.dart';

abstract interface class PublicCartRepository {
  Future<Map<String, int>> load();
  Future<void> save(Map<String, int> quantities);
}

/// UI simulation only. No authentication, stock reservation or real order occurs.
class ShoppingSession extends ChangeNotifier {
  ShoppingSession({this.repository}) : ready = repository == null;
  final PublicCartRepository? repository;
  List<PublicProduct> _products = demoPublicProducts;
  void updateCatalog(List<PublicProduct> products, {bool notify = true}) {
    _products = List.unmodifiable(products);
    if (notify) notifyListeners();
  }

  List<String> get unavailableProductIds => _quantities.keys
      .where(
        (id) => !_products.any(
          (p) => p.id == id && p.availability != PublicAvailability.unavailable,
        ),
      )
      .toList();
  Map<String, int> _quantities = {};
  Map<String, int> get quantities => UnmodifiableMapView(_quantities);
  bool ready, busy = false;
  String? storageError;
  String? email;
  String displayName = '';
  bool verified = false;
  bool get signedIn => email != null;
  final List<DemoReceipt> _receipts = [];
  List<DemoReceipt> get receipts =>
      customerReady ? List.unmodifiable(_receipts) : const [];
  List<CartLine> get lines => [
    for (final p in _products)
      if (_quantities.containsKey(p.id)) CartLine(p, _quantities[p.id]!),
  ];
  int get itemCount => _quantities.values.fold(0, (a, b) => a + b);
  int get total => lines.fold(0, (a, line) => a + line.total);

  final List<CustomerOrder> _orders = [];
  final List<CustomerAddress> _addresses = [];
  final List<CustomerRequest> _requests = [];
  final Set<String> _readNotices = {};
  String phone = '';
  String? _deliveryId, _billingId;
  int _serial = 0;
  bool get customerReady => signedIn && verified;
  List<CustomerOrder> get customerOrders =>
      customerReady ? List.unmodifiable(_orders) : const [];
  List<CustomerAddress> get addresses =>
      customerReady ? List.unmodifiable(_addresses) : const [];
  List<CustomerRequest> get requests =>
      customerReady ? List.unmodifiable(_requests) : const [];
  String? get defaultDeliveryId => customerReady ? _deliveryId : null;
  String? get defaultBillingId => customerReady ? _billingId : null;
  DeliveryAddress? get defaultDelivery =>
      addresses.where((a) => a.id == _deliveryId).firstOrNull?.address;
  CustomerOrder? customerOrder(String id) =>
      customerOrders.where((o) => o.id == id).firstOrNull;

  void _requireCustomer() {
    if (!customerReady) {
      throw StateError('Une session client simulée et vérifiée est requise.');
    }
    if (busy) throw StateError('Une opération est déjà en cours.');
  }

  void _clearCustomer() {
    _receipts.clear();
    _orders.clear();
    _addresses.clear();
    _requests.clear();
    _readNotices.clear();
    displayName = '';
    phone = '';
    _deliveryId = null;
    _billingId = null;
  }

  void updateCustomerProfile(String name, String number) {
    _requireCustomer();
    if (name.trim().isEmpty ||
        name.trim().length > 160 ||
        number.trim().length > 160) {
      throw ArgumentError('Vérifiez le nom et le téléphone.');
    }
    displayName = name.trim();
    phone = number.trim();
    notifyListeners();
  }

  CustomerAddress saveAddress({
    String? id,
    required String label,
    required DeliveryAddress address,
  }) {
    _requireCustomer();
    if (!address.complete || label.trim().isEmpty || label.trim().length > 80) {
      throw ArgumentError(
        'Complétez le libellé et tous les champs de l’adresse.',
      );
    }
    if (id != null && !_addresses.any((a) => a.id == id)) {
      throw ArgumentError('Adresse introuvable.');
    }
    final value = CustomerAddress(
      id: id ?? 'ADDR-${_serial++}',
      label: label.trim(),
      address: address,
    );
    if (id == null) {
      _addresses.add(value);
    } else {
      _addresses[_addresses.indexWhere((a) => a.id == id)] = value;
    }
    _deliveryId ??= value.id;
    _billingId ??= value.id;
    notifyListeners();
    return value;
  }

  void setDefaultAddress(String id, {bool billing = false}) {
    _requireCustomer();
    if (!_addresses.any((a) => a.id == id)) {
      throw ArgumentError('Adresse introuvable.');
    }
    if (billing) {
      _billingId = id;
    } else {
      _deliveryId = id;
    }
    notifyListeners();
  }

  void removeAddress(String id) {
    _requireCustomer();
    if (!_addresses.any((a) => a.id == id)) {
      throw ArgumentError('Adresse introuvable.');
    }
    _addresses.removeWhere((a) => a.id == id);
    if (_deliveryId == id) _deliveryId = _addresses.firstOrNull?.id;
    if (_billingId == id) _billingId = _addresses.firstOrNull?.id;
    notifyListeners();
  }

  CustomerRequest submitRequest(
    String orderId,
    CustomerRequestKind kind,
    String message, {
    String attachmentName = '',
  }) {
    _requireCustomer();
    final order = customerOrder(orderId);
    if (order == null) {
      throw ArgumentError('Commande introuvable dans cette session.');
    }
    if (kind == CustomerRequestKind.cancellation &&
        !order.canRequestCancellation) {
      throw ArgumentError(
        'L’annulation peut être demandée avant expédition seulement.',
      );
    }
    if (kind == CustomerRequestKind.returnGoods && !order.canRequestReturn) {
      throw ArgumentError(
        'Un retour peut être demandé après livraison seulement.',
      );
    }
    if (message.trim().length < 10 || message.trim().length > 1000) {
      throw ArgumentError('Décrivez la demande en 10 à 1 000 caractères.');
    }
    if (_requests.any(
      (r) =>
          r.orderId == orderId &&
          r.kind == kind &&
          (r.status == CustomerRequestStatus.received ||
              r.status == CustomerRequestStatus.reviewing),
    )) {
      throw StateError(
        'Une demande de ce type est déjà en cours pour cette commande.',
      );
    }
    final request = CustomerRequest(
      id: 'REQ-${DateTime.now().microsecondsSinceEpoch}-${_serial++}',
      orderId: orderId,
      kind: kind,
      message: message.trim(),
      attachmentName: attachmentName,
      createdAt: DateTime.now(),
    );
    _requests.insert(0, request);
    notifyListeners();
    return request;
  }

  List<CustomerNotice> get notices {
    if (!customerReady) return const [];
    final result = [
      for (final order in _orders)
        CustomerNotice(
          id: 'order-${order.id}-${order.status.name}',
          orderId: order.id,
          title: 'Commande ${order.status.label.toLowerCase()}',
          description: order.id,
          date: order.receipt.createdAt.add(
            Duration(days: order.status.index.clamp(0, 3)),
          ),
        ),
      for (final request in _requests)
        CustomerNotice(
          id: 'request-${request.id}-${request.status.name}',
          orderId: request.orderId,
          title:
              '${request.kind.label} : ${request.status.label.toLowerCase()}',
          description: request.message,
          date: request.createdAt,
        ),
    ];
    result.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(result);
  }

  bool noticeRead(String id) => _readNotices.contains(id);
  int get unreadNoticeCount => notices.where((n) => !noticeRead(n.id)).length;
  void markNoticeRead(String id) {
    _requireCustomer();
    if (!notices.any((n) => n.id == id)) {
      throw ArgumentError('Notification introuvable.');
    }
    _readNotices.add(id);
    notifyListeners();
  }

  void markAllNoticesRead() {
    _requireCustomer();
    _readNotices.addAll(notices.map((n) => n.id));
    notifyListeners();
  }

  void loadCustomerExamples() {
    _requireCustomer();
    if (_orders.isNotEmpty) {
      throw StateError('Les exemples sont réservés à un historique vide.');
    }
    final now = DateTime.now();
    final address =
        defaultDelivery ??
        DeliveryAddress(
          name: displayName.isEmpty ? 'Client Démo' : displayName,
          phone: '00000000',
          street: 'Rue de démonstration',
          city: 'Cotonou',
          country: 'Bénin',
        );
    for (final entry in [
      (CustomerOrderStatus.confirmed, 0),
      (CustomerOrderStatus.shipped, 5),
      (CustomerOrderStatus.delivered, 10),
    ]) {
      final receipt = DemoReceipt(
        id: 'DEMO-EXEMPLE-${entry.$1.name.toUpperCase()}',
        lines: [CartLine(demoPublicProducts[entry.$2 == 5 ? 1 : 0], 2)],
        email: email!,
        address: address,
        createdAt: now.subtract(Duration(days: entry.$2)),
      );
      _orders.add(
        CustomerOrder(
          receipt: receipt,
          status: entry.$1,
          fromExample: true,
          carrier: entry.$1 == CustomerOrderStatus.confirmed
              ? ''
              : 'Transport Démo',
          tracking: entry.$1 == CustomerOrderStatus.confirmed
              ? ''
              : 'SUIVI-FICTIF-${entry.$2}',
          expectedDelivery: entry.$1 == CustomerOrderStatus.shipped
              ? now.add(const Duration(days: 2))
              : null,
        ),
      );
    }
    _requests.add(
      CustomerRequest(
        id: 'REQ-EXEMPLE',
        orderId: _orders.last.id,
        kind: CustomerRequestKind.assistance,
        message: 'Exemple : obtenir une précision sur le conditionnement.',
        createdAt: now.subtract(const Duration(days: 1)),
        status: CustomerRequestStatus.reviewing,
        response: 'Exemple fictif : votre demande est en cours d’examen.',
      ),
    );
    notifyListeners();
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      final values = await repository?.load() ?? <String, int>{};
      for (final entry in values.entries) {
        if (entry.key.isEmpty || entry.value < 1 || entry.value > 999) {
          throw const FormatException('Panier invalide');
        }
      }
      _quantities = Map.of(values);
      ready = true;
      storageError = null;
    } catch (_) {
      ready = false;
      storageError = 'Le panier enregistré est illisible. Réessayez ou réinitialisez-le explicitement.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _save(Map<String, int> next, {bool reset = false}) async {
    if (busy) throw StateError('Une opération est déjà en cours.');
    if (!ready && !reset) {
      throw StateError('Le panier doit être chargé avant modification.');
    }
    busy = true;
    notifyListeners();
    try {
      await repository?.save(next);
      _quantities = Map.of(next);
      ready = true;
      storageError = null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> add(String id, {int quantity = 1}) async {
    final product = _products.where((p) => p.id == id).firstOrNull;
    if (product == null) {
      throw ArgumentError('Ce produit a été retiré du catalogue.');
    }
    if (product.availability == PublicAvailability.unavailable) {
      throw ArgumentError('Ce produit est en rupture.');
    }
    final next = (_quantities[id] ?? 0) + quantity;
    if (quantity < 1 || next > 999) {
      throw ArgumentError('La quantité doit rester comprise entre 1 et 999.');
    }
    await _save({..._quantities, id: next});
  }

  Future<void> setQuantity(String id, int quantity) async {
    if (!_quantities.containsKey(id)) {
      throw ArgumentError('Produit absent du panier.');
    }
    if (quantity < 1 || quantity > 999) {
      throw ArgumentError('La quantité doit rester comprise entre 1 et 999.');
    }
    await _save({..._quantities, id: quantity});
  }

  Future<void> remove(String id) => _save(Map.of(_quantities)..remove(id));
  Future<void> reset() => _save({}, reset: true);

  void signInDemo(String value, {String name = '', bool registration = false}) {
    if (busy) throw StateError('Une opération est déjà en cours.');
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      throw ArgumentError('E-mail invalide.');
    }
    final identity = value.trim().toLowerCase();
    if (email != identity) _clearCustomer();
    email = identity;
    if (name.trim().isNotEmpty) displayName = name.trim();
    verified = !registration;
    notifyListeners();
  }

  void verifyDemo() {
    if (!signedIn) throw StateError('Connectez-vous d’abord.');
    verified = true;
    notifyListeners();
  }

  void signOut() {
    if (busy) throw StateError('Une opération est déjà en cours.');
    email = null;
    verified = false;
    _clearCustomer();
    notifyListeners();
  }

  Future<DemoReceipt> confirmDemo(DeliveryAddress address) async {
    if (!signedIn || !verified) {
      throw StateError('Une session client simulée et vérifiée est requise.');
    }
    if (!address.complete) {
      throw ArgumentError('Complétez l’adresse de livraison.');
    }
    if (unavailableProductIds.isNotEmpty) {
      throw StateError(
        'Retirez les produits indisponibles avant de confirmer.',
      );
    }
    if (lines.isEmpty) throw StateError('Votre panier est vide.');
    final receipt = DemoReceipt(
      id: 'DEMO-${DateTime.now().microsecondsSinceEpoch}',
      lines: lines,
      email: email!,
      address: address,
      createdAt: DateTime.now(),
    );
    await _save({});
    _receipts.insert(0, receipt);
    _orders.insert(
      0,
      CustomerOrder(receipt: receipt, status: CustomerOrderStatus.confirmed),
    );
    notifyListeners();
    return receipt;
  }
}
