import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/trade_store.dart';
import 'design_system/components.dart';

String friendlyError(Object error) => switch (error) {
  ArgumentError() => error.message.toString(),
  StateError() => error.message,
  _ => 'Enregistrement impossible. Vos modifications n’ont pas été appliquées. Réessayez.',
};

String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'Ce champ est obligatoire.' : null;
String? integer(String? value) {
  final number = int.tryParse(value ?? '');
  if (number == null || number < 0 || number > 1000000000) {
    return 'Saisissez un entier de 0 à 1 000 000 000.';
  }
  return null;
}

String? positiveInteger(String? value) {
  final error = integer(value);
  if (error != null) return error;
  return int.parse(value!) == 0
      ? 'La quantité doit être supérieure à zéro.'
      : null;
}

Widget field(
  TextEditingController controller,
  String label, {
  bool numeric = false,
  bool positive = false,
  TextInputType? keyboard,
  bool required = true,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: FlowField(
    controller: controller,
    label: label,
    keyboardType: numeric ? TextInputType.number : keyboard,
    maxLength: numeric ? 10 : 160,
    inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
    validator: numeric
        ? (positive ? positiveInteger : integer)
        : (required ? requiredText : null),
  ),
);

Future<void> showEditor({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    builder: builder,
    barrierDismissible: false,
  );
  await navigator.push(route);
  await route.completed;
}

class SaveDialog extends StatefulWidget {
  const SaveDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.save,
    this.description,
  });
  final String title;
  final String? description;
  final List<Widget> fields;
  final Future<void> Function() save;
  @override
  State<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<SaveDialog> {
  final form = GlobalKey<FormState>();
  bool saving = false;
  String? error;
  Future<void> submit() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.save();
      if (mounted) Navigator.of(context).pop();
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
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.description != null) ...[
                  Text(widget.description!),
                  const SizedBox(height: 20),
                ],
                ...widget.fields,
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        FlowButton(label: 'Enregistrer', onPressed: submit, loading: saving),
      ],
    ),
  );
}

Future<void> contactForm(BuildContext context, TradeStore store) async {
  final name = TextEditingController(), country = TextEditingController();
  final email = TextEditingController(), phone = TextEditingController();
  var kind = ContactKind.client;
  await showEditor(
    context: context,
    builder: (context) => SaveDialog(
      title: 'Nouveau partenaire',
      fields: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<ContactKind>(
            isExpanded: true,
            initialValue: kind,
            decoration: const InputDecoration(labelText: 'Type de partenaire'),
            items: const [
              DropdownMenuItem(
                value: ContactKind.client,
                child: Text('Client'),
              ),
              DropdownMenuItem(
                value: ContactKind.supplier,
                child: Text('Fournisseur'),
              ),
            ],
            onChanged: (v) => kind = v!,
          ),
        ),
        field(name, 'Nom / raison sociale'),
        field(country, 'Pays'),
        field(
          email,
          'E-mail (facultatif)',
          keyboard: TextInputType.emailAddress,
          required: false,
        ),
        field(
          phone,
          'Téléphone (facultatif)',
          keyboard: TextInputType.phone,
          required: false,
        ),
      ],
      save: () => store.addContact(
        name: name.text,
        kind: kind,
        country: country.text,
        email: email.text,
        phone: phone.text,
      ),
    ),
  );
  for (final c in [name, country, email, phone]) {
    c.dispose();
  }
}

Future<void> stockForm(
  BuildContext context,
  TradeStore store,
  Product product,
) async {
  final quantity = TextEditingController(), reason = TextEditingController();
  var direction = 1;
  await showEditor(
    context: context,
    builder: (context) => SaveDialog(
      title: 'Ajuster le stock',
      description: '${product.name}\nDisponible : ${product.quantity}',
      fields: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: direction,
            decoration: const InputDecoration(labelText: 'Mouvement'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Entrée de stock')),
              DropdownMenuItem(value: -1, child: Text('Sortie de stock')),
            ],
            onChanged: (v) => direction = v!,
          ),
        ),
        field(quantity, 'Quantité', numeric: true, positive: true),
        field(reason, 'Motif du mouvement'),
      ],
      save: () => store.adjustStock(
        product.id,
        int.parse(quantity.text) * direction,
        reason.text,
      ),
    ),
  );
  quantity.dispose();
  reason.dispose();
}

Future<void> orderForm(BuildContext context, TradeStore store) async {
  final products = store.data.products
      .where((p) => p.quantity > 0 && p.status != ProductStatus.archived)
      .toList();
  final customers = store.data.contacts
      .where((c) => c.kind == ContactKind.client)
      .toList();
  if (products.isEmpty || customers.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Préparons votre commande'),
        content: const Text(
          'Ajoutez au moins un produit avec du stock et un contact de type client avant de créer une commande.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
    return;
  }
  var productId = products.first.id, customerId = customers.first.id;
  final quantity = TextEditingController(text: '1'),
      destination = TextEditingController();
  await showEditor(
    context: context,
    builder: (context) => SaveDialog(
      title: 'Nouvelle commande',
      description: 'La confirmation déduit immédiatement le stock disponible. Une commande contient un produit dans cette première version.',
      fields: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: customerId,
            decoration: const InputDecoration(labelText: 'Client'),
            items: [
              for (final c in customers)
                DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => customerId = v!,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: productId,
            decoration: const InputDecoration(labelText: 'Produit'),
            items: [
              for (final p in products)
                DropdownMenuItem(
                  value: p.id,
                  child: Text(
                    '${p.name} (${p.quantity} dispo.)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => productId = v!,
          ),
        ),
        field(quantity, 'Quantité', numeric: true, positive: true),
        field(destination, 'Adresse / destination de livraison'),
      ],
      save: () => store.createOrder(
        productId: productId,
        customerId: customerId,
        quantity: int.parse(quantity.text),
        destination: destination.text,
      ),
    ),
  );
  quantity.dispose();
  destination.dispose();
}
