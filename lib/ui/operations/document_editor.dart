import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../application/trade_store.dart';
import '../forms.dart' show field, friendlyError;
import '../catalog/product_widgets.dart' show publicPrice;

Future<void> commercialDocumentEditor(
  BuildContext context,
  TradeStore store, {
  bool purchase = false,
  TradeQuote? quote,
  PurchaseOrder? order,
  String? partnerId,
}) => Navigator.push<void>(
  context,
  MaterialPageRoute(
    builder: (_) => CommercialDocumentEditor(
      store: store,
      purchase: purchase,
      quote: quote,
      order: order,
      partnerId: partnerId,
    ),
  ),
);

class CommercialDocumentEditor extends StatefulWidget {
  const CommercialDocumentEditor({
    super.key,
    required this.store,
    this.purchase = false,
    this.quote,
    this.order,
    this.partnerId,
  });
  final TradeStore store;
  final bool purchase;
  final TradeQuote? quote;
  final PurchaseOrder? order;
  final String? partnerId;
  @override
  State<CommercialDocumentEditor> createState() =>
      _CommercialDocumentEditorState();
}

class _CommercialDocumentEditorState extends State<CommercialDocumentEditor> {
  final form = GlobalKey<FormState>();
  late final products = widget.store.data.products
      .where(
        (p) =>
            p.status != ProductStatus.archived ||
            p.id == (widget.quote?.productId ?? widget.order?.productId),
      )
      .toList();
  late final partners = widget.store.data.contacts
      .where(
        (c) =>
            (!c.archived ||
                c.id ==
                    (widget.quote?.customerId ?? widget.order?.supplierId)) &&
            c.kind ==
                (widget.purchase ? ContactKind.supplier : ContactKind.client),
      )
      .toList();
  late String? productId =
      widget.quote?.productId ??
      widget.order?.productId ??
      products.firstOrNull?.id;
  late String? partnerId =
      widget.quote?.customerId ??
      widget.order?.supplierId ??
      widget.partnerId ??
      partners.firstOrNull?.id;
  late final quantity = TextEditingController(
    text: '${widget.quote?.quantity ?? widget.order?.quantity ?? 1}',
  );
  late final price = TextEditingController(
    text:
        '${widget.quote?.unitPrice ?? widget.order?.unitPrice ?? (widget.purchase ? selectedProduct?.purchasePrice : selectedProduct?.price) ?? 0}',
  );
  late final destination = TextEditingController(
    text: widget.quote?.destination ?? widget.order?.destination,
  );
  late final notes = TextEditingController(
    text: widget.quote?.notes ?? widget.order?.notes,
  );
  late DateTime expires =
      widget.quote?.expiresAt ?? DateTime.now().add(const Duration(days: 30));
  Product? get selectedProduct =>
      products.where((p) => p.id == productId).firstOrNull;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in [quantity, price, destination, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (productId == null || partnerId == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (widget.purchase) {
        await widget.store.savePurchase(
          id: widget.order?.id,
          expectedRevision: widget.order?.revision,
          supplierId: partnerId!,
          productId: productId!,
          expectedUnit: selectedProduct?.unit,
          quantity: int.parse(quantity.text),
          unitPrice: int.parse(price.text),
          destination: destination.text,
          notes: notes.text,
        );
      } else {
        await widget.store.saveQuote(
          id: widget.quote?.id,
          expectedRevision: widget.quote?.revision,
          customerId: partnerId!,
          productId: productId!,
          expectedUnit: selectedProduct?.unit,
          quantity: int.parse(quantity.text),
          unitPrice: int.parse(price.text),
          destination: destination.text,
          notes: notes.text,
          expiresAt: expires,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = friendlyError(e);
        });
      }
    }
  }

  Future<void> chooseDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: expires.isBefore(today) ? today : expires,
      firstDate: today,
      lastDate: DateTime(today.year + 10, today.month, today.day),
    );
    if (selected != null && mounted) setState(() => expires = selected);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.purchase ? 'Achat fournisseur' : 'Devis client'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: busy || productId == null || partnerId == null
                    ? null
                    : save,
                child: Text(
                  busy ? 'Enregistrement…' : 'Enregistrer le brouillon',
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.purchase
                        ? 'Le stock augmentera uniquement à la réception des marchandises.'
                        : 'Le devis ne réserve aucun stock. Le prix saisi sera conservé lors de la conversion en commande.',
                  ),
                  const SizedBox(height: 20),
                  if (products.isEmpty || partners.isEmpty)
                    Text(
                      widget.purchase
                          ? 'Ajoutez un produit actif et un fournisseur actif pour préparer un achat.'
                          : 'Ajoutez un produit actif et un client actif pour préparer un devis.',
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: partnerId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: widget.purchase ? 'Fournisseur' : 'Client',
                    ),
                    items: [
                      for (final c in partners)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (v) => setState(() => partnerId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: productId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Produit'),
                    items: [
                      for (final p in products)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.name} · ${p.unit}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (v) => setState(() {
                            productId = v;
                            price.text =
                                '${widget.purchase ? selectedProduct!.purchasePrice : selectedProduct!.price}';
                          }),
                  ),
                  const SizedBox(height: 16),
                  field(quantity, 'Quantité', numeric: true, positive: true),
                  field(
                    price,
                    widget.purchase
                        ? 'Prix d’achat convenu (XOF)'
                        : 'Prix de vente proposé (XOF)',
                    numeric: true,
                  ),
                  ListenableBuilder(
                    listenable: Listenable.merge([quantity, price]),
                    builder: (context, _) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Total produits : ${publicPrice((int.tryParse(quantity.text) ?? 0) * (int.tryParse(price.text) ?? 0))}',
                      ),
                    ),
                  ),
                  field(
                    destination,
                    widget.purchase
                        ? 'Lieu de réception'
                        : 'Destination de livraison',
                  ),
                  if (!widget.purchase)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: busy ? null : chooseDate,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          'Valable jusqu’au ${DateFormat('dd/MM/yyyy', 'fr').format(expires)}',
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: notes,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Conditions et notes',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Une référence par document · XOF · transport et taxes à préciser séparément.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
