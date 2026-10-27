# Phase 3 — Panier et accès client simulé

## Parcours à tester

1. Ouvrir une fiche produit, choisir une quantité puis **Ajouter au panier**.
2. Ouvrir **Voir mon panier** depuis la fiche ou **Panier** dans la navigation publique/client.
3. Modifier les quantités (de 1 à 999), retirer un produit ou continuer les achats.
4. Choisir **Se connecter pour continuer**.
5. Tester la connexion avec une adresse fictive valide et un mot de passe fictif d’au moins huit caractères ; ou choisir **Inscription**, remplir les champs puis **Simuler la vérification**.
6. Renseigner une adresse et un téléphone fictifs, puis ouvrir le récapitulatif.
7. Vérifier les lignes, quantités, prix et adresse ; accepter le caractère fictif de la commande puis confirmer.
8. Consulter le récapitulatif temporaire et revenir au panier, désormais vide.

Le formulaire **Mot de passe oublié** présente une confirmation de demande simulée. Aucun e-mail de récupération ou de vérification n’est envoyé.

## Règles de la démonstration

- La consultation du catalogue et la préparation du panier restent possibles sans connexion.
- Un produit en rupture ne peut pas être ajouté. Les produits « sur commande » restent sélectionnables, avec un avertissement concernant les délais.
- Ajouter plusieurs fois un produit augmente sa quantité au lieu de créer des lignes en double.
- Les totaux sont calculés en XOF entiers, par conditionnement. Transport et taxes ne sont pas calculés ; aucun total payable n’est présenté.
- La connexion est demandée avant de saisir l’adresse et de confirmer ; le panier reste intact si le parcours est interrompu.
- Le profil « Client » du sélecteur de démonstration ne connecte pas automatiquement l’utilisateur. Il n’accorde aucune autorisation backend.
- Les formulaires simulent une connexion : ils ne vérifient aucun identifiant auprès d’un service. N’utiliser que des données fictives.
- Les mots de passe saisis ne sont ni enregistrés dans les préférences ni envoyés à un service.
- La session de démonstration, l’adresse et les récapitulatifs restent en mémoire. Au redémarrage, une nouvelle connexion simulée sera nécessaire.
- La déconnexion conserve le panier mais efface les récapitulatifs temporaires. Le changement d’identité de connexion efface aussi ces récapitulatifs et les données temporaires de l’espace client.
- Une confirmation ne crée aucune commande interne, ne réserve aucun stock, ne prélève aucun paiement et ne déclenche aucune livraison.

## Sauvegarde locale

Le panier public utilise une clé distincte : `tradeflow.publicCart.v1`. Seuls la version du format, les identifiants des produits publics et leurs quantités sont enregistrés. Aucun e-mail, mot de passe ou renseignement de livraison ne figure dans cette sauvegarde.

La sauvegarde est validée avant de publier la modification de l’état. En cas d’échec, le panier affiché reste inchangé. La confirmation ne vide le panier que si cette écriture réussit. Les écritures concurrentes sont rejetées.

Si les données locales sont illisibles, elles ne sont pas écrasées silencieusement. Le panier propose une nouvelle tentative ou une réinitialisation explicitement confirmée. Effacer les données de l’application ou du navigateur efface le panier.

## Accès aux écrans

- L’icône **Mon compte de démonstration**, en haut de l’application, permet de se connecter, vérifier une adresse fictive ou se déconnecter.
- Le profil Client propose désormais Accueil, Catalogue, Panier, Commandes et Profil.
- La phase 4 ajoute un espace client temporaire : historique et suivi des commandes de la session, profil, adresses, documents spécimens, demandes et notifications. La persistance distante reste différée. Voir [CUSTOMER_SPACE_DEMO.md](CUSTOMER_SPACE_DEMO.md).

## Fichiers

- `lib/application/shopping_session.dart` : panier, session simulée et reçus temporaires.
- `lib/data/public_cart_repository.dart` : sauvegarde locale dédiée.
- `lib/ui/shopping/shopping_scope.dart` : partage de la session entre les routes.
- `lib/ui/shopping/cart_page.dart` : lignes du panier et entrée dans le parcours.
- `lib/ui/shopping/auth_page.dart` : connexion, inscription, vérification et récupération simulées.
- `lib/ui/shopping/checkout_page.dart` : livraison, récapitulatif et confirmation.
- `lib/ui/shopping/account_page.dart` : accès au compte simulé et déconnexion.

Firebase Authentication, la vérification réelle des prix et des stocks côté serveur, les règles d’accès et les paiements restent différés. Ce module n’est pas un système d’authentification ou de commande de production.
