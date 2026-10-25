import 'package:flutter/material.dart';

import '../../domain/public_catalog.dart';
import '../catalog/product_widgets.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';
import '../forms.dart' show friendlyError;
import 'shopping_scope.dart';
import 'auth_page.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon panier')),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FlowLayout.contentWidth),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [CartContents(onBrowse: () => Navigator.pop(context))],
          ),
        ),
      ),
    ),
  );
}

class CartContents extends StatelessWidget {
  const CartContents({super.key, required this.onBrowse});
  final VoidCallback onBrowse;
  Future<void> act(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    }
  }

  Future<void> checkout(BuildContext context) async {
    final session = ShoppingScope.of(context);
    if (!session.signedIn || !session.verified) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const DemoAuthPage()),
      );
      if (result != true || !context.mounted) return;
    }
    if (!context.mounted ||
        !session.signedIn ||
        !session.verified ||
        session.lines.isEmpty) {
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ShoppingScope.of(context);
    if (!session.ready) {
      return Column(
        children: [
          FlowStateView(
            title: 'Panier indisponible',
            description: session.storageError ?? 'Chargement du panier…',
            icon: Icons.error_outline,
            actionLabel: 'Réessayer',
            onAction: session.busy ? null : session.load,
          ),
          TextButton(
            onPressed: session.busy
                ? null
                : () async {
                    final confirmed = await showFlowConfirmation(
                      context,
                      title: 'Réinitialiser le panier ?',
                      description: 'Le panier local illisible sera remplacé par un panier vide.',
                      confirmLabel: 'Réinitialiser',
                    );
                    if (confirmed && context.mounted) {
                      await act(context, session.reset);
                    }
                  },
            child: const Text('Réinitialiser le panier local'),
          ),
        ],
      );
    }
    if (session.lines.isEmpty) {
      return FlowStateView(
        title: 'Votre panier est vide',
        description: 'Découvrez le catalogue et ajoutez les produits qui vous intéressent.',
        icon: Icons.shopping_bag_outlined,
        actionLabel: 'Explorer le catalogue',
        onAction: onBrowse,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FlowBadge('Panier de démonstration'),
        const SizedBox(height: 16),
        const Text(
          'Les quantités ne réservent aucun stock. Les prix sont indicatifs et aucun achat réel n’est effectué.',
        ),
        const SizedBox(height: 20),
        for (final line in session.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${publicPrice(line.product.price)} · ${line.product.unit}',
                    ),
                    const SizedBox(height: 8),
                    FlowBadge(
                      line.product.availability.label,
                      tone: availabilityTone(line.product.availability),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Diminuer ${line.product.name}',
                          onPressed: session.busy || line.quantity <= 1
                              ? null
                              : () => act(
                                  context,
                                  () => session.setQuantity(
                                    line.product.id,
                                    line.quantity - 1,
                                  ),
                                ),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Semantics(
                          label: 'Quantité de ${line.product.name}',
                          child: Text('${line.quantity}'),
                        ),
                        IconButton(
                          tooltip: 'Augmenter ${line.product.name}',
                          onPressed: session.busy || line.quantity >= 999
                              ? null
                              : () => act(
                                  context,
                                  () => session.setQuantity(
                                    line.product.id,
                                    line.quantity + 1,
                                  ),
                                ),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        TextButton.icon(
                          onPressed: session.busy
                              ? null
                              : () => act(
                                  context,
                                  () => session.remove(line.product.id),
                                ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Retirer'),
                        ),
                      ],
                    ),
                    Text(
                      'Sous-total : ${publicPrice(line.total)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Total des produits : ${publicPrice(session.total)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Transport et taxes non calculés. Aucun paiement ne sera demandé.',
                ),
                if (session.lines.any(
                  (line) =>
                      line.product.availability == PublicAvailability.onOrder,
                )) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Certains articles sont sur commande : les délais réels restent à confirmer.',
                  ),
                ],
                const SizedBox(height: 20),
                FlowButton(
                  label: session.signedIn && session.verified
                      ? 'Préparer la commande'
                      : 'Se connecter pour continuer',
                  icon: Icons.arrow_forward,
                  onPressed: session.busy ? null : () => checkout(context),
                ),
                TextButton(
                  onPressed: onBrowse,
                  child: const Text('Continuer mes achats'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
