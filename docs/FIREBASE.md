# Préparer la connexion Firebase

## État actuel

L’application démarre avec `LocalTradeRepository` et fonctionne sans Firebase. Le dépôt contient uniquement une configuration d’émulateurs et des règles qui refusent tous les accès. Il n’y a pas encore d’authentification, de dépôt Firestore ni de notifications push.

## Raccordement à un projet de développement

À exécuter avec un compte autorisé à administrer le projet Firebase de l’entreprise. Choisir une région et une politique de conservation adaptées avant de créer Firestore. Confirmer aussi les identifiants Android et iOS avant d’enregistrer les applications.

La [documentation officielle Firebase pour Flutter](https://firebase.google.com/docs/flutter/setup) décrit le raccordement :

```sh
# Installer Firebase CLI selon les instructions officielles, puis :
firebase login
dart pub global activate flutterfire_cli
flutter pub add firebase_core firebase_auth cloud_firestore
flutterfire configure --project=<identifiant-projet-developpement>
```

`flutterfire configure` génère notamment `lib/firebase_options.dart` et peut modifier la configuration des plateformes. Aucun identifiant fictif n’est fourni dans le code actuel.

L’initialisation à ajouter avant l’utilisation des services est :

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Cette initialisation seule ne synchronise pas le stockage local. L’étape suivante consiste à implémenter le dépôt distant et l’authentification, puis à les sélectionner explicitement au démarrage. Ne pas importer automatiquement les données de démonstration dans le cloud.

## Modèle distant proposé

Une entreprise possède ses propres collections :

```text
companies/{companyId}
  members/{uid}        rôle et appartenance (administrés côté serveur)
  products/{productId}
  contacts/{contactId}
  orders/{orderId}
  movements/{movementId}
```

Travail requis avant activation :

1. Ajouter une connexion Firebase Authentication, la déconnexion et la récupération de compte.
2. Définir les rôles et autorisations de l’entreprise ; ne jamais laisser un client s’attribuer un rôle.
3. Implémenter un dépôt distant adapté aux collections, avec gestion des erreurs, chargement et pagination. Le contrat de stockage local est un point de séparation, pas une solution de synchronisation.
4. Réaliser les changements de stock et la création/annulation de commandes dans une transaction Firestore ou une opération serveur vérifiée. Les contrôles Dart locaux ne sécurisent pas une base distante.
5. Imposer les invariants par des règles testées ou une couche serveur : quantités non négatives, prix figé, transitions valides, absence de double annulation, isolation entre entreprises et journal non modifiable.
6. Tester avec les émulateurs les accès non authentifiés, les rôles, les tentatives entre entreprises, les conflits et les opérations répétées.
7. Prévoir une migration explicite des données locales réelles, avec validation et sans les exemples fictifs.

## Émulateurs

Depuis la racine, après installation de Firebase CLI et des prérequis Java :

```sh
firebase emulators:start --project demo-tradeflow --only auth,firestore,storage
```

Le préfixe `demo-` désigne un projet de démonstration. Les émulateurs ne sont pas automatiquement utilisés par l’application actuelle. Les règles initiales refusent toute lecture et écriture de documents et de fichiers : les remplacer uniquement lorsque l’authentification et les tests d’autorisation sont prêts.

La configuration initiale réside dans `firebase.json`, `firebase/firestore.rules` et `firebase/storage.rules`. Aucune commande de déploiement n’est exécutée par le projet.

## Notifications et exploitation

Les alertes actuelles restent dans l’interface locale. Pour les notifications push, prévoir Firebase Cloud Messaging, les permissions Android/iOS, APNs pour iOS, la gestion des jetons et un déclenchement serveur évitant les doublons.

Avant utilisation réelle : compléter les tests de sécurité, les sauvegardes, la supervision, la signature des applications et la gestion des environnements. Utiliser les services Firebase et leurs régions selon les contraintes de l’entreprise.

Références : [installation FlutterFire](https://firebase.google.com/docs/flutter/setup), [transactions Firestore](https://firebase.google.com/docs/firestore/manage-data/transactions), [règles de sécurité](https://firebase.google.com/docs/firestore/security/get-started).
