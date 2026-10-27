# Livraisons et retours

Le module est accessible depuis **Magasinier → Expéditions → Ouvrir les opérations**, ou depuis **Opérations commerciales → Livraisons et retours**. Les données restent locales.

- **À livrer** regroupe les commandes non annulées dont une quantité reste à livrer. Recherche par partenaire, produit, référence ou suivi ; filtres Tous, En retard et Sans suivi.
- **Transporteur et suivi** permet de renseigner transporteur, référence de suivi, date prévue et consignes. Une date prévue passée constitue un retard tant qu’une quantité reste à livrer. Le jour prévu lui-même n’est pas en retard.
- La référence est conservée localement ; aucun service de transporteur n’est interrogé automatiquement.
- La planification ne modifie ni le stock ni les compteurs de livraison. Sa révision empêche un formulaire obsolète d’écraser un suivi plus récent. Les commandes terminées ou annulées conservent leur suivi en lecture seule.
- Chaque livraison mémorise le transporteur et la référence connus lors de son enregistrement. Modifier ensuite le suivi ne réécrit pas les livraisons passées.

L’onglet **Retours** présente les quantités livrées ou reçues qui peuvent encore être retournées. Un retour client distingue les marchandises revendables de celles qui ne doivent pas réintégrer le disponible :

- Case **Réintégrer au stock disponible** cochée : retour ajouté au stock et mouvement avant/après.
- Case décochée : retour et motif historisés, compteur retourné augmenté, mais stock disponible inchangé et aucun mouvement de quantité nulle.
- Ce choix ne peut pas être appliqué deux fois aux mêmes quantités. Il n’existe pas encore de stock de quarantaine ni de procédure de remise en vente des retours exclus du disponible.

L’historique regroupe livraisons et retours, avec recherche, filtres sur 7/30 jours ou toutes les dates et indication de la réintégration. Les anciens retours sont considérés réintégrés, conformément au comportement des versions précédentes. Les anciens événements sans transporteur restent vides ; aucune donnée n’est inventée.

Les règles de réception, livraison partielle, unités, quantités maximales et sauvegardes atomiques restent celles de la [phase 6](COMMERCIAL_OPERATIONS.md). Les retours ne constituent pas des remboursements ou des avoirs.

Tests : suivi révisé, retards, transporteur historique, commandes closes, retours revendables/non revendables, refus des doubles retours, échecs d’écriture, compatibilité des données et parcours à 320 et 1 440 pixels.
