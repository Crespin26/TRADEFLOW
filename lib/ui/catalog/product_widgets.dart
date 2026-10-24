import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/public_catalog.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';

String publicPrice(int amount) =>
    '${NumberFormat.decimalPattern('fr').format(amount)} F CFA';
FlowTone availabilityTone(PublicAvailability value) => switch (value) {
  PublicAvailability.available => FlowTone.success,
  PublicAvailability.onOrder => FlowTone.warning,
  PublicAvailability.unavailable => FlowTone.error,
};
IconData categoryIcon(String category) => switch (category) {
  'Alimentation' => Icons.rice_bowl_outlined,
  'Textile' => Icons.checkroom_outlined,
  'Équipement' => Icons.chair_outlined,
  _ => Icons.inventory_2_outlined,
};

class ProductIllustration extends StatelessWidget {
  const ProductIllustration({
    super.key,
    required this.product,
    this.variant = 0,
    this.height = 160,
  });
  final PublicProduct product;
  final int variant;
  final double height;
  @override
  Widget build(BuildContext context) {
    final color = switch (product.category) {
      'Alimentation' => const Color(0xFF407655),
      'Textile' => const Color(0xFF5965A2),
      'Équipement' => const Color(0xFF437C8F),
      _ => const Color(0xFFA57543),
    };
    return Semantics(
      label: 'Illustration de démonstration : ${product.name}',
      image: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: .08 + variant * .04),
              color.withValues(alpha: .22),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: height * .65,
              height: height * .65,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(variant == 1 ? 20 : height),
              ),
            ),
            Icon(
              switch (product.id) {
                'oil' => Icons.water_drop_outlined,
                'cocoa' => Icons.spa_outlined,
                'solar' => Icons.solar_power_outlined,
                'fabric' => Icons.texture,
                _ => categoryIcon(product.category),
              },
              size: height * .38,
              color: color,
            ),
            const Positioned(
              bottom: 10,
              right: 12,
              child: Text(
                'VISUEL DÉMO',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: FlowColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PublicProductTile extends StatelessWidget {
  const PublicProductTile({
    super.key,
    required this.product,
    required this.onOpen,
  });
  final PublicProduct product;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onOpen,
          child: ProductIllustration(product: product),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.category,
                style: const TextStyle(fontSize: 12, color: FlowColors.muted),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                product.unit,
                style: const TextStyle(color: FlowColors.muted),
              ),
              const SizedBox(height: 12),
              FlowBadge(
                product.availability.label,
                tone: availabilityTone(product.availability),
              ),
              const SizedBox(height: 12),
              Text(
                publicPrice(product.price),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FlowButton(
                  label: 'Voir le produit',
                  secondary: true,
                  onPressed: onOpen,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Wrap instead of a fixed-height grid so large text never clips product cards.
class PublicProductGrid extends StatelessWidget {
  const PublicProductGrid({
    super.key,
    required this.products,
    required this.onOpen,
  });
  final List<PublicProduct> products;
  final ValueChanged<PublicProduct> onOpen;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / 260).floor().clamp(1, 4);
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final product in products)
            SizedBox(
              width: width,
              child: PublicProductTile(
                product: product,
                onOpen: () => onOpen(product),
              ),
            ),
        ],
      );
    },
  );
}
