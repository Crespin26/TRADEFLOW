# Phase 2 — Catalogue public

## Parcours disponibles

- **Visiteur → Accueil** : présentation, catégories, sélection de produits et entreprise de démonstration.
- **Visiteur ou Client → Catalogue** : huit produits fictifs, recherche, filtres et tri.
- **Voir le produit** : fiche détaillée, photographie agrandissable, disponibilité, prix par conditionnement, description, caractéristiques, origine et conditions indicatives.
- **À découvrir aussi** : navigation vers les autres produits de la même catégorie lorsqu’il y en a.

Aucun compte n’est nécessaire pour consulter ces interfaces. Les données publiques sont indépendantes de `TradeStore` et des produits locaux internes. Le modèle public ne contient ni coût d’achat, ni quantité de stock, ni coordonnées de partenaires.

## Recherche et filtres

La recherche porte sur le nom, la référence, la catégorie et la description. Elle ignore les accents et la casse, et accepte plusieurs mots.

Les filtres se combinent :

- Catégorie : alimentation, textile, équipement ou emballage.
- Disponibilité : disponible, sur commande ou rupture.
- Prix en XOF : moins de 10 000, de 10 000 à 50 000 inclus, plus de 50 000.
- Tri : sélection mise en avant, nom, prix croissant ou décroissant.

Le nombre de résultats est affiché. En l’absence de résultat, une action réinitialise la recherche et les filtres. Revenir depuis une fiche conserve la sélection courante. Les catégories de l’accueil ouvrent directement le catalogue filtré.

## Nature des données et limites

Les noms, prix, caractéristiques, disponibilités et coordonnées d’entreprise sont fictifs. Les visuels sont des photographies de Pexels et Unsplash intégrées localement. Ce sont des photos illustratives, et non les photos certifiées des références vendues. Chaque fiche propose un agrandissement avec zoom. Voir [PHOTO_CREDITS.md](PHOTO_CREDITS.md).

Les produits ne proviennent pas de Firebase et ne sont pas synchronisés avec la gestion locale. L’entreprise présentée est fictive et son adresse e-mail utilise le domaine réservé `.example`.

La phase 3 ajoute l’action Ajouter au panier, le panier sauvegardé localement et les parcours de connexion et commande simulés. Les articles en rupture ne sont pas ajoutables. Voir [CART_AND_AUTH_DEMO.md](CART_AND_AUTH_DEMO.md). Aucun paiement ni envoi de demande réel n’est réalisé.

## Fichiers

- `lib/domain/public_catalog.dart` : modèle public, exemples et sélection des résultats.
- `lib/ui/catalog/public_home.dart` : accueil public et présentation de l’entreprise.
- `lib/ui/catalog/catalog_page.dart` : recherche, filtres et catalogue.
- `lib/ui/catalog/product_detail.dart` : fiche produit et variantes de présentation.
- `lib/ui/catalog/product_widgets.dart` : cartes, miniatures et disposition adaptative.
- `lib/ui/catalog/catalog_photo.dart` : photo locale, zoom, crédits et repli en cas d’absence.
- `lib/domain/catalog_photos.dart` : association des références aux photographies et à leurs crédits.

La grille utilise des cartes de hauteur libre pour rester lisible avec du texte agrandi. Le jeu de huit produits est affiché entièrement ; la pagination sera ajoutée avec une source distante ou un catalogue plus important.

## Catalogue relié à la gestion locale

Depuis le volet produits de la phase 5, la première publication remplace les huit exemples par les produits publiés localement. Les brouillons et archives restent internes. Le catalogue, les fiches et le panier suivent les modifications et retraits ; le choix persiste même lorsque tous les produits sont retirés. Voir [PRODUCTS_AND_CATALOG.md](PRODUCTS_AND_CATALOG.md).
