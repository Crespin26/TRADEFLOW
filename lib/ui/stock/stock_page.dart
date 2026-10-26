import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../domain/trade_store.dart';
import '../../domain/public_catalog.dart' show normalizeCatalogText;
import '../forms.dart';
import '../design_system/components.dart';
import 'inventory_editor.dart';

String stockDate(DateTime value) =>
    DateFormat('dd/MM/yyyy · HH:mm', 'fr').format(value.toLocal());

enum StockFilter { all, low, empty, available }

extension on StockFilter {
  String get label => switch (this) {
    StockFilter.all => 'Tous',
    StockFilter.low => 'En alerte',
    StockFilter.empty => 'Ruptures',
    StockFilter.available => 'Disponibles',
  };
  bool accepts(Product p) => switch (this) {
    StockFilter.all => true,
    StockFilter.low => p.lowStock,
    StockFilter.empty => p.quantity == 0,
    StockFilter.available => p.quantity > 0,
  };
}

class StockPage extends StatefulWidget {
  const StockPage({super.key, required this.store});
  final TradeStore store;
  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final search = TextEditingController();
  StockFilter filter = StockFilter.all;
  StockMovementKind? kind;
  int? days;
  String? productId;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  bool matches(String value) =>
      normalizeCatalogText(value).contains(normalizeCatalogText(search.text));
  void inventory() => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => InventoryEditor(store: widget.store)),
  );
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestion des stocks'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Stocks'),
                Tab(text: 'Mouvements'),
                Tab(text: 'Inventaires'),
              ],
            ),
          ),
          body: !store.loaded
              ? Center(
                  child: FlowStateView(
                    title: store.loadError == null
                        ? 'Chargement des stocks'
                        : 'Stocks indisponibles',
                    description:
                        store.loadError ?? 'Ouverture des données locales.',
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
                        decoration: InputDecoration(
                          labelText: 'Rechercher dans les stocks',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Effacer la recherche',
                                  onPressed: () => setState(search.clear),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          stockList(store),
                          movementList(store),
                          inventoryList(store),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    ),
  );
  Widget stockList(TradeStore store) {
    final active = store.data.products
        .where((p) => p.status != ProductStatus.archived)
        .toList();
    final items =
        active
            .where(
              (p) =>
                  filter.accepts(p) &&
                  matches('${p.name} ${p.sku} ${p.category}'),
            )
            .toList()
          ..sort(
            (a, b) =>
                normalizeCatalogText(a.name)
                    .compareTo(normalizeCatalogText(b.name)),
          );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Text(
          'Stock global sur cet appareil. Les commandes publiques simulées ne réservent aucun stock.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FlowBadge('${active.length} références actives'),
            FlowBadge(
              '${active.where((p) => p.quantity == 0).length} ruptures',
              tone: FlowTone.error,
            ),
            FlowBadge(
              '${active.where((p) => p.lowStock).length} alertes de seuil',
              tone: FlowTone.warning,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final f in StockFilter.values)
              ChoiceChip(
                label: Text(f.label),
                selected: filter == f,
                onSelected: (_) => setState(() => filter = f),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: store.busy || active.isEmpty ? null : inventory,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Faire un inventaire'),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const FlowStateView(
            title: 'Aucun stock à afficher',
            description: 'Ajoutez un produit actif ou modifiez les filtres.',
            icon: Icons.inventory_2_outlined,
          ),
        for (final p in items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(p.name, style: Theme.of(context).textTheme.titleMedium),
                  Text('${p.sku} · ${p.category}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${p.quantity} ${p.unit} en stock',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Seuil : ${p.threshold} ${p.unit}'),
                      if (p.quantity == 0)
                        const FlowBadge('Rupture', tone: FlowTone.error)
                      else if (p.lowStock)
                        const FlowBadge('Stock faible', tone: FlowTone.warning),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: store.busy
                            ? null
                            : () => stockForm(context, store, p),
                        icon: const Icon(Icons.add),
                        label: const Text('Entrée'),
                      ),
                      TextButton.icon(
                        onPressed: store.busy || p.quantity == 0
                            ? null
                            : () => stockForm(
                                context,
                                store,
                                p,
                                initialDirection: -1,
                              ),
                        icon: const Icon(Icons.remove),
                        label: const Text('Sortie'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => productId = p.id),
                        child: const Text('Filtrer ses mouvements'),
                      ),
                    ],
                  ),
                  if (productId == p.id)
                    const Text('Filtre actif dans l’onglet Mouvements.'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget movementList(TradeStore store) {
    final since = days == null
        ? null
        : DateTime.now().subtract(Duration(days: days!));
    final items =
        store.data.movements
            .where(
              (m) =>
                  (kind == null || kind == m.kind) &&
                  (productId == null || m.productId == productId) &&
                  (since == null || !m.createdAt.isBefore(since)) &&
                  matches(
                    '${m.productName} ${m.sku} ${m.reason} ${m.reference ?? ''}',
                  ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Text(
          'Historique immuable. Corrigez une erreur par un nouveau mouvement motivé.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<StockMovementKind>(
          initialValue: kind,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Type de mouvement'),
          items: [
            const DropdownMenuItem<StockMovementKind>(
              value: null,
              child: Text('Tous les types'),
            ),
            for (final k in StockMovementKind.values)
              DropdownMenuItem(value: k, child: Text(k.label)),
          ],
          onChanged: (v) => setState(() => kind = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('stock-product-$productId'),
          initialValue: productId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Produit'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Tous les produits'),
            ),
            for (final p in store.data.products)
              DropdownMenuItem(
                value: p.id,
                child: Text('${p.name} · ${p.sku}'),
              ),
          ],
          onChanged: (v) => setState(() => productId = v),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final d in <int?>[null, 7, 30])
              ChoiceChip(
                label: Text(
                  d == null ? 'Toutes les dates' : '$d derniers jours',
                ),
                selected: days == d,
                onSelected: (_) => setState(() => days = d),
              ),
          ],
        ),
        Text('${items.length} mouvement(s)'),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text('Aucun mouvement ne correspond aux filtres.'),
        if (productId != null)
          const Text(
            'Les anciens mouvements sans identifiant produit restent accessibles avec « Tous les produits ».',
          ),
        for (final m in items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.productName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (m.sku.isNotEmpty) Text(m.sku),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      FlowBadge(m.kind.label),
                      Text(
                        '${m.delta > 0 ? '+' : ''}${m.delta} ${m.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (m.beforeQuantity != null && m.afterQuantity != null)
                    Text(
                      'Stock : ${m.beforeQuantity} → ${m.afterQuantity} ${m.unit}',
                    )
                  else
                    const Text(
                      'Stock avant/après non renseigné dans l’ancienne sauvegarde.',
                    ),
                  Text(m.reason),
                  Text(stockDate(m.createdAt)),
                  if (m.reference != null)
                    SelectableText('Référence : ${m.reference}'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget inventoryList(TradeStore store) {
    final items = store.data.inventories
        .where(
          (i) => matches(
            '${i.id} ${i.reason} ${i.counts.map((c) => '${c.productName} ${c.sku}').join(' ')}',
          ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Text(
          'Inventaires validés, conservés avec les quantités théoriques, les comptages et les écarts.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed:
                store.busy ||
                    !store.data.products.any(
                      (p) => p.status != ProductStatus.archived,
                    )
                ? null
                : inventory,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Nouvel inventaire'),
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Aucun inventaire à afficher.'),
          ),
        for (final i in items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.reason,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(stockDate(i.createdAt)),
                  Text(
                    '${i.counts.length} produit(s) compté(s) · ${i.correctedProducts} corrigé(s)',
                  ),
                  TextButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventoryDetailPage(inventory: i),
                      ),
                    ),
                    child: const Text('Voir le comptage'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class InventoryDetailPage extends StatelessWidget {
  const InventoryDetailPage({super.key, required this.inventory});
  final StockInventory inventory;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Inventaire validé')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SelectableText(inventory.id),
        Text(inventory.reason),
        Text(stockDate(inventory.createdAt)),
        const SizedBox(height: 16),
        for (final c in inventory.counts)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.productName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${c.sku} · ${c.unit}'),
                  Text(
                    'Théorique : ${c.expectedQuantity} · Compté : ${c.countedQuantity}',
                  ),
                  Text('Écart : ${c.delta > 0 ? '+' : ''}${c.delta} ${c.unit}'),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
