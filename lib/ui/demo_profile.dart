import 'package:flutter/material.dart';

/// UI previews only. Never use these roles to authorize a backend operation.
enum DemoProfile {
  visitor(
    'Visiteur',
    'Espace public',
    'Catalogue accessible sans compte',
    Icons.public,
  ),
  client(
    'Client',
    'Espace client',
    'Commandes et informations personnelles',
    Icons.person_outline,
  ),
  sales(
    'Commercial',
    'Espace commercial',
    'Clients, devis et commandes',
    Icons.handshake_outlined,
  ),
  warehouse(
    'Magasinier',
    'Espace logistique',
    'Stocks, réceptions et expéditions',
    Icons.inventory_2_outlined,
  ),
  accountant(
    'Comptable',
    'Espace comptabilité',
    'Factures, paiements et échéances',
    Icons.receipt_long_outlined,
  ),
  administrator(
    'Administrateur',
    'Administration',
    'Entreprise, équipe et activité globale',
    Icons.admin_panel_settings_outlined,
  );

  const DemoProfile(this.label, this.space, this.description, this.icon);
  final String label, space, description;
  final IconData icon;
}

class DemoDestination {
  const DemoDestination(this.label, this.icon, this.description);
  final String label, description;
  final IconData icon;
}

List<DemoDestination> destinationsFor(DemoProfile profile) => switch (profile) {
  DemoProfile.visitor => const [
    DemoDestination(
      'Accueil',
      Icons.home_outlined,
      'Découvrez les produits et notre entreprise.',
    ),
    DemoDestination(
      'Catalogue',
      Icons.storefront_outlined,
      'Parcourez les produits publiés, leurs prix et leur disponibilité.',
    ),
    DemoDestination(
      'Panier',
      Icons.shopping_bag_outlined,
      'Préparez votre commande avant de vous connecter.',
    ),
  ],
  DemoProfile.client => const [
    DemoDestination(
      'Accueil',
      Icons.home_outlined,
      'Retrouvez votre activité personnelle.',
    ),
    DemoDestination(
      'Catalogue',
      Icons.storefront_outlined,
      'Découvrez les produits disponibles.',
    ),
    DemoDestination(
      'Commandes',
      Icons.local_shipping_outlined,
      'Consultez uniquement vos commandes et livraisons.',
    ),
    DemoDestination(
      'Profil',
      Icons.person_outline,
      'Gérez vos coordonnées et adresses.',
    ),
  ],
  DemoProfile.sales => const [
    DemoDestination(
      'Activité',
      Icons.space_dashboard_outlined,
      'Suivez les ventes de votre entreprise.',
    ),
    DemoDestination(
      'Clients',
      Icons.people_outline,
      'Retrouvez vos clients et leur historique commercial.',
    ),
    DemoDestination(
      'Devis',
      Icons.description_outlined,
      'Préparez les propositions commerciales.',
    ),
    DemoDestination(
      'Commandes',
      Icons.local_shipping_outlined,
      'Traitez les commandes reçues.',
    ),
  ],
  DemoProfile.warehouse => const [
    DemoDestination(
      'Activité',
      Icons.space_dashboard_outlined,
      'Organisez les opérations logistiques.',
    ),
    DemoDestination(
      'Stocks',
      Icons.inventory_2_outlined,
      'Consultez les stocks et les mouvements.',
    ),
    DemoDestination(
      'Réceptions',
      Icons.move_to_inbox_outlined,
      'Contrôlez les marchandises reçues.',
    ),
    DemoDestination(
      'Expéditions',
      Icons.local_shipping_outlined,
      'Préparez les commandes à livrer.',
    ),
  ],
  DemoProfile.accountant => const [
    DemoDestination(
      'Activité',
      Icons.space_dashboard_outlined,
      'Retrouvez vos indicateurs financiers.',
    ),
    DemoDestination(
      'Factures',
      Icons.receipt_long_outlined,
      'Consultez les factures et les avoirs.',
    ),
    DemoDestination(
      'Paiements',
      Icons.payments_outlined,
      'Suivez les encaissements et les règlements.',
    ),
    DemoDestination(
      'Échéances',
      Icons.event_outlined,
      'Identifiez les montants à régler.',
    ),
  ],
  DemoProfile.administrator => const [
    DemoDestination(
      'Activité',
      Icons.space_dashboard_outlined,
      'Pilotez l’ensemble de votre activité.',
    ),
    DemoDestination(
      'Gestion',
      Icons.business_center_outlined,
      'Accédez au prototype local de gestion existant.',
    ),
    DemoDestination(
      'Équipe',
      Icons.groups_outlined,
      'Organisez les collaborateurs et leurs rôles.',
    ),
    DemoDestination(
      'Paramètres',
      Icons.settings_outlined,
      'Configurez les informations de votre entreprise.',
    ),
  ],
};
