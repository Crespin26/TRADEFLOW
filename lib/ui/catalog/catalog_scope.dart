import 'package:flutter/widgets.dart';

import '../../application/product_catalog.dart';
import '../../domain/public_catalog.dart';

class CatalogScope extends InheritedNotifier<ProductCatalog> {
  const CatalogScope({
    super.key,
    required ProductCatalog catalog,
    required super.child,
  }) : super(notifier: catalog);
  static ProductCatalog? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CatalogScope>()?.notifier;
  static List<PublicProduct> productsOf(BuildContext context) =>
      maybeOf(context)?.products ?? demoPublicProducts;
}
