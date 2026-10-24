import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

enum FlowTone { neutral, success, warning, error }

class FlowBadge extends StatelessWidget {
  const FlowBadge(this.label, {super.key, this.tone = FlowTone.neutral});
  final String label;
  final FlowTone tone;
  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      FlowTone.neutral => FlowColors.muted,
      FlowTone.success => FlowColors.success,
      FlowTone.warning => FlowColors.warning,
      FlowTone.error => FlowColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FlowButton extends StatelessWidget {
  const FlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading, secondary;
  @override
  Widget build(BuildContext context) {
    final child = Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        Text(loading ? 'Enregistrement…' : label, textAlign: TextAlign.center),
      ],
    );
    return Semantics(
      liveRegion: loading,
      child: secondary
          ? OutlinedButton(onPressed: loading ? null : onPressed, child: child)
          : FilledButton(onPressed: loading ? null : onPressed, child: child),
    );
  }
}

class FlowField extends StatelessWidget {
  const FlowField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.hint,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label, hintText: hint),
    validator: validator,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
  );
}

class FlowStateView extends StatelessWidget {
  const FlowStateView({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.loading = false,
    this.tone = FlowTone.neutral,
  });
  final String title, description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;
  final FlowTone tone;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(FlowSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator()
            else
              Icon(
                icon,
                size: 36,
                color: tone == FlowTone.error
                    ? FlowColors.error
                    : FlowColors.primary,
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: FlowColors.muted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FlowButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Only public presentation fields belong here; never pass internal stock or cost.
class FlowProductCard extends StatelessWidget {
  const FlowProductCard({
    super.key,
    required this.name,
    required this.category,
    required this.priceLabel,
    required this.availability,
    this.onOpen,
  });
  final String name, category, priceLabel, availability;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 120,
          color: FlowColors.primary.withValues(alpha: .06),
          child: const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: FlowColors.primary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(color: FlowColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              FlowBadge(availability, tone: FlowTone.success),
              const SizedBox(height: 12),
              Text(priceLabel, style: Theme.of(context).textTheme.titleLarge),
              if (onOpen != null) ...[
                const SizedBox(height: 16),
                FlowButton(
                  label: 'Voir le produit',
                  onPressed: onOpen,
                  secondary: true,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Future<bool> showFlowConfirmation(
  BuildContext context, {
  required String title,
  required String description,
  String confirmLabel = 'Confirmer',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FlowButton(
            label: confirmLabel,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
    false;
