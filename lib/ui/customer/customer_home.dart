import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../design_system/theme.dart';
import 'customer_common.dart';
import 'customer_orders.dart';
import 'customer_addresses.dart';
import 'customer_documents.dart';
import 'customer_requests.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key, required this.onBrowse});
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => CustomerGate(
    builder: (context, session) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          session.displayName.isEmpty
              ? 'Bienvenue dans votre espace client'
              : 'Bonjour ${session.displayName}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Retrouvez vos commandes et informations de cette session de démonstration. Aucune donnée n’est envoyée à une entreprise.',
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FlowBadge('${session.customerOrders.length} commande(s)'),
            FlowBadge('${session.requests.length} demande(s)'),
            FlowBadge(
              '${session.unreadNoticeCount} notification(s) non lue(s)',
              tone: FlowTone.success,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const CustomerLinks(),
        const SizedBox(height: 24),
        FlowButton(
          label: 'Découvrir le catalogue',
          secondary: true,
          onPressed: onBrowse,
        ),
        if (session.customerOrders.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Ma dernière commande',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          CustomerOrderCard(order: session.customerOrders.first),
        ],
      ],
    ),
  );
}

class CustomerLinks extends StatelessWidget {
  const CustomerLinks({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final entry in <(String, IconData, Widget)>[
        (
          'Mes commandes',
          Icons.local_shipping_outlined,
          const CustomerOrdersPage(),
        ),
        (
          'Mes adresses',
          Icons.location_on_outlined,
          const CustomerAddressesPage(),
        ),
        (
          'Mes documents',
          Icons.description_outlined,
          const CustomerDocumentsPage(),
        ),
        ('Mes demandes', Icons.support_agent, const CustomerRequestsPage()),
        (
          'Mes notifications',
          Icons.notifications_outlined,
          const CustomerNotificationsPage(),
        ),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              leading: Icon(entry.$2, color: FlowColors.primary),
              title: Text(entry.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => entry.$3),
              ),
            ),
          ),
        ),
    ],
  );
}

class CustomerNotificationsPage extends StatelessWidget {
  const CustomerNotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => CustomerPage(
    title: 'Mes notifications',
    child: CustomerGate(
      builder: (context, session) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Événements de la session uniquement. Aucune notification push ni aucun e-mail ne sont envoyés.',
          ),
          const SizedBox(height: 16),
          if (session.notices.isEmpty)
            const FlowStateView(
              title: 'Aucune notification',
              description: 'Les commandes et demandes simulées alimenteront cette liste.',
              icon: Icons.notifications_none,
            ),
          if (session.notices.isNotEmpty)
            TextButton(
              onPressed: session.busy ? null : session.markAllNoticesRead,
              child: const Text('Tout marquer comme lu'),
            ),
          for (final notice in session.notices)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    session.noticeRead(notice.id)
                        ? Icons.drafts_outlined
                        : Icons.mark_email_unread_outlined,
                  ),
                  title: Text(notice.title),
                  subtitle: Text(
                    '${notice.description}\n${customerDate(notice.date)}',
                  ),
                  onTap: session.busy
                      ? null
                      : () {
                          session.markNoticeRead(notice.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CustomerOrderPage(orderId: notice.orderId),
                            ),
                          );
                        },
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
