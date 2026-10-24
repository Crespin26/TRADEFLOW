import 'package:flutter/material.dart';

import '../../domain/public_catalog.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';
import 'product_detail.dart';
import 'product_widgets.dart';

class PublicHome extends StatelessWidget {
  const PublicHome({super.key, required this.onCatalog});
  final ValueChanged<String?> onCatalog;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF113C45), FlowColors.primary],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.public, size: 36, color: Color(0xFFA1E7D4)),
            const SizedBox(height: 20),
            const Text(
              'Des produits pour\nvos ambitions.',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Explorez notre sélection de marchandises et d’équipements. Le catalogue est ouvert à tous, sans compte.',
              style: TextStyle(color: Color(0xFFE0F4EE), height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => onCatalog(null),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: FlowColors.primary,
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Découvrir le catalogue'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Démonstration : produits, visuels et prix fictifs.',
        style: TextStyle(fontSize: 12, color: FlowColors.muted),
      ),
      const SizedBox(height: 28),
      Text(
        'Explorez nos catégories',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final category
              in demoPublicProducts.map((p) => p.category).toSet())
            OutlinedButton.icon(
              onPressed: () => onCatalog(category),
              icon: Icon(categoryIcon(category)),
              label: Text(category),
            ),
        ],
      ),
      const SizedBox(height: 28),
      Text('Notre sélection', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text(
        'Des références pour découvrir les possibilités de TradeFlow.',
        style: TextStyle(color: FlowColors.muted),
      ),
      const SizedBox(height: 16),
      PublicProductGrid(
        products: demoPublicProducts.where((p) => p.featured).take(4).toList(),
        onOpen: (p) => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProductDetailPage(product: p),
          ),
        ),
      ),
      const SizedBox(height: 28),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.business_outlined, color: FlowColors.primary),
              const SizedBox(height: 12),
              Text(
                'Un partenaire pour votre commerce',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'TradeFlow Démo est une entreprise fictive présentant un catalogue de marchandises pour les professionnels. Cette page illustre les informations qui pourront être publiées par une entreprise.',
              ),
              const SizedBox(height: 16),
              const FlowBadge('Entreprise de démonstration'),
              const SizedBox(height: 12),
              const SelectableText(
                'Cotonou, Bénin · Adresse indicative\ncontact@tradeflow.example',
              ),
              const SizedBox(height: 12),
              const Text(
                'Les coordonnées réelles, horaires et modalités de livraison seront renseignés avant publication.',
                style: TextStyle(color: FlowColors.muted),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
