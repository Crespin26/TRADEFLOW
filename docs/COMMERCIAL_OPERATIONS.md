# Phase 6 — Opérations commerciales locales

La phase 6 couvre les devis, ventes internes, achats fournisseurs, réceptions et livraisons partielles, retours et leur journal. Les documents et mouvements sont sauvegardés sur cet appareil, sans Firebase. Le catalogue suit les disponibilités locales ; les commandes publiques simulées restent indépendantes.

**Périmètre : une référence produit par document, quantités entières et XOF.** Les factures, avoirs, paiements, taxes, frais de transport, devises et documents internationaux relèvent de la phase 7. Les documents à plusieurs lignes et les entrepôts multiples restent des évolutions distinctes.

## Accès

- Administrateur → Gestion → Ouvrir la gestion locale → **Opérations commerciales**, ou Commandes → **Devis, achats et livraisons**.
- Commercial → **Devis** ou **Commandes** → Ouvrir les opérations.
- Magasinier → **Réceptions** ou **Expéditions** → Ouvrir les opérations.
- Fiche client : Nouveau devis, Nouvelle commande, devis liés et suivi des commandes.
- Fiche fournisseur : Nouvel achat et achats liés, y compris réceptions et retours.

Les onglets sont Ventes, Devis, Achats et Journal. La recherche porte sur la référence du document, le partenaire, le produit et la destination ; le journal recherche également les motifs. Chaque liste propose ses filtres de statut ou de type d’opération. Les profils de démonstration ne sont pas des permissions serveur.

## Devis

1. **Nouveau devis** : choisir un client actif et un produit actif, saisir quantité, prix proposé, destination, validité et conditions.
2. Enregistrer le brouillon. Il peut être modifié tant qu’il reste brouillon.
3. **Marquer envoyé** enregistre le fait que le devis a été communiqué au client ; cette action n’envoie aucun e-mail.
4. **Marquer accepté** ou **Marquer refusé** selon le retour du client.
5. Un devis accepté et encore valide peut être **converti en commande**, sous réserve du stock disponible.

Les dates de validité sont inclusives, selon le calendrier de l’appareil. Un devis expiré ne peut pas être envoyé, accepté ou converti. Un brouillon peut être modifié pour corriger sa validité ; un devis déjà envoyé est figé. Les devis brouillons, envoyés ou acceptés peuvent être annulés ; les états refusé, annulé et converti sont terminaux.

Le devis ne réserve et ne déduit aucun stock. La conversion crée une commande confirmée, relie les deux documents et déduit la quantité en **une seule sauvegarde**. Elle conserve les noms, l’unité et le prix convenus, même si la fiche produit ou partenaire a changé. Reconvertir un devis déjà converti renvoie sa commande existante, sans nouvelle commande ni décompte. Annuler cette commande ne rouvre pas le devis.

## Ventes, livraisons et retours clients

Une vente directe utilise le prix actuel du produit et un client actif. Sa confirmation déduit immédiatement le stock disponible, comme dans les phases précédentes. Ce stock représente le disponible commercial ; la séparation entre stock physique et réservations n’est pas encore modélisée.

- **Confirmée → Expédier** : le stock reste inchangé, car il a déjà été déduit.
- **Expédiée → Enregistrer une livraison** : saisir la quantité réellement livrée et une référence ou un motif. Plusieurs livraisons sont possibles jusqu’à la quantité commandée.
- La commande reste expédiée pendant une livraison partielle. Elle devient livrée lorsque la totalité de la quantité commandée a été livrée.
- **Retour client** : saisir une quantité effectivement livrée et non encore retournée. Elle est réintégrée au stock disponible si la case correspondante est cochée ; sinon elle reste hors disponible. Le motif et l’historique sont toujours conservés.
- Une commande confirmée peut être annulée : le stock est restitué une seule fois. Après expédition, utiliser les retours sur les quantités livrées ; l’annulation n’est plus autorisée.

L’ancien bouton « Marquer livrée » enregistre désormais le solde restant à livrer et son opération historique. Les livraisons ne créent pas de deuxième sortie de stock. Les retours ne rouvrent pas automatiquement une quantité à livrer et ne constituent ni remboursement ni avoir. Une nouvelle livraison de remplacement nécessite une nouvelle commande.

La fiche affiche livré/commandé et retourné. La valeur livrée du tableau de bord additionne les quantités livrées moins les retours clients, au prix de leur commande. Le total contractuel du document reste inchangé.

## Achats et réceptions

1. **Nouvel achat** : fournisseur actif, produit actif, quantité, prix d’achat convenu, lieu de réception et notes.
2. Enregistrer le brouillon puis **Confirmer l’achat** pour le marquer commandé. Aucune quantité n’est ajoutée au stock à ces étapes.
3. **Réceptionner** : saisir la quantité réellement reçue et le motif ou la référence du bon.
4. Répéter pour les réceptions suivantes, sans dépasser le solde de l’achat.

L’achat reste commandé pendant une réception partielle ; il devient reçu à réception complète. Chaque réception augmente le stock et enregistre l’opération et le mouvement avant/après dans une seule sauvegarde. Elle n’écrase pas le prix d’achat de la fiche produit et ne calcule pas de coût moyen pondéré.

Un achat brouillon ou commandé peut être annulé si rien n’a été reçu. Une réception, même partielle, bloque l’annulation. Il n’y a pas d’arrêt automatique du reliquat d’un achat partiellement reçu.

## Retours fournisseurs

Un retour est limité à la quantité reçue non encore retournée **et au stock actuellement disponible**. Il diminue le stock, augmente le compteur retourné et ajoute un événement et un mouvement lié à l’achat. Les retours ne rouvrent pas le solde à recevoir : les quantités reçues restent des cumuls bruts et les retours sont suivis séparément. Ils ne génèrent pas d’avoir ou de remboursement.

## Contrôles et intégrité

- Quantités : 1 à 1 000 000 000 ; prix unitaires : 0 à 1 000 000 000 XOF. Les totaux supérieurs à la plage d’entiers exactement représentables sur Web sont refusés.
- Stock final toujours compris entre 0 et 1 000 000 000 ; réception ou retour client au-delà de la limite refusé.
- Référence ou motif obligatoire pour chaque réception, livraison et retour ; maximum de 500 caractères. Destination : 160 caractères ; conditions : 2 000.
- Chaque document possède une révision. Un formulaire de réception, livraison, retour ou modification devenu obsolète est refusé, y compris après une première validation identique.
- Les unités convenues sont conservées. Une unité de produit modifiée bloque les opérations qui changeraient son stock sans conversion explicite ; aucune conversion d’unité automatique n’est inventée.
- Les formulaires vérifient l’unité affichée au moment de la saisie. Une vente directe refuse également un prix modifié depuis l’ouverture du formulaire.
- Les partenaires archivés sont exclus des nouveaux devis, achats et ventes. Les opérations d’un achat déjà commandé restent possibles avec un fournisseur archivé.
- Un produit doit être actif pour créer un document, convertir un devis ou recevoir un achat. Les retours sur un ancien document peuvent concerner un produit archivé, en conservant son état archivé et sous réserve de l’unité et du stock.
- Le type d’un partenaire lié à une commande, un devis ou un achat ne peut plus être changé.
- Un échec de sauvegarde ne modifie ni les documents, ni le stock, ni les historiques. Ces garanties portent sur le magasin local dans cette instance de l’application ; les transactions entre appareils attendent Firebase.

## Journal et compatibilité

Réceptions, livraisons et retours sont ajoutés à un journal consultable globalement et depuis leur document. Chaque événement conserve produit, partenaire, quantité, unité, date, motif et référence du document. Les opérations de stock créent également un mouvement avant/après. Les événements validés ne sont ni supprimés ni modifiés.

Les sauvegardes versions 1 et 2 restent lisibles. Les listes `quotes`, `purchases` et `commercialEvents` sont facultatives dans les anciennes données. Une ancienne commande livrée est considérée entièrement livrée, avec zéro retour. Ses événements historiques et son ancienne unité ne sont pas inventés. La clé de stockage et le format version 2 sont conservés. Les photos, partenaires et inventaires existants sont préservés.

## Vérifications

**121 tests réussis**, analyse Flutter sans anomalie, format Dart conforme et compilation Web de production réussie avec le SDK permanent.

Tests métier : prix et noms convenus, conversion unique, transitions et validité des devis, modifications obsolètes, réceptions et livraisons partielles, retours bornés, stock insuffisant ou maximal, changements d’unité et de prix, archives, échecs de sauvegarde, anciennes données et redémarrage du magasin local.

Tests d’interface à 320 et 1 440 pixels : création d’un devis et d’un achat, acceptation/conversion, expédition/livraison partielle, réception partielle et retours. Les accès Commercial/Magasinier et l’édition d’un brouillon dont le produit a été archivé sont également contrôlés.

Le [module Livraisons et retours](DELIVERIES_AND_RETURNS.md) ajoute le suivi transporteur, les retards et le choix de ne pas réintégrer les marchandises non revendables.
