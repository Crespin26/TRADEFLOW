# Phase 1 — Fondations des interfaces

## Explorer l’application

Au démarrage, TradeFlow affiche l’espace **visiteur**. Le catalogue, le panier et les espaces métier sont pour l’instant des emplacements de navigation explicitement marqués « interface à venir » : leur contenu sera développé dans les phases suivantes.

- L’icône de changement de compte, en haut à droite, ouvre les six profils de démonstration.
- Le bandeau indique toujours le profil simulé et l’absence d’authentification.
- L’icône palette ouvre le guide interactif des composants.
- Pour retrouver les fonctions existantes : **Administrateur → Gestion → Ouvrir la gestion locale**.

Les changements de profil ne créent pas de compte, ne modifient pas les données locales et sont réinitialisés au redémarrage. Ce mécanisme sert uniquement à valider les interfaces ; il devra être retiré de la distribution de production lorsque l’authentification sera implémentée. Aucune permission de sécurité ne doit reposer sur `DemoProfile`.

## Identité visuelle

Les valeurs communes résident dans `lib/ui/design_system/theme.dart`.

| Élément | Convention |
|---|---|
| Couleur principale | Vert profond `#007F73` |
| Texte principal | Bleu nuit `#142C38` |
| Arrière-plan | Gris clair `#F4F7F8` |
| Espacements | 4, 8, 16, 24, 32 et 48 pixels logiques |
| Arrondis | 12 pour les champs/boutons, 16 pour les cartes |
| Typographie | Police système, hiérarchie centralisée dans `TextTheme` |
| Navigation | Barre inférieure sous 900 pixels ; rail latéral à partir de 900 pixels |
| Zone de contenu | Largeur maximale de 1 120 pixels pour les nouveaux espaces |

Les titres et textes suivent le facteur d’agrandissement de l’appareil. Les listes et formulaires défilent, les boutons ont une taille minimale de 48 pixels et les icônes d’action portent des infobulles.

## Composants réutilisables

Dans `lib/ui/design_system/components.dart` :

- `FlowButton` : action principale, secondaire, désactivée ou en cours d’enregistrement.
- `FlowField` : champ de formulaire avec clavier, formatage et validation configurables.
- `FlowBadge` : statut neutre, succès, avertissement ou erreur, toujours accompagné d’un libellé.
- `FlowProductCard` : présentation publique d’un produit, sans coût d’achat ni quantité interne.
- `FlowStateView` : contenu vide, chargement, erreur avec reprise ou succès.
- `showFlowConfirmation` : confirmation explicite d’une action.

Les formulaires existants utilisent le champ et le bouton partagés. Le thème s’applique également à la gestion locale. Le guide permet de vérifier les états, valider un champ et tester une confirmation sans enregistrer de données.

## Navigation de démonstration

| Profil | Destinations |
|---|---|
| Visiteur | Accueil, Catalogue, Panier |
| Client | Accueil, Catalogue, Commandes, Profil |
| Commercial | Activité, Clients, Devis, Commandes |
| Magasinier | Activité, Stocks, Réceptions, Expéditions |
| Comptable | Activité, Factures, Paiements, Échéances |
| Administrateur | Activité, Gestion, Équipe, Paramètres |

Le changement de profil revient à la première destination. La navigation et les textes annoncent les futurs périmètres ; les autorisations backend seront développées ultérieurement.

## Étape suivante

Phase 2 : construire l’accueil public, le catalogue, les catégories, les filtres et les fiches produit avec des données fictives dédiées. Le raccordement Firebase reste différé jusqu’à la validation des interfaces.
