# Recette des phases 1 à 4 — 25 octobre 2026

## Corrections de cette recette

- Remplacement des illustrations par huit photographies de produits et une photo d’entrepôt, embarquées localement.
- Suppression des trois pseudo-vues d’une même illustration : une vraie photo consultable et agrandissable est présentée sur chaque fiche.
- Ajout des crédits, des sources et d’un état de repli explicite en cas de photo absente.
- Ajout de miniatures dans le panier et les cartes de commande.
- Passage automatique à l’espace client après une connexion simulée vérifiée, tant qu’aucun profil n’a été choisi manuellement dans le simulateur.
- Navigation par destination logique : le panier reste monté pendant la connexion, et une déconnexion depuis Profil revient à une destination publique valide.
- Conservation du choix explicite d’un profil de démonstration, sans lui attribuer une authentification.

## Couverture des parcours

| Phase | Contrôles automatisés |
|---|---|
| 1 — Fondations | Six profils, navigation mobile/ordinateur, écrans étroits, texte agrandi, boutons et confirmations, validation des champs et états d’écran. |
| 2 — Catalogue | Recherche sans accents, références, catégories, filtres combinés, tri, absence de résultats, retour depuis une fiche, agrandissement et décodage des photos embarquées sans réseau. |
| 3 — Panier et connexion | Quantités et totaux, produits indisponibles, sauvegarde et restauration, erreur de stockage, écritures concurrentes, connexion/inscription/vérification/récupération fictives, panier conservé et confirmation. |
| 4 — Client | Historique issu du panier, suivi et exemples, demandes éligibles et doublons, justificatif fictif, documents spécimens, profil, adresses par défaut et instantanés historiques, notifications, fermeture et changement de session. |

Les tests d’interface couvrent notamment 320, 390 et 1 440 pixels. Les contrôles utilisent le SDK Flutter permanent de la machine ; les dépendances ne doivent plus être régénérées avec des chemins temporaires.

## Résultat automatisé

- 56 tests réussis.
- Analyse Flutter sans anomalie.
- Format Dart conforme et diff Git sans erreur d’espacement.
- Les neuf photographies sont présentes dans les ressources Flutter et décodables sans réseau.
- Compilation Web de production réussie. Contrôle visuel effectué dans Chromium : accueil et catalogue sur ordinateur, catalogue et agrandissement photo sur mobile. Aucune erreur JavaScript/HTTP observée ; aucune requête de photo vers Pexels ou Unsplash à l’exécution.

## Parcours manuel de validation

1. Ouvrir l’accueil puis le catalogue ; vérifier photos, recherche et filtres.
2. Ouvrir une fiche, agrandir sa photo puis ajouter une quantité au panier.
3. Se connecter avec une identité fictive ; vérifier que le panier et ses quantités sont conservés.
4. Compléter une adresse fictive, la mémoriser pour la session et confirmer la commande simulée.
5. Ouvrir Mes commandes, vérifier l’adresse historique et le document de confirmation.
6. Depuis un historique vide d’une autre session fictive, charger les exemples et parcourir une commande expédiée/livrée.
7. Tester une demande de retour avec justificatif fictif, consulter son état et un document spécimen.
8. Modifier une adresse, marquer les notifications lues, puis se déconnecter ; vérifier l’absence d’anciennes données client dans les pages privées.

## Limites conservées

L’authentification, les commandes publiques et les documents restent simulés. Les données privées client sont temporaires et disparaissent à la déconnexion ou au redémarrage. Aucun stock interne, paiement, e-mail ou service de livraison n’est déclenché. Les documents PDF réels, le téléversement des justificatifs, Firebase et les permissions serveur restent prévus dans les phases suivantes.

Les essais sur appareils physiques Android et iOS restent à réaliser. La réussite de cette recette ne constitue pas une validation de production.
