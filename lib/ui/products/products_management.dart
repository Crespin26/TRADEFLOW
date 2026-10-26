import '../stock/stock_page.dart';

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/trade_store.dart';
import '../../domain/product_catalog.dart';
import '../../domain/public_catalog.dart';
import '../catalog/catalog_photo.dart';
import '../catalog/product_detail.dart';
import '../catalog/product_widgets.dart';
import '../design_system/components.dart';
import '../forms.dart';
import 'product_editor.dart';

class ProductsManagement extends StatefulWidget {
  const ProductsManagement({super.key, required this.store, this.query = ''});
  final TradeStore store;
  final String query;
  @override
  State<ProductsManagement> createState() => _ProductsManagementState();
}

class _ProductsManagementState extends State<ProductsManagement> {
  ProductStatus? status;
  String? category;
  bool alphabetical = false;
  Future<void> action(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> transition(Product p, ProductStatus next) async {
    final confirmed = await showFlowConfirmation(
      context,
      title:
          '${next == ProductStatus.published
              ? 'Publier'
              : next == ProductStatus.archived
              ? 'Archiver'
              : p.status == ProductStatus.archived
              ? 'Restaurer'
              : 'Retirer du catalogue'} ce produit ?',
      description: next == ProductStatus.published
          ? 'Le produit sera visible dans le catalogue de cet appareil. La première publication remplace le catalogue d’exemple. Le prix d’achat et le stock exact restent internes.'
          : next == ProductStatus.archived
          ? 'Le produit sera masqué du catalogue et des nouvelles commandes. Son historique sera conservé.'
          : 'Le produit sera en brouillon et restera accessible dans la gestion locale.',
      confirmLabel: 'Confirmer',
    );
    if (confirmed && mounted) {
      await action(() => widget.store.setProductStatus(p.id, next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final effectiveCategory = store.data.categories.contains(category)
        ? category
        : null;
    final items = store.data.products
        .where(
          (p) =>
              (status == null || p.status == status) &&
              (effectiveCategory == null || effectiveCategory == p.category) &&
              normalizeCatalogText('${p.name} ${p.sku} ${p.category}')
                  .contains(normalizeCatalogText(widget.query)),
        )
        .toList();
    if (alphabetical) {
      items.sort(
        (a, b) =>
            normalizeCatalogText(a.name)
                .compareTo(normalizeCatalogText(b.name)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => StockPage(store: store)),
            ),
            icon: const Icon(Icons.warehouse_outlined),
            label: const Text('Gérer les stocks'),
          ),
        ),
        Text('${items.length} produit(s) · Prix unitaires en XOF'),
        Text(
          store.data.catalogEnabled
              ? 'Catalogue local activé : seuls les produits publiés sont visibles.'
              : 'Le catalogue public affiche les exemples jusqu’à votre première publication.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tous les statuts'),
              selected: status == null,
              onSelected: (_) => setState(() => status = null),
            ),
            for (final value in ProductStatus.values)
              ChoiceChip(
                label: Text(value.label),
                selected: status == value,
                onSelected: (_) => setState(() => status = value),
              ),
            FilterChip(
              label: const Text('Trier par nom'),
              selected: alphabetical,
              onSelected: (v) => setState(() => alphabetical = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('${store.data.categories.join()}-$category'),
          initialValue: store.data.categories.contains(category)
              ? category
              : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Filtrer par catégorie'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Toutes les catégories'),
            ),
            for (final c in store.data.categories)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() => category = v),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: store.busy
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReferencesPage(store: store),
                    ),
                  ),
            icon: const Icon(Icons.category_outlined),
            label: const Text('Catégories et unités'),
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucun produit à afficher. Ajoutez un produit ou modifiez votre recherche.',
            ),
          ),
        for (final p in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (p.photos.isNotEmpty) ...[
                          SizedBox(
                            width: 70,
                            child: CatalogPhotoView(
                              photo: p.photos.first,
                              height: 70,
                              showCaption: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(p.sku),
                            ],
                          ),
                        ),
                        if (p.status != ProductStatus.archived)
                          IconButton(
                            tooltip: 'Ajuster le stock',
                            onPressed: store.busy
                                ? null
                                : () => stockForm(context, store, p),
                            icon: const Icon(Icons.tune_rounded),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FlowBadge(p.status.label),
                        Text('${p.category} · ${p.unit}'),
                        Text(publicPrice(p.price)),
                        Text('${p.quantity} en stock'),
                        Text('Seuil : ${p.threshold}'),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: store.busy
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProductDetailPage(
                                      product: publicProduct(p),
                                      preview: true,
                                    ),
                                  ),
                                ),
                          child: const Text('Aperçu'),
                        ),
                        if (p.status != ProductStatus.archived) ...[
                          TextButton(
                            onPressed: store.busy
                                ? null
                                : () =>
                                      productEditor(context, store, product: p),
                            child: const Text('Modifier'),
                          ),
                          TextButton(
                            onPressed: store.busy
                                ? null
                                : () => transition(
                                    p,
                                    p.status == ProductStatus.published
                                        ? ProductStatus.draft
                                        : ProductStatus.published,
                                  ),
                            child: Text(
                              p.status == ProductStatus.published
                                  ? 'Retirer du catalogue'
                                  : 'Publier',
                            ),
                          ),
                          TextButton(
                            onPressed: store.busy
                                ? null
                                : () => transition(p, ProductStatus.archived),
                            child: const Text('Archiver'),
                          ),
                        ] else
                          TextButton(
                            onPressed: store.busy
                                ? null
                                : () => transition(p, ProductStatus.draft),
                            child: const Text('Restaurer'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ReferencesPage extends StatelessWidget {
  const ReferencesPage({super.key, required this.store});
  final TradeStore store;
  Future<void> edit(
    BuildContext context,
    bool category, [
    String? previous,
  ]) async {
    final controller = TextEditingController(text: previous);
    await showEditor(
      context: context,
      builder: (_) => SaveDialog(
        title: previous == null ? 'Ajouter' : 'Renommer',
        description: 'Le renommage sera appliqué à tous les produits concernés, y compris les archives.',
        fields: [field(controller, category ? 'Catégorie' : 'Unité')],
        save: () => store.saveReference(
          category: category,
          previous: previous,
          value: controller.text,
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> remove(BuildContext context, bool category, String value) async {
    final confirmed = await showFlowConfirmation(
      context,
      title: 'Supprimer « $value » ?',
      description: 'La suppression est possible uniquement si aucun produit n’utilise cette référence.',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await store.deleteReference(category: category, value: value);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Catégories et unités')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final category in [true, false]) ...[
                Text(
                  category ? 'Catégories' : 'Unités de vente',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: store.busy
                        ? null
                        : () => edit(context, category),
                    icon: const Icon(Icons.add),
                    label: Text(
                      category ? 'Ajouter une catégorie' : 'Ajouter une unité',
                    ),
                  ),
                ),
                for (final value
                    in category ? store.data.categories : store.data.units)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(value),
                          Text(
                            '${store.data.products.where((p) => (category ? p.category : p.unit) == value).length} produit(s)',
                          ),
                          Wrap(
                            children: [
                              TextButton(
                                onPressed: store.busy
                                    ? null
                                    : () => edit(context, category, value),
                                child: const Text('Renommer'),
                              ),
                              TextButton(
                                onPressed: store.busy
                                    ? null
                                    : () => remove(context, category, value),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
