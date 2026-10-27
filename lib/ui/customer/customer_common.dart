import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/shopping_session.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';
import '../shopping/auth_page.dart';
import '../shopping/shopping_scope.dart';

String customerDate(DateTime date) =>
    DateFormat('dd/MM/yyyy', 'fr').format(date.toLocal());
FlowTone orderTone(CustomerOrderStatus status) => switch (status) {
  CustomerOrderStatus.delivered => FlowTone.success,
  CustomerOrderStatus.cancelled => FlowTone.error,
  CustomerOrderStatus.confirmed => FlowTone.neutral,
  _ => FlowTone.warning,
};

class CustomerGate extends StatelessWidget {
  const CustomerGate({super.key, required this.builder});
  final Widget Function(BuildContext, ShoppingSession) builder;
  @override
  Widget build(BuildContext context) {
    final session = ShoppingScope.of(context);
    if (!session.customerReady) {
      return FlowStateView(
        title: 'Ouvrez votre espace client',
        description: 'Une connexion et une vérification simulées sont nécessaires. Le sélecteur de profils ne vous connecte pas.',
        icon: Icons.lock_outline,
        actionLabel: 'Connexion ou inscription',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute<bool>(builder: (_) => const DemoAuthPage()),
        ),
      );
    }
    return builder(context, session);
  }
}

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: FlowLayout.contentWidth),
          child: ListView(
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const FlowBadge('Espace client simulé · Données temporaires'),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}
