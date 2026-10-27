# Documents commerciaux et PDF

Accès : **Opérations commerciales → Documents commerciaux**, ou **Comptable → Factures → Ouvrir les documents**. Cette dernière entrée présente les proformas et bons disponibles ; la facturation fiscale et les paiements restent à développer.

## Bibliothèque

Les documents sont construits à partir des données réellement enregistrées : devis, confirmations de commande, factures pro forma, bons de commande fournisseurs, bons de livraison, de réception et de retour client/fournisseur. Chaque réception ou livraison partielle possède son propre bon, limité à sa quantité effective. Les bons logistiques ne reprennent pas les prix d’achat ou de vente.

La recherche porte sur référence, partenaire et produit. Le filtre sélectionne le type. Une commande annulée ne produit plus de nouvelle proforma, mais ses versions déjà archivées restent consultables.

## Entreprise et export

Renseigner l’**Entreprise émettrice** : nom obligatoire, adresse, pays, e-mail, téléphone et registre facultatifs. Les coordonnées appartiennent au stockage local ; elles ne sont pas publiées dans le catalogue. Les modifications sont révisées pour empêcher l’écrasement d’un formulaire obsolète.

**Aperçu et PDF** ouvre une représentation lisible du contenu capturé à cet instant. **Exporter / partager le PDF** génère un fichier A4 puis ouvre le téléchargement sur Web ou le service de partage natif. Aucune application destinataire n’est choisie et aucun message n’est envoyé automatiquement.

Les PDF présentent l’émetteur, le partenaire, la référence, le statut, la date du document source, la ligne produit, la quantité, l’unité, les montants lorsqu’ils sont pertinents, la destination et les conditions ou motifs. Les notes internes des fiches partenaires sont exclues. Transport et taxes ne sont pas calculés. Une proforma est explicitement identifiée et ne constate aucun paiement.

Les bibliothèques [pdf](https://pub.dev/packages/pdf) et [printing](https://pub.dev/packages/printing) assurent génération et export. Les polices DejaVu Sans normale/grasse sont embarquées pour les accents français : aucun téléchargement de police à l’export. Leur licence est conservée dans `assets/fonts/LICENSE-DejaVu.txt`.

## Versions et archives

La référence comprend type, identifiant source, révision commerciale et révision de l’émetteur. Les noms de fichiers sont normalisés et se terminent par `.pdf`.

Après génération réussie du PDF, une copie structurée des données est sauvegardée avant ouverture du partage. Elle permet de régénérer la version historique même après modification de la commande ou de l’entreprise. Réexporter la même version ne duplique pas l’archive. Annuler le partage laisse cette archive locale : un document a été généré, sans prétendre qu’il a été envoyé.

La bibliothèque réunit les versions courantes et les versions archivées ; une version déjà archivée n’est affichée qu’une fois. L’aperçu ouvert reste figé, même si d’autres données changent. Les PDF binaires ne sont pas stockés dans la sauvegarde JSON : les données nécessaires à leur régénération le sont, avec les limites locales existantes. Il n’y a pas encore de synchronisation ou d’archivage externe.

Les anciennes sauvegardes restent lisibles sans profil d’entreprise ni archives. Le chargement d’exemples dans un espace vide conserve l’entreprise déjà renseignée.

## Vérification

Tests : projections depuis les vraies opérations, exclusion des notes privées, versions historiques, réexport sans doublon, sauvegarde/relecture, échecs d’archivage, émetteur obligatoire, fichiers PDF valides et extraction des accents français avec Poppler lorsqu’il est installé. Les parcours aperçu/export/archivage sont testés à 320 et 1 440 pixels avec un service de partage injecté.

L’impression et le partage natifs doivent être essayés sur les appareils Android/iOS ciblés avant distribution. Les tests d’interface utilisent un service injecté ; ils ne valident pas les applications de partage installées sur l’appareil.
