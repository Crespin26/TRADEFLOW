import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/trade_store.dart';
import '../../domain/public_catalog.dart' show normalizeCatalogText;
import '../design_system/components.dart';
import '../operations/operation_details.dart';

class FulfilmentPage extends StatefulWidget {
  const FulfilmentPage({super.key, required this.store});
  final TradeStore store;
  @override
  State<FulfilmentPage> createState() => _FulfilmentPageState();
}

class _FulfilmentPageState extends State<FulfilmentPage> {
  final search = TextEditingController();
  String filter = 'Tous';
  int? days;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  bool matches(String text) =>
      normalizeCatalogText(text).contains(normalizeCatalogText(search.text));
  void open(Widget page) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final plans = {for (final p in store.data.deliveryPlans) p.orderId: p};
        final pending = store.data.orders
            .where(
              (o) =>
                  o.status != OrderStatus.cancelled && o.remainingQuantity > 0,
            )
            .toList();
        final since = days == null
            ? null
            : DateTime.now().subtract(Duration(days: days!));
        return Scaffold(
          appBar: AppBar(
            title: const Text('Livraisons et retours'),
            bottom: const TabBar(
              labelPadding: EdgeInsets.symmetric(horizontal: 4),
              tabs: [
                Tab(text: 'À livrer'),
                Tab(text: 'Retours'),
                Tab(text: 'Historique'),
              ],
            ),
          ),
          body: !store.loaded
              ? Center(
                  child: FlowStateView(
                    title: 'Données indisponibles',
                    description:
                        store.loadError ?? 'Chargement des données locales.',
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
                          labelText: 'Rechercher un partenaire ou un suivi',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FlowBadge('${pending.length} à livrer'),
                                  FlowBadge(
                                    '${pending.where((o) => plans[o.id]?.lateAt(DateTime.now()) == true).length} en retard',
                                    tone: FlowTone.warning,
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  for (final f in [
                                    'Tous',
                                    'En retard',
                                    'Sans suivi',
                                  ])
                                    ChoiceChip(
                                      label: Text(f),
                                      selected: filter == f,
                                      onSelected: (_) =>
                                          setState(() => filter = f),
                                    ),
                                ],
                              ),
                              for (final o in pending.where(
                                (o) =>
                                    matches(
                                      '${o.id} ${o.customerName} ${o.productName} ${plans[o.id]?.carrier ?? ''} ${plans[o.id]?.trackingNumber ?? ''}',
                                    ) &&
                                    (filter != 'En retard' ||
                                        plans[o.id]?.lateAt(DateTime.now()) ==
                                            true) &&
                                    (filter != 'Sans suivi' ||
                                        (plans[o.id]?.carrier.isEmpty !=
                                                false &&
                                            plans[o.id]
                                                    ?.trackingNumber
                                                    .isEmpty !=
                                                false)),
                              ))
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          o.customerName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(o.productName),
                                        Text(
                                          'Reste à livrer : ${o.remainingQuantity} ${o.unit}',
                                        ),
                                        FlowBadge(o.status.label),
                                        if (plans[o.id] != null) ...[
                                          if (plans[o.id]!.carrier.isNotEmpty)
                                            Text(plans[o.id]!.carrier),
                                          if (plans[o.id]!
                                              .trackingNumber
                                              .isNotEmpty)
                                            SelectableText(
                                              plans[o.id]!.trackingNumber,
                                            ),
                                          if (plans[o.id]!.expectedDate != null)
                                            Text(
                                              'Prévu le ${commercialDate(plans[o.id]!.expectedDate!)}',
                                            ),
                                        ],
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: () => open(
                                              SaleDetailPage(
                                                store: store,
                                                id: o.id,
                                              ),
                                            ),
                                            child: const Text(
                                              'Ouvrir le suivi',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (pending.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Aucune commande restant à livrer.',
                                  ),
                                ),
                            ],
                          ),
                          ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              const Text(
                                'Retours possibles sur les quantités effectivement livrées ou reçues, non encore retournées.',
                              ),
                              for (final o in store.data.orders.where(
                                (o) =>
                                    o.returnableQuantity > 0 &&
                                    matches(
                                      '${o.id} ${o.customerName} ${o.productName}',
                                    ),
                              ))
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const FlowBadge('Client'),
                                        Text(o.customerName),
                                        Text(o.productName),
                                        Text(
                                          '${o.returnableQuantity} ${o.unit} retournables',
                                        ),
                                        TextButton(
                                          onPressed: () => open(
                                            SaleDetailPage(
                                              store: store,
                                              id: o.id,
                                            ),
                                          ),
                                          child: const Text(
                                            'Traiter le retour client',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              for (final p in store.data.purchases.where(
                                (p) =>
                                    p.returnableQuantity > 0 &&
                                    matches(
                                      '${p.id} ${p.supplierName} ${p.productName}',
                                    ),
                              ))
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const FlowBadge('Fournisseur'),
                                        Text(p.supplierName),
                                        Text(p.productName),
                                        Text(
                                          '${p.returnableQuantity} ${p.unit} retournables',
                                        ),
                                        TextButton(
                                          onPressed: () => open(
                                            PurchaseDetailPage(
                                              store: store,
                                              id: p.id,
                                            ),
                                          ),
                                          child: const Text(
                                            'Traiter le retour fournisseur',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (!store.data.orders.any(
                                    (o) => o.returnableQuantity > 0,
                                  ) &&
                                  !store.data.purchases.any(
                                    (p) => p.returnableQuantity > 0,
                                  ))
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Aucune quantité retournable.'),
                                ),
                            ],
                          ),
                          ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              Wrap(
                                spacing: 8,
                                children: [
                                  for (final d in <int?>[null, 7, 30])
                                    ChoiceChip(
                                      label: Text(
                                        d == null
                                            ? 'Toutes les dates'
                                            : '$d jours',
                                      ),
                                      selected: days == d,
                                      onSelected: (_) =>
                                          setState(() => days = d),
                                    ),
                                ],
                              ),
                              for (final e in store.data.commercialEvents.where(
                                (e) =>
                                    e.kind != CommercialEventKind.receipt &&
                                    (since == null ||
                                        !e.createdAt.isBefore(since)) &&
                                    matches(
                                      '${e.documentId} ${e.partnerName} ${e.productName} ${e.reason} ${e.trackingNumber}',
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
                                        if (e.kind ==
                                            CommercialEventKind.customerReturn)
                                          Text(
                                            e.restocked
                                                ? 'Réintégré au stock disponible'
                                                : 'Hors stock disponible',
                                          ),
                                        if (e.carrier.isNotEmpty)
                                          Text(e.carrier),
                                        if (e.trackingNumber.isNotEmpty)
                                          SelectableText(e.trackingNumber),
                                      ],
                                    ),
                                  ),
                                ),
                              if (!store.data.commercialEvents.any(
                                (e) => e.kind != CommercialEventKind.receipt,
                              ))
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Aucune livraison ni retour enregistré.',
                                  ),
                                ),
                            ],
                          ),
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
