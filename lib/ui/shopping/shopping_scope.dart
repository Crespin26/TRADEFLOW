import '../../domain/public_catalog.dart' show demoPublicProducts;

import 'package:flutter/material.dart';

import '../../application/shopping_session.dart';
import '../../application/trade_store.dart';
import '../../application/product_catalog.dart';
import '../catalog/catalog_scope.dart';

class ShoppingScope extends InheritedNotifier<ShoppingSession> {
  const ShoppingScope({
    super.key,
    required ShoppingSession session,
    this.catalogRevision = 0,
    required super.child,
  }) : super(notifier: session);
  final int catalogRevision;
  @override
  bool updateShouldNotify(ShoppingScope oldWidget) =>
      super.updateShouldNotify(oldWidget) ||
      catalogRevision != oldWidget.catalogRevision;
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
  late ShoppingSession session;
  ProductCatalog? catalog;
  int catalogRevision = 0;
  @override
  void initState() {
    super.initState();
    session = widget.session ?? ShoppingSession();
    attachCatalog();
  }

  void attachCatalog() {
    catalogRevision++;
    if (widget.store != null) {
      catalog = ProductCatalog(widget.store!);
      catalog!.addListener(syncCatalog);
    }
    // A rebind occurs during build: inherited widgets deliver the change themselves.
    session.updateCatalog(
      catalog?.products ?? demoPublicProducts,
      notify: false,
    );
  }

  void detachCatalog() {
    catalog?.removeListener(syncCatalog);
    catalog?.dispose();
    catalog = null;
  }

  @override
  void didUpdateWidget(ShoppingHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        oldWidget.session != widget.session) {
      detachCatalog();
      if (oldWidget.session != widget.session) {
        if (oldWidget.session == null) session.dispose();
        session = widget.session ?? ShoppingSession();
      }
      attachCatalog();
    }
  }

  void syncCatalog() => session.updateCatalog(catalog!.products);
  @override
  void dispose() {
    detachCatalog();
    // Injected controllers belong to their caller and must not be disposed here.
    if (widget.session == null) session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShoppingScope(
    session: session,
    catalogRevision: catalogRevision,
    child: catalog == null
        ? widget.child
        : CatalogScope(catalog: catalog!, child: widget.child),
  );
}
