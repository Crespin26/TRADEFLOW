import 'package:flutter/material.dart';

import '../design_system/components.dart';
import 'shopping_scope.dart';
import 'auth_page.dart';

class DemoAccountPage extends StatelessWidget {
  const DemoAccountPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon compte · Démonstration')),
    body: const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: AccountContents(),
      ),
    ),
  );
}

class AccountContents extends StatelessWidget {
  const AccountContents({super.key});
  @override
  Widget build(BuildContext context) {
    final session = ShoppingScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FlowBadge('Session temporaire · Aucun compte réel'),
        const SizedBox(height: 20),
        if (!session.signedIn)
          FlowStateView(
            title: 'Découvrez votre espace client',
            description: 'Ouvrez une session de démonstration pour tester le parcours. Le choix d’un profil dans le simulateur ne vous connecte pas.',
            icon: Icons.person_outline,
            actionLabel: 'Connexion ou inscription',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute<bool>(builder: (_) => const DemoAuthPage()),
            ),
          )
        else ...[
          Text(
            session.displayName.isEmpty
                ? 'Client de démonstration'
                : session.displayName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(session.email!),
          const SizedBox(height: 12),
          FlowBadge(
            session.verified
                ? 'Vérification simulée'
                : 'Vérification à simuler',
            tone: session.verified ? FlowTone.success : FlowTone.warning,
          ),
          if (!session.verified) ...[
            const SizedBox(height: 16),
            FlowButton(
              label: 'Vérifier mon adresse fictive',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<bool>(builder: (_) => const DemoAuthPage()),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FlowButton(
            label: 'Déconnexion simulée',
            secondary: true,
            onPressed: session.busy
                ? null
                : () async {
                    final confirmed = await showFlowConfirmation(
                      context,
                      title: 'Fermer la session de démonstration ?',
                      description: 'Votre panier sera conservé. Les récapitulatifs temporaires seront effacés.',
                      confirmLabel: 'Se déconnecter',
                    );
                    if (confirmed && context.mounted) session.signOut();
                  },
          ),
        ],
      ],
    );
  }
}
