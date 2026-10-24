import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/public_catalog.dart';

void main() {
  test('search ignores accents and case and matches public references', () {
    expect(
      selectPublicProducts(
        demoPublicProducts,
        query: '  RIZ parfume ',
      ).single.id,
      'rice',
    );
    expect(
      selectPublicProducts(demoPublicProducts, query: 'pub-sol').single.id,
      'solar',
    );
    expect(
      selectPublicProducts(demoPublicProducts, query: 'equipement').length,
      2,
    );
  });
  test('category, availability and price filters combine', () {
    final result = selectPublicProducts(
      demoPublicProducts,
      category: 'Alimentation',
      availability: PublicAvailability.available,
      price: CatalogPrice.under10000,
    );
    expect(result.single.id, 'oil');
    expect(
      selectPublicProducts(
        demoPublicProducts,
        category: 'Équipement',
        availability: PublicAvailability.unavailable,
      ),
      isEmpty,
    );
  });
  test('price bands cover the catalogue without overlap', () {
    final filtered =
        [
              CatalogPrice.under10000,
              CatalogPrice.from10000to50000,
              CatalogPrice.over50000,
            ]
            .expand(
              (price) => selectPublicProducts(demoPublicProducts, price: price),
            )
            .toList();
    expect(filtered.length, demoPublicProducts.length);
    expect(filtered.map((p) => p.id).toSet().length, demoPublicProducts.length);
  });
  test('sort is deterministic and does not mutate the original data', () {
    final original = demoPublicProducts.map((p) => p.id).toList();
    final asc = selectPublicProducts(
      demoPublicProducts,
      sort: CatalogSort.priceAscending,
    );
    expect(asc.first.id, 'oil');
    expect(asc.last.id, 'solar');
    final desc = selectPublicProducts(
      demoPublicProducts,
      sort: CatalogSort.priceDescending,
    );
    expect(
      desc.map((p) => p.id).toList(),
      asc.reversed.map((p) => p.id).toList(),
    );
    expect(demoPublicProducts.map((p) => p.id).toList(), original);
    expect(
      selectPublicProducts(demoPublicProducts).take(4).every((p) => p.featured),
      isTrue,
    );
  });
}
