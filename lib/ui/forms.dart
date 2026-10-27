import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../application/trade_store.dart';
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
    this.confirm,
  });
  final String title;
  final String? description;
  final List<Widget> fields;
  final Future<void> Function() save;
  final Future<bool> Function()? confirm;
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
      if (widget.confirm != null && !await widget.confirm!()) {
        if (mounted) setState(() => saving = false);
        return;
      }
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

Future<void> stockForm(
  BuildContext context,
  TradeStore store,
  Product product, {
  int initialDirection = 1,
}) async {
  final quantity = TextEditingController(), reason = TextEditingController();
  var direction = initialDirection;
  await showEditor(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => SaveDialog(
        title: 'Ajuster le stock',
        description:
            '${product.name} · ${product.sku}\nDisponible : ${product.quantity} ${product.unit}',
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
              onChanged: (v) => refresh(() => direction = v!),
            ),
          ),
          field(quantity, 'Quantité', numeric: true, positive: true),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: quantity,
            builder: (context, value, _) {
              final q = int.tryParse(value.text);
              final next = q == null ? null : product.quantity + direction * q;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  next == null
                      ? 'Saisissez la quantité à ajouter ou à retirer.'
                      : 'Stock après mouvement : $next ${product.unit}',
                  style: TextStyle(
                    color: next != null && (next < 0 || next > 1000000000)
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              );
            },
          ),
          field(reason, 'Motif du mouvement'),
        ],
        confirm: () async {
          final delta = int.parse(quantity.text) * direction;
          if (delta + product.quantity < 0 ||
              delta + product.quantity > 1000000000) {
            throw ArgumentError(
              'Stock insuffisant ou quantité maximale dépassée.',
            );
          }
          return showFlowConfirmation(
            context,
            title: 'Confirmer le mouvement ?',
            description:
                '${product.name} : ${product.quantity} → ${product.quantity + delta} ${product.unit}.\nMotif : ${reason.text.trim()}',
            confirmLabel: 'Confirmer',
          );
        },
        save: () async {
          final delta = int.parse(quantity.text) * direction;
          await store.adjustStock(
            product.id,
            delta,
            reason.text,
            expectedQuantity: product.quantity,
            expectedUnit: product.unit,
          );
        },
      ),
    ),
  );
  quantity.dispose();
  reason.dispose();
}

Future<void> orderForm(
  BuildContext context,
  TradeStore store, {
  String? initialCustomerId,
}) async {
  final products = store.data.products
      .where((p) => p.quantity > 0 && p.status != ProductStatus.archived)
      .toList();
  final customers = store.data.contacts
      .where((c) => c.kind == ContactKind.client && !c.archived)
      .toList();
  if (products.isEmpty ||
      customers.isEmpty ||
      (initialCustomerId != null &&
          !customers.any((c) => c.id == initialCustomerId))) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Préparons votre commande'),
        content: const Text(
          'Ajoutez au moins un produit avec du stock et un client actif avant de créer une commande. Le client choisi doit encore être actif.',
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
  var productId = products.first.id,
      customerId = initialCustomerId ?? customers.first.id;
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
        expectedUnit: products.firstWhere((p) => p.id == productId).unit,
        expectedPrice: products.firstWhere((p) => p.id == productId).price,
        quantity: int.parse(quantity.text),
        destination: destination.text,
      ),
    ),
  );
  quantity.dispose();
  destination.dispose();
}
