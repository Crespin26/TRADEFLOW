import 'package:flutter/foundation.dart';

import '../data/trade_repository.dart';
import 'models.dart';
import 'catalog_photos.dart';
import 'public_catalog.dart' show normalizeCatalogText;

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
      // Publish the new state only after the complete snapshot has been saved.
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
    int purchasePrice = 0,
    String category = 'Sans catégorie',
    String unit = 'pièce',
    String description = '',
    String origin = '',
    List<CatalogPhoto> photos = const [],
    bool featured = false,
    bool allowBackorder = false,
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
      purchasePrice: purchasePrice,
      category: category,
      unit: unit,
      description: description.trim(),
      origin: origin.trim(),
      photos: List.unmodifiable(photos),
      featured: featured,
      allowBackorder: allowBackorder,
    );
    _validateProduct(p);
    await _commit(
      _data.copyWith(
        products: [..._data.products, p],
        movements: [
          if (quantity > 0)
            StockMovement(
              id: _id('MVT'),
              productName: p.name,
              delta: quantity,
              productId: p.id,
              sku: p.sku,
              unit: p.unit,
              kind: StockMovementKind.initial,
              beforeQuantity: 0,
              afterQuantity: quantity,
              reason: 'Stock initial',
              createdAt: DateTime.now(),
            ),
          ..._data.movements,
        ],
      ),
    );
  }

  void _validateProduct(Product p) {
    _checkText(p.name, 'Le nom');
    _checkText(p.sku, 'La référence');
    if ([
      p.quantity,
      p.threshold,
      p.price,
      p.purchasePrice,
    ].any((v) => v < 0 || v > 1000000000)) {
      throw ArgumentError('Valeurs autorisées : 0 à 1 000 000 000.');
    }
    if (_data.products.any(
      (other) =>
          other.id != p.id &&
          other.sku.toLowerCase() == p.sku.trim().toLowerCase(),
    )) {
      throw ArgumentError('Cette référence produit existe déjà.');
    }
    if (!_data.categories.contains(p.category) ||
        !_data.units.contains(p.unit)) {
      throw ArgumentError('Choisissez une catégorie et une unité existantes.');
    }
    if (p.photos.length > 3 ||
        p.photos.any(
          (photo) => photo.bytes == null
              ? !catalogPhotos.values.any((asset) => asset.asset == photo.asset)
              : photo.bytes!.length > 350000,
        )) {
      throw ArgumentError('Trois photos maximum, de 350 Ko maximum chacune.');
    }
    final bytes = [..._data.products.where((other) => other.id != p.id), p]
        .expand((item) => item.photos)
        .fold<int>(0, (sum, photo) => sum + (photo.bytes?.length ?? 0));
    if (bytes > 2000000) {
      throw ArgumentError(
        'La limite locale de photos (2 Mo) est atteinte. Retirez des photos inutilisées.',
      );
    }
    if (p.status == ProductStatus.published &&
        (p.description.trim().isEmpty || p.photos.isEmpty)) {
      throw ArgumentError(
        'Ajoutez une description et au moins une photo avant de publier.',
      );
    }
  }

  Future<void> updateProduct(Product product) async {
    final original = _data.products.firstWhere((p) => p.id == product.id);
    if (original.status == ProductStatus.archived) {
      throw StateError('Restaurez ce produit avant de le modifier.');
    }
    if (product.quantity != original.quantity ||
        product.status != original.status) {
      throw ArgumentError(
        'Utilisez les actions de stock et de publication dédiées.',
      );
    }
    _validateProduct(product);
    await _commit(
      _data.copyWith(
        products: [
          for (final p in _data.products)
            if (p.id == product.id) product.copyWith() else p,
        ],
      ),
    );
  }

  Future<void> setProductStatus(String id, ProductStatus status) async {
    final p = _data.products.firstWhere((p) => p.id == id);
    if (p.status == ProductStatus.archived && status != ProductStatus.draft) {
      throw ArgumentError(
        'Un produit archivé doit être restauré en brouillon.',
      );
    }
    final next = p.copyWith(status: status);
    _validateProduct(next);
    await _commit(
      _data.copyWith(
        catalogEnabled:
            _data.catalogEnabled || status == ProductStatus.published,
        products: [
          for (final item in _data.products)
            if (item.id == id) next else item,
        ],
      ),
    );
  }

  Future<void> saveReference({
    required bool category,
    String? previous,
    required String value,
  }) async {
    final name = value.trim();
    _checkText(name, category ? 'La catégorie' : 'L’unité');
    if (name.length > 60) throw ArgumentError('60 caractères maximum.');
    final source = category ? _data.categories : _data.units;
    if (previous != null && !source.contains(previous)) {
      throw ArgumentError('Référence introuvable.');
    }
    if (source.any(
      (item) => item != previous && item.toLowerCase() == name.toLowerCase(),
    )) {
      throw ArgumentError('Ce nom existe déjà.');
    }
    final updated = [
      for (final item in source)
        if (item == previous) name else item,
      if (previous == null) name,
    ];
    await _commit(
      _data.copyWith(
        categories: category ? updated : null,
        units: category ? null : updated,
        products: [
          for (final p in _data.products)
            p.copyWith(
              category: category && p.category == previous ? name : null,
              unit: !category && p.unit == previous ? name : null,
            ),
        ],
      ),
    );
  }

  Future<void> deleteReference({
    required bool category,
    required String value,
  }) async {
    final source = category ? _data.categories : _data.units;
    if (source.length <= 1 ||
        _data.products.any((p) => (category ? p.category : p.unit) == value)) {
      throw ArgumentError(
        'Référence utilisée ou dernière référence disponible.',
      );
    }
    await _commit(
      _data.copyWith(
        categories: category ? source.where((v) => v != value).toList() : null,
        units: category ? null : source.where((v) => v != value).toList(),
      ),
    );
  }

  /// Enregistre une variation motivée sans écraser un stock modifié depuis l’ouverture du formulaire.
  Future<void> adjustStock(
    String productId,
    int delta,
    String reason, {
    int? expectedQuantity,
    String? expectedUnit,
  }) async {
    _checkText(reason, 'Le motif');
    final p = _data.products.firstWhere((p) => p.id == productId);
    if (p.status == ProductStatus.archived) {
      throw ArgumentError('Ce produit est archivé.');
    }
    if ((expectedQuantity != null && p.quantity != expectedQuantity) ||
        (expectedUnit != null && p.unit != expectedUnit)) {
      throw StateError(
        'Le stock ou l’unité a changé. Fermez le formulaire et recommencez avec les données actuelles.',
      );
    }
    if (delta.abs() > 1000000000 || p.quantity + delta > 1000000000) {
      throw ArgumentError(
        'Le stock doit rester compris entre 0 et 1 000 000 000.',
      );
    }
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
            productId: p.id,
            sku: p.sku,
            unit: p.unit,
            kind: delta > 0
                ? StockMovementKind.receipt
                : StockMovementKind.issue,
            beforeQuantity: p.quantity,
            afterQuantity: p.quantity + delta,
            reason: reason.trim(),
            createdAt: DateTime.now(),
          ),
          ..._data.movements,
        ],
      ),
    );
  }

  /// Valide tous les comptages avant de sauvegarder stock, inventaire et mouvements ensemble.
  Future<void> performInventory({
    required List<StockCount> counts,
    required String reason,
  }) async {
    _checkText(reason, 'Le motif de l’inventaire');
    if (counts.isEmpty ||
        counts.map((c) => c.productId).toSet().length != counts.length) {
      throw ArgumentError('Sélectionnez des produits distincts à compter.');
    }
    // Validate every count before building a single atomic stock/history update.
    final canonical = <StockCount>[];
    for (final count in counts) {
      final p = _data.products
          .where((p) => p.id == count.productId)
          .firstOrNull;
      if (p == null || p.status == ProductStatus.archived) {
        throw StateError(
          'Un produit est archivé ou absent. Recommencez l’inventaire.',
        );
      }
      // A concurrent receipt, sale or unit change invalidates the opening snapshot.
      if (p.quantity != count.expectedQuantity || p.unit != count.unit) {
        throw StateError(
          'Le stock ou l’unité de ${p.name} a changé. Fermez cet inventaire et recommencez avec les données actuelles.',
        );
      }
      if (count.countedQuantity < 0 || count.countedQuantity > 1000000000) {
        throw ArgumentError(
          'Le comptage doit être compris entre 0 et 1 000 000 000.',
        );
      }
      canonical.add(
        StockCount(
          productId: p.id,
          productName: p.name,
          sku: p.sku,
          unit: p.unit,
          expectedQuantity: p.quantity,
          countedQuantity: count.countedQuantity,
        ),
      );
    }
    final inventory = StockInventory(
      id: _id('INV'),
      reason: reason.trim(),
      createdAt: DateTime.now(),
      counts: canonical,
    );
    final byId = {for (final c in canonical) c.productId: c};
    await _commit(
      _data.copyWith(
        products: [
          for (final p in _data.products)
            if (byId.containsKey(p.id))
              p.withQuantity(byId[p.id]!.countedQuantity)
            else
              p,
        ],
        inventories: [inventory, ..._data.inventories],
        movements: [
          for (final c in canonical)
            // Counts without discrepancies stay in the audit, without a zero movement.
            if (c.delta != 0)
              StockMovement(
                id: _id('MVT'),
                productId: c.productId,
                productName: c.productName,
                sku: c.sku,
                unit: c.unit,
                delta: c.delta,
                beforeQuantity: c.expectedQuantity,
                afterQuantity: c.countedQuantity,
                kind: StockMovementKind.inventory,
                reference: inventory.id,
                reason: inventory.reason,
                createdAt: inventory.createdAt,
              ),
          ..._data.movements,
        ],
      ),
    );
  }

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
        _data.orders.any((o) => o.customerId == original.id)) {
      throw ArgumentError(
        'Le type d’un client lié à des commandes ne peut pas être modifié.',
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

  Future<void> createOrder({
    required String productId,
    required String customerId,
    required int quantity,
    required String destination,
  }) async {
    _checkText(destination, 'La destination');
    final p = _data.products.firstWhere((p) => p.id == productId);
    if (p.status == ProductStatus.archived) {
      throw ArgumentError('Ce produit est archivé.');
    }
    final c = _data.contacts.firstWhere((c) => c.id == customerId);
    if (c.archived) throw ArgumentError('Ce client est archivé.');
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
            productId: p.id,
            sku: p.sku,
            unit: p.unit,
            kind: StockMovementKind.sale,
            reference: order.id,
            beforeQuantity: p.quantity,
            afterQuantity: p.quantity - quantity,
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
      final original = _data.products.firstWhere(
        (p) => p.id == order.productId,
      );
      if (original.quantity + order.quantity > 1000000000) {
        throw ArgumentError('Le retour dépasserait le stock maximal autorisé.');
      }
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
          productId: original.id,
          sku: original.sku,
          unit: original.unit,
          kind: StockMovementKind.cancellation,
          reference: order.id,
          beforeQuantity: original.quantity,
          afterQuantity: original.quantity + order.quantity,
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
        _data.movements.isNotEmpty ||
        _data.inventories.isNotEmpty) {
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
