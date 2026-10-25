import 'package:flutter/material.dart';

import '../../domain/shopping_session.dart';
import '../catalog/product_widgets.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';
import '../forms.dart' show friendlyError;
import 'customer_common.dart';
import 'customer_documents.dart';
import 'customer_requests.dart';

class CustomerOrdersPage extends StatelessWidget {
  const CustomerOrdersPage({super.key});
  @override
  Widget build(BuildContext context) => const CustomerPage(
    title: 'Mes commandes',
    child: CustomerOrdersContents(),
  );
}

class CustomerOrdersContents extends StatefulWidget {
  const CustomerOrdersContents({super.key});
  @override
  State<CustomerOrdersContents> createState() => _CustomerOrdersContentsState();
}

class _CustomerOrdersContentsState extends State<CustomerOrdersContents> {
  CustomerOrderStatus? status;
  String query = '';
  @override
  Widget build(BuildContext context) => CustomerGate(
    builder: (context, session) {
      final orders = session.customerOrders
          .where(
            (o) =>
                (status == null || o.status == status) &&
                '${o.id} ${o.receipt.lines.map((l) => l.product.name).join(' ')}'
                    .toLowerCase()
                    .contains(query.toLowerCase().trim()),
          )
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Rechercher mes commandes',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Toutes'),
                selected: status == null,
                onSelected: (_) => setState(() => status = null),
              ),
              for (final value in CustomerOrderStatus.values)
                ChoiceChip(
                  label: Text(value.label),
                  selected: status == value,
                  onSelected: (_) => setState(() => status = value),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (session.customerOrders.isEmpty) ...[
            const FlowStateView(
              title: 'Votre historique est vide',
              description: 'Confirmez une commande fictive depuis le panier ou chargez des exemples pour explorer les états de livraison.',
              icon: Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 16),
            FlowButton(
              label: 'Charger des commandes fictives',
              secondary: true,
              onPressed: session.busy
                  ? null
                  : () {
                      try {
                        session.loadCustomerExamples();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyError(e))),
                        );
                      }
                    },
            ),
          ] else if (orders.isEmpty)
            const FlowStateView(
              title: 'Aucune commande correspondante',
              description: 'Modifiez la recherche ou le filtre de statut.',
            ),
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CustomerOrderCard(order: order),
            ),
        ],
      );
    },
  );
}

class CustomerOrderCard extends StatelessWidget {
  const CustomerOrderCard({super.key, required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CustomerOrderPage(orderId: order.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowBadge(order.status.label, tone: orderTone(order.status)),
            const SizedBox(height: 12),
            Text(order.id, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              order.receipt.lines
                  .map((l) => '${l.quantity} × ${l.product.name}')
                  .join('\n'),
            ),
            const SizedBox(height: 12),
            Text(
              publicPrice(order.receipt.total),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${customerDate(order.receipt.createdAt)} · Ouvrir le détail',
              style: const TextStyle(color: FlowColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class CustomerOrderPage extends StatelessWidget {
  const CustomerOrderPage({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context) => CustomerPage(
    title: 'Détail de ma commande',
    child: CustomerGate(
      builder: (context, session) {
        final order = session.customerOrder(orderId);
        if (order == null) {
          return const FlowStateView(
            title: 'Commande introuvable',
            description:
                'Cette commande ne fait pas partie de la session actuelle.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FlowBadge(order.status.label, tone: orderTone(order.status)),
            const SizedBox(height: 16),
            SelectableText(
              order.id,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Créée le ${customerDate(order.receipt.createdAt)}'),
            const SizedBox(height: 24),
            Text(
              'Suivi de livraison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (order.status == CustomerOrderStatus.cancelled)
              const FlowStateView(
                title: 'Commande annulée',
                description: 'Aucune livraison prévue.',
              )
            else
              for (final value in [
                CustomerOrderStatus.confirmed,
                CustomerOrderStatus.preparing,
                CustomerOrderStatus.shipped,
                CustomerOrderStatus.delivered,
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    order.status.index >= value.index
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: order.status.index >= value.index
                        ? FlowColors.primary
                        : FlowColors.muted,
                  ),
                  title: Text(value.label),
                  subtitle: Text(
                    order.status.index >= value.index
                        ? customerDate(
                            order.receipt.createdAt.add(
                              Duration(days: value.index),
                            ),
                          )
                        : 'À venir · Simulation',
                  ),
                ),
            if (order.carrier.isNotEmpty) ...[
              Text('Transporteur fictif : ${order.carrier}'),
              const SizedBox(height: 8),
              SelectableText('Référence fictive : ${order.tracking}'),
            ],
            if (order.expectedDelivery != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Date indicative : ${customerDate(order.expectedDelivery!)}',
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Adresse au moment de la commande',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(order.receipt.address.label),
            const SizedBox(height: 24),
            for (final line in order.receipt.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${line.quantity} × ${line.product.name}\n${line.product.unit} · ${publicPrice(line.total)}',
                ),
              ),
            Text(
              'Total des produits : ${publicPrice(order.receipt.total)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Frais et taxes non calculés. Aucun montant à payer dans cette simulation.',
            ),
            const SizedBox(height: 24),
            FlowButton(
              label: 'Documents de cette commande',
              secondary: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CustomerDocumentsPage(orderId: orderId),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FlowButton(
              label: 'Faire une demande',
              icon: Icons.support_agent,
              onPressed: () => showCustomerRequestForm(context, orderId),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CustomerRequestsPage(orderId: orderId),
                ),
              ),
              child: const Text('Suivre mes demandes'),
            ),
          ],
        );
      },
    ),
  );
}
