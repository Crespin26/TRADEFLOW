import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../application/trade_store.dart';
import '../forms.dart';
import '../design_system/components.dart';

class InventoryEditor extends StatefulWidget {
  const InventoryEditor({super.key, required this.store});
  final TradeStore store;
  @override
  State<InventoryEditor> createState() => _InventoryEditorState();
}

class _InventoryEditorState extends State<InventoryEditor> {
  // Capture the opening stock once; the store checks it again on validation.
  late final products = widget.store.data.products
      .where((p) => p.status != ProductStatus.archived)
      .toList();
  late final quantities = {
    for (final p in products) p.id: TextEditingController(),
  };
  final reason = TextEditingController();
  final search = TextEditingController();
  final form = GlobalKey<FormState>();
  String? error;
  bool busy = false;
  @override
  void dispose() {
    for (final c in quantities.values) {
      c.dispose();
    }
    reason.dispose();
    search.dispose();
    super.dispose();
  }

  List<StockCount> get counts => [
    for (final p in products)
      if (quantities[p.id]!.text.trim().isNotEmpty)
        StockCount(
          productId: p.id,
          productName: p.name,
          sku: p.sku,
          unit: p.unit,
          expectedQuantity: p.quantity,
          countedQuantity: int.parse(quantities[p.id]!.text),
        ),
  ];
  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    // Validate every controller, including products currently hidden by search.
    if (quantities.values.any(
      (c) => c.text.trim().isNotEmpty && integer(c.text) != null,
    )) {
      setState(
        () => error = 'Vérifiez toutes les quantités saisies, y compris les produits masqués par la recherche.',
      );
      return;
    }
    final entries = counts;
    if (entries.isEmpty) {
      setState(() => error = 'Renseignez au moins une quantité comptée.');
      return;
    }
    setState(() => busy = true);
    try {
      final confirmed = await showFlowConfirmation(
        context,
        title: 'Valider l’inventaire ?',
        description:
            '${entries.length} produit(s) compté(s), ${entries.where((c) => c.delta != 0).length} écart(s). Les quantités comptées remplaceront les stocks théoriques. Cette validation sera historisée.',
        confirmLabel: 'Valider l’inventaire',
      );
      if (!confirmed) {
        if (mounted) {
          setState(() => busy = false);
        }
        return;
      }
      await widget.store.performInventory(counts: entries, reason: reason.text);
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

  @override
  Widget build(BuildContext context) {
    final shown = products
        .where(
          (p) => '${p.name} ${p.sku}'.toLowerCase().contains(
            search.text.toLowerCase().trim(),
          ),
        )
        .toList();
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Nouvel inventaire')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: busy || products.isEmpty ? null : save,
              child: Text(busy ? 'Validation…' : 'Vérifier et valider'),
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Comptage physique · Stock global local'),
                    const SizedBox(height: 12),
                    const Text(
                      'Saisissez le stock réellement compté. Laissez vide les produits non comptés ; saisissez 0 pour une rupture constatée. Les produits archivés sont exclus.',
                    ),
                    const SizedBox(height: 20),
                    field(reason, 'Motif ou référence de l’inventaire'),
                    TextField(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Rechercher dans le comptage',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (products.isEmpty)
                      const Text(
                        'Créez un produit actif avant de réaliser un inventaire.',
                      ),
                    if (products.isNotEmpty && shown.isEmpty)
                      const Text(
                        'Aucun produit ne correspond à cette recherche.',
                      ),
                    for (final p in shown)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                p.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text('${p.sku} · ${p.unit}'),
                              const SizedBox(height: 8),
                              Text('Stock théorique : ${p.quantity} ${p.unit}'),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: ValueKey('count-${p.id}'),
                                controller: quantities[p.id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Quantité comptée',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? null
                                    : integer(v),
                              ),
                              ValueListenableBuilder(
                                valueListenable: quantities[p.id]!,
                                builder: (context, value, _) {
                                  final counted = int.tryParse(value.text);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      counted == null
                                          ? 'Non compté : stock inchangé.'
                                          : 'Écart : ${counted - p.quantity > 0 ? '+' : ''}${counted - p.quantity} ${p.unit}',
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
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
}
