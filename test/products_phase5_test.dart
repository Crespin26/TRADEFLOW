import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradeflow_mobile/data/trade_repository.dart';
import 'package:tradeflow_mobile/data/public_cart_repository.dart';
import 'package:image/image.dart' as img;
import 'package:tradeflow_mobile/domain/catalog_photos.dart';
import 'package:tradeflow_mobile/domain/models.dart';
import 'package:tradeflow_mobile/domain/photo_import.dart';
import 'package:tradeflow_mobile/application/product_catalog.dart';
import 'package:tradeflow_mobile/application/shopping_session.dart';
import 'package:tradeflow_mobile/application/trade_store.dart';

import 'support/fakes.dart' show MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryRepository repo;
  late TradeStore store;
  setUp(() async {
    repo = MemoryRepository();
    store = TradeStore(repo);
    await store.load();
    await store.addProduct(
      name: 'Riz',
      sku: 'RIZ',
      quantity: 10,
      threshold: 3,
      price: 15000,
      purchasePrice: 9000,
      description: 'Riz parfumé conditionné en sac.',
      photos: [catalogPhotos['rice']!],
    );
  });
  test('version 1 migrates without changing stock or identifiers', () {
    final legacy = {
      'version': 1,
      'products': [
        {
          'id': 'old',
          'name': 'Ancien',
          'sku': 'OLD',
          'price': 12,
          'quantity': 7,
          'threshold': 2,
        },
      ],
      'contacts': <Map<String, dynamic>>[],
      'orders': <Map<String, dynamic>>[],
      'movements': <Map<String, dynamic>>[],
    };
    final data = TradeData.fromJson(legacy);
    expect(data.products.single.status, ProductStatus.draft);
    expect(data.catalogEnabled, isFalse);
    expect(data.products.single.quantity, 7);
    final restored = TradeData.fromJson(
      jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>,
    );
    expect(restored.products.single.id, 'old');
    expect(restored.toJson()['version'], 2);
  });
  test('publication projects public fields, withdrawal remains an empty managed catalogue after restart', () async {
    final catalog = ProductCatalog(store);
    addTearDown(catalog.dispose);
    expect(catalog.products.length, 8);
    final p = store.data.products.single;
    await store.setProductStatus(p.id, ProductStatus.published);
    expect(catalog.managed, isTrue);
    expect(catalog.products.single.id, p.id);
    expect(catalog.products.single.photo, same(p.photos.first));
    expect(catalog.products.single.specifications, isEmpty);
    await store.setProductStatus(p.id, ProductStatus.draft);
    expect(catalog.products, isEmpty);
    final restarted = TradeStore(repo);
    await restarted.load();
    final restored = ProductCatalog(restarted);
    addTearDown(restored.dispose);
    expect(restored.managed, isTrue);
    expect(restored.products, isEmpty);
  });
  test(
    'published edits preserve metadata and historical order snapshots',
    () async {
      final p = store.data.products.single;
      await store.addContact(
        name: 'Client',
        kind: ContactKind.client,
        country: 'Bénin',
        email: '',
        phone: '',
      );
      await store.createOrder(
        productId: p.id,
        customerId: store.data.contacts.single.id,
        quantity: 2,
        destination: 'Cotonou',
      );
      await store.setProductStatus(p.id, ProductStatus.published);
      await store.updateProduct(
        store.data.products.single.copyWith(name: 'Riz premium', price: 18000),
      );
      expect(store.data.orders.single.productName, 'Riz');
      expect(store.data.orders.single.unitPrice, 15000);
      expect(store.data.products.single.quantity, 8);
      await store.adjustStock(p.id, 1, 'Réception');
      expect(
        store.data.products.single.photos.single.asset,
        p.photos.single.asset,
      );
      expect(store.data.products.single.status, ProductStatus.published);
      expect(store.data.products.single.description, isNotEmpty);
    },
  );
  test('validation, duplicate references and failed persistence leave state intact', () async {
    final p = store.data.products.single;
    final previous = store.data;
    await expectLater(
      store.updateProduct(p.copyWith(price: -1)),
      throwsArgumentError,
    );
    await expectLater(
      store.addProduct(
        name: 'Autre',
        sku: ' riz ',
        quantity: 0,
        threshold: 0,
        price: 1,
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.updateProduct(p.copyWith(quantity: 99)),
      throwsArgumentError,
    );
    expect(store.data, same(previous));
    repo.failSave = true;
    await expectLater(
      store.setProductStatus(p.id, ProductStatus.published),
      throwsStateError,
    );
    expect(store.data, same(previous));
    expect(store.data.catalogEnabled, isFalse);
  });
  test('publication requires a description and photo, archive forbids operations and restores to draft', () async {
    final p = store.data.products.single;
    await store.updateProduct(p.copyWith(description: '', photos: []));
    await expectLater(
      store.setProductStatus(p.id, ProductStatus.published),
      throwsArgumentError,
    );
    await store.setProductStatus(p.id, ProductStatus.archived);
    expect(store.data.products.single.lowStock, isFalse);
    await expectLater(
      store.adjustStock(p.id, 1, 'Réception'),
      throwsArgumentError,
    );
    await expectLater(store.updateProduct(p.copyWith()), throwsStateError);
    await expectLater(
      store.setProductStatus(p.id, ProductStatus.published),
      throwsArgumentError,
    );
    await store.setProductStatus(p.id, ProductStatus.draft);
    expect(store.data.products.single.quantity, 10);
  });
  test('category/unit renaming updates archived products and used references cannot be removed', () async {
    final p = store.data.products.single;
    await store.setProductStatus(p.id, ProductStatus.archived);
    await store.saveReference(
      category: true,
      previous: 'Sans catégorie',
      value: 'Céréales',
    );
    await store.saveReference(category: false, previous: 'pièce', value: 'lot');
    expect(store.data.products.single.category, 'Céréales');
    expect(store.data.products.single.unit, 'lot');
    await expectLater(
      store.deleteReference(category: true, value: 'Céréales'),
      throwsArgumentError,
    );
    await store.saveReference(category: true, value: 'Autres');
    await expectLater(
      store.saveReference(category: true, value: ' autres '),
      throwsArgumentError,
    );
    await store.deleteReference(category: true, value: 'Autres');
    expect(store.data.categories, isNot(contains('Autres')));
  });
  test('live price and availability reach cart; removed products remain visible as invalid lines', () async {
    final session = ShoppingSession();
    final catalog = ProductCatalog(store);
    addTearDown(catalog.dispose);
    void sync() => session.updateCatalog(catalog.products);
    catalog.addListener(sync);
    final p = store.data.products.single;
    await store.setProductStatus(p.id, ProductStatus.published);
    await session.add(p.id);
    expect(session.total, 15000);
    await store.updateProduct(
      store.data.products.single.copyWith(price: 17000),
    );
    expect(session.total, 17000);
    await store.adjustStock(p.id, -10, 'Vente');
    expect(session.unavailableProductIds, [p.id]);
    await store.setProductStatus(p.id, ProductStatus.archived);
    expect(session.lines, isEmpty);
    expect(session.quantities[p.id], 1);
    await expectLater(session.add(p.id), throwsArgumentError);
    session.signInDemo('test@example.com');
    await expectLater(
      session.confirmDemo(
        const DeliveryAddress(
          name: 'Client',
          phone: '123',
          street: 'Rue',
          city: 'Cotonou',
          country: 'Bénin',
        ),
      ),
      throwsStateError,
    );
    await session.remove(p.id);
    expect(session.quantities, isEmpty);
  });
  test('imported photographs are resized and survive JSON roundtrip', () {
    final bytes = optimizeProductPhoto(
      img.encodePng(img.Image(width: 1600, height: 800)),
    );
    final decoded = img.decodeJpg(bytes)!;
    expect(decoded.width, 1200);
    expect(decoded.height, 600);
    expect(bytes.length, lessThanOrEqualTo(350000));
    final photo = CatalogPhoto(
      asset: '',
      bytes: bytes,
      description: 'Photo',
      author: 'Entreprise',
      source: 'Import local',
      sourceUrl: '',
      licenseUrl: '',
    );
    final p = store.data.products.single.copyWith(photos: [photo]);
    final saved = Product.fromJson(
      jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
    );
    expect(saved.photos.single.bytes, bytes);
    expect(saved.photos.single.isLocal, isTrue);
    expect(
      () => optimizeProductPhoto(Uint8List.fromList([1, 2, 3])),
      throwsArgumentError,
    );
  });
  test('published photo metadata and persisted cart survive a real repository restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = TradeStore(LocalTradeRepository(prefs));
    await first.load();
    final bytes = optimizeProductPhoto(
      img.encodePng(img.Image(width: 16, height: 16)),
    );
    await first.addProduct(
      name: 'Photo locale',
      sku: 'PHOTO',
      quantity: 1,
      threshold: 0,
      price: 100,
      description: 'Produit photographié',
      photos: [
        CatalogPhoto(
          asset: '',
          bytes: bytes,
          description: 'Produit',
          author: 'Entreprise',
          source: 'Import local',
          sourceUrl: '',
          licenseUrl: '',
        ),
      ],
    );
    final id = first.data.products.single.id;
    await first.setProductStatus(id, ProductStatus.published);
    final cart = ShoppingSession(repository: LocalPublicCartRepository(prefs));
    await cart.load();
    cart.updateCatalog([publicProduct(first.data.products.single)]);
    await cart.add(id);
    final second = TradeStore(LocalTradeRepository(prefs));
    await second.load();
    expect(second.data.products.single.photos.single.bytes, bytes);
    expect(second.data.catalogEnabled, isTrue);
    final secondCart = ShoppingSession(
      repository: LocalPublicCartRepository(prefs),
    );
    await secondCart.load();
    expect(secondCart.ready, isTrue);
    expect(secondCart.quantities[id], 1);
    secondCart.updateCatalog(
      second.data.products
          .where((p) => p.status == ProductStatus.published)
          .map(publicProduct)
          .toList(),
    );
    expect(secondCart.total, 100);
    await second.setProductStatus(id, ProductStatus.archived);
    final removedCart = ShoppingSession(
      repository: LocalPublicCartRepository(prefs),
    );
    await removedCart.load();
    removedCart.updateCatalog(
      second.data.products
          .where((p) => p.status == ProductStatus.published)
          .map(publicProduct)
          .toList(),
    );
    expect(removedCart.ready, isTrue);
    expect(removedCart.unavailableProductIds, [id]);
  });
}
