import '../operations/document_editor.dart';
import '../operations/operation_details.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models.dart';
import '../../application/trade_store.dart';
import '../../domain/public_catalog.dart' show normalizeCatalogText;
import '../design_system/components.dart';
import '../catalog/product_widgets.dart' show publicPrice;
import '../forms.dart' show friendlyError, orderForm;
import 'partner_editor.dart';

class PartnersPage extends StatefulWidget {
  const PartnersPage({super.key, required this.store, this.initialKind});
  final TradeStore store;
  final ContactKind? initialKind;
  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Clients et fournisseurs')),
      floatingActionButton: widget.store.loaded
          ? FloatingActionButton.extended(
              onPressed: widget.store.busy
                  ? null
                  : () => partnerEditor(
                      context,
                      widget.store,
                      initialKind: widget.initialKind ?? ContactKind.client,
                    ),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Nouveau partenaire'),
            )
          : null,
      body: !widget.store.loaded
          ? Center(
              child: FlowStateView(
                title: widget.store.loadError == null
                    ? 'Chargement des partenaires'
                    : 'Partenaires indisponibles',
                description:
                    widget.store.loadError ?? 'Ouverture des fiches locales.',
                loading: widget.store.loadError == null,
                actionLabel: widget.store.loadError == null
                    ? null
                    : 'Réessayer',
                onAction: widget.store.busy ? null : widget.store.load,
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  children: [
                    TextField(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Rechercher un partenaire',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ContactsManagement(
                      store: widget.store,
                      query: search.text,
                      initialKind: widget.initialKind,
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}

class ContactsManagement extends StatefulWidget {
  const ContactsManagement({
    super.key,
    required this.store,
    this.query = '',
    this.initialKind,
  });
  final TradeStore store;
  final String query;
  final ContactKind? initialKind;
  @override
  State<ContactsManagement> createState() => _ContactsManagementState();
}

class _ContactsManagementState extends State<ContactsManagement> {
  late ContactKind? kind = widget.initialKind;
  bool? archived = false;
  String? country;
  @override
  Widget build(BuildContext context) {
    final contacts = widget.store.data.contacts;
    final countries = contacts.map((c) => c.country).toSet().toList()..sort();
    final effectiveCountry = countries.contains(country) ? country : null;
    final query = normalizeCatalogText(widget.query);
    final items =
        contacts
            .where(
              (c) =>
                  (kind == null || kind == c.kind) &&
                  (archived == null || archived == c.archived) &&
                  (effectiveCountry == null || effectiveCountry == c.country) &&
                  normalizeCatalogText(
                    '${c.name} ${c.country} ${c.email} ${c.phone} ${c.contactPerson} ${c.city} ${c.taxId}',
                  ).contains(query),
            )
            .toList()
          ..sort(
            (a, b) =>
                normalizeCatalogText(a.name)
                    .compareTo(normalizeCatalogText(b.name)),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('Tous'),
              selected: kind == null,
              onSelected: (_) => setState(() => kind = null),
            ),
            for (final k in ContactKind.values)
              ChoiceChip(
                label: Text(
                  k == ContactKind.client ? 'Clients' : 'Fournisseurs',
                ),
                selected: kind == k,
                onSelected: (_) => setState(() => kind = k),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final state in <bool?>[false, true, null])
              ChoiceChip(
                label: Text(
                  state == null
                      ? 'Tous les statuts'
                      : state
                      ? 'Archivés'
                      : 'Actifs',
                ),
                selected: archived == state,
                onSelected: (_) => setState(() => archived = state),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'partner-countries-${countries.join()}-$effectiveCountry',
          ),
          initialValue: effectiveCountry,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Pays'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Tous les pays'),
            ),
            for (final c in countries)
              DropdownMenuItem(
                value: c,
                child: Text(c, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => country = v),
        ),
        const SizedBox(height: 16),
        Text('${items.length} partenaire(s)'),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const FlowStateView(
            title: 'Aucun partenaire à afficher',
            description:
                'Créez une fiche ou modifiez les filtres et la recherche.',
            icon: Icons.people_outline,
          ),
        for (final c in items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(c.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      FlowBadge(c.kind.label),
                      if (c.archived) const FlowBadge('Archivé'),
                      Text(
                        [
                          c.city,
                          c.country,
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                    ],
                  ),
                  if (c.contactPerson.isNotEmpty) Text(c.contactPerson),
                  if (c.email.isNotEmpty) SelectableText(c.email),
                  if (c.phone.isNotEmpty) SelectableText(c.phone),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartnerDetailPage(
                            store: widget.store,
                            contactId: c.id,
                          ),
                        ),
                      ),
                      child: const Text('Ouvrir la fiche'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class PartnerDetailPage extends StatelessWidget {
  const PartnerDetailPage({
    super.key,
    required this.store,
    required this.contactId,
  });
  final TradeStore store;
  final String contactId;
  Future<void> archive(BuildContext context, Contact c) async {
    final confirmed = await showFlowConfirmation(
      context,
      title: c.archived
          ? 'Restaurer le partenaire ?'
          : 'Archiver le partenaire ?',
      description: c.archived ? 'La fiche sera de nouveau active.' : 'La fiche restera consultable avec son historique. Un client archivé ne pourra pas être choisi pour une nouvelle commande.',
      confirmLabel: c.archived ? 'Restaurer' : 'Archiver',
    );
    if (!confirmed) return;
    try {
      await store.setContactArchived(
        c.id,
        !c.archived,
        expectedRevision: c.revision,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final c = store.data.contacts.where((c) => c.id == contactId).firstOrNull;
      if (c == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Partenaire')),
          body: const Center(child: Text('Fiche indisponible.')),
        );
      }
      final orders =
          store.data.orders.where((o) => o.customerId == c.id).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche partenaire')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(c.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FlowBadge(c.kind.label),
                    FlowBadge(c.archived ? 'Archivé' : 'Actif'),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (!c.archived)
                      TextButton.icon(
                        onPressed: store.busy
                            ? null
                            : () => partnerEditor(context, store, contact: c),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Modifier'),
                      ),
                    TextButton.icon(
                      onPressed: store.busy ? null : () => archive(context, c),
                      icon: Icon(
                        c.archived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                      ),
                      label: Text(c.archived ? 'Restaurer' : 'Archiver'),
                    ),
                    if (!c.archived && c.kind == ContactKind.client)
                      TextButton.icon(
                        onPressed: store.busy
                            ? null
                            : () => orderForm(
                                context,
                                store,
                                initialCustomerId: c.id,
                              ),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Nouvelle commande'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Coordonnées',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final entry in {
                  'Personne à contacter': c.contactPerson,
                  'E-mail': c.email,
                  'Téléphone': c.phone,
                  'Adresse': c.address,
                  'Ville': c.city,
                  'Code postal': c.postalCode,
                  'Pays': c.country,
                  'Identifiant fiscal / registre': c.taxId,
                  'Site web': c.website,
                }.entries)
                  if (entry.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SelectableText(entry.value),
                        ],
                      ),
                    ),
                if (c.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Notes internes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(c.notes),
                ],
                const SizedBox(height: 24),
                Text(
                  c.kind == ContactKind.client
                      ? 'Commandes internes'
                      : 'Relation fournisseur',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (c.kind == ContactKind.supplier) ...[
                  if (!c.archived)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialDocumentEditor(
                                context,
                                store,
                                purchase: true,
                                partnerId: c.id,
                              ),
                        child: const Text('Nouvel achat'),
                      ),
                    ),
                  if (!store.data.purchases.any((p) => p.supplierId == c.id))
                    const Text('Aucun achat enregistré pour ce fournisseur.'),
                  for (final p in store.data.purchases.where(
                    (p) => p.supplierId == c.id,
                  ))
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.productName),
                            FlowBadge(p.status.label),
                            Text(
                              '${publicPrice(p.total)} · Reçu ${p.receivedQuantity}/${p.quantity} · Retourné ${p.returnedQuantity}',
                            ),
                            TextButton(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PurchaseDetailPage(
                                    store: store,
                                    id: p.id,
                                  ),
                                ),
                              ),
                              child: const Text('Ouvrir l’achat'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FlowBadge('${orders.length} commande(s)'),
                      FlowBadge(
                        '${orders.where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.shipped).length} en cours',
                      ),
                    ],
                  ),
                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Aucune commande interne pour ce client.'),
                    ),
                  for (final o in orders)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(o.id),
                            Text(o.productName),
                            Text('Client à la commande : ${o.customerName}'),
                            Text(
                              '${o.quantity} × ${publicPrice(o.unitPrice)} · ${publicPrice(o.total)}',
                            ),
                            FlowBadge(o.status.label),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy · HH:mm',
                                'fr',
                              ).format(o.createdAt.toLocal()),
                            ),
                            Text('Destination : ${o.destination}'),
                            Text(
                              'Livré ${o.deliveredQuantity}/${o.quantity} · Retourné ${o.returnedQuantity}',
                            ),
                            TextButton(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SaleDetailPage(store: store, id: o.id),
                                ),
                              ),
                              child: const Text('Suivi et retours'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                if (c.kind == ContactKind.client) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Devis client',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (!c.archived)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: store.busy
                            ? null
                            : () => commercialDocumentEditor(
                                context,
                                store,
                                partnerId: c.id,
                              ),
                        child: const Text('Nouveau devis'),
                      ),
                    ),
                  if (!store.data.quotes.any((q) => q.customerId == c.id))
                    const Text('Aucun devis enregistré pour ce client.'),
                  for (final q in store.data.quotes.where(
                    (q) => q.customerId == c.id,
                  ))
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.productName),
                            FlowBadge(q.status.label),
                            Text(publicPrice(q.total)),
                            TextButton(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      QuoteDetailPage(store: store, id: q.id),
                                ),
                              ),
                              child: const Text('Ouvrir le devis'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
