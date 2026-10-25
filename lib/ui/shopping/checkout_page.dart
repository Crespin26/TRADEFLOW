import 'package:flutter/material.dart';

import '../../domain/shopping_session.dart';
import '../catalog/product_widgets.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';
import '../forms.dart' show friendlyError, requiredText;
import 'shopping_scope.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final form = GlobalKey<FormState>();
  final scroll = ScrollController();
  void changeStep(bool value) {
    setState(() => review = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  final name = TextEditingController(),
      phone = TextEditingController(),
      street = TextEditingController(),
      city = TextEditingController(),
      country = TextEditingController(text: 'Bénin');
  bool review = false, accepted = false, saving = false;
  String? error;
  DeliveryAddress get address => DeliveryAddress(
    name: name.text.trim(),
    phone: phone.text.trim(),
    street: street.text.trim(),
    city: city.text.trim(),
    country: country.text.trim(),
  );
  @override
  void dispose() {
    for (final c in [name, phone, street, city, country]) {
      c.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  Future<void> confirm() async {
    if (!accepted || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final receipt = await ShoppingScope.of(context).confirmDemo(address);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DemoReceiptPage(receipt: receipt),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = friendlyError(e);
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ShoppingScope.of(context);
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(title: Text(review ? 'Récapitulatif' : 'Livraison')),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                controller: scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(24),
                children: [
                  const FlowBadge('Commande simulée · Aucun paiement'),
                  const SizedBox(height: 20),
                  if (!session.signedIn || !session.verified)
                    const FlowStateView(
                      title: 'Connexion simulée requise',
                      description: 'Revenez au panier pour ouvrir une session client de démonstration.',
                      icon: Icons.lock_outline,
                    )
                  else if (session.lines.isEmpty)
                    const FlowStateView(
                      title: 'Le panier est vide',
                      description:
                          'Revenez au catalogue pour choisir des produits.',
                    )
                  else if (!review) ...[
                    Text(
                      'Où livrer votre commande ?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Utilisez une adresse et un numéro fictifs. Ils ne seront transmis à personne.',
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: form,
                      child: Column(
                        children: [
                          for (final entry in [
                            (name, 'Destinataire'),
                            (phone, 'Téléphone'),
                            (street, 'Adresse'),
                            (city, 'Ville'),
                            (country, 'Pays'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FlowField(
                                controller: entry.$1,
                                label: entry.$2,
                                maxLength: 160,
                                validator: requiredText,
                                keyboardType: entry.$1 == phone
                                    ? TextInputType.phone
                                    : TextInputType.streetAddress,
                              ),
                            ),
                        ],
                      ),
                    ),
                    FlowButton(
                      label: 'Voir le récapitulatif',
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          changeStep(true);
                        }
                      },
                    ),
                  ] else ...[
                    Text(
                      'Vérifiez votre sélection',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text('Session de démonstration : ${session.email}'),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Adresse de livraison',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(address.label),
                            TextButton(
                              onPressed: saving
                                  ? null
                                  : () => changeStep(false),
                              child: const Text('Modifier l’adresse'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final line in session.lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${line.quantity} × ${line.product.name}'),
                            Text(
                              '${line.product.unit} · ${publicPrice(line.total)}',
                              style: const TextStyle(color: FlowColors.muted),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    Text(
                      'Total des produits : ${publicPrice(session.total)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Transport et taxes non calculés. Les prix et disponibilités sont fictifs. Aucun paiement, aucune réservation de stock et aucune livraison ne seront déclenchés.',
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: accepted,
                      onChanged: saving
                          ? null
                          : (value) =>
                                setState(() => accepted = value ?? false),
                      title: const Text(
                        'Je comprends qu’il s’agit d’une commande de démonstration.',
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          error!,
                          style: const TextStyle(color: FlowColors.error),
                        ),
                      ),
                    FlowButton(
                      label: 'Confirmer la commande simulée',
                      loading: saving,
                      onPressed: accepted ? confirm : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DemoReceiptPage extends StatelessWidget {
  const DemoReceiptPage({super.key, required this.receipt});
  final DemoReceipt receipt;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Confirmation de démonstration')),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const FlowStateView(
                title: 'Parcours de commande terminé',
                description: 'Votre commande fictive a été simulée. Aucun paiement, e-mail, mouvement de stock ni livraison n’a été déclenché.',
                icon: Icons.check_circle_outline,
                tone: FlowTone.success,
              ),
              const SizedBox(height: 24),
              SelectableText(receipt.id),
              const SizedBox(height: 12),
              Text(receipt.email),
              const SizedBox(height: 12),
              Text(receipt.address.label),
              const SizedBox(height: 20),
              for (final line in receipt.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${line.quantity} × ${line.product.name} · ${publicPrice(line.total)}',
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Total des produits : ${publicPrice(receipt.total)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Le panier a été vidé après la confirmation. Ce récapitulatif reste temporaire et disparaît au redémarrage ou à la déconnexion.',
              ),
              const SizedBox(height: 24),
              FlowButton(
                label: 'Fermer le récapitulatif',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
