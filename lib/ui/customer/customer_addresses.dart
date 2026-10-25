import 'package:flutter/material.dart';

import '../../domain/shopping_session.dart';
import '../design_system/components.dart';
import '../forms.dart';
import '../shopping/shopping_scope.dart';
import 'customer_common.dart';

Future<void> showCustomerProfileForm(BuildContext context) async {
  final session = ShoppingScope.of(context);
  if (!session.customerReady) return;
  final name = TextEditingController(text: session.displayName),
      phone = TextEditingController(text: session.phone);
  await showEditor(
    context: context,
    builder: (_) => SaveDialog(
      title: 'Modifier mon profil',
      description: 'Données fictives conservées uniquement pendant cette session. L’adresse e-mail identifie la session et ne se modifie pas ici.',
      fields: [
        field(name, 'Nom complet'),
        field(
          phone,
          'Téléphone',
          keyboard: TextInputType.phone,
          required: false,
        ),
      ],
      save: () async {
        session.updateCustomerProfile(name.text, phone.text);
      },
    ),
  );
  name.dispose();
  phone.dispose();
}

Future<void> showCustomerAddressForm(
  BuildContext context, {
  CustomerAddress? existing,
}) async {
  final session = ShoppingScope.of(context);
  if (!session.customerReady) return;
  final label = TextEditingController(text: existing?.label ?? ''),
      name = TextEditingController(
        text: existing?.address.name ?? session.displayName,
      ),
      phone = TextEditingController(
        text: existing?.address.phone ?? session.phone,
      ),
      street = TextEditingController(text: existing?.address.street ?? ''),
      city = TextEditingController(text: existing?.address.city ?? ''),
      country = TextEditingController(
        text: existing?.address.country ?? 'Bénin',
      );
  await showEditor(
    context: context,
    builder: (_) => SaveDialog(
      title: existing == null ? 'Ajouter une adresse' : 'Modifier l’adresse',
      description: 'Utilisez uniquement des informations fictives. Les adresses seront effacées à la déconnexion.',
      fields: [
        field(label, 'Libellé (ex. : Boutique)'),
        field(name, 'Destinataire'),
        field(phone, 'Téléphone', keyboard: TextInputType.phone),
        field(street, 'Adresse'),
        field(city, 'Ville'),
        field(country, 'Pays'),
      ],
      save: () async {
        session.saveAddress(
          id: existing?.id,
          label: label.text,
          address: DeliveryAddress(
            name: name.text.trim(),
            phone: phone.text.trim(),
            street: street.text.trim(),
            city: city.text.trim(),
            country: country.text.trim(),
          ),
        );
      },
    ),
  );
  for (final c in [label, name, phone, street, city, country]) {
    c.dispose();
  }
}

class CustomerAddressesPage extends StatelessWidget {
  const CustomerAddressesPage({super.key});
  @override
  Widget build(BuildContext context) => CustomerPage(
    title: 'Mes adresses',
    child: CustomerGate(
      builder: (context, session) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Adresses de livraison et de facturation de la session. Les anciennes commandes conservent leur adresse d’origine.',
          ),
          const SizedBox(height: 20),
          FlowButton(
            label: 'Ajouter une adresse',
            icon: Icons.add_location_alt_outlined,
            onPressed: session.busy
                ? null
                : () => showCustomerAddressForm(context),
          ),
          const SizedBox(height: 20),
          if (session.addresses.isEmpty)
            const FlowStateView(
              title: 'Aucune adresse enregistrée',
              description: 'Ajoutez une adresse fictive pour la réutiliser lors de votre prochaine commande.',
              icon: Icons.location_on_outlined,
            ),
          for (final item in session.addresses)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(item.address.label),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (session.defaultDeliveryId == item.id)
                            const FlowBadge(
                              'Livraison par défaut',
                              tone: FlowTone.success,
                            ),
                          if (session.defaultBillingId == item.id)
                            const FlowBadge('Facturation par défaut'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton(
                            onPressed: session.busy
                                ? null
                                : () => showCustomerAddressForm(
                                    context,
                                    existing: item,
                                  ),
                            child: const Text('Modifier'),
                          ),
                          TextButton(
                            onPressed: session.busy
                                ? null
                                : () => session.setDefaultAddress(item.id),
                            child: const Text('Pour la livraison'),
                          ),
                          TextButton(
                            onPressed: session.busy
                                ? null
                                : () => session.setDefaultAddress(
                                    item.id,
                                    billing: true,
                                  ),
                            child: const Text('Pour la facturation'),
                          ),
                          TextButton(
                            onPressed: session.busy
                                ? null
                                : () async {
                                    final confirm = await showFlowConfirmation(
                                      context,
                                      title: 'Supprimer cette adresse ?',
                                      description: 'Les commandes existantes conserveront leur adresse historique.',
                                      confirmLabel: 'Supprimer',
                                    );
                                    if (confirm && context.mounted) {
                                      session.removeAddress(item.id);
                                    }
                                  },
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
