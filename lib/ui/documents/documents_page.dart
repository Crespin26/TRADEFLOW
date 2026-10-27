import '../../domain/document_catalog.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../domain/business_documents.dart';
import '../../application/trade_store.dart';
import '../../domain/public_catalog.dart' show normalizeCatalogText;
import 'business_pdf.dart';
import '../forms.dart' show field, SaveDialog, showEditor, friendlyError;
import '../design_system/components.dart';

typedef DocumentExporter = Future<bool> Function(
  Uint8List bytes,
  String filename,
);
Future<void> companyProfileForm(BuildContext context, TradeStore store) async {
  final original = store.data.company;
  final name = TextEditingController(text: original.name),
      address = TextEditingController(text: original.address),
      country = TextEditingController(text: original.country),
      email = TextEditingController(text: original.email),
      phone = TextEditingController(text: original.phone),
      registration = TextEditingController(text: original.registration);
  await showEditor(
    context: context,
    builder: (_) => SaveDialog(
      title: 'Entreprise émettrice',
      description:
          'Ces coordonnées apparaîtront sur les prochains PDF exportés.',
      fields: [
        field(name, 'Nom de l’entreprise'),
        field(address, 'Adresse', required: false),
        field(country, 'Pays', required: false),
        field(email, 'E-mail', required: false),
        field(phone, 'Téléphone', required: false),
        field(registration, 'Registre / identifiant', required: false),
      ],
      save: () => store.saveCompanyProfile(
        CompanyProfile(
          name: name.text,
          address: address.text,
          country: country.text,
          email: email.text,
          phone: phone.text,
          registration: registration.text,
        ),
        expectedRevision: original.revision,
      ),
    ),
  );
  for (final c in [name, address, country, email, phone, registration]) {
    c.dispose();
  }
}

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key, required this.store, this.exporter});
  final TradeStore store;
  final DocumentExporter? exporter;
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final search = TextEditingController();
  BusinessDocumentKind? kind;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final query = normalizeCatalogText(search.text);
      final docs = businessDocuments(store.data)
          .where(
            (d) =>
                (kind == null || d.kind == kind) &&
                normalizeCatalogText('${d.reference} ${d.partner} ${d.product}')
                    .contains(query),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: const Text('Documents commerciaux'),
          actions: [
            IconButton(
              tooltip: 'Entreprise émettrice',
              onPressed: !store.loaded || store.busy
                  ? null
                  : () => companyProfileForm(context, store),
              icon: const Icon(Icons.business_outlined),
            ),
          ],
        ),
        body: !store.loaded
            ? Center(
                child: FlowStateView(
                  title: 'Documents indisponibles',
                  description:
                      store.loadError ?? 'Chargement des données locales.',
                  loading: store.loadError == null,
                  actionLabel: store.loadError == null ? null : 'Réessayer',
                  onAction: store.busy ? null : store.load,
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (store.data.company.name.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Renseignez le nom de l’entreprise pour exporter les PDF.',
                                ),
                                TextButton(
                                  onPressed: store.busy
                                      ? null
                                      : () =>
                                            companyProfileForm(context, store),
                                  child: const Text('Renseigner l’entreprise'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      TextField(
                        controller: search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Rechercher un document',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<BusinessDocumentKind>(
                        initialValue: kind,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Type de document',
                        ),
                        items: [
                          const DropdownMenuItem<BusinessDocumentKind>(
                            value: null,
                            child: Text('Tous les types'),
                          ),
                          for (final k in BusinessDocumentKind.values)
                            DropdownMenuItem(
                              value: k,
                              child: Text(
                                k.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => kind = v),
                      ),
                      const SizedBox(height: 16),
                      Text('${docs.length} document(s)'),
                      const SizedBox(height: 12),
                      if (docs.isEmpty)
                        const Text(
                          'Aucun document à afficher. Les documents apparaissent à partir des devis, commandes et opérations enregistrés.',
                        ),
                      for (final doc in docs)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  doc.kind.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(doc.partner),
                                Text(doc.product),
                                if (doc.issuedAt != null)
                                  const Text(
                                    'Version archivée lors d’un export',
                                  ),
                                Text(
                                  '${documentDate(doc.date)} · ${doc.status}',
                                ),
                                if (doc.total != null)
                                  Text(documentMoney(doc.total!)),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () => Navigator.push<void>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DocumentContentPage(
                                          document: doc,
                                          store: store,
                                          exporter: widget.exporter,
                                        ),
                                      ),
                                    ),
                                    child: const Text('Aperçu et PDF'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      );
    },
  );
}

class DocumentContentPage extends StatefulWidget {
  const DocumentContentPage({
    super.key,
    required this.document,
    this.exporter,
    this.store,
  });
  final BusinessDocument document;
  final TradeStore? store;
  final DocumentExporter? exporter;
  @override
  State<DocumentContentPage> createState() => _DocumentContentPageState();
}

class _DocumentContentPageState extends State<DocumentContentPage> {
  bool busy = false;
  String? error;
  Future<void> export() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final bytes = await buildBusinessPdf(widget.document);
      await widget.store?.archiveBusinessDocument(widget.document);
      final exporter =
          widget.exporter ??
          (bytes, name) => Printing.sharePdf(bytes: bytes, filename: name);
      final completed = await exporter(bytes, widget.document.filename);
      if (completed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF transmis au service de téléchargement ou de partage.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.document;
    return Scaffold(
      appBar: AppBar(title: const Text('Aperçu du contenu')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              FilledButton.icon(
                onPressed: busy || d.company.name.isEmpty ? null : export,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  busy ? 'Création du PDF…' : 'Exporter / partager le PDF',
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                d.company.name.isEmpty
                    ? 'Entreprise à renseigner'
                    : d.company.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              for (final value in [
                d.company.address,
                d.company.country,
                d.company.email,
                d.company.phone,
                d.company.registration,
              ])
                if (value.isNotEmpty) Text(value),
              const SizedBox(height: 24),
              Text(d.kind.label, style: Theme.of(context).textTheme.titleLarge),
              SelectableText(d.reference),
              Text('${documentDate(d.date)} · ${d.status}'),
              const SizedBox(height: 20),
              Text('Partenaire : ${d.partner}'),
              Text('Destination : ${d.destination}'),
              const SizedBox(height: 16),
              Text(d.product, style: Theme.of(context).textTheme.titleMedium),
              Text('Quantité : ${d.quantity} ${d.unit}'),
              if (d.unitPrice != null)
                Text('Prix unitaire : ${documentMoney(d.unitPrice!)}'),
              if (d.total != null)
                Text('Total produits : ${documentMoney(d.total!)}'),
              const SizedBox(height: 16),
              for (final detail in d.details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(detail),
                ),
              if (d.notes.isNotEmpty) Text(d.notes),
              const SizedBox(height: 24),
              const Text(
                'Montants des produits uniquement. Transport et taxes non calculés. Ce document ne constate aucun paiement.',
              ),
              if (d.company.name.isEmpty)
                const Text(
                  'Renseignez l’entreprise dans la bibliothèque puis rouvrez le document pour exporter.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
