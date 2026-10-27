import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../application/trade_store.dart';
import '../forms.dart' show field, friendlyError;

Future<void> partnerEditor(
  BuildContext context,
  TradeStore store, {
  Contact? contact,
  ContactKind initialKind = ContactKind.client,
}) => Navigator.push<void>(
  context,
  MaterialPageRoute(
    builder: (_) =>
        PartnerEditor(store: store, contact: contact, initialKind: initialKind),
  ),
);

class PartnerEditor extends StatefulWidget {
  const PartnerEditor({
    super.key,
    required this.store,
    this.contact,
    this.initialKind = ContactKind.client,
  });
  final TradeStore store;
  final Contact? contact;
  final ContactKind initialKind;
  @override
  State<PartnerEditor> createState() => _PartnerEditorState();
}

class _PartnerEditorState extends State<PartnerEditor> {
  final form = GlobalKey<FormState>();
  late final values = <String, TextEditingController>{
    'name': TextEditingController(text: widget.contact?.name),
    'country': TextEditingController(text: widget.contact?.country),
    'email': TextEditingController(text: widget.contact?.email),
    'phone': TextEditingController(text: widget.contact?.phone),
    'contactPerson': TextEditingController(text: widget.contact?.contactPerson),
    'address': TextEditingController(text: widget.contact?.address),
    'city': TextEditingController(text: widget.contact?.city),
    'postalCode': TextEditingController(text: widget.contact?.postalCode),
    'taxId': TextEditingController(text: widget.contact?.taxId),
    'website': TextEditingController(text: widget.contact?.website),
    'notes': TextEditingController(text: widget.contact?.notes),
  };
  late ContactKind kind = widget.contact?.kind ?? widget.initialKind;
  bool busy = false;
  String? error;
  String value(String key) => values[key]!.text;
  @override
  void dispose() {
    for (final c in values.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final original = widget.contact;
      if (original == null) {
        await widget.store.addContact(
          name: value('name'),
          kind: kind,
          country: value('country'),
          email: value('email'),
          phone: value('phone'),
          contactPerson: value('contactPerson'),
          address: value('address'),
          city: value('city'),
          postalCode: value('postalCode'),
          taxId: value('taxId'),
          website: value('website'),
          notes: value('notes'),
        );
      } else {
        await widget.store.updateContact(
          original.copyWith(
            name: value('name'),
            kind: kind,
            country: value('country'),
            email: value('email'),
            phone: value('phone'),
            contactPerson: value('contactPerson'),
            address: value('address'),
            city: value('city'),
            postalCode: value('postalCode'),
            taxId: value('taxId'),
            website: value('website'),
            notes: value('notes'),
          ),
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

  @override
  Widget build(BuildContext context) {
    final locked =
        widget.contact != null &&
        widget.store.data.orders.any((o) => o.customerId == widget.contact!.id);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.contact == null
                ? 'Nouveau partenaire'
                : 'Modifier le partenaire',
          ),
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
                  onPressed: busy ? null : save,
                  child: Text(busy ? 'Enregistrement…' : 'Enregistrer'),
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
                    const Text(
                      'Fiche interne à l’entreprise. L’enregistrement ne crée pas de compte utilisateur.',
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<ContactKind>(
                      initialValue: kind,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Type de partenaire',
                        helperText: locked
                            ? 'Type conservé car ce client possède des commandes.'
                            : null,
                        helperMaxLines: 2,
                      ),
                      items: [
                        for (final k in ContactKind.values)
                          DropdownMenuItem(value: k, child: Text(k.label)),
                      ],
                      onChanged: busy || locked
                          ? null
                          : (v) => setState(() => kind = v!),
                    ),
                    const SizedBox(height: 16),
                    field(values['name']!, 'Nom / raison sociale'),
                    field(values['country']!, 'Pays'),
                    field(
                      values['email']!,
                      'E-mail (facultatif)',
                      required: false,
                      keyboard: TextInputType.emailAddress,
                    ),
                    TextFormField(
                      controller: values['phone'],
                      keyboardType: TextInputType.phone,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone (facultatif)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    field(
                      values['contactPerson']!,
                      'Personne à contacter',
                      required: false,
                    ),
                    Text(
                      'Adresse et informations professionnelles',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    field(values['address']!, 'Adresse', required: false),
                    field(values['city']!, 'Ville', required: false),
                    field(
                      values['postalCode']!,
                      'Code postal',
                      required: false,
                    ),
                    field(
                      values['taxId']!,
                      'Identifiant fiscal / registre',
                      required: false,
                    ),
                    field(
                      values['website']!,
                      'Site web (https://…)',
                      required: false,
                      keyboard: TextInputType.url,
                    ),
                    TextFormField(
                      controller: values['notes'],
                      maxLength: 3000,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes internes',
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
