import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../domain/public_catalog.dart';
import 'trade_store.dart';

PublicProduct publicProduct(Product p) => PublicProduct(
  id: p.id,
  name: p.name,
  sku: p.sku,
  category: p.category,
  price: p.price,
  availability: p.quantity > 0
      ? PublicAvailability.available
      : p.allowBackorder
      ? PublicAvailability.onOrder
      : PublicAvailability.unavailable,
  description: p.description,
  unit: p.unit,
  origin: p.origin,
  specifications: const {},
  featured: p.featured,
  photos: p.photos,
);

class ProductCatalog extends ChangeNotifier {
  ProductCatalog(this.store) {
    store.addListener(_changed);
  }
  final TradeStore store;
  bool get managed => store.data.catalogEnabled;
  List<PublicProduct> get products => store.loadError != null
      ? const []
      : managed
      ? List.unmodifiable(
          store.data.products
              .where((p) => p.status == ProductStatus.published)
              .map(publicProduct),
        )
      : demoPublicProducts;
  void _changed() => notifyListeners();
  @override
  void dispose() {
    store.removeListener(_changed);
    super.dispose();
  }
}
