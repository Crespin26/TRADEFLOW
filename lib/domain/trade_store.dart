import 'package:flutter/foundation.dart';

import '../data/trade_repository.dart';
import 'models.dart';

class TradeStore extends ChangeNotifier {
  TradeStore(this.repository);
  final TradeRepository repository;
  TradeData _data = TradeData();
  TradeData get data => _data;
  bool _busy = false;
  bool get busy => _busy;
  bool _loaded = false;
  bool get loaded => _loaded;
  String? loadError;
  int _sequence = 0;
  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  Future<void> load() async {
    if (_busy) return;
    _busy = true;
    loadError = null;
    notifyListeners();
    try {
      _data = await repository.load();
      _loaded = true;
    } catch (_) {
      // Preserve the original saved data; never replace unreadable data silently.
      loadError = 'Impossible de lire les données locales. Réessayez sans effacer le stockage.';
      _loaded = false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _commit(TradeData next) async {
    if (!_loaded) throw StateError('Les données ne sont pas chargées.');
    if (_busy) throw StateError('Une sauvegarde est déjà en cours.');
    _busy = true;
    notifyListeners();
    try {
      await repository.save(next);
      _data = next;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _checkText(String text, String label) {
    if (text.trim().isEmpty) throw ArgumentError('$label est obligatoire.');
  }

  Future<void> addProduct({
    required String name,
    required String sku,
    required int quantity,
    required int threshold,
    required int price,
  }) async {
    _checkText(name, 'Le nom');
    _checkText(sku, 'La référence');
    if (quantity < 0 || threshold < 0 || price < 0) {
      throw ArgumentError('Les valeurs doivent être positives ou nulles.');
    }
    if (_data.products.any(
      (p) => p.sku.toLowerCase() == sku.trim().toLowerCase(),
    )) {
      throw ArgumentError('Cette référence produit existe déjà.');
    }
    final p = Product(
      id: _id('PRD'),
      name: name.trim(),
      sku: sku.trim(),
      quantity: quantity,
      threshold: threshold,
      price: price,
    );
    await _commit(
      _data.copyWith(
        products: [..._data.products, p],
        movements: [
          if (quantity > 0)
            StockMovement(
              id: _id('MVT'),
              productName: p.name,
              delta: quantity,
              reason: 'Stock initial',
              createdAt: DateTime.now(),
            ),
          ..._data.movements,
        ],
      ),
    );
  }

  Future<void> adjustStock(String productId, int delta, String reason) async {
    _checkText(reason, 'Le motif');
    final p = _data.products.firstWhere((p) => p.id == productId);
    if (delta == 0) {
      throw ArgumentError('La quantité doit être différente de zéro.');
    }
    if (p.quantity + delta < 0) {
      throw ArgumentError('Stock disponible insuffisant.');
    }
    await _commit(
      _data.copyWith(
        products: [
          for (final item in _data.products)
            if (item.id == p.id) p.withQuantity(p.quantity + delta) else item,
        ],
        movements: [
          StockMovement(
            id: _id('MVT'),
            productName: p.name,
            delta: delta,
            reason: reason.trim(),
            createdAt: DateTime.now(),
          ),
          ..._data.movements,
        ],
      ),
    );
  }

  Future<void> addContact({
    required String name,
    required ContactKind kind,
    required String country,
    required String email,
    required String phone,
  }) async {
    _checkText(name, 'Le nom');
    _checkText(country, 'Le pays');
    if (email.trim().isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      throw ArgumentError('Adresse e-mail invalide.');
    }
    await _commit(
      _data.copyWith(
        contacts: [
          ..._data.contacts,
          Contact(
            id: _id('CT'),
            name: name.trim(),
            kind: kind,
            country: country.trim(),
            email: email.trim(),
            phone: phone.trim(),
          ),
        ],
      ),
    );
  }

  Future<void> createOrder({
    required String productId,
    required String customerId,
    required int quantity,
    required String destination,
  }) async {
    _checkText(destination, 'La destination');
    final p = _data.products.firstWhere((p) => p.id == productId);
    final c = _data.contacts.firstWhere((c) => c.id == customerId);
    if (c.kind != ContactKind.client) {
      throw ArgumentError('Sélectionnez un client.');
    }
    if (quantity <= 0 || quantity > p.quantity) {
      throw ArgumentError('Quantité invalide ou stock insuffisant.');
    }
    final now = DateTime.now();
    final order = TradeOrder(
      id: _id('CMD'),
      customerId: c.id,
      customerName: c.name,
      productId: p.id,
      productName: p.name,
      quantity: quantity,
      unitPrice: p.price,
      status: OrderStatus.confirmed,
      createdAt: now,
      destination: destination.trim(),
    );
    await _commit(
      _data.copyWith(
        products: [
          for (final item in _data.products)
            if (item.id == p.id)
              p.withQuantity(p.quantity - quantity)
            else
              item,
        ],
        orders: [order, ..._data.orders],
        movements: [
          StockMovement(
            id: _id('MVT'),
            productName: p.name,
            delta: -quantity,
            reason: 'Commande ${order.id}',
            createdAt: now,
          ),
          ..._data.movements,
        ],
      ),
    );
  }

  Future<void> changeOrderStatus(String id, OrderStatus status) async {
    final order = _data.orders.firstWhere((o) => o.id == id);
    final allowed = switch (order.status) {
      OrderStatus.confirmed => [OrderStatus.shipped, OrderStatus.cancelled],
      OrderStatus.shipped => [OrderStatus.delivered],
      _ => <OrderStatus>[],
    };
    if (!allowed.contains(status)) {
      throw ArgumentError('Changement de statut non autorisé.');
    }
    var products = _data.products;
    var movements = _data.movements;
    if (status == OrderStatus.cancelled) {
      products = [
        for (final p in products)
          if (p.id == order.productId)
            p.withQuantity(p.quantity + order.quantity)
          else
            p,
      ];
      movements = [
        StockMovement(
          id: _id('MVT'),
          productName: order.productName,
          delta: order.quantity,
          reason: 'Annulation ${order.id}',
          createdAt: DateTime.now(),
        ),
        ...movements,
      ];
    }
    await _commit(
      _data.copyWith(
        products: products,
        movements: movements,
        orders: [
          for (final o in _data.orders)
            if (o.id == id) o.withStatus(status) else o,
        ],
      ),
    );
  }

  Future<void> loadDemo() async {
    if (_data.products.isNotEmpty ||
        _data.contacts.isNotEmpty ||
        _data.orders.isNotEmpty ||
        _data.movements.isNotEmpty) {
      throw StateError('Les exemples sont réservés à un espace vide.');
    }
    final now = DateTime.now();
    await _commit(
      TradeData(
        products: const [
          Product(
            id: 'demo-rice',
            name: 'Riz parfumé · sac de 25 kg',
            sku: 'RIZ-025',
            quantity: 48,
            threshold: 10,
            price: 18500,
          ),
          Product(
            id: 'demo-oil',
            name: 'Huile végétale · bidon de 5 L',
            sku: 'HUI-005',
            quantity: 6,
            threshold: 12,
            price: 7500,
          ),
          Product(
            id: 'demo-cocoa',
            name: 'Cacao · sac de 50 kg',
            sku: 'CAC-050',
            quantity: 24,
            threshold: 5,
            price: 95000,
          ),
        ],
        contacts: const [
          Contact(
            id: 'demo-client',
            name: 'Comptoir Atlantique (exemple)',
            kind: ContactKind.client,
            country: 'Bénin',
            email: 'contact@example.com',
            phone: '+229 00 00 00 00',
          ),
          Contact(
            id: 'demo-supplier',
            name: 'Agro Export (exemple)',
            kind: ContactKind.supplier,
            country: 'Côte d’Ivoire',
            email: 'export@example.com',
            phone: '',
          ),
        ],
        movements: [
          for (final entry in [
            ('Riz parfumé · sac de 25 kg', 48),
            ('Huile végétale · bidon de 5 L', 6),
            ('Cacao · sac de 50 kg', 24),
          ])
            StockMovement(
              id: _id('MVT'),
              productName: entry.$1,
              delta: entry.$2,
              reason: 'Stock initial de démonstration',
              createdAt: now,
            ),
        ],
      ),
    );
  }
}
