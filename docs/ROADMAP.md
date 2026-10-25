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
5. **Gestion interne.** Produits, publication, stocks, inventaires, entrepôts et partenaires.
6. **Opérations commerciales.** Ventes, devis, achats, réceptions, livraisons partielles et retours.
7. **Finance et commerce international.** Factures, paiements simulés, devises, coûts et documents internationaux.
8. **Pilotage et administration.** Tableaux de bord par rôle, rapports, collaborateurs et paramètres.
9. **Validation des interfaces.** Parcours complets, petits écrans, accessibilité et cohérence des informations par profil.
10. **Connexion aux services.** Firebase Authentication, Firestore, Storage, règles d’accès, transactions, synchronisation, notifications et paiement réel.

Les profils de démonstration ne sont pas des comptes ni des permissions réelles. Les fonctionnalités des phases futures ne sont pas implicitement disponibles dans le prototype.

## Avant distribution

- Valider les droits de publication et la confidentialité avec l’entreprise.
- Tester les règles de sécurité et les opérations concurrentes du backend.
- Vérifier les compilations et parcours réels sur Android et iOS.
- Finaliser identité, icônes, signature, sauvegardes et supervision.
- Retirer le sélecteur de profils de démonstration de la distribution de production.
