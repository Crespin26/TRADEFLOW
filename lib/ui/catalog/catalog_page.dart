import 'catalog_scope.dart';

import 'package:flutter/material.dart';

import '../../domain/public_catalog.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';
import 'product_widgets.dart';
import 'product_detail.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, this.initialCategory});
  final String? initialCategory;
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final search = TextEditingController();
  String? category;
  PublicAvailability? availability;
  CatalogPrice price = CatalogPrice.all;
  CatalogSort sort = CatalogSort.featured;
  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void reset() => setState(() {
    search.clear();
    category = null;
    availability = null;
    price = CatalogPrice.all;
    sort = CatalogSort.featured;
  });
  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.maybeOf(context);
    if (catalog?.store.loadError != null) {
      return FlowStateView(
        title: 'Catalogue indisponible',
        description: 'Les données locales ne peuvent pas être lues.',
        icon: Icons.cloud_off_outlined,
        actionLabel: 'Réessayer',
        onAction: catalog!.store.busy ? null : catalog.store.load,
      );
    }
    if (catalog?.managed == true && catalog!.products.isEmpty) {
      return const FlowStateView(
        title: 'Aucun produit publié',
        description:
            'L’entreprise n’a actuellement aucun produit dans son catalogue.',
        icon: Icons.inventory_2_outlined,
      );
    }
    final products = selectPublicProducts(
      CatalogScope.productsOf(context),
      query: search.text,
      category:
          CatalogScope.productsOf(context).any((p) => p.category == category)
          ? category
          : null,
      availability: availability,
      price: price,
      sort: sort,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlowBadge(
          CatalogScope.maybeOf(context)?.managed == true
              ? 'Catalogue local · Produits publiés'
              : 'Catalogue fictif · Prix indicatifs',
        ),
        const SizedBox(height: 20),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Rechercher un produit',
            hintText: 'Nom, référence, catégorie…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer la recherche',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(search.clear),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('Toutes les catégories'),
              selected: category == null,
              onSelected: (_) => setState(() => category = null),
            ),
            for (final value in CatalogScope.productsOf(
              context,
            ).map((p) => p.category).toSet())
              ChoiceChip(
                label: Text(value),
                selected: category == value,
                onSelected: (_) => setState(() => category = value),
              ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 680
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: DropdownButtonFormField<PublicAvailability>(
                    key: ValueKey('availability-${availability?.name}'),
                    isExpanded: true,
                    initialValue: availability,
                    decoration: const InputDecoration(
                      labelText: 'Disponibilité',
                    ),
                    items: [
                      const DropdownMenuItem(
                        child: Text('Toutes les disponibilités'),
                      ),
                      for (final value in PublicAvailability.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => availability = value),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: DropdownButtonFormField<CatalogPrice>(
                    key: ValueKey('price-${price.name}'),
                    isExpanded: true,
                    initialValue: price,
                    decoration: const InputDecoration(labelText: 'Prix (XOF)'),
                    items: const [
                      DropdownMenuItem(
                        value: CatalogPrice.all,
                        child: Text('Tous les prix'),
                      ),
                      DropdownMenuItem(
                        value: CatalogPrice.under10000,
                        child: Text('Moins de 10 000'),
                      ),
                      DropdownMenuItem(
                        value: CatalogPrice.from10000to50000,
                        child: Text('10 000 à 50 000'),
                      ),
                      DropdownMenuItem(
                        value: CatalogPrice.over50000,
                        child: Text('Plus de 50 000'),
                      ),
                    ],
                    onChanged: (value) => setState(() => price = value!),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: DropdownButtonFormField<CatalogSort>(
                    key: ValueKey('sort-${sort.name}'),
                    isExpanded: true,
                    initialValue: sort,
                    decoration: const InputDecoration(labelText: 'Trier par'),
                    items: const [
                      DropdownMenuItem(
                        value: CatalogSort.featured,
                        child: Text('Notre sélection'),
                      ),
                      DropdownMenuItem(
                        value: CatalogSort.name,
                        child: Text('Nom : A à Z'),
                      ),
                      DropdownMenuItem(
                        value: CatalogSort.priceAscending,
                        child: Text('Prix croissant'),
                      ),
                      DropdownMenuItem(
                        value: CatalogSort.priceDescending,
                        child: Text('Prix décroissant'),
                      ),
                    ],
                    onChanged: (value) => setState(() => sort = value!),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                '${products.length} produit(s)',
                style: const TextStyle(color: FlowColors.muted),
              ),
            ),
            TextButton.icon(
              onPressed: reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          FlowStateView(
            title: 'Aucun produit trouvé',
            description:
                'Essayez une autre recherche ou élargissez vos filtres.',
            icon: Icons.search_off,
            actionLabel: 'Afficher tous les produits',
            onAction: reset,
          )
        else
          PublicProductGrid(
            products: products,
            onOpen: (p) => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ProductDetailPage(product: p),
              ),
            ),
          ),
      ],
    );
  }
}
