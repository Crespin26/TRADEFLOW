import 'package:flutter/material.dart';

import '../../domain/public_catalog.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';
import 'product_widgets.dart';
import '../shopping/shopping_scope.dart';
import '../shopping/cart_page.dart';
import '../forms.dart' show friendlyError;

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});
  final PublicProduct product;
  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int visual = 0;
  int quantity = 1;
  @override
  Widget build(BuildContext context) {
    final p = widget.product;
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
                const FlowBadge(
                  'Produit fictif · Illustration de démonstration',
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gallery = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: ProductIllustration(
                            product: p,
                            variant: visual,
                            height: 270,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < 3; i++)
                              ChoiceChip(
                                label: Text(
                                  [
                                    'Vue principale',
                                    'Conditionnement',
                                    'Présentation',
                                  ][i],
                                ),
                                selected: visual == i,
                                onSelected: (_) => setState(() => visual = i),
                              ),
                          ],
                        ),
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
                        if (p.availability == PublicAvailability.unavailable)
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
                const Text(
                  'Les prix, disponibilités et caractéristiques présentés sont fictifs. Dans le service final, transport, taxes, délais et conditions de vente seront précisés avant toute confirmation.',
                ),
                const SizedBox(height: 32),
                Text(
                  'À découvrir aussi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                PublicProductGrid(
                  products: demoPublicProducts
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
