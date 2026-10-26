import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/trade_store.dart';
import '../../domain/catalog_photos.dart';
import '../../domain/photo_import.dart';
import '../forms.dart' show field, friendlyError;
import '../catalog/catalog_photo.dart';

Future<void> productEditor(
  BuildContext context,
  TradeStore store, {
  Product? product,
}) => Navigator.push<void>(
  context,
  MaterialPageRoute(
    builder: (_) => ProductEditor(store: store, product: product),
  ),
);

class ProductEditor extends StatefulWidget {
  const ProductEditor({super.key, required this.store, this.product});
  final TradeStore store;
  final Product? product;
  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.product?.name);
  late final sku = TextEditingController(text: widget.product?.sku);
  late final price = TextEditingController(
    text: widget.product?.price.toString(),
  );
  late final quantity = TextEditingController(
    text: '${widget.product?.quantity ?? 0}',
  );
  late final threshold = TextEditingController(
    text: '${widget.product?.threshold ?? 5}',
  );
  late final cost = TextEditingController(
    text: '${widget.product?.purchasePrice ?? 0}',
  );
  late final description = TextEditingController(
    text: widget.product?.description,
  );
  late final origin = TextEditingController(text: widget.product?.origin);
  late String category =
      widget.product?.category ?? widget.store.data.categories.first;
  late String unit = widget.product?.unit ?? widget.store.data.units.first;
  late bool featured = widget.product?.featured ?? false;
  late bool backorder = widget.product?.allowBackorder ?? false;
  late final photos = [...?widget.product?.photos];
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in [
      name,
      sku,
      price,
      quantity,
      threshold,
      cost,
      description,
      origin,
    ]) {
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
      final original = widget.product;
      if (original == null) {
        await widget.store.addProduct(
          name: name.text,
          sku: sku.text,
          quantity: int.parse(quantity.text),
          threshold: int.parse(threshold.text),
          price: int.parse(price.text),
          purchasePrice: int.parse(cost.text),
          category: category,
          unit: unit,
          description: description.text,
          origin: origin.text,
          photos: photos,
          featured: featured,
          allowBackorder: backorder,
        );
      } else {
        await widget.store.updateProduct(
          original.copyWith(
            name: name.text.trim(),
            sku: sku.text.trim(),
            price: int.parse(price.text),
            threshold: int.parse(threshold.text),
            purchasePrice: int.parse(cost.text),
            category: category,
            unit: unit,
            description: description.text.trim(),
            origin: origin.text.trim(),
            photos: photos,
            featured: featured,
            allowBackorder: backorder,
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = friendlyError(e);
          busy = false;
        });
      }
    }
  }

  Future<void> importPhoto() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Photos',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
            uniformTypeIdentifiers: ['public.image'],
          ),
        ],
      );
      if (file != null) {
        if (await file.length() > 10000000) {
          throw ArgumentError('Photo trop volumineuse : 10 Mo maximum.');
        }
        final bytes = await compute(
          optimizeProductPhoto,
          await file.readAsBytes(),
        );
        if (mounted) {
          setState(
            () => photos.add(
              CatalogPhoto(
                asset: '',
                bytes: bytes,
                description: 'Photographie du produit',
                author: 'Entreprise',
                source: 'Import local',
                sourceUrl: '',
                licenseUrl: '',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> library() async {
    final photo = await showDialog<CatalogPhoto>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photos illustratives intégrées'),
        content: SizedBox(
          width: 440,
          height: 360,
          child: ListView(
            children: [
              for (final p in catalogPhotos.values)
                ListTile(
                  leading: SizedBox(
                    width: 60,
                    child: CatalogPhotoView(
                      photo: p,
                      height: 50,
                      showCaption: false,
                    ),
                  ),
                  title: Text(p.description),
                  subtitle: Text(p.author),
                  onTap: () => Navigator.pop(context, p),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
    if (photo != null && mounted) setState(() => photos.add(photo));
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Nouveau produit' : 'Modifier le produit',
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Prix en francs CFA (XOF). Un nouveau produit est enregistré en brouillon.',
                  ),
                  const SizedBox(height: 20),
                  field(name, 'Nom du produit'),
                  field(sku, 'Référence unique (SKU)'),
                  field(price, 'Prix unitaire (XOF)', numeric: true),
                  if (widget.product == null)
                    field(quantity, 'Stock initial', numeric: true)
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Stock actuel : ${widget.product!.quantity}. Utilisez « Ajuster le stock » pour le modifier.',
                      ),
                    ),
                  field(threshold, 'Seuil d’alerte', numeric: true),
                  field(cost, 'Prix d’achat (XOF) · interne', numeric: true),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: [
                      for (final c in widget.store.data.categories)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: busy
                        ? null
                        : (v) => setState(() => category = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: unit,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Unité de vente',
                    ),
                    items: [
                      for (final u in widget.store.data.units)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: busy ? null : (v) => setState(() => unit = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: description,
                    maxLines: 4,
                    maxLength: 3000,
                    decoration: const InputDecoration(
                      labelText: 'Description publique',
                    ),
                  ),
                  const SizedBox(height: 16),
                  field(origin, 'Origine', required: false),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mettre en avant'),
                    value: featured,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => featured = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Disponible sur commande si stock nul'),
                    value: backorder,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => backorder = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Photos (${photos.length}/3)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text(
                    'La première photo est la couverture. Importez uniquement des photos que vous êtes autorisé à utiliser. Photos optimisées et conservées sur cet appareil.',
                  ),
                  for (var i = 0; i < photos.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              CatalogPhotoView(photo: photos[i], height: 150),
                              Wrap(
                                children: [
                                  TextButton(
                                    onPressed: busy || i == 0
                                        ? null
                                        : () => setState(() {
                                            final p = photos.removeAt(i);
                                            photos.insert(0, p);
                                          }),
                                    child: Text(
                                      i == 0
                                          ? 'Couverture'
                                          : 'Définir en couverture',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => setState(
                                            () => photos.removeAt(i),
                                          ),
                                    child: const Text('Retirer la photo'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: busy || photos.length >= 3
                            ? null
                            : importPhoto,
                        icon: const Icon(Icons.upload),
                        label: const Text('Importer une photo'),
                      ),
                      TextButton(
                        onPressed: busy || photos.length >= 3 ? null : library,
                        child: const Text('Choisir une illustration'),
                      ),
                    ],
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
