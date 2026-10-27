import '../fulfilment/fulfilment_forms.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../application/trade_store.dart';
import '../forms.dart' show field, SaveDialog, showEditor, friendlyError;
import '../design_system/components.dart';
import '../catalog/product_widgets.dart' show publicPrice;
import 'document_editor.dart';

String commercialDate(DateTime value) =>
    DateFormat('dd/MM/yyyy', 'fr').format(value.toLocal());

Future<void> commercialAction(
  BuildContext context, {
  required String title,
  required String description,
  required Future<void> Function() action,
}) async {
  final confirmed = await showFlowConfirmation(
    context,
    title: title,
    description: description,
  );
  if (!confirmed) return;
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }
}

Future<void> commercialQuantityForm(
  BuildContext context, {
  required String title,
  required int maximum,
  required String unit,
  required Future<void> Function(int, String) save,
}) async {
  final quantity = TextEditingController(text: '1');
  final reason = TextEditingController();
  await showEditor(
    context: context,
    builder: (context) => SaveDialog(
      title: title,
      description:
          'Maximum : $maximum $unit. Le motif ou la référence est obligatoire.',
      fields: [
        field(quantity, 'Quantité', numeric: true, positive: true),
        field(reason, 'Motif / référence'),
      ],
      confirm: () async {
        if (int.parse(quantity.text) > maximum) {
          throw ArgumentError('La quantité dépasse le solde autorisé.');
        }
        return showFlowConfirmation(
          context,
          title: 'Confirmer cette opération ?',
          description:
              '$title : ${quantity.text} $unit.\n${reason.text.trim()}',
        );
      },
      save: () => save(int.parse(quantity.text), reason.text),
    ),
  );
  quantity.dispose();
  reason.dispose();
}

Widget commercialInfo({
  required String partner,
  required String product,
  required String unit,
  required int quantity,
  required int price,
  required String destination,
  required String notes,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Text(
      partner,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    Text(product),
    Text('$quantity $unit × ${publicPrice(price)}'),
    const SizedBox(height: 12),
    Text(
      'Total produits : ${publicPrice(quantity * price)}',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    Text('Destination : $destination'),
    if (notes.isNotEmpty) ...[const SizedBox(height: 12), Text(notes)],
  ],
);
Widget commercialJournal(TradeStore store, String id) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const SizedBox(height: 24),
    const Text(
      'Historique des opérations',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    if (!store.data.commercialEvents.any((e) => e.documentId == id))
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Aucune opération enregistrée sur ce document.'),
      ),
    for (final event in store.data.commercialEvents.where(
      (e) => e.documentId == id,
    ))
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${event.kind.label} · ${event.quantity} ${event.unit}'),
              Text(event.reason),
              if (event.kind == CommercialEventKind.customerReturn)
                Text(
                  event.restocked
                      ? 'Réintégré au stock disponible'
                      : 'Hors stock disponible',
                ),
              if (event.carrier.isNotEmpty) Text(event.carrier),
              if (event.trackingNumber.isNotEmpty) Text(event.trackingNumber),
              Text(commercialDate(event.createdAt)),
              SelectableText(event.id),
            ],
          ),
        ),
      ),
  ],
);

class QuoteDetailPage extends StatelessWidget {
  const QuoteDetailPage({super.key, required this.store, required this.id});
  final TradeStore store;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final q = store.data.quotes.firstWhere((q) => q.id == id);
      final expired = q.isExpiredAt(DateTime.now());
      Widget statusButton(String label, QuoteStatus next) => TextButton(
        onPressed: store.busy
            ? null
            : () => commercialAction(
                context,
                title: label,
                description: 'Confirmez le changement d’état de ce devis.',
                action: () => store.changeQuoteStatus(
                  q.id,
                  next,
                  expectedRevision: q.revision,
                ),
              ),
        child: Text(label),
      );
      return Scaffold(
        appBar: AppBar(title: const Text('Devis client')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SelectableText(q.id),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FlowBadge(q.status.label),
                    if (expired &&
                        q.status != QuoteStatus.converted &&
                        q.status != QuoteStatus.cancelled &&
                        q.status != QuoteStatus.rejected)
                      const FlowBadge('Expiré', tone: FlowTone.warning),
                  ],
                ),
                const SizedBox(height: 16),
                commercialInfo(
                  partner: q.customerName,
                  product: q.productName,
                  unit: q.unit,
                  quantity: q.quantity,
                  price: q.unitPrice,
                  destination: q.destination,
                  notes: q.notes,
                ),
                const SizedBox(height: 12),
                Text('Valable jusqu’au ${commercialDate(q.expiresAt)} inclus'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (q.status == QuoteStatus.draft) ...[
                      TextButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialDocumentEditor(
                                context,
                                store,
                                quote: q,
                              ),
                        child: const Text('Modifier le brouillon'),
                      ),
                      if (!expired)
                        statusButton('Marquer envoyé', QuoteStatus.sent),
                    ],
                    if (q.status == QuoteStatus.sent) ...[
                      if (!expired)
                        statusButton('Marquer accepté', QuoteStatus.accepted),
                      statusButton('Marquer refusé', QuoteStatus.rejected),
                    ],
                    if (q.status == QuoteStatus.accepted && !expired)
                      FilledButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialAction(
                                context,
                                title: 'Convertir en commande ?',
                                description: 'Le prix accepté sera conservé et le stock sera déduit une seule fois. Le client et le produit doivent être actifs.',
                                action: () async {
                                  await store.convertQuote(
                                    q.id,
                                    expectedRevision: q.revision,
                                  );
                                },
                              ),
                        child: const Text('Convertir en commande'),
                      ),
                    if ([
                      QuoteStatus.draft,
                      QuoteStatus.sent,
                      QuoteStatus.accepted,
                    ].contains(q.status))
                      statusButton('Annuler le devis', QuoteStatus.cancelled),
                    if (q.orderId != null)
                      FilledButton.tonal(
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SaleDetailPage(store: store, id: q.orderId!),
                          ),
                        ),
                        child: const Text('Ouvrir la commande'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Les changements d’état sont enregistrés localement. « Marquer envoyé » n’envoie aucun e-mail.',
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class PurchaseDetailPage extends StatelessWidget {
  const PurchaseDetailPage({super.key, required this.store, required this.id});
  final TradeStore store;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final p = store.data.purchases.firstWhere((p) => p.id == id);
      return Scaffold(
        appBar: AppBar(title: const Text('Achat fournisseur')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SelectableText(p.id),
                const SizedBox(height: 12),
                FlowBadge(p.status.label),
                const SizedBox(height: 16),
                commercialInfo(
                  partner: p.supplierName,
                  product: p.productName,
                  unit: p.unit,
                  quantity: p.quantity,
                  price: p.unitPrice,
                  destination: p.destination,
                  notes: p.notes,
                ),
                const SizedBox(height: 16),
                Text(
                  'Reçu : ${p.receivedQuantity}/${p.quantity} ${p.unit} · Retourné : ${p.returnedQuantity} ${p.unit}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (p.status == PurchaseStatus.draft) ...[
                      TextButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialDocumentEditor(
                                context,
                                store,
                                purchase: true,
                                order: p,
                              ),
                        child: const Text('Modifier le brouillon'),
                      ),
                      FilledButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialAction(
                                context,
                                title: 'Confirmer l’achat ?',
                                description: 'Cet achat sera marqué commandé. Le stock restera inchangé jusqu’à réception.',
                                action: () => store.changePurchaseStatus(
                                  p.id,
                                  PurchaseStatus.ordered,
                                  expectedRevision: p.revision,
                                ),
                              ),
                        child: const Text('Confirmer l’achat'),
                      ),
                    ],
                    if (p.status == PurchaseStatus.ordered &&
                        p.remainingQuantity > 0)
                      FilledButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialQuantityForm(
                                context,
                                title: 'Réception fournisseur',
                                maximum: p.remainingQuantity,
                                unit: p.unit,
                                save: (qty, reason) => store.receivePurchase(
                                  p.id,
                                  qty,
                                  reason,
                                  expectedRevision: p.revision,
                                ),
                              ),
                        child: const Text('Réceptionner'),
                      ),
                    if (p.returnableQuantity > 0 &&
                        p.status != PurchaseStatus.cancelled)
                      TextButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialQuantityForm(
                                context,
                                title: 'Retour fournisseur',
                                maximum: p.returnableQuantity,
                                unit: p.unit,
                                save: (qty, reason) => store.returnSupplier(
                                  p.id,
                                  qty,
                                  reason,
                                  expectedRevision: p.revision,
                                ),
                              ),
                        child: const Text('Retour fournisseur'),
                      ),
                    if (p.status == PurchaseStatus.draft ||
                        (p.status == PurchaseStatus.ordered &&
                            p.receivedQuantity == 0))
                      TextButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialAction(
                                context,
                                title: 'Annuler cet achat ?',
                                description: 'Aucune réception ne doit avoir été enregistrée.',
                                action: () => store.changePurchaseStatus(
                                  p.id,
                                  PurchaseStatus.cancelled,
                                  expectedRevision: p.revision,
                                ),
                              ),
                        child: const Text('Annuler l’achat'),
                      ),
                  ],
                ),
                commercialJournal(store, p.id),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class SaleDetailPage extends StatelessWidget {
  const SaleDetailPage({super.key, required this.store, required this.id});
  final TradeStore store;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final o = store.data.orders.firstWhere((o) => o.id == id);
      return Scaffold(
        appBar: AppBar(title: const Text('Commande client')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SelectableText(o.id),
                const SizedBox(height: 12),
                FlowBadge(o.status.label),
                const SizedBox(height: 16),
                commercialInfo(
                  partner: o.customerName,
                  product: o.productName,
                  unit: o.unit,
                  quantity: o.quantity,
                  price: o.unitPrice,
                  destination: o.destination,
                  notes: '',
                ),
                const SizedBox(height: 16),
                Text(
                  'Livré : ${o.deliveredQuantity}/${o.quantity} ${o.unit} · Retourné : ${o.returnedQuantity} ${o.unit}',
                ),
                if (o.quoteId != null)
                  TextButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            QuoteDetailPage(store: store, id: o.quoteId!),
                      ),
                    ),
                    child: const Text('Voir le devis d’origine'),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (o.status == OrderStatus.confirmed) ...[
                      FilledButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialAction(
                                context,
                                title: 'Expédier la commande ?',
                                description: 'Le stock a déjà été déduit à la confirmation. Cette étape ne le décompte pas une seconde fois.',
                                action: () => store.changeOrderStatus(
                                  o.id,
                                  OrderStatus.shipped,
                                ),
                              ),
                        child: const Text('Expédier'),
                      ),
                      TextButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialAction(
                                context,
                                title: 'Annuler la commande ?',
                                description: 'La totalité du stock sera restituée. Une commande expédiée ne peut plus être annulée.',
                                action: () => store.changeOrderStatus(
                                  o.id,
                                  OrderStatus.cancelled,
                                ),
                              ),
                        child: const Text('Annuler la commande'),
                      ),
                    ],
                    if (o.status == OrderStatus.shipped &&
                        o.remainingQuantity > 0)
                      FilledButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialQuantityForm(
                                context,
                                title: 'Livraison client',
                                maximum: o.remainingQuantity,
                                unit: o.unit,
                                save: (qty, reason) => store.recordDelivery(
                                  o.id,
                                  qty,
                                  reason,
                                  expectedRevision: o.revision,
                                ),
                              ),
                        child: const Text('Enregistrer une livraison'),
                      ),
                    if (o.returnableQuantity > 0)
                      TextButton(
                        onPressed: store.busy
                            ? null
                            : () => customerReturnForm(context, store, o),
                        child: const Text('Retour client'),
                      ),
                  ],
                ),
                if (o.status == OrderStatus.confirmed ||
                    o.status == OrderStatus.shipped)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: store.busy
                          ? null
                          : () => deliveryPlanForm(context, store, o),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Transporteur et suivi'),
                    ),
                  ),
                for (final plan in store.data.deliveryPlans.where(
                  (p) => p.orderId == o.id,
                ))
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (plan.carrier.isNotEmpty)
                            Text('Transporteur : ${plan.carrier}'),
                          if (plan.trackingNumber.isNotEmpty)
                            SelectableText('Suivi : ${plan.trackingNumber}'),
                          if (plan.expectedDate != null)
                            Text(
                              'Date prévue : ${commercialDate(plan.expectedDate!)}',
                            ),
                          if (plan.notes.isNotEmpty) Text(plan.notes),
                        ],
                      ),
                    ),
                  ),
                commercialJournal(store, o.id),
              ],
            ),
          ),
        ),
      );
    },
  );
}
