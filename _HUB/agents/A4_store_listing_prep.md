# Agent A4 — Store Listing Prep (App Store Connect)

## Objectif
Produire TOUS les textes/réponses prêts à coller dans App Store Connect. **Pas de code — uniquement des livrables documentés** dans `_HUB/store/`.

## Livrables (à écrire dans `_HUB/store/`)
1. **`subscription_metadata.md`** — pour l'abonnement auto-renouvelable :
   - Nom d'affichage (EN/FR), durée, description marketing (EN/FR), groupe d'abonnement.
   - Reco de palier de prix (à valider par le fondateur).
   - Texte du screenshot de review de l'abonnement (ce que voit le reviewer).
2. **`app_privacy_labels.md`** — réponses au questionnaire App Privacy :
   - Types de données (email, identifiants, données d'usage produit : tâches/habitudes/streaks, contacts amis), liées/non liées à l'identité, finalité, tiers (Supabase, RevenueCat, Apple/Google Sign-In, email).
   - Doit correspondre EXACTEMENT à la privacy policy (coord. A3).
3. **`review_notes.md`** — notes de revue Apple : repartir de `docs/app_store_submission_packet.md`, ajouter compte de démo, explication "Screen Time/Family Controls = on-device only", instructions de test du blocage.
4. **`listing_copy.md`** — nom, sous-titre, description (EN/FR), mots-clés ASO, texte promotionnel, URLs (support / marketing / privacy / account deletion).
5. **`screenshots_checklist.md`** — tailles requises iPhone (+ iPad si supporté) et écrans à capturer.

## Points de vigilance
- **Nom commercial** : trancher CEO OS vs WakeApp (incohérence repo) AVANT de rédiger la fiche.
- Ne rien sur-promettre (pas d'« IA » : l'app n'en a pas — cohérent avec le positionnement "centre de contrôle personnalisable").
- ASO minimal mais correct : viser les requêtes "focus / discipline / screen time / blocage".

## Critères d'acceptation
- Le fondateur peut copier-coller chaque livrable dans ASC sans réécriture.
- Cohérence totale entre App Privacy labels (A4) et privacy policy (A3).

## Entrée requise (fondateur)
- Décision nom commercial.
- Palier de prix souhaité (ex. mensuel / annuel).
- App supporte-t-elle l'iPad ? (détermine les screenshots).
