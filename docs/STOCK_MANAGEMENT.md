# Stocks et inventaires — gestion locale

Le module gère un **stock global par produit sur cet appareil**. Il fonctionne sans Firebase. Les entrepôts multiples, transferts, lots, réservations et notifications push restent à développer. Les rôles affichés sont des profils de démonstration, pas des permissions réelles.

## Accès

- **Magasinier → Stocks → Ouvrir les stocks**.
- **Administrateur → Gestion → Ouvrir la gestion locale → icône « Gérer les stocks »**.
- Depuis la liste des produits : bouton **Gérer les stocks**.

Les trois onglets sont **Stocks**, **Mouvements** et **Inventaires**.

## Stocks

- Liste des produits actifs (brouillons et publiés), recherche par nom, référence ou catégorie et tri alphabétique.
- Filtres : tous, en alerte, ruptures, disponibles.
- Quantité disponible dans l’unité du produit ; seuil d’alerte et indicateurs par nombre de références.
- Une alerte apparaît lorsque `quantité <= seuil`. Une rupture correspond à une quantité nulle. Les références en rupture peuvent aussi être en alerte : les indicateurs se recoupent.
- Les quantités d’unités différentes ne sont jamais additionnées dans un total global.
- Les produits archivés restent exclus des nouvelles opérations. Leurs mouvements historiques restent consultables.
- Pour modifier un seuil, ouvrir la fiche du produit dans la gestion des produits.

### Entrée ou sortie

1. Choisir le produit puis **Entrée** ou **Sortie**.
2. Saisir une quantité strictement positive et un motif obligatoire.
3. Vérifier le stock calculé après mouvement.
4. Enregistrer puis confirmer le récapitulatif. Annuler la confirmation conserve le formulaire sans appliquer le mouvement.

Le stock doit rester compris entre 0 et 1 000 000 000. Une sortie excessive est refusée. Si la quantité ou l’unité a changé depuis l’ouverture du formulaire, l’enregistrement est refusé ; fermer et rouvrir le formulaire avec les données actuelles.

Une entrée manuelle constate une augmentation du stock ; elle ne crée ni achat, ni facture fournisseur, ni document de réception.

## Inventaire physique

1. Cliquer **Faire un inventaire** ou **Nouvel inventaire**.
2. Donner un motif ou une référence de comptage.
3. Saisir la quantité réellement comptée pour chaque produit concerné.
4. **Vide** signifie non compté, sans modification du produit. **0** signifie un stock réellement nul.
5. Consulter les écarts par produit, puis **Vérifier et valider** et confirmer le récapitulatif.

Au moins un produit doit être compté. Les valeurs négatives et les doublons sont interdits. La recherche conserve les saisies des produits masqués ; toutes les saisies sont vérifiées avant validation.

La validation applique les comptages et enregistre l’inventaire et ses corrections dans **une seule sauvegarde locale**. Un échec ne modifie ni le stock ni l’historique. Si un stock ou une unité a changé, ou si un produit compté a été archivé, tout l’inventaire est refusé : il faut fermer puis recommencer avec les données actuelles.

Les produits sans écart sont conservés dans le compte rendu sans créer de mouvement de quantité nulle. Les produits non comptés restent inchangés. Le comptage en cours reste temporaire ; seuls les inventaires validés sont sauvegardés.

## Historique et traçabilité

Chaque nouveau mouvement de stock possède un identifiant, le produit et son identifiant stable, sa référence et son unité au moment du mouvement, le motif, la date, la variation et les quantités avant/après.

Types : stock initial, entrée, sortie, commande interne, annulation et correction d’inventaire. Les corrections référencent leur inventaire ; les ventes et annulations référencent leur commande. Les noms et unités de l’historique ne sont pas réécrits lors d’un changement de fiche.

L’onglet Mouvements propose recherche, filtre par type et par produit, ainsi que toutes les dates, 7 ou 30 derniers jours. Les produits archivés sont disponibles dans ce filtre. Les anciens mouvements sans identifiant restent visibles avec « Tous les produits » ; leurs quantités avant/après ne sont pas inventées.

L’onglet Inventaires conserve les comptages validés et ouvre leur détail : produit, référence, unité, théorique, compté et écart. Un inventaire validé est consultable, sans suppression ni modification. Une correction nécessite un nouveau mouvement ou inventaire motivé.

Les commandes internes continuent à déduire le stock et leur annulation avant expédition le restitue une seule fois. Une annulation reste possible pour un produit archivé si le stock final respecte la limite autorisée. Le catalogue public suit les nouvelles disponibilités. Les commandes publiques simulées ne modifient et ne réservent aucun stock.

## Compatibilité et limites

Les sauvegardes locales versions 1 et 2 restent lisibles. Les champs de traçabilité et la liste `inventories` sont ajoutés au format version 2 avec des valeurs par défaut pour les anciennes données. La clé de sauvegarde ne change pas. Les anciens mouvements sont conservés comme historiques non détaillés.

Les données restent enregistrées dans le stockage local existant, avec sa limite de 4 Mo par sauvegarde. Il n’y a ni synchronisation entre appareils ni sauvegarde externe. Les protections de concurrence couvrent le magasin local dans l’application ; les transactions serveur et les conflits entre appareils seront traités lors du raccordement Firebase.

## Vérifications

Suite complète : **82 tests réussis**. Analyse Flutter sans erreur ni avertissement, format Dart conforme et compilation Web de production réussie.

Tests métier : mouvements avant/après, identité historique, inventaires multiples atomiques, produits non comptés et sans écart, stock ou unité périmés, produits archivés, bornes et doublons, échecs de sauvegarde, commandes et annulations, anciennes sauvegardes et persistance après redémarrage.

Tests d’interface : entrées, annulation de confirmation, sortie excessive, comptage à zéro, compte rendu, historique et conflit de stock à 320 et 1 440 pixels. Accès depuis les profils Magasinier et Administrateur sur écran de 320 pixels.

Les essais sur appareils Android/iOS réels et la sécurité multi-utilisateur restent nécessaires avant distribution.
