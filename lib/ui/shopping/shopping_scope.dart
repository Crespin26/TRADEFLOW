import 'package:flutter/material.dart';

import '../../domain/shopping_session.dart';
import '../../domain/trade_store.dart';
import '../../domain/product_catalog.dart';
import '../catalog/catalog_scope.dart';

class ShoppingScope extends InheritedNotifier<ShoppingSession> {
  const ShoppingScope({
    super.key,
    required ShoppingSession session,
    required super.child,
  }) : super(notifier: session);
  static ShoppingSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShoppingScope>()!.notifier!;
}

class ShoppingHost extends StatefulWidget {
  const ShoppingHost({
    super.key,
    this.session,
    this.store,
    required this.child,
  });
  final ShoppingSession? session;
  final TradeStore? store;
  final Widget child;
  @override
  State<ShoppingHost> createState() => _ShoppingHostState();
}

class _ShoppingHostState extends State<ShoppingHost> {
  late final ShoppingSession session = widget.session ?? ShoppingSession();
  ProductCatalog? catalog;
  @override
  void initState() {
    super.initState();
    if (widget.store != null) {
      catalog = ProductCatalog(widget.store!);
      session.updateCatalog(catalog!.products, notify: false);
      catalog!.addListener(syncCatalog);
    }
  }

  void syncCatalog() => session.updateCatalog(catalog!.products);
  @override
  void dispose() {
    catalog?.removeListener(syncCatalog);
    catalog?.dispose();
    if (widget.session == null) session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShoppingScope(
    session: session,
    child: catalog == null
        ? widget.child
        : CatalogScope(catalog: catalog!, child: widget.child),
  );
}
