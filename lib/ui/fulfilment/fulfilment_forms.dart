import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../application/trade_store.dart';
import '../forms.dart' show field, showEditor, SaveDialog;
import '../design_system/components.dart';

Future<void> deliveryPlanForm(
  BuildContext context,
  TradeStore store,
  TradeOrder order,
) async {
  final original = store.data.deliveryPlans
      .where((p) => p.orderId == order.id)
      .firstOrNull;
  final carrier = TextEditingController(text: original?.carrier),
      tracking = TextEditingController(text: original?.trackingNumber),
      notes = TextEditingController(text: original?.notes);
  DateTime? date = original?.expectedDate;
  await showEditor(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => SaveDialog(
        title: 'Suivi de livraison',
        fields: [
          field(carrier, 'Transporteur', required: false),
          field(tracking, 'Référence de suivi', required: false),
          Wrap(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  date == null
                      ? 'Date prévue'
                      : DateFormat('dd/MM/yyyy', 'fr').format(date!),
                ),
                onPressed: () async {
                  final today = DateUtils.dateOnly(DateTime.now());
                  final first = DateTime(today.year - 5);
                  final last = DateTime(today.year + 5, 12, 31);
                  final initial =
                      date == null ||
                          date!.isBefore(first) ||
                          date!.isAfter(last)
                      ? today
                      : date!;
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: first,
                    lastDate: last,
                  );
                  if (selected != null && context.mounted) {
                    refresh(() => date = selected);
                  }
                },
              ),
              if (date != null)
                TextButton(
                  onPressed: () => refresh(() => date = null),
                  child: const Text('Effacer la date'),
                ),
            ],
          ),
          TextFormField(
            controller: notes,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Consignes de livraison',
            ),
          ),
        ],
        save: () => store.saveDeliveryPlan(
          order.id,
          carrier: carrier.text,
          trackingNumber: tracking.text,
          notes: notes.text,
          expectedDate: date,
          expectedRevision: original?.revision ?? 0,
        ),
      ),
    ),
  );
  carrier.dispose();
  tracking.dispose();
  notes.dispose();
}

Future<void> customerReturnForm(
  BuildContext context,
  TradeStore store,
  TradeOrder order,
) async {
  final quantity = TextEditingController(text: '1'),
      reason = TextEditingController();
  bool restock = true;
  await showEditor(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => SaveDialog(
        title: 'Retour client',
        description: 'Maximum : ${order.returnableQuantity} ${order.unit}.',
        fields: [
          field(quantity, 'Quantité', numeric: true, positive: true),
          field(reason, 'Motif / référence'),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: restock,
            onChanged: (v) => refresh(() => restock = v!),
            title: const Text('Réintégrer au stock disponible'),
          ),
          const Text(
            'Décochez pour les marchandises abîmées ou non revendables. Elles seront suivies dans les retours sans augmenter le stock disponible.',
          ),
        ],
        confirm: () async {
          if (int.parse(quantity.text) > order.returnableQuantity) {
            throw ArgumentError('La quantité dépasse le solde autorisé.');
          }
          return showFlowConfirmation(
            context,
            title: 'Confirmer cette opération ?',
            description:
                'Retour client : ${quantity.text} ${order.unit}. ${restock ? 'Réintégration au stock disponible.' : 'Aucune réintégration au stock disponible.'}',
          );
        },
        save: () => store.returnCustomer(
          order.id,
          int.parse(quantity.text),
          reason.text,
          expectedRevision: order.revision,
          restock: restock,
        ),
      ),
    ),
  );
  quantity.dispose();
  reason.dispose();
}
