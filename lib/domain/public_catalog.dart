/// Public demonstration data only. No internal cost, stock count or partner data.
enum PublicAvailability {
  available('Disponible'),
  onOrder('Sur commande'),
  unavailable('Rupture');

  const PublicAvailability(this.label);
  final String label;
}

enum CatalogSort { featured, name, priceAscending, priceDescending }

enum CatalogPrice { all, under10000, from10000to50000, over50000 }

class PublicProduct {
  const PublicProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.availability,
    required this.description,
    required this.unit,
    required this.origin,
    required this.specifications,
    this.featured = false,
  });
  final String id, name, sku, category, description, unit, origin;
  final int price;
  final PublicAvailability availability;
  final Map<String, String> specifications;
  final bool featured;
}

String normalizeCatalogText(String value) {
  var result = value.toLowerCase().trim();
  for (final entry in {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'œ': 'oe',
  }.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

List<PublicProduct> selectPublicProducts(
  Iterable<PublicProduct> source, {
  String query = '',
  String? category,
  PublicAvailability? availability,
  CatalogPrice price = CatalogPrice.all,
  CatalogSort sort = CatalogSort.featured,
}) {
  final words = normalizeCatalogText(query)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);
  final result = source.where((p) {
    final text = normalizeCatalogText(
      '${p.name} ${p.sku} ${p.category} ${p.description}',
    );
    return words.every(text.contains) &&
        (category == null || category == p.category) &&
        (availability == null || availability == p.availability) &&
        switch (price) {
          CatalogPrice.all => true,
          CatalogPrice.under10000 => p.price < 10000,
          CatalogPrice.from10000to50000 => p.price >= 10000 && p.price <= 50000,
          CatalogPrice.over50000 => p.price > 50000,
        };
  }).toList();
  int alphabetical(PublicProduct a, PublicProduct b) =>
      normalizeCatalogText(a.name).compareTo(normalizeCatalogText(b.name));
  result.sort((a, b) {
    final comparison = switch (sort) {
      CatalogSort.featured => (b.featured ? 1 : 0).compareTo(
        a.featured ? 1 : 0,
      ),
      CatalogSort.name => alphabetical(a, b),
      CatalogSort.priceAscending => a.price.compareTo(b.price),
      CatalogSort.priceDescending => b.price.compareTo(a.price),
    };
    return comparison == 0 ? alphabetical(a, b) : comparison;
  });
  return result;
}

const demoPublicProducts = [
  PublicProduct(
    id: 'rice',
    name: 'Riz parfumé',
    sku: 'PUB-RIZ-025',
    category: 'Alimentation',
    price: 18500,
    availability: PublicAvailability.available,
    unit: 'Sac de 25 kg',
    origin: 'Bénin',
    featured: true,
    description: 'Un riz parfumé sélectionné pour les besoins des commerces et de la restauration. Conditionnement adapté au stockage et à la distribution.',
    specifications: {
      'Conditionnement': 'Sac de 25 kg',
      'Conservation': 'Au sec, à l’abri de la chaleur',
      'Usage': 'Commerce et restauration',
    },
  ),
  PublicProduct(
    id: 'oil',
    name: 'Huile végétale',
    sku: 'PUB-HUI-005',
    category: 'Alimentation',
    price: 7500,
    availability: PublicAvailability.available,
    unit: 'Bidon de 5 L',
    origin: 'Côte d’Ivoire',
    featured: true,
    description: 'Huile végétale en bidon refermable pour un usage quotidien. Un format pratique pour les professionnels de l’alimentation.',
    specifications: {
      'Conditionnement': 'Bidon de 5 L',
      'Stockage': 'À l’abri de la lumière',
      'Emballage': 'Bidon refermable',
    },
  ),
  PublicProduct(
    id: 'cocoa',
    name: 'Cacao en fèves',
    sku: 'PUB-CAC-050',
    category: 'Alimentation',
    price: 95000,
    availability: PublicAvailability.onOrder,
    unit: 'Sac de 50 kg',
    origin: 'Côte d’Ivoire',
    featured: true,
    description: 'Fèves de cacao destinées à la transformation et au négoce. Les conditions de préparation et le délai seront précisés dans une offre commerciale.',
    specifications: {
      'Conditionnement': 'Sac de 50 kg',
      'Usage': 'Transformation',
      'Délai': 'À confirmer sur devis',
    },
  ),
  PublicProduct(
    id: 'fabric',
    name: 'Tissu coton uni',
    sku: 'PUB-TIS-006',
    category: 'Textile',
    price: 12000,
    availability: PublicAvailability.available,
    unit: 'Coupon de 6 m',
    origin: 'Bénin',
    description: 'Tissu en coton uni pour la confection. Un coupon polyvalent pour les ateliers et revendeurs.',
    specifications: {
      'Composition': 'Coton',
      'Longueur': '6 mètres',
      'Coloris': 'Bleu indigo',
    },
  ),
  PublicProduct(
    id: 'workwear',
    name: 'Veste de travail',
    sku: 'PUB-VES-001',
    category: 'Textile',
    price: 8500,
    availability: PublicAvailability.unavailable,
    unit: 'À l’unité',
    origin: 'Togo',
    description: 'Veste de travail à poches pour les activités d’atelier et de manutention. Ce modèle illustre un article temporairement indisponible.',
    specifications: {
      'Taille présentée': 'L',
      'Coloris': 'Bleu marine',
      'Entretien': 'Lavage à 30 °C',
    },
  ),
  PublicProduct(
    id: 'solar',
    name: 'Kit solaire portable',
    sku: 'PUB-SOL-001',
    category: 'Équipement',
    price: 145000,
    availability: PublicAvailability.onOrder,
    unit: 'Kit complet',
    origin: 'Importation',
    featured: true,
    description: 'Un ensemble de démonstration pour l’éclairage et les petits équipements. La composition finale et les performances devront être validées dans une offre réelle.',
    specifications: {
      'Contenu indicatif': 'Panneau, batterie et éclairage',
      'Usage': 'Éclairage d’appoint',
      'Installation': 'Selon notice fournisseur',
    },
  ),
  PublicProduct(
    id: 'chair',
    name: 'Chaise de bureau',
    sku: 'PUB-CHA-001',
    category: 'Équipement',
    price: 68000,
    availability: PublicAvailability.available,
    unit: 'À l’unité',
    origin: 'Importation',
    description: 'Chaise de bureau réglable pour les espaces professionnels. Une référence de démonstration du catalogue équipement.',
    specifications: {
      'Réglage': 'Hauteur ajustable',
      'Coloris': 'Gris anthracite',
      'Livraison': 'À assembler',
    },
  ),
  PublicProduct(
    id: 'cartons',
    name: 'Cartons d’expédition',
    sku: 'PUB-EMB-020',
    category: 'Emballage',
    price: 15000,
    availability: PublicAvailability.available,
    unit: 'Lot de 20',
    origin: 'Bénin',
    description: 'Cartons pour préparer les expéditions de marchandises. Livrés à plat pour faciliter leur stockage.',
    specifications: {
      'Quantité par lot': '20 cartons',
      'Dimensions': '40 × 30 × 30 cm',
      'Matière': 'Carton ondulé',
    },
  ),
];
