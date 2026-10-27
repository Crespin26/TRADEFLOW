import '../documents/documents_page.dart';
import '../fulfilment/fulfilment_page.dart';

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/trade_store.dart';
import '../../domain/public_catalog.dart' show normalizeCatalogText;
import '../forms.dart' show orderForm;
import '../design_system/components.dart';
import '../catalog/product_widgets.dart' show publicPrice;
import 'document_editor.dart';
import 'operation_details.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key, required this.store, this.initialTab = 0});
  final TradeStore store;
  final int initialTab;
  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  final search = TextEditingController();
  OrderStatus? saleStatus;
  QuoteStatus? quoteStatus;
  PurchaseStatus? purchaseStatus;
  CommercialEventKind? eventKind;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  bool matches(String value) =>
      normalizeCatalogText(value).contains(normalizeCatalogText(search.text));
  void open(Widget page) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));
  Widget list(List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    children: children,
  );
  Widget card({
    required String id,
    required String partner,
    required String product,
    required String state,
    required int total,
    required String progress,
    required VoidCallback onOpen,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(partner, style: Theme.of(context).textTheme.titleMedium),
          Text(product),
          const SizedBox(height: 8),
          FlowBadge(state),
          Text(publicPrice(total)),
          Text(progress),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpen,
              child: const Text('Ouvrir le document'),
            ),
          ),
          SelectableText(id),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    initialIndex: widget.initialTab,
    child: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Opérations commerciales'),
            bottom: const TabBar(
              labelPadding: EdgeInsets.symmetric(horizontal: 4),
              tabs: [
                Tab(text: 'Ventes'),
                Tab(text: 'Devis'),
                Tab(text: 'Achats'),
                Tab(text: 'Journal'),
              ],
            ),
          ),
          body: !store.loaded
              ? Center(
                  child: FlowStateView(
                    title: store.loadError == null
                        ? 'Chargement des opérations'
                        : 'Opérations indisponibles',
                    description:
                        store.loadError ?? 'Ouverture des documents locaux.',
                    loading: store.loadError == null,
                    actionLabel: store.loadError == null ? null : 'Réessayer',
                    onAction: store.busy ? null : store.load,
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Rechercher un document ou partenaire',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => open(FulfilmentPage(store: store)),
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: const Text('Livraisons et retours'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => open(DocumentsPage(store: store)),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Documents commerciaux'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          list([
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: store.busy
                                    ? null
                                    : () => orderForm(context, store),
                                icon: const Icon(Icons.add),
                                label: const Text('Nouvelle vente'),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Toutes'),
                                  selected: saleStatus == null,
                                  onSelected: (_) =>
                                      setState(() => saleStatus = null),
                                ),
                                for (final s in OrderStatus.values)
                                  ChoiceChip(
                                    label: Text(s.label),
                                    selected: saleStatus == s,
                                    onSelected: (_) =>
                                        setState(() => saleStatus = s),
                                  ),
                              ],
                            ),
                            for (final o in store.data.orders.where(
                              (o) =>
                                  (saleStatus == null ||
                                      saleStatus == o.status) &&
                                  matches(
                                    '${o.id} ${o.customerName} ${o.productName} ${o.destination}',
                                  ),
                            ))
                              card(
                                id: o.id,
                                partner: o.customerName,
                                product: o.productName,
                                state: o.status.label,
                                total: o.total,
                                progress:
                                    'Livré ${o.deliveredQuantity}/${o.quantity} · Retourné ${o.returnedQuantity}',
                                onOpen: () => open(
                                  SaleDetailPage(store: store, id: o.id),
                                ),
                              ),
                            if (!store.data.orders.any(
                              (o) =>
                                  (saleStatus == null ||
                                      saleStatus == o.status) &&
                                  matches(
                                    '${o.id} ${o.customerName} ${o.productName} ${o.destination}',
                                  ),
                            ))
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Aucune vente à afficher.'),
                              ),
                          ]),
                          list([
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: store.busy
                                    ? null
                                    : () => commercialDocumentEditor(
                                        context,
                                        store,
                                      ),
                                icon: const Icon(Icons.add),
                                label: const Text('Nouveau devis'),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Tous'),
                                  selected: quoteStatus == null,
                                  onSelected: (_) =>
                                      setState(() => quoteStatus = null),
                                ),
                                for (final s in QuoteStatus.values)
                                  ChoiceChip(
                                    label: Text(s.label),
                                    selected: quoteStatus == s,
                                    onSelected: (_) =>
                                        setState(() => quoteStatus = s),
                                  ),
                              ],
                            ),
                            for (final q in store.data.quotes.where(
                              (q) =>
                                  (quoteStatus == null ||
                                      quoteStatus == q.status) &&
                                  matches(
                                    '${q.id} ${q.customerName} ${q.productName} ${q.destination}',
                                  ),
                            ))
                              card(
                                id: q.id,
                                partner: q.customerName,
                                product: q.productName,
                                state: q.status.label,
                                total: q.total,
                                progress:
                                    'Valable jusqu’au ${commercialDate(q.expiresAt)}${q.isExpiredAt(DateTime.now()) && ![QuoteStatus.converted, QuoteStatus.cancelled, QuoteStatus.rejected].contains(q.status) ? ' · Expiré' : ''}',
                                onOpen: () => open(
                                  QuoteDetailPage(store: store, id: q.id),
                                ),
                              ),
                            if (!store.data.quotes.any(
                              (q) =>
                                  (quoteStatus == null ||
                                      quoteStatus == q.status) &&
                                  matches(
                                    '${q.id} ${q.customerName} ${q.productName} ${q.destination}',
                                  ),
                            ))
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Aucun devis à afficher.'),
                              ),
                          ]),
                          list([
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: store.busy
                                    ? null
                                    : () => commercialDocumentEditor(
                                        context,
                                        store,
                                        purchase: true,
                                      ),
                                icon: const Icon(Icons.add),
                                label: const Text('Nouvel achat'),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Tous'),
                                  selected: purchaseStatus == null,
                                  onSelected: (_) =>
                                      setState(() => purchaseStatus = null),
                                ),
                                for (final s in PurchaseStatus.values)
                                  ChoiceChip(
                                    label: Text(s.label),
                                    selected: purchaseStatus == s,
                                    onSelected: (_) =>
                                        setState(() => purchaseStatus = s),
                                  ),
                              ],
                            ),
                            for (final p in store.data.purchases.where(
                              (p) =>
                                  (purchaseStatus == null ||
                                      purchaseStatus == p.status) &&
                                  matches(
                                    '${p.id} ${p.supplierName} ${p.productName} ${p.destination}',
                                  ),
                            ))
                              card(
                                id: p.id,
                                partner: p.supplierName,
                                product: p.productName,
                                state: p.status.label,
                                total: p.total,
                                progress:
                                    'Reçu ${p.receivedQuantity}/${p.quantity} · Retourné ${p.returnedQuantity}',
                                onOpen: () => open(
                                  PurchaseDetailPage(store: store, id: p.id),
                                ),
                              ),
                            if (!store.data.purchases.any(
                              (p) =>
                                  (purchaseStatus == null ||
                                      purchaseStatus == p.status) &&
                                  matches(
                                    '${p.id} ${p.supplierName} ${p.productName} ${p.destination}',
                                  ),
                            ))
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Aucun achat à afficher.'),
                              ),
                          ]),
                          list([
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Toutes'),
                                  selected: eventKind == null,
                                  onSelected: (_) =>
                                      setState(() => eventKind = null),
                                ),
                                for (final k in CommercialEventKind.values)
                                  ChoiceChip(
                                    label: Text(k.label),
                                    selected: eventKind == k,
                                    onSelected: (_) =>
                                        setState(() => eventKind = k),
                                  ),
                              ],
                            ),
                            for (final e in store.data.commercialEvents.where(
                              (e) =>
                                  (eventKind == null || eventKind == e.kind) &&
                                  matches(
                                    '${e.id} ${e.documentId} ${e.partnerName} ${e.productName} ${e.reason}',
                                  ),
                            ))
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FlowBadge(e.kind.label),
                                      Text(
                                        '${e.partnerName} · ${e.productName}',
                                      ),
                                      Text('${e.quantity} ${e.unit}'),
                                      Text(e.reason),
                                      Text(commercialDate(e.createdAt)),
                                      TextButton(
                                        onPressed: () => open(
                                          [
                                                CommercialEventKind.receipt,
                                                CommercialEventKind
                                                    .supplierReturn,
                                              ].contains(e.kind)
                                              ? PurchaseDetailPage(
                                                  store: store,
                                                  id: e.documentId,
                                                )
                                              : SaleDetailPage(
                                                  store: store,
                                                  id: e.documentId,
                                                ),
                                        ),
                                        child: const Text('Voir le document'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (!store.data.commercialEvents.any(
                              (e) =>
                                  (eventKind == null || eventKind == e.kind) &&
                                  matches(
                                    '${e.id} ${e.documentId} ${e.partnerName} ${e.productName} ${e.reason}',
                                  ),
                            ))
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Aucune opération à afficher.'),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    ),
  );
}
