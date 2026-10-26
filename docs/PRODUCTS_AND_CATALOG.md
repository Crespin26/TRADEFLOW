# Phase 5 — Produits et catalogue local

Le volet produits et catalogue est opérationnel **sur cet appareil**, sans Firebase. Les profils restent des profils de démonstration et les commandes publiques restent simulées. Une publication locale ne met pas le produit en ligne et ne le partage pas avec d’autres utilisateurs.

## Parcours de gestion

1. Choisir le profil Administrateur → Gestion → Ouvrir la gestion locale → Produits.
2. Créer un produit : nom, référence unique, prix de vente, stock initial, seuil, prix d’achat interne, catégorie, unité, description, origine et photos.
3. Enregistrer : le nouveau produit est un **brouillon**, absent du catalogue public.
4. Utiliser **Aperçu** pour consulter sa fiche sans ajout au panier.
5. Cliquer **Publier**, puis confirmer. Une description et au moins une photo sont obligatoires.
6. Ouvrir le catalogue public : le produit apparaît avec ses informations publiques, sa disponibilité et ses photos. Les changements de prix, de description ou de stock sont répercutés.
7. **Retirer du catalogue** remet le produit en brouillon. **Archiver** le masque et bloque son utilisation dans de nouvelles commandes internes. **Restaurer** le remet en brouillon ; une nouvelle publication est nécessaire.

La première publication remplace les huit références fictives par les produits publiés de l’entreprise. Ce choix est sauvegardé. Retirer le dernier produit laisse un catalogue vide ; les exemples ne réapparaissent pas.

## Fonctionnalités et règles

| Fonction | Comportement |
|---|---|
| Création / modification | SKU unique sans distinction de casse, y compris dans les archives ; montants entiers XOF et quantités non négatives, limités à un milliard. |
| Stock | Stock initial à la création, puis ajustements motivés et historisés. Modifier une fiche ne modifie pas son stock. |
| Informations publiques | Nom, référence, catégorie, unité, prix de vente, description, origine, photos et disponibilité. |
| Informations internes | Prix d’achat, quantité exacte, seuil et historique. Ils ne sont pas inclus dans le modèle public. Ceci prépare la séparation des données ; les permissions réelles restent à implémenter côté serveur. |
| Disponibilité | Stock positif : disponible ; stock nul et option activée : sur commande ; sinon : rupture. |
| Mise en avant | Les produits mis en avant apparaissent sur l’accueil ; à défaut, celui-ci présente les premiers produits publiés. |
| Recherche / filtres | Nom, référence et catégorie sans accents ; statut, catégorie et tri alphabétique en gestion. Filtres et tris publics conservés. |
| Catégories / unités | Ajout, renommage sur toutes les fiches, suppression si inutilisées ; conservation d’au moins une référence de chaque type. |
| Commandes existantes | Le nom et le prix déjà enregistrés restent identiques après une modification ou un archivage. Annuler une ancienne commande peut toujours restituer le stock d’un produit archivé. |
| Panier | Les prix et disponibilités suivent le catalogue. Les articles retirés restent signalés dans le panier jusqu’à suppression explicite. Leur présence bloque la confirmation. Aucun stock n’est réservé par ce parcours simulé. |

## Photos

- Import JPEG, PNG ou WebP depuis l’appareil, ou sélection parmi les photographies illustratives embarquées.
- Trois photos maximum par produit ; choix de la couverture et suppression individuelle.
- Galerie sur la fiche publique et ouverture de chaque photo avec zoom.
- À l’import : fichier de 10 Mo maximum, 24 mégapixels maximum, orientation corrigée, redimensionnement à 1 200 pixels sur le grand côté, réencodage JPEG sans métadonnées EXIF et compression à 350 Ko maximum.
- Limite cumulée des photos importées : 2 Mo pour la gestion locale ; sauvegarde JSON limitée à 4 Mo. Une erreur de sauvegarde conserve l’état précédent et laisse le formulaire ouvert.
- Les photos importées sont sauvegardées avec les données locales, sans transfert réseau. Les illustrations intégrées conservent leurs crédits et la mention illustrative.
- Utiliser des photos dont l’entreprise détient les droits. Une photo importée est présentée comme photo du produit ; vérifier sa correspondance avant publication.

## Persistance et compatibilité

La clé `tradeflow.snapshot.v1` est conservée pour retrouver les anciennes données. Le contenu est désormais au format **version 2**. Une sauvegarde version 1 est lue sans perdre les identifiants, le stock, les commandes ou les mouvements ; ses produits deviennent des brouillons avec catégorie « Sans catégorie » et unité « pièce ».

Les photos, catégories, unités, statuts et le choix du catalogue local sont restaurés au redémarrage. Une sauvegarde illisible n’est jamais remplacée automatiquement. Le panier sauvegarde les identifiants et les quantités, y compris les identifiants devenus indisponibles.

Ce stockage local n’est pas une base partagée ni un système de sauvegarde externe. La désinstallation ou l’effacement des données du navigateur peut supprimer les données. Firebase Authentication, Firestore, Storage, la synchronisation et les règles de sécurité restent une étape distincte : [FIREBASE.md](FIREBASE.md).

## Validation

Validation : **68 tests réussis**, analyse Flutter sans anomalie et compilation Web de production réussie. Le catalogue publié et une photo enregistrée localement ont aussi été contrôlés dans Chromium, avec un profil de test isolé.

Tests automatisés : migration version 1, persistance version 2 et photos, historique des commandes, unicité des références, échecs d’écriture, publication/archivage/restauration, renommage des références utilisées, projection publique, panier après retrait et normalisation d’images. Parcours d’interface à 320 et 1 440 pixels et catalogue mis à jour en direct.

À vérifier sur appareil Android/iOS : ouverture du sélecteur natif, import d’une photo de l’appareil, clavier, retour système et conservation après fermeture complète. Les tests automatisés du traitement d’images ne remplacent pas ces essais natifs.

## Suite de la gestion interne

Ce volet clôt les **produits et le catalogue**. Le module [Stocks et inventaires](STOCK_MANAGEMENT.md) permet désormais les comptages physiques, les entrées/sorties et leur traçabilité locale. Les [fiches clients et fournisseurs](PARTNERS_MANAGEMENT.md) sont également disponibles. Les entrepôts multiples et transferts de stock restent à développer. Les ventes, achats, devis et réceptions appartiennent aux étapes suivantes.
