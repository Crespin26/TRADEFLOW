# Phase 4 — Espace client de démonstration

## Accéder à l’espace

1. Ouvrir **Mon compte de démonstration** dans la barre supérieure.
2. Se connecter ou s’inscrire avec des données fictives. Après une inscription, simuler la vérification de l’adresse e-mail.
3. Les liens **Mes commandes**, **Mes adresses**, **Mes documents**, **Mes demandes** et **Mes notifications** deviennent disponibles.
4. Le profil Client du sélecteur propose également un accueil personnel et les onglets Commandes et Profil. Le sélecteur seul ne connecte toujours pas l’utilisateur.

Les données privées de cet espace restent en mémoire : commandes, profil, adresses, demandes et notifications sont effacés à la déconnexion, au changement d’identité ou au redémarrage. Le panier conserve sa sauvegarde locale distincte. Il ne s’agit pas d’une authentification ou d’une isolation serveur réelle.

## Finalisation de la phase 3

- La confirmation du panier crée une commande confirmée dans l’historique de la session client, avec un instantané des produits, prix, quantités et adresse.
- Le reçu propose **Voir mes commandes**.
- Une adresse de livraison par défaut peut préremplir le formulaire ; les adresses enregistrées sont sélectionnables.
- L’utilisateur peut mémoriser une nouvelle adresse pour la session après une confirmation réussie. Un échec de sauvegarde du panier ne crée ni commande ni nouvelle adresse mémorisée.
- Les identités de connexion sont normalisées (espaces et casse). Une reconnexion à la même identité conserve les données courantes ; une autre identité les efface.
- Un ancien reçu ne s’affiche plus lorsque la session est fermée ou que la commande n’appartient plus à la session actuelle.

## Fonctionnalités de la phase 4

### Accueil personnel et commandes

L’accueil présente les compteurs de commandes, demandes et notifications non lues, les accès aux modules et la dernière commande. L’historique dispose d’une recherche et d’un filtre par statut.

Les commandes confirmées depuis le panier apparaissent immédiatement. Lorsque l’historique est vide, **Charger des commandes fictives** ajoute trois exemples : confirmée, expédiée et livrée. Ce chargement ne modifie ni le panier ni la gestion interne.

Le détail présente les lignes et montants indicatifs, l’adresse historique, les étapes de livraison et, pour les exemples expédiés/livrés, un transporteur et une référence fictifs. Les dates et délais sont des valeurs de démonstration, sans engagement réel.

### Profil et adresses

Le nom et le téléphone sont modifiables. L’e-mail représente l’identité de la session ; il se change en ouvrant une autre session simulée.

Les adresses peuvent être créées, modifiées ou supprimées. Des adresses par défaut distinctes sont sélectionnables pour livraison et facturation. La suppression d’une adresse par défaut utilise la première adresse restante, ou aucune si la liste est vide.

L’adresse de livraison par défaut est réutilisée par le panier. La préférence de facturation prépare le futur parcours financier ; elle ne produit pas une facture réelle et ne réécrit pas les documents existants. Modifier une adresse ne modifie pas les anciennes commandes.

### Documents

- Une confirmation accompagne chaque commande simulée.
- Les exemples incluent un devis spécimen.
- Un bon de livraison spécimen est disponible pour les commandes expédiées/livrées.
- Une facture spécimen est disponible pour une commande livrée.

Chaque aperçu est marqué **SANS VALEUR COMPTABLE**, avec montants des produits et absence de calcul des taxes/transport. Le récapitulatif est consultable et copiable. Les exports PDF et la facturation réelle restent prévus dans les phases suivantes.

### Demandes et justificatif fictif

Les demandes concernent une commande de la session :

- Annulation avant expédition (confirmée ou en préparation).
- Retour après livraison.
- Assistance, quel que soit le statut.

Un motif de 10 à 1 000 caractères est requis. Une demande du même type déjà reçue/en cours pour la commande empêche un doublon. Une demande enregistrée reste au statut **Reçue** ; un exemple illustre le statut **En cours d’examen** et une réponse fictive.

L’option **Joindre un justificatif fictif** associe le spécimen `justificatif-demo.txt`, dont un aperçu explicatif est consultable. Aucun fichier personnel n’est choisi ni téléversé. L’import réel et le stockage des pièces jointes viendront avec les services adaptés.

Déposer une demande n’annule pas automatiquement une commande, ne réintègre pas du stock et n’effectue pas de remboursement. Le traitement par les équipes sera ajouté au parcours interne.

### Notifications

Les commandes et demandes alimentent des notifications locales. Elles peuvent être ouvertes, marquées lues et toutes marquées lues. Le badge du compte indique le nombre non lu. Aucun push ni e-mail n’est envoyé.

## Contrôles et limites

Les vues recherchent les commandes/documents dans l’état de la session actuelle, sans conserver des données d’un autre client dans les pages après déconnexion. Ces vérifications servent à valider les interfaces ; les permissions et l’authentification côté serveur restent à implémenter avec Firebase.

Les stocks, clients et commandes de la gestion locale sont indépendants. Les données de cette phase ne sont pas synchronisées entre appareils ni conservées après fermeture de session. Aucune commande, expédition, facture ou demande réelle n’est transmise.

## Organisation du code

- `lib/domain/shopping_models.dart` : lignes de panier, adresses et reçus.
- `lib/domain/customer_models.dart` : commandes, statuts, adresses, demandes et notifications client.
- `lib/domain/shopping_session.dart` : état et règles de la simulation partagés par les phases 3 et 4.
- `lib/ui/customer/` : accueil, historique/détail, profil/adresses, documents, demandes et notifications.

La prochaine phase concerne la gestion interne : produits complets et publication, inventaires, entrepôts et partenaires. Firebase reste différé conformément à l’approche « interfaces d’abord ».
