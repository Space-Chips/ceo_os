# Agent A3 — Legal Docs (pages publiques prêtes à déployer)

## Objectif
Finaliser Privacy Policy + Terms en documents publiables (URLs publiques exigées par Apple/Google), cohérents avec le comportement réel de l'app. **Pas de code.**

## Fichiers
- `docs/site_privacy_policy.md`, `docs/site_account_deletion.md` (versions "site")
- `docs/privacy_policy_draft.md`, `docs/terms_of_service_draft.md` (sources)
- `docs/legal_pages_patches.md` (notes de patch)

## À faire
1. **Remplir TOUS les placeholders `<INSERT ...>`** : entité légale, email privacy, adresse, URL du site. (Valeurs fournies par le fondateur — voir « Entrée requise ».)
2. Ajouter une section **« Connexions amis / Leaderboard »** : préciser que l'ajout d'un ami par email rend visibles à cette personne le nom, le rang, les streaks et les scores.
3. Vérifier la **cohérence avec l'app réelle** : données collectées (email, profil, stats/streaks, contacts amis), tiers (Supabase, RevenueCat, Apple/Google Sign-In, service email), suppression effective sous 7 j.
4. Mentionner explicitement le **droit à l'effacement (RGPD art.17)** + la voie in-app + un email de contact valide (plus de placeholder).
5. Produire **2 pages finales prêtes à publier** (markdown propre, et/ou HTML simple) que le fondateur colle sur son site.

## Ne PAS faire
- Inventer des informations légales (entité, adresse) → utiliser uniquement les valeurs fournies.

## Critères d'acceptation
- Zéro placeholder restant (hors valeurs d'identité explicitement listées comme fournies).
- Section "amis" présente ; cohérence app↔policy validée ; email de contact réel.
- Pages prêtes à coller à `site/privacy` et `site/terms`.

## Entrée requise (fondateur)
- Nom de l'entité légale (ou nom propre si entreprise individuelle)
- Email privacy/contact
- Adresse (pays au minimum)
- URL du site + chemins prévus (ex. `monsite.com/privacy`, `/terms`)
