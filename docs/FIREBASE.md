# TradeFlow — Configuration Firebase et passage au fonctionnement réel

Guide adapté au dépôt, vérifié le 25 octobre 2026 à partir des documentations officielles. Les commandes ci-dessous sont à exécuter au moment du raccordement ; leur présence dans ce document ne signifie pas qu’elles ont été exécutées.

## 0. État actuel et résultat recherché

Aujourd’hui : aucun plugin Firebase dans `pubspec.yaml`, aucun projet cloud associé et aucune initialisation Firebase dans `main.dart`. Les interfaces des phases 1 à 4 fonctionnent avec des données locales ou simulées. `firebase.json`, les émulateurs et les règles de refus par défaut existent déjà.

Le raccordement technique est une première étape. Il faudra ensuite remplacer les services simulés par Authentication, des dépôts Firestore et des opérations serveur. Ajouter une configuration Firebase ne synchronise pas automatiquement les données locales et ne crée pas de commandes réelles.

Périmètre initial conseillé : une entreprise, XOF, un entrepôt, catalogue public et opérations internes protégées.

## 1. Confirmer les décisions de configuration

Avant d’enregistrer les applications :

- Compte Google propriétaire du projet et personnes autorisées à l’administrer.
- Identifiants des projets de développement et de production, distincts et globalement uniques.
- Identifiants définitifs des applications Android et Apple.
- Région de Firestore, région du bucket Storage et région des fonctions selon les utilisateurs et les contraintes de l’entreprise.
- Domaine Web de production, identité de l’entreprise et adresse d’assistance.
- Compte de facturation pour les services qui le nécessitent.

Identifiants **actuellement dans le code** :

| Plateforme | Valeur actuelle | Emplacement |
|---|---|---|
| Android | `com.tradeflow.tradeflow_mobile` | `android/app/build.gradle.kts` : `applicationId` |
| iOS | `com.tradeflow.tradeflowMobile` | `ios/Runner.xcodeproj/project.pbxproj` : `PRODUCT_BUNDLE_IDENTIFIER` de Runner |
| Web | Application Web à enregistrer dans Firebase | Pas de package Android ni de bundle Apple |

Les identifiants Android et iOS diffèrent. Ne pas enregistrer le package Android à la place du bundle iOS. Confirmer ou modifier ces identifiants avant le raccordement ; le nom du dépôt GitHub n’est pas un identifiant Firebase.

Pour installer simultanément une version dev et une version prod sur mobile, prévoir des flavors/schemes et identifiants distincts, par exemple un suffixe `.dev` pour le développement. Ne pas remplacer simplement la configuration native dev par celle de prod dans le même build.

## 2. Vérifier les outils sur la machine

Depuis la racine du projet :

```sh
flutter --version
dart --version
flutter doctor -v
node --version
npm --version
java -version
```

Utiliser un Node.js LTS récent compatible avec Firebase CLI. Pour les émulateurs, prévoir un JDK compatible ; JDK 21 est un choix pratique à vérifier avec la version installée de Firebase CLI. iOS doit être configuré/compilé et testé avec les outils Apple sur macOS ; on peut commencer par Android et Web sur Linux.

Sur cette machine, le SDK Flutter permanent est `~/snap/flutter/common/flutter`. La sélection locale est déjà configurée dans VS Code. Les commandes doivent utiliser cette installation et le cache permanent `~/.pub-cache`, sans régénérer les dépendances avec les copies de test `/tmp`.

Installer les outils nécessaires :

```sh
npm install -g firebase-tools
firebase --version
firebase login
firebase projects:list

dart pub global activate flutterfire_cli
```

Si `flutterfire` n’est pas dans le chemin du terminal, utiliser l’exécutable `~/.pub-cache/bin/flutterfire`, ou `dart pub global run flutterfire_cli:flutterfire` à la place de `flutterfire` dans les commandes suivantes.

Références : [Firebase CLI](https://firebase.google.com/docs/cli), [FlutterFire](https://firebase.google.com/docs/flutter/setup).

## 3. Créer les environnements dans Firebase Console

Dans [Firebase Console](https://console.firebase.google.com/), créer deux projets :

- **TradeFlow Dev** : développement, tests et essais utilisateurs.
- **TradeFlow Prod** : données réelles, à activer après validation du développement.

Les noms affichés sont libres ; les identifiants réels seront uniques. Activer Analytics uniquement si son usage est prévu ; ce n’est pas nécessaire pour commencer l’authentification et la base métier.

Les applications Android/Web/iOS d’un même environnement se rattachent à son projet Firebase. Les applications de production utilisent le projet de production, pas celui de développement.

### Facturation

Cloud Storage for Firebase requiert désormais le plan Blaze ; le déploiement de Cloud Functions nécessite également Blaze. Prévoir le compte Cloud Billing et des alertes de budget/usage. Les émulateurs permettent de tester les services localement avant un déploiement cloud. La création d’un compte de facturation doit être réalisée par la personne autorisée de l’entreprise.

Références : [organisation des projets](https://firebase.google.com/docs/projects/learn-more), [exigences Storage](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024), [Cloud Functions](https://firebase.google.com/docs/functions/get-started).

## 4. Associer le dépôt au projet de développement

Pour la suite, définir dans le terminal l’identifiant réel du projet dev, en remplaçant la valeur d’exemple :

```sh
TRADEFLOW_DEV_PROJECT_ID='remplacer-par-id-reel-du-projet-dev'
```

Puis :

```sh
firebase projects:list
firebase use --add
```

Sélectionner le projet dev et lui attribuer l’alias `dev`. L’alias peut être stocké dans `.firebaserc` ; le projet explicitement fourni par `--project` reste préférable dans les commandes de déploiement.

Le dépôt contient déjà `firebase.json` avec Firestore, Storage et les ports des émulateurs. Conserver les chemins `firebase/firestore.rules`, `firebase/firestore.indexes.json` et `firebase/storage.rules`. Les étapes interactives `firebase init` suivantes doivent compléter cette configuration, sans remplacer les règles existantes par des règles ouvertes.

## 5. Installer les plugins et configurer FlutterFire

Plugins du socle :

```sh
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutterfire configure --project="$TRADEFLOW_DEV_PROJECT_ID" --platforms=android,web
```

Sur un environnement capable de configurer les plateformes Apple, ajouter iOS à la sélection et fournir son bundle identifier exact. FlutterFire peut créer les applications Firebase ou retrouver celles qui correspondent aux identifiants existants.

Vérifier les applications dans les paramètres du projet Firebase et examiner les fichiers générés, notamment `lib/firebase_options.dart`. Vérifier aussi les configurations natives produites par le CLI pour les plateformes choisies.

Après ajout ultérieur de services, relancer FlutterFire si la procédure du plugin le demande. Prévoir selon le lot :

```sh
flutter pub add cloud_functions
flutter pub add firebase_messaging
flutter pub add firebase_app_check
flutter pub add firebase_crashlytics
```

Ne pas activer tous les services dans le code sans leur configuration correspondante. Crashlytics concerne ici les plateformes mobiles prises en charge ; prévoir un suivi d’erreurs adapté pour Web.

### Développement et production

Commencer avec la configuration dev uniquement. Avant d’introduire prod, mettre en place la sélection explicite d’environnement et les flavors/schemes mobiles. Chaque build doit utiliser un ensemble cohérent : identifiant de plateforme, fichier natif et options Dart du même projet. Un simple changement de `firebase use` ne change pas la configuration de l’application Flutter.

Référence : [configuration FlutterFire](https://firebase.google.com/docs/flutter/setup).

## 6. Initialiser Firebase au démarrage

Après génération du fichier de configuration, ajouter à `lib/main.dart` :

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
```

Puis, après `WidgetsFlutterBinding.ensureInitialized()` et avant toute utilisation des services :

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Conserver un traitement distinct des erreurs de démarrage Firebase. Dans le `main.dart` actuel, le `catch` affiche une erreur de stockage local : il doit être adapté pour ne pas présenter une panne Firebase comme un problème de préférences locales.

Démarrer l’application après intégration de cette initialisation :

```sh
flutter run -d chrome
```

Ce démarrage valide l’initialisation technique, pas encore le remplacement du mode simulé.

## 7. Configurer Authentication

Dans Firebase Console → Authentication :

1. Initialiser Authentication.
2. Activer le fournisseur **E-mail/Mot de passe**.
3. Configurer les modèles de vérification d’adresse et de récupération du mot de passe.
4. Vérifier les domaines autorisés : domaine Web de production et domaines de développement nécessaires. Vérifier explicitement `localhost` pour les essais Web locaux ; ne pas supposer sa présence automatique.
5. Définir la politique de mot de passe et les paramètres de protection adaptés.

Dans le code :

| Interface actuelle | Raccordement réel requis |
|---|---|
| Connexion simulée | `signInWithEmailAndPassword` |
| Inscription simulée | `createUserWithEmailAndPassword` puis création contrôlée du profil client |
| Vérification simulée | `sendEmailVerification`, rechargement de l’utilisateur et contrôle de `emailVerified` |
| Récupération simulée | `sendPasswordResetEmail` |
| Déconnexion simulée | `signOut` et nettoyage des caches privés de l’application |
| Session en mémoire | Écoute de l’état Auth et chargement du profil associé au `uid` |

Les mots de passe sont gérés par Authentication, jamais par Firestore ou `shared_preferences`. Les documents métier sont liés au `uid`, et non à un e-mail utilisé comme seule preuve d’identité.

Les nouveaux inscrits deviennent clients. Le premier administrateur et les collaborateurs sont provisionnés par une procédure serveur contrôlée ; un client ne doit pas pouvoir écrire son propre rôle ou son appartenance à une entreprise. Retirer le sélecteur des profils de démonstration du build distribué.

Référence : [Authentication pour Flutter](https://firebase.google.com/docs/auth/flutter/start).

## 8. Créer Firestore et définir les données

Dans Firebase Console → Firestore Database :

1. Créer la base métier dans l’édition et le mode appropriés au SDK Firebase retenu, typiquement Firestore Standard/native pour ce projet.
2. Choisir la localisation avant création.
3. Commencer avec les règles de production fermées ; les ouvrir uniquement selon les permissions testées.

Structure de départ proposée pour TradeFlow :

```text
publicProducts/{productId}           # uniquement les champs publiables
users/{uid}                         # profil du titulaire
users/{uid}/addresses/{addressId}
users/{uid}/notifications/{noticeId}
companies/{companyId}
companies/{companyId}/members/{uid}  # rôles administrés côté serveur
companies/{companyId}/products/{id}  # coûts et stock internes
companies/{companyId}/contacts/{id}
companies/{companyId}/orders/{id}    # customerUid, état et instantanés validés
companies/{companyId}/movements/{id}
companies/{companyId}/requests/{id}  # customerUid et orderId contrôlés
```

Adapter ce schéma aux requêtes réelles et créer les index correspondants. Les règles Firestore s’appliquent aux documents : les coûts/marges et quantités exactes ne doivent pas être mélangés dans le document public du produit.

À développer : dépôts distants, modèles sérialisés, flux de lecture, pagination, gestion des erreurs et reprise après coupure. Remplacer progressivement les listes en mémoire et l’instantané local de gestion ; ne pas synchroniser un instantané complet non contrôlé entre plusieurs utilisateurs.

Les exemples ne sont importés que dans l’environnement dev, avec un marquage explicite. Une migration des données locales réelles doit être volontaire, validée et séparée des exemples.

Références : [création de Firestore](https://firebase.google.com/docs/firestore/quickstart), [conditions des règles](https://firebase.google.com/docs/firestore/security/rules-conditions).

## 9. Écrire et tester les règles d’accès

Les fichiers actuels refusent tous les accès. Cette base est intentionnelle ; des erreurs `permission-denied` sont attendues tant que les règles métier n’ont pas été implémentées.

La matrice à implémenter et tester doit garantir :

- Lecture anonyme des seuls produits publiés, avec des requêtes compatibles avec les règles.
- Profil/adresses/notifications accessibles seulement à leur propriétaire, avec validation des champs modifiables.
- Commandes, demandes et documents visibles seulement par le client concerné ou les membres autorisés de l’entreprise.
- Absence d’auto-attribution des rôles et d’accès à une autre entreprise.
- Absence de modification libre des prix, du statut payé, des quantités et de l’historique.
- Validation des types, bornes, champs requis et transitions.

Les tests doivent couvrir les refus aussi bien que les accès légitimes. Les contrôles de l’interface ne remplacent pas ces règles. Les opérations Admin SDK côté serveur contournent les règles : chaque fonction doit donc vérifier l’identité, les permissions et les entrées elle-même.

## 10. Configurer Cloud Storage

Dans Firebase Console → Storage : créer le bucket, choisir la région et conserver des règles fermées jusqu’à validation.

Organisation proposée :

```text
companies/{companyId}/products/{productId}/...
companies/{companyId}/orders/{orderId}/documents/...
companies/{companyId}/requests/{requestId}/attachments/...
```

Développer le choix de fichier, l’envoi, la progression, les limites de taille/type et les erreurs. Les photos de produits publiées peuvent être rendues publiques selon la stratégie retenue ; les pièces justificatives et documents clients restent privés. Éviter des liens permanents partageables pour les documents confidentiels ; employer des accès contrôlés.

Les photos actuellement embarquées restent utilisables comme ressources illustratives. Pour les produits réels, téléverser les photographies autorisées de l’entreprise et enregistrer leurs références dans les données publiques.

Référence : [Storage pour Flutter](https://firebase.google.com/docs/storage/flutter/start).

## 11. Mettre en place les opérations serveur

Pour les commandes et stocks, prévoir une couche serveur. Si Cloud Functions est retenu :

```sh
firebase init functions
```

Choisir par exemple TypeScript et un runtime actuellement pris en charge par Firebase. Vérifier que l’initialisation complète `firebase.json` sans remplacer ses autres sections. La région des fonctions doit être définie et le client Flutter doit appeler la même région.

Opérations à implémenter :

- Création de commande avec clé d’idempotence.
- Vérification du client, des produits publiés, prix et disponibilités côté serveur.
- Réservation de stock et instantanés des lignes/adresses.
- Expédition, livraison, annulation et retour avec permissions et transitions contrôlées.
- Enregistrement des paiements vérifiés et traitement des confirmations du prestataire, si paiement en ligne.
- Journal d’activité et déclenchement des notifications.

Les écritures liées doivent être atomiques ; les opérations répétées ne doivent pas créer de double commande ni double mouvement. Une transaction serveur doit revalider les données qu’elle lit.

Les secrets du prestataire de paiement ou du service de messagerie restent côté serveur dans un gestionnaire de secrets. Ne pas les mettre dans l’application Flutter.

Références : [Cloud Functions](https://firebase.google.com/docs/functions/get-started), [transactions Firestore](https://firebase.google.com/docs/firestore/manage-data/transactions).

## 12. Tester avec les émulateurs

Configuration déjà présente :

| Service | Port |
|---|---:|
| Authentication | 9099 |
| Firestore | 8080 |
| Storage | 9199 |
| Interface des émulateurs | 4000 |

Démarrer les services avec un identifiant de projet de démonstration :

```sh
firebase emulators:start --project demo-tradeflow --only auth,firestore,storage
```

L’application ne s’y connecte pas automatiquement. Pour un build local dédié, initialiser Firebase avec la configuration cohérente du projet `demo-tradeflow`, puis connecter **tous** les services émulés avant leur première utilisation. Après ajout des plugins et de leurs imports :

```dart
await Firebase.initializeApp(demoProjectId: 'demo-tradeflow');

const emulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);

await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
```

Pour ce mode local, l’initialisation montrée ci-dessus remplace celle du projet dev cloud. Ne pas initialiser deux fois l’application Firebase par défaut. Le `projectId` doit correspondre à celui du CLI des émulateurs.

Ce bloc doit être protégé par une option explicite réservée aux builds de test. Il ne doit pas être activé dans une distribution de production. Un indicateur `--dart-define` n’a aucun effet tant que le code ne le lit pas.

Sur l’émulateur Android standard, l’hôte de la machine est généralement `10.0.2.2` ; sur Web/ordinateur, utiliser `127.0.0.1`. Les configurations réseau/HTTP locales spécifiques à Android ou Apple doivent être validées pour les tests. Pour un téléphone physique, employer une configuration réseau locale maîtrisée ou le projet dev cloud, pas une configuration production improvisée.

Si Functions est ajouté, déclarer son émulateur dans `firebase.json` et connecter aussi `FirebaseFunctions` à son port. Ne pas laisser une fonction ou un service manquant envoyer involontairement des opérations vers le cloud pendant un test.

Tester notamment l’accès anonyme, les rôles, les clients distincts, les entreprises distinctes, les commandes concurrentes, la répétition d’une confirmation, les retours, les fichiers interdits et les refus d’accès.

Référence : [Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure).

## 13. Activer les notifications et les e-mails utiles

Après fonctionnement des comptes et commandes :

- Ajouter/configurer Firebase Cloud Messaging.
- Android : valider les permissions requises et les appareils Google Play Services ciblés.
- iOS : préparer les capacités nécessaires et la configuration APNs dans les outils Apple/Firebase.
- Web : configurer VAPID, le service worker et le contexte HTTPS approprié.
- Enregistrer les jetons des appareils pour leur propriétaire et gérer leur renouvellement/suppression.
- Envoyer les notifications depuis le backend à partir d’événements vérifiés, sans doublons.
- Conserver un historique de notifications en base pour l’espace client.

Les e-mails de vérification/récupération appartiennent au parcours Authentication. Les e-mails de commande et livraison nécessitent un envoi transactionnel serveur/configuré séparément.

Référence : [Cloud Messaging pour Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started).

## 14. Ajouter App Check et la supervision

Enregistrer les applications avec un fournisseur App Check adapté à chaque plateforme. Initialiser App Check après Firebase, avant les services concernés. Utiliser les fournisseurs de débogage seulement pour les builds de test ; observer les métriques avant l’activation de l’application stricte des contrôles.

App Check complète l’authentification et les règles, il ne les remplace pas. Ajouter le suivi des erreurs, les journaux backend, les alertes d’usage, les sauvegardes et un essai de restauration. Ne pas enregistrer de mots de passe, jetons ou documents sensibles dans les journaux.

Références : [App Check Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers), [préparation au lancement](https://firebase.google.com/support/guides/launch-checklist).

## 15. Déployer d’abord en développement

Après implémentation et validation des règles :

```sh
firebase deploy --only firestore:rules,firestore:indexes,storage --project "$TRADEFLOW_DEV_PROJECT_ID"
```

Les règles de refus actuelles peuvent être déployées pour garder la base fermée, mais ne rendent pas l’application métier opérationnelle. Déployer les règles métier testées pour le fonctionnement réel.

Après création et validation des fonctions :

```sh
firebase deploy --only functions --project "$TRADEFLOW_DEV_PROJECT_ID"
```

Pour un hébergement Web Firebase, initialiser Hosting, sélectionner `build/web`, configurer le fonctionnement SPA si nécessaire et conserver les fichiers Flutter générés :

```sh
firebase init hosting
flutter build web --release
firebase deploy --only hosting --project "$TRADEFLOW_DEV_PROJECT_ID"
```

Avant chaque déploiement, vérifier les fichiers réellement modifiés, la cible et les services sélectionnés. Ces commandes sont une procédure à appliquer à un résultat testé ; aucun déploiement n’est réalisé par ce document.

## 16. Valider le fonctionnement réel puis préparer prod

Parcours de validation indispensables :

1. Compte créé dans Firebase Auth, vérification et récupération effectives.
2. Données client retrouvées après déconnexion/reconnexion et sur un autre appareil.
3. Catalogue public sans exposition des coûts et quantités internes.
4. Client A incapable de consulter/modifier les données du client B.
5. Collaborateur incapable de dépasser son rôle ou son entreprise.
6. Commande enregistrée une seule fois et stock cohérent en concurrence.
7. Fichiers privés protégés et opérations serveur contrôlées.
8. Notifications/documents réels cohérents avec les opérations.
9. Sauvegarde et restauration testées ; erreurs réseau présentées correctement.
10. Tests Android/Web/iOS selon les plateformes distribuées.

Contrôles du code :

```sh
flutter analyze
flutter test
flutter build web --release
```

Les tests du prototype doivent rester disponibles et être complétés par les tests de règles, d’intégration et de transactions ; ils ne prouvent pas à eux seuls la sécurité du backend.

Pour prod : configurer les identifiants/builds dédiés, initialiser les services du projet prod, déployer les règles et fonctions validées, provisionner le premier administrateur de manière contrôlée, puis publier un pilote. Les données de test et boutons de simulation ne doivent pas accompagner les opérations réelles.

Les options Firebase clientes générées ne sont généralement pas des secrets ; la protection repose sur Auth, les règles et le backend. Les comptes de service, clés privées et secrets serveur ne doivent jamais être commités. La signature Android actuelle du dépôt utilise encore la configuration de debug pour release : configurer une vraie signature de distribution avant publication.

## 17. Informations nécessaires pour commencer le raccordement

- Identifiant réel du projet Firebase dev.
- Plateformes à connecter d’abord : Android et Web conseillés sur cette machine Linux.
- Confirmation des identifiants Android et iOS.
- Régions retenues pour Firestore/Storage/Functions.
- Activation du fournisseur E-mail/Mot de passe et disponibilité des services nécessaires.
- Identité du premier administrateur à provisionner via une procédure autorisée.

Ne pas transmettre ici de mot de passe Google, de jeton de connexion, de clé privée ou de fichier de compte de service. Le `projectId` et les identifiants des applications suffisent pour commencer à préparer les fichiers de raccordement.
