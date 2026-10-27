# Clients et fournisseurs — gestion locale

Le module gère les **fiches partenaires internes**. Une fiche client n’est pas un compte utilisateur et n’apparaît pas automatiquement dans l’espace client simulé. Les données restent sur cet appareil, sans Firebase ni synchronisation entre utilisateurs.

## Accès

- **Administrateur → Gestion → Ouvrir la gestion locale → Contacts** : clients et fournisseurs.
- **Commercial → Clients → Ouvrir les partenaires** : annuaire ouvert sur le filtre Clients, avec possibilité d’afficher les fournisseurs.

Les profils restent des profils de démonstration. Ils ne constituent pas des autorisations de production.

## Fiches et recherche

Les fiches comportent :

- Type : client ou fournisseur ; nom / raison sociale et pays obligatoires.
- E-mail, téléphone et personne à contacter.
- Adresse, ville, code postal, identifiant fiscal / registre et site web.
- Notes internes et état actif ou archivé.

Créer avec **Nouveau partenaire**, puis ouvrir la fiche pour consulter les coordonnées, modifier, archiver ou restaurer. La liste propose recherche sans distinction d’accents ou de casse, filtres par type, statut et pays, et tri alphabétique.

Les champs facultatifs peuvent rester vides. Les e-mails sont normalisés en minuscules ; leur format est vérifié sans envoyer de message. Un site web doit commencer par `http://` ou `https://` et comporter un hôte. Le téléphone est conservé comme texte, avec une limite de 40 caractères, sans validation internationale par pays. Les autres champs sont limités à 160 caractères et les notes à 3 000.

À la création et à la modification, un même type de partenaire ne peut pas avoir le même nom et le même pays qu’une autre fiche, après suppression des accents, passage en minuscules et retrait des espaces de début/fin. Les archives participent à ce contrôle pour favoriser leur restauration. Un nom identique est autorisé pour un autre pays ou pour l’autre type. Une entreprise à la fois cliente et fournisseur utilise donc deux fiches distinctes. L’e-mail n’est pas un identifiant unique.

## Historique client et commandes

La fiche client présente les commandes internes liées à son identifiant stable : produit, quantité, prix enregistré, total, statut, date et destination. Les commandes annulées restent consultables. Une modification du nom du client ne réécrit pas le nom enregistré dans les anciennes commandes.

Le bouton **Nouvelle commande** présélectionne le client de la fiche. Les contraintes de stock existantes restent appliquées. Il ne s’agit pas d’une commande publique simulée.

Un partenaire lié à une commande, un devis ou un achat conserve son type. Sans document commercial lié, une fiche peut changer de type. La fiche fournisseur contient ses informations professionnelles, notes et achats réels saisis localement. La [phase 6](COMMERCIAL_OPERATIONS.md) permet désormais achats, réceptions partielles, retours et journal fournisseur. Les devis sont également accessibles depuis la fiche client.

## Archivage, restauration et sauvegarde

L’archivage conserve la fiche, son identifiant et les commandes existantes. Un client archivé est exclu de la sélection des nouvelles commandes ; le magasin métier refuse également une création pour ce client. Ses commandes existantes peuvent continuer leur traitement, y compris une annulation autorisée.

Une fiche archivée est consultable mais doit être restaurée avant modification. La restauration réactive la même fiche. Il n’y a pas de suppression définitive.

Une révision de fiche augmente après modification, archivage ou restauration. Enregistrer depuis un formulaire devenu obsolète est refusé, même si une fiche a été archivée puis restaurée pendant son ouverture. Fermer le formulaire et ouvrir la version actuelle avant de recommencer.

Les nouveaux champs sont facultatifs dans les sauvegardes locales versions 1 et 2 ; les anciennes fiches deviennent actives avec des champs supplémentaires vides et une révision nulle. La clé et la version de sauvegarde restent inchangées. Un échec d’écriture conserve l’état précédent et laisse le formulaire ouvert avec un message.

Les coordonnées et notes restent dans la gestion interne ; elles ne sont pas ajoutées au catalogue public. Les contrôles d’accès réels, la sauvegarde externe et la sécurité multi-utilisateur restent à implémenter avec Firebase.

## Commentaires métier

Le code du stock et des inventaires explique désormais les règles de sauvegarde atomique, le contrôle des quantités au début du comptage, le refus des données obsolètes et la conservation des comptages sans écart. Les fiches partenaires documentent également leur distinction avec les comptes utilisateurs, la compatibilité des anciennes données et les liens immuables des commandes.

## Validation

Suite complète : **95 tests réussis** ; analyse Flutter sans anomalie et compilation Web de production réussie.

Les tests couvrent la normalisation, les anciennes fiches, les doublons actifs/archivés, les formats et limites, l’historique après renommage, le blocage des clients archivés, la restauration, les révisions obsolètes et les échecs de sauvegarde. La persistance des champs et archives est vérifiée après création d’un nouveau magasin local.

Les parcours d’interface couvrent création, modification, archivage, restauration, recherche sans accents et filtres à 320 et 1 440 pixels, l’historique client, la présélection pour une commande et l’accès Commercial.
