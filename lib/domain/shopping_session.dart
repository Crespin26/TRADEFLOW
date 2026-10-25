import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'public_catalog.dart';

abstract interface class PublicCartRepository {
  Future<Map<String, int>> load();
  Future<void> save(Map<String, int> quantities);
}

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

/// UI simulation only. No authentication, stock reservation or real order occurs.
class ShoppingSession extends ChangeNotifier {
  ShoppingSession({this.repository}) : ready = repository == null;
  final PublicCartRepository? repository;
  Map<String, int> _quantities = {};
  Map<String, int> get quantities => UnmodifiableMapView(_quantities);
  bool ready, busy = false;
  String? storageError;
  String? email;
  String displayName = '';
  bool verified = false;
  bool get signedIn => email != null;
  final List<DemoReceipt> _receipts = [];
  List<DemoReceipt> get receipts => List.unmodifiable(_receipts);
  List<CartLine> get lines => [
    for (final p in demoPublicProducts)
      if (_quantities.containsKey(p.id)) CartLine(p, _quantities[p.id]!),
  ];
  int get itemCount => _quantities.values.fold(0, (a, b) => a + b);
  int get total => lines.fold(0, (a, line) => a + line.total);

  Future<void> load() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      final values = await repository?.load() ?? <String, int>{};
      for (final entry in values.entries) {
        final known = demoPublicProducts.where(
          (p) =>
              p.id == entry.key &&
              p.availability != PublicAvailability.unavailable,
        );
        if (known.isEmpty || entry.value < 1 || entry.value > 999) {
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
    final product = demoPublicProducts.firstWhere((p) => p.id == id);
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
    if (email != value.trim()) _receipts.clear();
    email = value.trim();
    displayName = name.trim();
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
    displayName = '';
    verified = false;
    _receipts.clear();
    notifyListeners();
  }

  Future<DemoReceipt> confirmDemo(DeliveryAddress address) async {
    if (!signedIn || !verified) {
      throw StateError('Une session client simulée et vérifiée est requise.');
    }
    if (!address.complete) {
      throw ArgumentError('Complétez l’adresse de livraison.');
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
    notifyListeners();
    return receipt;
  }
}
