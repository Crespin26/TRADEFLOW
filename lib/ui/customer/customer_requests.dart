import 'package:flutter/material.dart';

import '../../application/shopping_session.dart';
import '../design_system/components.dart';
import '../shopping/shopping_scope.dart';
import '../forms.dart';
import 'customer_common.dart';

Future<void> showCustomerRequestForm(
  BuildContext context,
  String orderId,
) async {
  final session = ShoppingScope.of(context);
  final order = session.customerOrder(orderId);
  if (order == null || !session.customerReady) return;
  final options = [
    CustomerRequestKind.assistance,
    if (order.canRequestCancellation) CustomerRequestKind.cancellation,
    if (order.canRequestReturn) CustomerRequestKind.returnGoods,
  ];
  var kind = options.first;
  var attachExample = false;
  final message = TextEditingController();
  await showEditor(
    context: context,
    builder: (context) => SaveDialog(
      title: 'Nouvelle demande',
      description: 'Cette demande restera dans la session de démonstration. Aucun message ni justificatif ne sera transmis à une entreprise.',
      fields: [
        DropdownButtonFormField<CustomerRequestKind>(
          isExpanded: true,
          initialValue: kind,
          decoration: const InputDecoration(labelText: 'Type de demande'),
          items: [
            for (final value in options)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: (value) => kind = value!,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: message,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Motif ou question (fictif)',
          ),
          validator: (value) => (value?.trim().length ?? 0) < 10
              ? 'Décrivez la demande en au moins 10 caractères.'
              : null,
        ),
        StatefulBuilder(
          builder: (context, change) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Joindre un justificatif fictif'),
            subtitle: const Text(
              'Exemple fourni : justificatif-demo.txt · Aucun fichier personnel importé',
            ),
            value: attachExample,
            onChanged: (value) => change(() => attachExample = value ?? false),
          ),
        ),
      ],
      save: () async {
        session.submitRequest(
          orderId,
          kind,
          message.text,
          attachmentName: attachExample ? 'justificatif-demo.txt' : '',
        );
      },
    ),
  );
  message.dispose();
}

class CustomerRequestsPage extends StatelessWidget {
  const CustomerRequestsPage({super.key, this.orderId});
  final String? orderId;
  @override
  Widget build(BuildContext context) => CustomerPage(
    title: 'Mes demandes',
    child: CustomerGate(
      builder: (context, session) {
        final requests = session.requests
            .where((r) => orderId == null || orderId == r.orderId)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Annulations avant expédition, retours après livraison et assistance. Les demandes ne sont ni envoyées ni traitées par un service réel.',
            ),
            const SizedBox(height: 20),
            if (requests.isEmpty)
              const FlowStateView(
                title: 'Aucune demande',
                description: 'Ouvrez une commande pour créer une demande adaptée à son état.',
                icon: Icons.support_agent,
              ),
            for (final request in requests)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FlowBadge(
                          request.status.label,
                          tone:
                              request.status == CustomerRequestStatus.reviewing
                              ? FlowTone.warning
                              : FlowTone.neutral,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          request.kind.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(request.orderId),
                        const SizedBox(height: 8),
                        Text(request.message),
                        const SizedBox(height: 8),
                        Text('Créée le ${customerDate(request.createdAt)}'),
                        if (request.attachmentName.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Voir le justificatif fictif'),
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(request.attachmentName),
                                content: const Text(
                                  'JUSTIFICATIF DE DÉMONSTRATION\nExemple de preuve de livraison ou de colis. Aucun document réel n’est importé ou transmis.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Fermer'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (request.response.isNotEmpty) ...[
                          const Divider(height: 24),
                          Text(request.response),
                        ],
                      ],
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
