import 'catalog_scope.dart';

import 'package:flutter/material.dart';

import '../../domain/public_catalog.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';
import 'product_widgets.dart';
import 'catalog_photo.dart';
import '../shopping/shopping_scope.dart';
import '../shopping/cart_page.dart';
import '../forms.dart' show friendlyError;

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    this.preview = false,
  });
  final PublicProduct product;
  final bool preview;
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  @override
  Widget build(BuildContext context) {
    final current = CatalogScope.productsOf(context)
        .where((p) => p.id == widget.product.id)
        .firstOrNull;
    if (!widget.preview && current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche produit')),
        body: const Center(
          child: Text('Ce produit a été retiré du catalogue.'),
        ),
      );
    }
    final p = widget.preview ? widget.product : current!;
    final shopping = ShoppingScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche produit'),
        actions: [
          IconButton(
            tooltip: 'Voir mon panier',
            icon: Badge(
              isLabelVisible: shopping.itemCount > 0,
              label: Text('${shopping.itemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const CartPage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FlowLayout.contentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FlowBadge(
                  widget.preview
                      ? 'Aperçu · Produit interne'
                      : CatalogScope.maybeOf(context)?.managed == true
                      ? 'Produit du catalogue local'
                      : 'Référence fictive · Photographie illustrative',
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gallery = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CatalogPhotoView(
                            photo: p.photo,
                            height: 320,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (p.photos.length > 1)
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final photo in p.photos)
                                SizedBox(
                                  width: 80,
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            PhotoViewerPage(photo: photo),
                                      ),
                                    ),
                                    child: CatalogPhotoView(
                                      photo: photo,
                                      height: 80,
                                      showCaption: false,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        if (p.photo != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PhotoViewerPage(photo: p.photo!),
                              ),
                            ),
                            icon: const Icon(Icons.zoom_in),
                            label: const Text('Agrandir la photo'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Photo : ${p.photo!.author} · ${p.photo!.source}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: FlowColors.muted,
                            ),
                          ),
                        ],
                      ],
                    );
                    final info = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.category,
                          style: const TextStyle(
                            color: FlowColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.name,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'Réf. ${p.sku}',
                          style: const TextStyle(color: FlowColors.muted),
                        ),
                        const SizedBox(height: 16),
                        FlowBadge(
                          p.availability.label,
                          tone: availabilityTone(p.availability),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          publicPrice(p.price),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Prix indicatif · ${p.unit}',
                          style: const TextStyle(color: FlowColors.muted),
                        ),
                        const SizedBox(height: 20),
                        Text(p.description),
                        const SizedBox(height: 24),
                        if (widget.preview)
                          const Text(
                            'Aperçu uniquement. Publiez le produit pour le rendre accessible dans le catalogue.',
                          )
                        else if (p.availability ==
                            PublicAvailability.unavailable)
                          const FlowStateView(
                            title: 'Produit temporairement indisponible',
                            description: 'Cet article ne peut pas être ajouté au panier.',
                            icon: Icons.inventory_2_outlined,
                          )
                        else ...[
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Quantité :'),
                              IconButton(
                                tooltip: 'Diminuer la quantité',
                                onPressed: quantity <= 1
                                    ? null
                                    : () => setState(() => quantity--),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$quantity'),
                              IconButton(
                                tooltip: 'Augmenter la quantité',
                                onPressed: quantity >= 999
                                    ? null
                                    : () => setState(() => quantity++),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FlowButton(
                            label: 'Ajouter au panier',
                            icon: Icons.add_shopping_cart,
                            onPressed: shopping.busy || !shopping.ready
                                ? null
                                : () async {
                                    try {
                                      await shopping.add(
                                        p.id,
                                        quantity: quantity,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${p.name} ajouté au panier.',
                                                ),
                                              ),
                                            );
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(friendlyError(error)),
                                          ),
                                        );
                                      }
                                    }
                                  },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Démonstration : aucun stock réservé. Vous pourrez vous connecter au moment de confirmer.',
                          ),
                        ],
                      ],
                    );
                    if (constraints.maxWidth < 720) {
                      return Column(
                        children: [gallery, const SizedBox(height: 24), info],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: gallery),
                        const SizedBox(width: 32),
                        Expanded(child: info),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Caractéristiques',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final entry in {
                          'Origine indicative': p.origin,
                          ...p.specifications,
                        }.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '${entry.key} :',
                                  style: const TextStyle(
                                    color: FlowColors.muted,
                                  ),
                                ),
                                Text(entry.value),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Conditions commerciales',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  CatalogScope.maybeOf(context)?.managed == true ||
                          widget.preview
                      ? 'Transport, taxes et délais sont à confirmer auprès de l’entreprise. Le parcours de commande reste simulé.'
                      : 'Les prix, disponibilités et caractéristiques présentés sont fictifs. Dans le service final, transport, taxes, délais et conditions de vente seront précisés avant toute confirmation.',
                ),
                const SizedBox(height: 32),
                Text(
                  'À découvrir aussi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                PublicProductGrid(
                  products: CatalogScope.productsOf(context)
                      .where(
                        (item) =>
                            item.id != p.id && item.category == p.category,
                      )
                      .take(2)
                      .toList(),
                  onOpen: (item) => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailPage(product: item),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
