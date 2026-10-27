# Pilotage de l’activité

Accès : **Activité → Ouvrir le pilotage** pour les profils Administrateur, Commercial, Magasinier et Comptable ; également **Gestion locale → Pilotage** pour la vue administrateur.

Les tableaux utilisent exclusivement les données du magasin local. Il n’y a ni valeurs aléatoires ni données de paiement inventées. Le bouton Actualiser recalcule la situation, y compris les changements de date ; les changements enregistrés dans le magasin actualisent aussi l’écran.

## Périodes et périmètres

Filtres : 7, 30, 90 jours ou Toutes dates. Une période commence à minuit du premier jour inclus et finit à l’heure du calcul, selon le calendrier de l’appareil. Les enregistrements datés dans le futur sont exclus des flux de période.

Chaque carte distingue :

- **Période** : opérations ou documents correspondant aux dates choisies.
- **Situation actuelle** : commandes restant à livrer, retards, achats restant à recevoir et alertes de stock actuels. Ces soldes ne sont pas artificiellement limités aux seuls documents créés dans la période.

Les ruptures sont les références actives à quantité nulle. Les alertes de seuil incluent les quantités inférieures ou égales au seuil : une même référence peut compter dans les deux indicateurs. Les produits archivés sont exclus des alertes. Les quantités d’unités différentes ne sont jamais additionnées.

## Montants

- **Ventes confirmées** : quantité × prix convenu des commandes créées dans la période, hors annulations.
- **Achats engagés** : quantité × prix convenu des achats commandés ou reçus créés dans la période ; les brouillons et annulations sont exclus.
- **Valeur livrée nette** : livraisons moins retours clients sur la période, au prix de leur commande.
- **Valeur reçue nette** : réceptions moins retours fournisseurs sur la période, au prix de leur achat.

Pour une période bornée, livraisons et retours suivent leur propre date d’opération, même si la commande ou l’achat est plus ancien. Un retour peut donc produire un montant net négatif sur une période sans livraison. Les retours non revendables diminuent aussi la valeur des marchandises livrées, sans augmenter le stock disponible.

Sur Toutes dates, les compteurs cumulés des documents permettent d’inclure les livraisons historiques sans date d’opération. Sur les autres périodes, ces anciennes livraisons ne reçoivent pas de date fictive ; un message explique leur exclusion.

Les montants utilisent `BigInt` pour conserver des sommes exactes, y compris sur Web au-delà de la précision des nombres JavaScript ordinaires. Ce sont des valeurs commerciales de marchandises et commandes, pas des encaissements, factures réglées, marges ou bénéfices. Taxes, transport, devises et comptabilité restent à développer.

## Vues par profil

- **Magasinier** : commandes et achats à traiter, retards, ruptures, seuils et retours ; activité logistique par nombre d’événements. Les cartes et rapports ne présentent pas de montants financiers.
- **Commercial** : ventes, livraisons, devis, conversion, retards et retours.
- **Comptable** : valeurs commerciales, achats, réceptions, retours et versions PDF archivées ; aucun solde d’impayé n’est inventé.
- **Administrateur** : vue d’ensemble des indicateurs disponibles.

Ces vues organisent les interfaces des profils de démonstration ; elles ne remplacent pas les permissions Firebase.

Le taux de conversion concerne l’état actuel des devis créés dans la période, brouillons inclus dans le dénominateur. Les produits les plus commandés sont classés par valeur des commandes créées, hors annulations, avec regroupement par identifiant produit stable. Le graphique présente les sept derniers jours, en conservant le filtre de période actif.

## Rapports et actions

Le bouton **Rapport CSV** ouvre un texte sélectionnable, copiable dans le presse-papiers. Il comprend indicateur, valeur brute exacte, unité, périmètre, début/fin et entreprise. Les soldes actuels n’ont pas de date de début de période. Les textes sont échappés et les débuts pouvant être interprétés comme des formules de tableur sont neutralisés.

Le rapport respecte la vue du profil. Il ne télécharge pas de fichier automatiquement et ne transmet aucune donnée à un service. Les raccourcis ouvrent les opérations, livraisons/retours, stocks et documents pertinents.

## Vérifications et suite

Tests des bornes de période, dates futures, annulations, anciens documents, dates propres aux retours/réceptions, soldes actuels, unités, montants supérieurs à la précision JavaScript, vue logistique sans montants, absence de données et affichage à 320 et 1 440 pixels.

La gestion des collaborateurs, les permissions réelles, les autres paramètres administratifs, les finances et la synchronisation entre appareils restent distincts du pilotage local livré ici.
