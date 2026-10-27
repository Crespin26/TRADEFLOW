import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/shopping_session.dart';
import '../catalog/product_widgets.dart';
import '../design_system/components.dart';
import 'customer_common.dart';

class CustomerDocumentsPage extends StatelessWidget {
  const CustomerDocumentsPage({super.key, this.orderId});
  final String? orderId;
  @override
  Widget build(BuildContext context) => CustomerPage(
    title: 'Mes documents',
    child: CustomerGate(
      builder: (context, session) {
        final orders = session.customerOrders
            .where((o) => orderId == null || o.id == orderId)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Aperçus de démonstration uniquement, sans valeur comptable. Les vrais devis, factures et exports PDF seront développés dans les prochaines phases.',
            ),
            const SizedBox(height: 20),
            if (orders.isEmpty)
              const FlowStateView(
                title: 'Aucun document',
                description:
                    'Les documents des commandes simulées apparaîtront ici.',
                icon: Icons.description_outlined,
              ),
            for (final order in orders)
              for (final kind in order.documentKinds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.description_outlined),
                      title: Text(kind.label),
                      subtitle: Text(order.id),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => CustomerDocumentPage(
                            orderId: order.id,
                            kind: kind,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    ),
  );
}

class CustomerDocumentPage extends StatelessWidget {
  const CustomerDocumentPage({
    super.key,
    required this.orderId,
    required this.kind,
  });
  final String orderId;
  final CustomerDocumentKind kind;
  @override
  Widget build(BuildContext context) => CustomerPage(
    title: kind.label,
    child: CustomerGate(
      builder: (context, session) {
        final order = session.customerOrder(orderId);
        if (order == null || !order.documentKinds.contains(kind)) {
          return const FlowStateView(
            title: 'Document indisponible',
            description:
                'Ce document ne fait pas partie de la session actuelle.',
          );
        }
        final text =
            'DÉMONSTRATION — SANS VALEUR COMPTABLE\n${kind.label}\nTradeFlow Démo\n$orderId\n${customerDate(order.receipt.createdAt)}\n${order.receipt.email}\n${order.receipt.address.label}\n\n${order.receipt.lines.map((l) => '${l.quantity} × ${l.product.name} · ${publicPrice(l.total)}').join('\n')}\n\nTotal des produits : ${publicPrice(order.receipt.total)}\nTransport et taxes non calculés. Aucun paiement effectué.';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FlowBadge(
              'SPÉCIMEN · SANS VALEUR COMPTABLE',
              tone: FlowTone.warning,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(text),
              ),
            ),
            const SizedBox(height: 20),
            FlowButton(
              label: 'Copier le récapitulatif',
              secondary: true,
              icon: Icons.copy,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Récapitulatif de démonstration copié.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    ),
  );
}
