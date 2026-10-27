import '../domain/models.dart';

/// Isolated fixtures, preserving an empty workspace’s configured references and issuer.
TradeData buildDemoData(
  TradeData current, {
  required String Function(String) id,
  required DateTime now,
}) {
  final seed = TradeData(
    company: current.company,
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
          id: id('MVT'),
          productName: entry.$1,
          delta: entry.$2,
          reason: 'Stock initial de démonstration',
          createdAt: now,
        ),
    ],
  );
  final category = current.categories.contains('Sans catégorie')
      ? 'Sans catégorie'
      : current.categories.first;
  final unit = current.units.contains('pièce') ? 'pièce' : current.units.first;
  return current.copyWith(
    products: [
      for (final p in seed.products) p.copyWith(category: category, unit: unit),
    ],
    contacts: seed.contacts,
    movements: seed.movements,
  );
}
