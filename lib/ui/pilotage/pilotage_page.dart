import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/pilotage.dart';
import '../../domain/trade_store.dart';
import '../demo_profile.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';
import '../operations/operations_page.dart';
import '../fulfilment/fulfilment_page.dart';
import '../stock/stock_page.dart';
import '../documents/documents_page.dart';

class PilotagePage extends StatefulWidget {
  const PilotagePage({
    super.key,
    required this.store,
    this.profile = DemoProfile.administrator,
  });
  final TradeStore store;
  final DemoProfile profile;
  @override
  State<PilotagePage> createState() => _PilotagePageState();
}

class _PilotagePageState extends State<PilotagePage> {
  PilotagePeriod period = PilotagePeriod.month;
  PilotageView get view => switch (widget.profile) {
    DemoProfile.warehouse => PilotageView.warehouse,
    DemoProfile.sales => PilotageView.sales,
    DemoProfile.accountant => PilotageView.accounting,
    _ => PilotageView.administrator,
  };
  void open(Widget page) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));
  Future<void> report(PilotageSnapshot snapshot) async {
    final csv = snapshot.reportCsv(view);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rapport CSV · ${period.label}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(child: SelectableText(csv)),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: csv));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rapport CSV copié.')),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Copie indisponible. Sélectionnez le texte du rapport.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier le rapport CSV'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final snapshot = PilotageSnapshot(
        store.data,
        now: DateTime.now(),
        period: period,
      );
      final metrics = snapshot.metrics(view);
      final activity = snapshot.activity;
      final maxActivity = activity.fold<int>(
        1,
        (max, d) => d.operations > max ? d.operations : max,
      );
      final maxSales = activity.fold<BigInt>(
        BigInt.one,
        (max, d) => d.salesValue > max ? d.salesValue : max,
      );
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pilotage'),
          actions: [
            IconButton(
              tooltip: 'Actualiser le pilotage',
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Rapport CSV',
              onPressed: !store.loaded ? null : () => report(snapshot),
              icon: const Icon(Icons.table_view_outlined),
            ),
          ],
        ),
        body: !store.loaded
            ? Center(
                child: FlowStateView(
                  title: 'Pilotage indisponible',
                  description:
                      store.loadError ?? 'Chargement des données locales.',
                  loading: store.loadError == null,
                  actionLabel: store.loadError == null ? null : 'Réessayer',
                  onAction: store.busy ? null : store.load,
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Vue ${widget.profile.label.toLowerCase()}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Indicateurs calculés depuis les opérations locales. Les montants ne représentent pas des paiements encaissés.',
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final p in PilotagePeriod.values)
                            ChoiceChip(
                              label: Text(p.label),
                              selected: period == p,
                              onSelected: (_) => setState(() => period = p),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 900
                              ? 3
                              : constraints.maxWidth >= 560
                              ? 2
                              : 1;
                          final width =
                              (constraints.maxWidth - (columns - 1) * 12) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final m in metrics)
                                SizedBox(
                                  width: width,
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(m.label),
                                          const SizedBox(height: 10),
                                          Text(
                                            m.money
                                                ? pilotageMoney(m.value)
                                                : '${m.value}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            m.scope,
                                            style: const TextStyle(
                                              color: FlowColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Activité des 7 derniers jours',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        view == PilotageView.warehouse
                            ? 'Nombre d’opérations logistiques enregistrées par jour.'
                            : 'Valeur des commandes créées, hors annulations. Le filtre de période reste appliqué.',
                      ),
                      const SizedBox(height: 12),
                      for (final day in activity)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 12,
                                children: [
                                  Text(
                                    '${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}',
                                  ),
                                  Text(
                                    view == PilotageView.warehouse
                                        ? '${day.operations} opération(s)'
                                        : pilotageMoney(day.salesValue),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: view == PilotageView.warehouse
                                    ? day.operations / maxActivity
                                    : day.salesValue.toDouble() /
                                          maxSales.toDouble(),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                        ),
                      if (view != PilotageView.warehouse) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Produits les plus commandés',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text(
                          'Classement par valeur des commandes créées sur la période, hors annulations.',
                        ),
                        if (snapshot.topProducts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Aucune vente sur cette période.'),
                          ),
                        for (final rank in snapshot.topProducts)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Text(rank.name),
                                  Text(pilotageMoney(rank.value)),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'État des commandes créées',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FlowBadge('${snapshot.orders.length} commandes'),
                            FlowBadge('${snapshot.cancelledSales} annulées'),
                          ],
                        ),
                        if (view != PilotageView.accounting)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Devis créés convertis : ${snapshot.convertedQuotes}/${snapshot.quotes.length} (${(snapshot.quoteConversion * 100).toStringAsFixed(0)} %). État actuel des devis créés sur la période.',
                            ),
                          ),
                      ],
                      if (snapshot.legacyDeliveries > 0 &&
                          period != PilotagePeriod.all)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Les livraisons historiques sans date d’opération sont incluses uniquement dans « Toutes dates ».',
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (view != PilotageView.warehouse)
                            TextButton.icon(
                              onPressed: () =>
                                  open(OperationsPage(store: store)),
                              icon: const Icon(Icons.handshake_outlined),
                              label: const Text('Opérations commerciales'),
                            ),
                          if (view != PilotageView.accounting) ...[
                            TextButton.icon(
                              onPressed: () =>
                                  open(FulfilmentPage(store: store)),
                              icon: const Icon(Icons.local_shipping_outlined),
                              label: const Text('Livraisons et retours'),
                            ),
                            TextButton.icon(
                              onPressed: () => open(StockPage(store: store)),
                              icon: const Icon(Icons.warehouse_outlined),
                              label: const Text('Stocks et inventaires'),
                            ),
                          ],
                          TextButton.icon(
                            onPressed: () => open(DocumentsPage(store: store)),
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Documents commerciaux'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      );
    },
  );
}
