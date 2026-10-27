import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';
import 'package:tradeflow_mobile/application/shopping_session.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/catalog_photos.dart';
import 'package:tradeflow_mobile/ui/shopping/shopping_scope.dart';
import 'package:tradeflow_mobile/ui/catalog/catalog_scope.dart';

import 'support/fakes.dart';

class TrackedSession extends ShoppingSession {
  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

Future<TradeStore> catalog(String name) async {
  final store = TradeStore(MemoryRepository());
  await store.load();
  await store.addProduct(
    name: name,
    sku: name,
    quantity: 1,
    threshold: 0,
    price: 100,
    description: 'Description',
    photos: [catalogPhotos['rice']!],
  );
  await store.setProductStatus(
    store.data.products.single.id,
    ProductStatus.published,
  );
  return store;
}

Widget host(TradeStore? store, ShoppingSession? session) => ShoppingHost(
  store: store,
  session: session,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Builder(
      builder: (context) => Text(
        '${CatalogScope.productsOf(context).map((p) => p.name).join(',')}|${ShoppingScope.of(context).itemCount}',
      ),
    ),
  ),
);

class CartTotalProbe extends StatelessWidget {
  const CartTotalProbe({super.key});
  @override
  Widget build(BuildContext context) =>
      Text('total:${ShoppingScope.of(context).total}');
}

void main() {
  testWidgets(
    'replacing store or injected session rebinds listeners without stale catalogues',
    (tester) async {
      final first = await catalog('Premier'), second = await catalog('Second');
      final old = TrackedSession(), next = TrackedSession();
      await tester.pumpWidget(host(first, old));
      expect(find.text('Premier|0'), findsOneWidget);
      await tester.pumpWidget(host(second, next));
      expect(find.text('Second|0'), findsOneWidget);
      expect(old.disposed, isFalse);
      await first.setProductStatus(
        first.data.products.single.id,
        ProductStatus.archived,
      );
      await tester.pump();
      expect(find.text('Second|0'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(next.disposed, isFalse);
      old.dispose();
      next.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'removing the store restores the default catalogue and owned sessions are released',
    (tester) async {
      final store = await catalog('Interne');
      ShoppingSession? owned;
      await tester.pumpWidget(
        ShoppingHost(
          store: store,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                owned = ShoppingScope.of(context);
                return const Text('ready');
              },
            ),
          ),
        ),
      );
      final reference = owned!;
      await tester.pumpWidget(host(null, null));
      expect(find.textContaining('Riz parfumé'), findsOneWidget);
      final injected = TrackedSession();
      await tester.pumpWidget(host(null, injected));
      expect(() => reference.addListener(() {}), throwsFlutterError);
      await tester.pumpWidget(const SizedBox());
      expect(injected.disposed, isFalse);
      injected.dispose();
    },
  );
  testWidgets(
    'same session and constant cart child refresh when only the store changes',
    (tester) async {
      final first = await catalog('Premier'), second = await catalog('Second');
      final session = ShoppingSession();
      const child = Directionality(
        textDirection: TextDirection.ltr,
        child: CartTotalProbe(),
      );
      await tester.pumpWidget(
        ShoppingHost(store: first, session: session, child: child),
      );
      await session.add(first.data.products.single.id);
      await tester.pump();
      expect(find.text('total:100'), findsOneWidget);
      await tester.pumpWidget(
        ShoppingHost(store: second, session: session, child: child),
      );
      expect(find.text('total:0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
}
