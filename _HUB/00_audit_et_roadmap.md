# CEO OS — Hub de pilotage

Objectif nord : **1 000 000 de téléchargements.**
Contexte : fondateur solo, budget ~0€, app en review / TestFlight.
Positionnement : **centre de contrôle personnel personnalisable** — 2 piliers qui convergent : sentiment de personnalisation + simplicité absolue.

---

## Deux objectifs parallèles

### 🚀 OBJECTIF 1 — SHIP (publier une app solide, safe, conforme)
Finir et réussir la publication : conformité Apple + légalité + robustesse.

### 📣 OBJECTIF 2 — MARKETING (usine à carrousels automatisée)
4 comptes de niche (productivité/organisation) × 2 carrousels/jour, dernière slide → app,
+ 1 compte officiel storytelling avec intervention perso du fondateur.
⚠️ Point de vigilance : l'auto-publication multi-comptes touche aux CGU des plateformes (risque de ban) — à cadrer.

---

## AUDIT — 2 piliers (2026-06-21)

### Pilier "Simplicité d'activation" — CASSÉ
- 9-12 écrans, 27-35 taps, 3-5 min avant le 1er moment de valeur.
- Inscription FORCÉE avant toute valeur (app_router.dart:301) — pas de mode invité/démo.
- Permission Screen Time au step 10/10 du control-center-setup — trop tard.
- Pas de seed de valeur sur /home (écrans vides tant que l'user n'a rien créé).

### Pilier "Personnalisation = identité" — SOUS-EXPLOITÉ
- Fort : rang 8 niveaux, visuel, gratuit, screenshotable (rank_screen.dart, rank_art.dart).
- Control center = 4 slots parmi 9 options + 5 widgets dashboard + 5 thèmes → réel mais **one-time**.
- Manque : réorg persistante post-setup, labels perso, **partage/snapshot** de config ou de rang.

---

## QUICK-WINS PRIORISÉS (dev solo)

| # | Action | Pilier | Effort | Impact | Quand |
|---|--------|--------|--------|--------|-------|
| 1 | Bouton "Skip" sur l'onboarding | Simplicité | Faible | Haut | Pré-launch |
| 2 | Pré-remplir /home avec 1 tâche + 1 habit d'exemple | Simplicité | Moyen | Moyen | Pré-launch |
| 3 | Indicateur de progression sur setup-gate | Simplicité | Faible | Moyen | Pré-launch |
| 4 | Déplacer la demande Screen Time tôt + contexte | Simplicité | Moyen | Haut | Pré-launch |
| 5 | **Carte de rang partageable (PNG "Share my rank")** | Identité/Viral | Moyen | **Haut** | Pré/post |
| 6 | Réorg drag persistante du control center après setup | Identité | Moyen | Moyen | Post-launch |
| 7 | Snapshot/share de la config control center | Identité/Viral | Moyen | Moyen | Post-launch |
| 8 | Mode démo / essai sans compte | Simplicité | Élevé | Critique | Post-launch (risqué pré-review) |

---

## AUDIT SHIP — Conformité & légal (2026-06-21, vérifié sur code)

### ✅ Déjà safe (vérifié, PAS des bloquants)
- **Données Screen Time NON exfiltrées** : sur iOS `_useLocalFamilyControlsStorage` toujours actif → block lists locales, leaderboard/stats cloud désactivés (apple_review_compliance.dart:8-21, focus_repository.dart:32-99). Le motif de rejet n°1 d'Apple est géré.
- **Suppression de compte** fonctionnelle + accessible (confirmation "Type DELETE", edge function delete-account — settings_repository.dart:96).
- **Terms/Privacy accessibles** dans le profil (legal_document_sheet).
- **Aucun secret committé** (key.properties non tracké). RLS OK (C0-1/2/3 résolus).

### 🔴 BLOQUANTS DURS (à corriger avant resubmission)
1. **Paywall non conforme Apple 3.1.1/3.1.2** [CONFIRMÉ] — dans `premium_paywall.dart` : PAS de bouton "Restore Purchases", liens Terms/Privacy définis mais JAMAIS rendus (`_openTerms`/`_openPrivacy` ligne 240-246 jamais appelés), PAS de texte d'auto-renouvellement. → Rejet quasi-certain. Fix ~1-2h.
2. **Age gate manquant** [CONFIRMÉ] — aucune vérification d'âge à l'inscription alors que policy/ToS disent 13+. Apple/Google + RGPD art.8 (public étudiant/jeune). Fix ~2-3h.
3. **Docs légaux non publiés à des URLs publiques + placeholders `<INSERT...>`** non remplis (site_privacy_policy.md, site_account_deletion.md). Apple/Google exigent des URLs cliquables. Fix : déployer + remplir.

### 🟠 À RISQUE (avant/autour de la soumission)
- Disclosure "amis = données visibles" absente de la privacy policy.
- Log d'audit de suppression (preuve du délai 7j) absent.
- Google Play Data Safety form encore en draft (§5 sans réponse).
- Rate limits edge functions non activés (15 min dashboard).
- `.single()` Supabase → risque crash, remplacer par `.maybeSingle()` (~2-3h).

### ⚡ Note stratégique (pour MARKETING)
Le leaderboard/social est DÉSACTIVÉ sur iOS (Apple-safe) → ça neutralise le levier viral sur iOS. À rouvrir/contourner côté marketing.

---

## Statut (mise à jour au fil de l'eau)
- [x] Audit produit 2 piliers — FAIT (2026-06-21)
- [x] Audit SHIP conformité & légal — FAIT (2026-06-21)
- [ ] Fix bloquant #1 — paywall conforme 3.1.1/3.1.2
- [ ] Fix bloquant #2 — age gate
- [ ] Fix bloquant #3 — publier docs légaux + remplir placeholders
- [x] Statuts fondateur confirmés : entitlement Distribution ✅, compte Apple Dev ✅, site pour URLs légales ✅ (2026-06-26)
- [x] Plan publication exhaustif — 01_plan_publication.md
- [x] Briefs par agent — _HUB/agents/A1..A5
- [x] Nom commercial tranché : **The WakeApp** (ex-CEO OS) ; France, dispo monde ; site the-wakeapp.com ; pas d'iPad (2026-06-27)
- [x] Audit live dashboards — voir 02_dashboards_state.md (Supabase réactivé ; 2 blocages backend trouvés)
- [ ] NOUVEAU A6 · Backend Config : déployer `delete-account` + activer providers Apple/Google dans Supabase
- [ ] Décision coût : passer Supabase en Pro avant lancement (Free = pause auto)
- [ ] RevenueCat + App Store Connect : collecte via screenshots (accès navigateur bloqué)
- [ ] Inputs fondateur restants : identité légale (A3), prix abonnement (A4)
- [x] A1 Paywall conforme ✅ · A2 Age gate ✅ · A3 Docs légaux ✅ · A4 Fiche store ✅ · A5 Build/QA (v1.0.0+19) ✅
- [x] `delete-account` déployé en prod ✅ (suppression compte réparée)
- [x] Email légal = contact@the-wakeapp.com · prix mensuel = 2,99 € · tests 11/11 verts ✅
- [ ] DÉCISION EN COURS : connexion sociale — Apple-now + Google-v1.1 (Google jamais configuré, client IDs vides)
- [ ] TOI : publier _HUB/site/{privacy,terms}.md sur the-wakeapp.com · screenshots iPhone · App Privacy + description ASC (contenu prêt dans _HUB/store/)
- [ ] APPLE (attente) : correction nom Indy François → contrat Apps payantes → abonnements ASC + Shared Secret + attacher entitlement RevenueCat
- [ ] ⚠️ À vérifier device réel : extensions Shield (ShieldAction/ShieldConfiguration non enregistrées comme targets Xcode)
- [x] Apple Sign-In activé dans Supabase + provider Apple OK
- [x] BUG Apple Sign-In diagnostiqué (device réel) : `MissingPluginException` sign_in_with_apple = build natif périmé → fix = flutter clean + rebuild (corrige aussi bouton "Manage")
- [x] BUG "setup se relance sur autre téléphone" corrigé : flag `setup_completed` désormais côté serveur (profiles) — migration appliquée + code (model/repo/view_model/auth_provider) analyze propre
- [ ] Rebuild propre en cours sur iPhone (USB) → vérifier Apple Sign-In + setup + Manage
- [ ] Reste fiche App Store (description/screenshots — contenu prêt _HUB/store/)
- [ ] Objectif 2 MARKETING — système carrousels à concevoir (après SHIP)
