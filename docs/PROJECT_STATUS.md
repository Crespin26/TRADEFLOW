# Bilan du projet — 25 octobre 2026

## État du produit

TradeFlow est actuellement un prototype Flutter local, avec un catalogue fictif et un parcours de commande simulé. Le développement suit l’ordre validé : interfaces et parcours d’abord, connexion aux services ensuite. La [recette des phases 1 à 4](ACCEPTANCE_PHASES_1_4.md) et les [crédits photographiques](PHOTO_CREDITS.md) présentent les derniers contrôles et ressources intégrées.

| Ensemble | État vérifié | Contenu |
|---|---|---|
| Base de gestion locale | Disponible | Produits, mouvements de stock, clients/fournisseurs, commandes à une ligne, expédition, livraison et annulation avant expédition. |
| Phase 1 — Fondations | Disponible | Thème, composants, états d’écran, navigation adaptative, guide des composants et six profils de démonstration. |
| Phase 2 — Catalogue public | Disponible avec données fictives | Accueil, huit produits, catégories, recherche, filtres, tri, fiches et présentation d’entreprise. |
| Phase 3 — Panier et accès client | Disponible en simulation | Panier à plusieurs lignes, sauvegarde locale, connexion/inscription/vérification/récupération fictives, livraison, récapitulatif et confirmation. |
| Phase 4 — Espace client | Disponible en simulation | Accueil personnel, commandes et suivi, profil, adresses, documents spécimens, demandes et notifications locales. |
| Firebase | Préparation documentaire uniquement | Procédure de raccordement et règles de refus par défaut ; aucun service Firebase connecté. |

Les commandes publiques simulées ne modifient pas le stock ni les commandes de la gestion interne. Le panier public conserve uniquement les identifiants des produits et leurs quantités. Les sessions, adresses et reçus simulés sont temporaires ; les mots de passe ne sont pas persistés.

## Problème des diagnostics rouges dans VS Code

### Cause identifiée

La capture montre des imports Flutter non résolus et de nombreuses erreurs en cascade. Les badges numériques de diagnostics sont distincts des marques Git `M` (modifié) et `U` (non suivi).

Le fichier généré `.dart_tool/package_config.json` référençait des copies de test sous `/tmp/tradeflow-flutter-sdk` et `/tmp/tradeflow-pub-cache`. Ces copies temporaires ne constituent pas une configuration de développement durable pour l’IDE. Une mauvaise résolution de Flutter fait ensuite apparaître des erreurs sur `Widget`, `TextEditingController`, etc., même lorsque le code est compilable avec un SDK correctement sélectionné.

### Correction effectuée

- Dépendances régénérées avec le SDK permanent : `~/snap/flutter/common/flutter`.
- Cache utilisateur permanent utilisé : `~/.pub-cache`.
- Les 47 racines de packages sont présentes ; aucune ne pointe vers `/tmp`.
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
- Tests : 56 scénarios réussis avec le SDK permanent.
- Racines de packages : 47 présentes, aucune temporaire.
- Diff Git : aucune erreur d’espacement signalée.
- Compilation Web de production : réussie avec le SDK permanent.

Les tests couvrent notamment les règles de stock, l’annulation, la persistance, les échecs d’écriture, les recherches et filtres, les six profils, les petits/grands écrans et les parcours de connexion/commande simulés. La recette des quatre phases ajoute le décodage hors réseau des photos et la navigation entre sessions. La phase 4 ajoute des contrôles sur l’historique client, les demandes, les adresses par défaut, leurs instantanés, les notifications et les vues après déconnexion. Ils ne remplacent pas les essais sur appareils Android et iOS.

## Travail restant

| Phase | Travail prévu |
|---|---|
| 5 — Gestion interne | Modification/publication/archivage, inventaires, entrepôts et fiches partenaires complètes. |
| 6 — Opérations | Devis, achats, réceptions, livraisons partielles et retours. |
| 7 — Finance et international | Factures, paiements simulés, devises, coûts et documents internationaux. |
| 8 — Pilotage | Tableaux de bord métier, rapports, collaborateurs et paramètres. |
| 9 — Validation des interfaces | Parcours complets, accessibilité et essais sur appareils réels. |
| 10 — Services réels | Authentification Firebase, Firestore, Storage, permissions, transactions, synchronisation, notifications et paiements. |

## État avant le prochain commit/push

Les commits existants couvrent la base et les phases 1 à 3, dont le correctif de configuration IDE. Les quatre phases sont commitées. La recette transversale, les photographies locales et les corrections de navigation constituent le travail local du prochain commit. Voir [CUSTOMER_SPACE_DEMO.md](CUSTOMER_SPACE_DEMO.md).

Les réglages SDK personnels et les fichiers générés restent exclus. Les fichiers de configuration VS Code partageables peuvent être commités. Le push doit transmettre les sources et la documentation, sans les caches ni le dossier de compilation.

## Formulation pour expliquer le problème

> Les erreurs affichées dans VS Code venaient d’une configuration locale des dépendances qui référençait un SDK Flutter et un cache temporaires. Les imports non résolus provoquaient une cascade de diagnostics. Les dépendances ont été régénérées avec l’installation permanente et le SDK de l’IDE a été configuré. L’analyse ne signale plus d’anomalie et les 56 tests passent ; un rechargement de VS Code permet de rafraîchir les diagnostics de l’éditeur.
