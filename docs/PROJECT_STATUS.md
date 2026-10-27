# Bilan du projet — 25 octobre 2026

## État du produit

TradeFlow est actuellement un prototype Flutter local, avec un catalogue d’exemple remplaçable par les produits publiés localement et un parcours de commande simulé. Le développement suit l’ordre validé : interfaces et parcours d’abord, connexion aux services ensuite. La [recette des phases 1 à 4](ACCEPTANCE_PHASES_1_4.md) et les [crédits photographiques](PHOTO_CREDITS.md) présentent les derniers contrôles et ressources intégrées.

| Ensemble | État vérifié | Contenu |
|---|---|---|
| Base de gestion locale | Disponible | Produits, mouvements de stock, clients/fournisseurs, commandes à une ligne, expédition, livraison et annulation avant expédition. |
| Phase 1 — Fondations | Disponible | Thème, composants, états d’écran, navigation adaptative, guide des composants et six profils de démonstration. |
| Phase 2 — Catalogue public | Disponible avec données fictives | Accueil, huit produits, catégories, recherche, filtres, tri, fiches et présentation d’entreprise. |
| Phase 3 — Panier et accès client | Disponible en simulation | Panier à plusieurs lignes, sauvegarde locale, connexion/inscription/vérification/récupération fictives, livraison, récapitulatif et confirmation. |
| Phase 4 — Espace client | Disponible en simulation | Accueil personnel, commandes et suivi, profil, adresses, documents spécimens, demandes et notifications locales. |
| Phase 5 — Produits et catalogue | Disponible localement | Modification, publication, archivage/restauration, catégories, unités et import de photos. Voir [PRODUCTS_AND_CATALOG.md](PRODUCTS_AND_CATALOG.md). |
| Phase 5 — Stocks et inventaires | Disponible localement | Entrées/sorties confirmées, mouvements avant/après, inventaires atomiques, historique et contrôles de stock périmé. Voir [STOCK_MANAGEMENT.md](STOCK_MANAGEMENT.md). |
| Phase 5 — Clients et fournisseurs | Disponible localement | Fiches détaillées, recherche/filtres, modification, archivage/restauration et commandes internes liées au client. Voir [PARTNERS_MANAGEMENT.md](PARTNERS_MANAGEMENT.md). |
| Phase 6 — Opérations commerciales | Disponible localement | Devis, conversion, ventes, achats, réceptions/livraisons partielles, retours et journal. Une référence produit par document, XOF. Voir [COMMERCIAL_OPERATIONS.md](COMMERCIAL_OPERATIONS.md). |
| Livraisons et retours | Disponible localement | Suivi transporteur, retards et retours revendables ou exclus du disponible. Voir [DELIVERIES_AND_RETURNS.md](DELIVERIES_AND_RETURNS.md). |
| Documents commerciaux | Disponible localement | Devis, bons, proformas, export PDF et versions archivées. Voir [BUSINESS_DOCUMENTS.md](BUSINESS_DOCUMENTS.md). |
| Pilotage | Disponible localement | Vues par profil, périodes, indicateurs, alertes, activité et CSV. Voir [PILOTAGE.md](PILOTAGE.md). |
| Qualité et architecture | Renforcées et vérifiées localement | Couches séparées, modèles découpés, intégrité des instantanés, cache d’écriture corrigé, cycle de vie et CI avec seuils de couverture. Voir [ARCHITECTURE.md](ARCHITECTURE.md) et [QUALITY.md](QUALITY.md). |
| Firebase | Préparation documentaire uniquement | Procédure de raccordement et règles de refus par défaut ; aucun service Firebase connecté. |

Les commandes publiques simulées ne modifient pas le stock ni les commandes de la gestion interne. Le panier public conserve uniquement les identifiants des produits et leurs quantités. Les sessions, adresses et reçus simulés sont temporaires ; les mots de passe ne sont pas persistés.

## Problème des diagnostics rouges dans VS Code

### Cause identifiée

La capture montre des imports Flutter non résolus et de nombreuses erreurs en cascade. Les badges numériques de diagnostics sont distincts des marques Git `M` (modifié) et `U` (non suivi).

Le fichier généré `.dart_tool/package_config.json` référençait des copies de test sous `/tmp/tradeflow-flutter-sdk` et `/tmp/tradeflow-pub-cache`. Ces copies temporaires ne constituent pas une configuration de développement durable pour l’IDE. Une mauvaise résolution de Flutter fait ensuite apparaître des erreurs sur `Widget`, `TextEditingController`, etc., même lorsque le code est compilable avec un SDK correctement sélectionné.

### Correction effectuée

- Dépendances régénérées avec le SDK permanent : `~/snap/flutter/common/flutter`.
- Cache utilisateur permanent utilisé : `~/.pub-cache`.
- Les 72 racines de packages sont présentes ; aucune ne pointe vers `/tmp`.
- Sélection du SDK ajoutée dans `.vscode/settings.json` pour cette machine, avec ajout du SDK au chemin des nouveaux terminaux intégrés.
- `.vscode/settings.json` exclu de Git pour éviter d’imposer un chemin local aux autres développeurs.
- Recommandations d’extensions Dart/Flutter et configuration de lancement Web ajoutées dans `.vscode/extensions.json` et `.vscode/launch.json`.

La correction de la résolution des dépendances est vérifiée. Le rafraîchissement effectif de la fenêtre VS Code doit être confirmé sur l’interface de l’utilisateur.

### Rafraîchir VS Code

1. Enregistrer les fichiers ouverts.
2. Ouvrir la palette avec `Ctrl + Maj + P` et exécuter **Developer: Reload Window**.
3. Vérifier le panneau **Problèmes** avec `Ctrl + Maj + M`.
4. Si nécessaire, exécuter **Dart: Restart Analysis Server**.
5. Ouvrir un nouveau terminal intégré pour utiliser le SDK sélectionné.

Les autres développeurs doivent sélectionner leur propre SDK via **Flutter: Change SDK**, puis exécuter `flutter pub get`. Les fichiers `.dart_tool`, `build` et les caches ne doivent pas être commités. Les vérifications futures sur cette machine doivent utiliser l’installation permanente, sans régénérer la configuration du projet avec des chemins `/tmp`.

## Vérifications du bilan

- Format Dart : conforme.
- Analyse Flutter avec le SDK permanent : aucune anomalie signalée.
- Tests : 172 scénarios réussis avec le SDK permanent.
- Racines de packages : 72 présentes, aucune temporaire.
- Couverture de lignes : 88,35 % globale, 98,02 % domaine, 97,11 % application ; seuils CI respectés.
- Diff Git : aucune erreur d’espacement signalée.
- Compilation Web de production : réussie avec le SDK permanent.

Les tests couvrent notamment les règles de stock, l’annulation, la persistance, les échecs d’écriture, les recherches et filtres, les six profils, les petits/grands écrans et les parcours de connexion/commande simulés. La recette des quatre phases ajoute le décodage hors réseau des photos et la navigation entre sessions. La phase 4 ajoute des contrôles sur l’historique client, les demandes, les adresses par défaut, leurs instantanés, les notifications et les vues après déconnexion. Le volet produits ajoute la migration des anciennes sauvegardes, la persistance des photos importées, publication/archivage/restauration, catégories/unités et synchronisation du catalogue et du panier local. Les tests de stocks ajoutent les inventaires atomiques, leurs conflits avec les mouvements récents, la traçabilité, les bornes et les parcours Magasinier/Administrateur. Ils ne remplacent pas les essais sur appareils Android et iOS.

## Travail restant

| Phase | Travail prévu |
|---|---|
| 5 — Suite gestion interne | Entrepôts multiples et transferts. Les volets produits/catalogue, stocks/inventaires et clients/fournisseurs sont implémentés localement. |
| 6 — Évolutions opérations | Documents multi-lignes, clôture de reliquats et intégrations aux services réels. Le parcours local à une référence par document est implémenté. |
| 7 — Finance et international | Factures, paiements simulés, devises, coûts et documents internationaux. |
| 8 — Administration | Collaborateurs, permissions réelles et autres paramètres. Le pilotage et les coordonnées de l’entreprise sont implémentés localement. |
| 9 — Validation sur appareils | Essais Android/iOS, lecteur d’écran, clavier et partage natif. Les gardes d’architecture et contrôles automatisés sont en place. |
| 10 — Services réels | Authentification Firebase, Firestore, Storage, permissions, transactions, synchronisation, notifications et paiements. |

## État avant le prochain commit/push

Les commits dédiés couvrent la phase 6 (`3f6b32f`), les livraisons et retours (`655ef24`) et les documents PDF (`9780c10`). Le pilotage est enregistré dans `e1ba784`. Le volet qualité et architecture ajoute les corrections, le découpage et les gardes de non-régression. Aucun push n’est effectué dans cette étape.

Les réglages SDK personnels et les fichiers générés restent exclus. Les fichiers de configuration VS Code partageables peuvent être commités. Le push doit transmettre les sources et la documentation, sans les caches ni le dossier de compilation.

## Formulation pour expliquer le problème

> Les erreurs affichées dans VS Code venaient d’une configuration locale des dépendances qui référençait un SDK Flutter et un cache temporaires. Les imports non résolus provoquaient une cascade de diagnostics. Les dépendances ont été régénérées avec l’installation permanente et le SDK de l’IDE a été configuré. L’analyse ne signale plus d’anomalie et les 172 tests passent ; un rechargement de VS Code permet de rafraîchir les diagnostics de l’éditeur.
