# TradeFlow

Application mobile de gestion commerciale internationale, construite avec Flutter.

> Flutter-based mobile application for inventory management, order tracking, customer relationships, and international trade operations.

TradeFlow centralise les produits, les stocks, les commandes et les partenaires commerciaux dans une interface en français. Cette version fonctionne localement, avec un accès client simulé et sans connexion Firebase.

## Interfaces : phases 1 à 4

L’application s’ouvre sur l’espace visiteur. Le sélecteur en haut à droite permet d’explorer six **profils de démonstration** : visiteur, client, commercial, magasinier, comptable et administrateur. Ces profils simulent la navigation ; ils ne sont pas une authentification et n’accordent aucune permission réelle.

Le thème commun, les composants réutilisables et les états vide/chargement/erreur/succès sont consultables via l’icône palette. Le catalogue public propose désormais huit produits fictifs, des catégories, une recherche, des filtres combinables, un tri et des fiches détaillées. L’accueil présente une sélection et une entreprise fictive. Le panier à plusieurs lignes est sauvegardé localement. Les écrans de connexion, inscription, vérification d’e-mail, récupération et confirmation de commande sont simulés. Aucun compte ni achat réel n’est créé. L’espace client comprend désormais commandes et suivi de livraison, profil, adresses, documents spécimens, demandes et notifications locales. Ses données restent temporaires. Le volet produits de la phase 5 permet désormais modification, publication, archivage, catégories, unités et import de photos ; seuls les produits publiés alimentent le catalogue local après la première publication. Firebase vient ensuite.

Pour retrouver les fonctionnalités locales existantes : **Administrateur → Gestion → Ouvrir la gestion locale**. Les exemples de produits se chargent depuis l’accueil de cette gestion, lorsque l’espace local est vide.

Les [documents commerciaux](docs/BUSINESS_DOCUMENTS.md) disposent d’une bibliothèque, d’un aperçu, de l’export PDF et de versions archivées avec les coordonnées de l’entreprise.

La [phase 6 — Opérations commerciales](docs/COMMERCIAL_OPERATIONS.md) ajoute les devis convertibles, achats fournisseurs, réceptions et livraisons partielles, retours clients/fournisseurs et leur journal. Les documents portent une référence produit et des montants XOF ; les opérations et leurs effets sur le stock sont sauvegardés ensemble.

Le module [Clients et fournisseurs](docs/PARTNERS_MANAGEMENT.md) permet les fiches détaillées, recherche et filtres, modification, archivage/restauration et consultation des commandes internes d’un client. Il est accessible depuis Contacts et depuis le profil Commercial.

Le module [Stocks et inventaires](docs/STOCK_MANAGEMENT.md) ajoute un écran Magasinier, des entrées/sorties confirmées, l’historique détaillé et les comptages physiques avec contrôle des stocks modifiés pendant la saisie. Les inventaires validés sont sauvegardés localement ; les entrepôts multiples restent à développer.

La [phase 5 — Produits et catalogue](docs/PRODUCTS_AND_CATALOG.md) détaille les parcours, la migration des données et les limites du stockage local.

Voir [docs/UI_FOUNDATIONS.md](docs/UI_FOUNDATIONS.md) pour les conventions, [docs/PUBLIC_CATALOG.md](docs/PUBLIC_CATALOG.md) pour le catalogue et [docs/CART_AND_AUTH_DEMO.md](docs/CART_AND_AUTH_DEMO.md) pour le panier et les parcours simulés. La phase 4 est décrite dans [docs/CUSTOMER_SPACE_DEMO.md](docs/CUSTOMER_SPACE_DEMO.md). Les produits utilisent désormais de vraies photographies illustratives, embarquées dans l’application ; les références et prix restent fictifs. Les [crédits photographiques](docs/PHOTO_CREDITS.md) et la [recette des phases 1 à 4](docs/ACCEPTANCE_PHASES_1_4.md) détaillent cette mise à jour.

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

La compilation iOS nécessite macOS et Xcode. Les identifiants provisoires sont `com.tradeflow.tradeflow_mobile` pour Android et `com.tradeflow.tradeflowMobile` pour iOS ; les confirmer avant l’enregistrement des applications Firebase et la publication sur les stores. La signature Android de production n’est pas configurée.

## Développement dans VS Code

Installer les extensions Dart et Flutter recommandées par le projet et sélectionner un SDK Flutter permanent. Les réglages SDK personnels de `.vscode/settings.json` sont exclus de Git. La configuration de lancement **TradeFlow — Web** est disponible pour le débogage.

Si les imports Flutter sont soulignés en rouge, régénérer les dépendances avec le SDK sélectionné puis recharger la fenêtre VS Code. Voir [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md) pour le diagnostic, la correction locale et le bilan du projet.

## Vérification

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Le workflow GitHub Actions exécute ces contrôles lors des push et des pull requests. Aucun workflow ne publie ni ne déploie l’application.

## Règles du prototype de gestion interne

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
  ui/catalog/                  # Accueil public, catalogue et fiches produit
  ui/shopping/                 # Panier, connexion et commande simulés
  ui/customer/                 # Espace client de démonstration
  domain/customer_models.dart  # Commandes, demandes, adresses et notifications client
  domain/shopping_session.dart # État du parcours public indépendant des stocks
  data/public_cart_repository.dart # Sauvegarde locale du panier public
  domain/public_catalog.dart   # Modèle public, filtres et exemples
  domain/product_catalog.dart  # Projection des produits publiés
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
