# TradeFlow

Application mobile de gestion commerciale internationale, construite avec Flutter.

> Flutter-based mobile application for inventory management, order tracking, customer relationships, and international trade operations.

TradeFlow centralise les produits, les stocks, les commandes et les partenaires commerciaux dans une interface en français. Cette première version fonctionne localement, sans compte ni connexion Firebase.

## Interfaces : phase 1

L’application s’ouvre sur l’espace visiteur. Le sélecteur en haut à droite permet d’explorer six **profils de démonstration** : visiteur, client, commercial, magasinier, comptable et administrateur. Ces profils simulent la navigation ; ils ne sont pas une authentification et n’accordent aucune permission réelle.

Le thème commun, les composants réutilisables et les états vide/chargement/erreur/succès sont consultables via l’icône palette. Les destinations des futures interfaces sont indiquées comme « interface à venir ». Le catalogue détaillé et les parcours client seront construits dans les phases suivantes, avant Firebase.

Pour retrouver les fonctionnalités locales existantes : **Administrateur → Gestion → Ouvrir la gestion locale**. Les exemples de produits se chargent depuis l’accueil de cette gestion, lorsque l’espace local est vide.

Voir [docs/UI_FOUNDATIONS.md](docs/UI_FOUNDATIONS.md) pour les conventions et la navigation.

## Fonctionnalités de gestion locale disponibles

- Tableau de bord : références produits, commandes en cours, alertes et valeur des commandes livrées.
- Création de produits avec référence unique, prix unitaire, stock initial et seuil d’alerte.
- Entrées et sorties de stock avec motif et contrôle des quantités disponibles.
- Création de clients et fournisseurs avec pays, e-mail et téléphone.
- Création de commandes, expédition, livraison et annulation avant expédition.
- Historique des mouvements de stock et recherche dans les listes.
- Alertes de stock dans l’application, calculées à partir des seuils.
- Sauvegarde locale entre les sessions, gestion des erreurs de lecture et d’écriture.
- Interface adaptée au mobile et aux grands écrans, avec navigation latérale sur Web.
- Exemples fictifs chargeables depuis l’accueil lorsque l’espace est vide.

## Démarrage

Prérequis : Flutter **3.47.3** avec Dart **3.13.3** (versions utilisées pour cette base), et les outils de la plateforme cible.

```sh
flutter pub get
flutter run -d chrome
```

Pour Android, démarrer un émulateur ou connecter un téléphone, puis :

```sh
flutter devices
flutter run -d <identifiant-appareil>
```

La compilation iOS nécessite macOS et Xcode. Les identifiants de plateforme provisoires utilisent `com.tradeflow.tradeflow_mobile` ; les confirmer avant l’enregistrement des applications Firebase et la publication sur les stores. La signature Android de production n’est pas configurée.

## Vérification

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Le workflow GitHub Actions exécute ces contrôles lors des push et des pull requests. Aucun workflow ne publie ni ne déploie l’application.

## Règles de cette première version

- Les prix sont des entiers en **XOF (franc CFA BCEAO)**. Pas de conversion de devises, TVA, douane ou facturation.
- Chaque commande contient **un produit**. Le prix et le nom du produit sont conservés dans la commande.
- La confirmation d’une commande déduit immédiatement le stock disponible. L’expédition et la livraison ne le déduisent pas une seconde fois.
- Une commande confirmée peut être expédiée ou annulée. L’annulation restitue le stock une seule fois.
- Une commande expédiée peut être marquée livrée. Les retours après expédition ne sont pas encore gérés.
- Le tableau de bord affiche la **valeur livrée**, pas les paiements encaissés.
- L’historique porte sur les mouvements de stock ; un journal comptable et un historique des paiements restent à développer.

## Stockage et Firebase

Les données sont enregistrées sur l’appareil avec `shared_preferences` dans un instantané JSON versionné. Cette solution convient à une démonstration locale, pas à un système de gestion multiutilisateur en production. Elle ne propose ni synchronisation, ni sauvegarde distante, ni chiffrement applicatif. Effacer les données de l’application ou du navigateur efface le stockage local.

**Firebase n’est pas connecté et aucun SDK Firebase n’est encore inclus.** La procédure officielle de raccordement et le travail restant sont décrits dans [docs/FIREBASE.md](docs/FIREBASE.md). Les règles Firestore et Storage fournies refusent tous les accès en attendant une implémentation contrôlée. Aucun projet cloud n’a été créé et aucune donnée n’est envoyée à Firebase.

## Structure

```text
lib/
  main.dart                    # Démarrage et accès au stockage local
  domain/models.dart           # Produits, contacts, commandes et mouvements
  domain/trade_store.dart      # Règles métier et état observable
  data/trade_repository.dart   # Contrat de stockage et implémentation locale
  ui/app.dart                  # Navigation, tableau de bord et listes
  ui/forms.dart                # Formulaires et validation
  ui/design_system/            # Thème, composants et états communs
  ui/demo_profile.dart         # Profils et destinations simulés
  ui/foundation_shell.dart     # Navigation publique, client et interne
  ui/foundation_gallery.dart   # Guide interactif des composants
firebase/                      # Règles de refus par défaut
test/                         # Tests métier, persistance et interface
```

Voir [docs/ROADMAP.md](docs/ROADMAP.md) pour la suite du développement.

## Présentation portfolio

> Application mobile de gestion commerciale permettant aux entreprises de centraliser leurs stocks, commandes et relations clients dans un environnement unifié.

Préciser lors d’une présentation que la version actuelle est un prototype local. Les jeux d’exemples intégrés sont fictifs.

## Confidentialité et publication

Un dépôt privé est recommandé. Si le projet est réalisé pour une entreprise, vérifier les droits de propriété du code et l’autorisation de publication. Les démonstrations, captures anonymisées et études de cas doivent être autorisées.

La visibilité du dépôt n’est pas modifiée par ces fichiers. Aucune licence de diffusion du code n’est accordée par ce README. Ne pas ajouter de secrets, de comptes de service ou de données commerciales confidentielles.
