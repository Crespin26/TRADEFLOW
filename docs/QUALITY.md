# Qualité et validation

## Vérifications reproductibles

Utiliser le SDK permanent sélectionné dans l’IDE, puis :

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test --coverage --reporter expanded
dart run tool/check_coverage.dart
flutter build web --release --no-pub
```

L’analyse active les casts et l’inférence stricts, ainsi que les règles Flutter. Les diagnostics ne sont pas masqués pour obtenir un résultat vert. Les fichiers générés restent exclus de Git ; le SDK et le cache de paquets ne doivent pas pointer vers un répertoire temporaire.

## Résultat mesuré

- 172 tests réussis, analyse stricte sans diagnostic, format conforme et compilation Web de production réussie.
- Couverture globale : **88,35 %** ; domaine : **98,02 %** ; application : **97,11 %** ; stockage : **96,77 %** ; interface/PDF : **83,73 %**.
- Les seuils sont respectés. Le contrôle a aussi été vérifié avec un rapport absent et un rapport sous les seuils : tous deux sont refusés.

## Gardes d’architecture

Les tests empêchent les dépendances directes du domaine vers Flutter, l’application ou le stockage ; celles de l’application vers les widgets ou le stockage ; celles du stockage vers l’application ou les widgets ; et celles des écrans vers les adaptateurs de données. Le point de composition `main.dart` relie ces couches.

Les aides de tests ne sont pas importées depuis d’autres fichiers `*_test.dart` : elles sont regroupées dans `test/support/`.

## Couverture des lignes

Le contrôle LCOV impose les minima suivants pour les sources de production instrumentées :

| Périmètre | Minimum |
|---|---:|
| Global | 85 % |
| Domaine | 95 % |
| Application | 95 % |
| Stockage | 90 % |
| Interface et PDF | 80 % |

Un rapport absent, vide, mal formé ou un périmètre sans source provoque un échec. Les chemins extérieurs au projet sont ignorés et les lignes dupliquées sont fusionnées. La couverture de lignes n’est pas une preuve d’absence de bugs ; les scénarios d’intégrité et de défaillance restent nécessaires.

## Régressions ajoutées

- Sauvegarde syntaxiquement lisible mais incohérente : références absentes, identifiants dupliqués, stocks négatifs, compteurs excessifs, conversion de devis mal reliée ou historique incompatible.
- Chargement rejeté sans remplacer le dernier état valide, sans effacer le stockage et avec écritures bloquées jusqu’à une lecture valide.
- Refus d’écriture plateforme retournant `false` ou levant une exception, avec contrôle de l’état, du cache et du rechargement.
- Panier refusé non réintroduit par le cache ; changements externes au cache pris en compte à la lecture.
- Remplacement des contrôleurs et du catalogue, détachement des anciens écouteurs et respect de la propriété des sessions injectées et actualisation d’un enfant constant conservant la même session.
- Démarrage normal, données corrompues et stockage initialement indisponible.
- Conservation de l’entreprise et des références personnalisées lors du chargement d’exemples dans un espace vide.

Les scénarios existants des stocks, partenaires, opérations, retours, PDF et pilotage restent exécutés, avec les parcours à 320, 390 et 1 440 pixels selon les fonctionnalités. Les tests du partage natif injectent un service ; les essais sur appareils restent distincts.

## CI

Le workflow `.github/workflows/flutter.yml` utilise le SDK épinglé et le fichier de verrouillage, vérifie le format, l’analyse, les tests avec couverture, les seuils et la compilation Web. Il conserve le rapport LCOV comme artefact pendant sept jours. Les exécutions obsolètes d’une même branche sont annulées et le job a une limite de vingt minutes.

Les commandes sont vérifiées localement. Une exécution GitHub Actions distante ne peut être considérée réussie qu’après son exécution effective sur le dépôt.

## Limites avant distribution

Firebase, permissions réelles, transactions et conflits entre appareils restent à implémenter. Les tests ne remplacent pas les essais Android/iOS, clavier, lecteur d’écran, impression/partage natifs, signature et distribution. Les profils de démonstration et données simulées doivent être traités lors du passage à la production.
