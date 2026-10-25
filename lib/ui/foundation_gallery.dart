import 'package:flutter/material.dart';

import 'design_system/components.dart';
import 'design_system/theme.dart';
import '../domain/catalog_photos.dart';
import 'catalog/catalog_photo.dart';

class FoundationGallery extends StatefulWidget {
  const FoundationGallery({super.key});
  @override
  State<FoundationGallery> createState() => _FoundationGalleryState();
}

enum _Preview { empty, loading, error, success }

class _FoundationGalleryState extends State<FoundationGallery> {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  _Preview preview = _Preview.empty;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void feedback(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guide des composants')),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          key: const ValueKey('foundation-gallery-scroll'),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Les fondations TradeFlow',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Un langage visuel commun pour le catalogue, l’espace client et les équipes. Les exemples de cette page ne modifient aucune donnée.',
            ),
            heading('Couleurs et typographie'),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final entry in [
                  ('Principal', FlowColors.primary),
                  ('Texte', FlowColors.ink),
                  ('Succès', FlowColors.success),
                  ('Attention', FlowColors.warning),
                  ('Erreur', FlowColors.error),
                ])
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 48,
                        decoration: BoxDecoration(
                          color: entry.$2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(entry.$1),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Des titres lisibles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text(
              'Des textes simples et des actions explicites.',
              style: TextStyle(color: FlowColors.muted),
            ),
            heading('Boutons et confirmation'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FlowButton(
                  label: 'Action principale',
                  icon: Icons.add,
                  onPressed: () => feedback('Action de démonstration.'),
                ),
                FlowButton(
                  label: 'Action secondaire',
                  secondary: true,
                  onPressed: () =>
                      feedback('Action secondaire de démonstration.'),
                ),
                const FlowButton(label: 'Indisponible', onPressed: null),
                FlowButton(
                  label: 'Tester la confirmation',
                  secondary: true,
                  onPressed: () async {
                    final confirmed = await showFlowConfirmation(
                      context,
                      title: 'Confirmer cet exemple ?',
                      description: 'Cette démonstration n’effectue aucune opération sur vos données.',
                    );
                    if (mounted && confirmed) {
                      feedback('Exemple confirmé. Aucune donnée modifiée.');
                    }
                  },
                ),
              ],
            ),
            heading('Champs et validation'),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlowField(
                    controller: controller,
                    label: 'Nom du produit',
                    hint: 'Exemple : riz parfumé',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Renseignez un nom de produit.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FlowButton(
                    label: 'Vérifier le champ',
                    onPressed: () {
                      if (form.currentState!.validate()) {
                        feedback('Champ valide. Exemple uniquement.');
                      }
                    },
                  ),
                ],
              ),
            ),
            heading('Statuts'),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FlowBadge('Brouillon'),
                FlowBadge('Disponible', tone: FlowTone.success),
                FlowBadge('À réapprovisionner', tone: FlowTone.warning),
                FlowBadge('Annulée', tone: FlowTone.error),
              ],
            ),
            heading('Carte produit publique'),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 320,
                child: FlowProductCard(
                  image: CatalogPhotoView(
                    photo: catalogPhotos['rice'],
                    height: 140,
                  ),
                  name: 'Riz parfumé · exemple fictif',
                  category: 'Produits alimentaires',
                  priceLabel: '18 500 F CFA',
                  availability: 'Disponible',
                ),
              ),
            ),
            heading('États d’un écran'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in [
                  (_Preview.empty, 'Vide'),
                  (_Preview.loading, 'Chargement'),
                  (_Preview.error, 'Erreur'),
                  (_Preview.success, 'Succès'),
                ])
                  ChoiceChip(
                    label: Text(entry.$2),
                    selected: preview == entry.$1,
                    onSelected: (_) => setState(() => preview = entry.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            switch (preview) {
              _Preview.empty => const FlowStateView(
                title: 'Aucun élément pour le moment',
                description:
                    'Les éléments apparaîtront ici une fois disponibles.',
              ),
              _Preview.loading => const FlowStateView(
                title: 'Chargement en cours',
                description: 'Un instant, nous préparons votre espace.',
                loading: true,
              ),
              _Preview.error => FlowStateView(
                title: 'Impossible de charger les éléments',
                description: 'Vérifiez votre connexion puis réessayez.',
                icon: Icons.cloud_off_outlined,
                tone: FlowTone.error,
                actionLabel: 'Réessayer',
                onAction: () => setState(() => preview = _Preview.success),
              ),
              _Preview.success => const FlowStateView(
                title: 'Opération réussie',
                description: 'Votre action a bien été prise en compte. Exemple uniquement.',
                icon: Icons.check_circle_outline,
                tone: FlowTone.success,
              ),
            },
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 16),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}
