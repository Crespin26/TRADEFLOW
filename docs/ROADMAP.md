# Feuille de route TradeFlow

## Base existante : prototype de gestion locale

- Produits, stocks, clients et fournisseurs.
- Commandes à une ligne, expédition, livraison et annulation avant expédition.
- Historique des mouvements, alertes et sauvegarde locale.
- Tests métier et interface ; préparation documentaire pour Firebase.

Cette base reste accessible via le profil de démonstration Administrateur → Gestion.

## Approche retenue : interfaces avant configuration

1. **Fondations visuelles et navigation — implémentées.** Thème commun, composants réutilisables, états d’écran, guide interactif et six profils de démonstration. Voir [UI_FOUNDATIONS.md](UI_FOUNDATIONS.md).
2. **Catalogue public — implémenté avec données fictives.** Accueil, catégories, recherche sans accents, filtres combinables, tri, fiches produit et présentation de l’entreprise. Photographies illustratives locales ; parcours panier et connexion ajoutés en phase 3. Voir [PUBLIC_CATALOG.md](PUBLIC_CATALOG.md).
3. **Panier et connexion — implémentés en simulation.** Panier à plusieurs lignes sauvegardé localement, connexion/inscription/vérification/récupération fictives, adresse et récapitulatif de commande. Aucun achat réel ni stock modifié. Voir [CART_AND_AUTH_DEMO.md](CART_AND_AUTH_DEMO.md).
4. **Espace client — interfaces implémentées en simulation.** Commandes personnelles et suivi, profil, adresses réutilisables, aperçus de documents, demandes avec justificatif fictif et notifications locales. Voir [CUSTOMER_SPACE_DEMO.md](CUSTOMER_SPACE_DEMO.md).
5. **Gestion interne — volet produits et catalogue implémenté localement.** Création, modification, publication, archivage/restauration, catégories, unités et photos importées. Voir [PRODUCTS_AND_CATALOG.md](PRODUCTS_AND_CATALOG.md). Le volet [Stocks et inventaires](STOCK_MANAGEMENT.md) ajoute entrées/sorties, traçabilité et comptages physiques locaux. Les [fiches clients et fournisseurs](PARTNERS_MANAGEMENT.md) sont implémentées avec modification, archives et commandes internes du client. Entrepôts multiples et transferts restent à développer.
6. **Opérations commerciales — implémentées localement.** Devis à validité contrôlée, conversion unique en vente, achats, réceptions et livraisons partielles, retours et journal lié au stock. Une référence par document et XOF. Voir [COMMERCIAL_OPERATIONS.md](COMMERCIAL_OPERATIONS.md) et [DELIVERIES_AND_RETURNS.md](DELIVERIES_AND_RETURNS.md) pour le suivi transporteur et les retours non revendables. Documents multi-lignes et clôture du reliquat reçu partiellement restent des évolutions.
7. **Documents commerciaux disponibles ; finance et international à compléter.** Bibliothèque, proformas, bons et export PDF avec versions archivées : [BUSINESS_DOCUMENTS.md](BUSINESS_DOCUMENTS.md). Factures fiscales, avoirs, paiements, devises, coûts et documents internationaux restent à développer.
8. **Pilotage implémenté localement ; administration à compléter.** Vues par profil, périodes, activité, alertes, classement produits et rapports CSV : [PILOTAGE.md](PILOTAGE.md). Collaborateurs, permissions réelles et autres paramètres restent à développer.
9. **Validation des interfaces.** Parcours complets, petits écrans, accessibilité et cohérence des informations par profil.
10. **Connexion aux services.** Firebase Authentication, Firestore, Storage, règles d’accès, transactions, synchronisation, notifications et paiement réel.

Les profils de démonstration ne sont pas des comptes ni des permissions réelles. Les fonctionnalités des phases futures ne sont pas implicitement disponibles dans le prototype.

## Avant distribution

- Valider les droits de publication et la confidentialité avec l’entreprise.
- Tester les règles de sécurité et les opérations concurrentes du backend.
- Vérifier les compilations et parcours réels sur Android et iOS.
- Finaliser identité, icônes, signature, sauvegardes et supervision.
- Retirer le sélecteur de profils de démonstration de la distribution de production.
