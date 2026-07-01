# CEO OS — Plan EXHAUSTIF de publication (v1)

Décision cadre : **Option B** — v1 AVEC premium conforme. On ne modifie PAS les fonctionnalités. Objectif : être en ligne (App Store en priorité) pour récolter du feedback réel.
Sources Apple 2026 : App Review Guidelines, Declared Age Range API, Requesting the Family Controls entitlement (voir liens en bas).
Légende ownership : **[FONDATEUR]** = action manuelle dans une console/portail (Claude ne peut pas) · **[CODE]** = Claude/agent peut le faire dans le repo · **[MIXTE]** = Claude prépare, fondateur applique.

---

## 0. CHEMIN CRITIQUE — à démarrer AUJOURD'HUI (délais longs)

| # | Item | Owner | Pourquoi bloquant | État à confirmer |
|---|------|-------|-------------------|------------------|
| 0.1 | **Family Controls *Distribution* entitlement** — formulaire dédié `developer.apple.com/contact/request/family-controls-distribution` | [FONDATEUR] | Sans approbation, distribution App Store IMPOSSIBLE. Délais 2026 : 13+ jours, parfois sans réponse. | ❓ Déjà demandé ? Accordé ? Si non → à soumettre MAINTENANT, le reste se fait en parallèle pendant l'attente. |
| 0.2 | Entitlement activé dans App Store Connect → Identifiers (après accord) | [FONDATEUR] | Doit suivre 0.1 | dépend de 0.1 |
| 0.3 | Compte Apple Developer Program actif + payé (99$/an) | [FONDATEUR] | Pas de soumission sinon | ❓ |

> ⚠️ Tant que 0.1 n'est pas accordé, tout le reste est de la prép. À lancer en priorité absolue.

---

## 1. CONFORMITÉ REVIEW APPLE — bloquants à corriger dans le repo

### 1.1 Paywall conforme 3.1.2 / 3.1.1 [CODE] — `lib/components/premium_paywall.dart`
Apple exige, visibles AVANT l'achat, DANS le binaire (le paywall) :
- [x] Titre de l'abonnement — présent
- [x] Durée (length) — `durationLabel` présent
- [x] Prix + prix par unité — `priceLabel` présent
- [ ] **Bouton "Restore Purchases"** → appeler `BillingService().restorePurchases()` (existe déjà, juste à câbler dans le UI)
- [ ] **Liens fonctionnels Terms (EULA) + Privacy** → `_openTerms`/`_openPrivacy` existent (l.240-246) mais JAMAIS rendus → les afficher
- [ ] **Texte d'auto-renouvellement** : "L'abonnement se renouvelle automatiquement sauf annulation au moins 24 h avant la fin de la période. Gérable dans les réglages du compte." (EN + FR)
Effort : ~1-2 h.

### 1.2 Age gate + classification d'âge [MIXTE]
- [ ] **Age gate à l'inscription** [CODE] — `signup_screen.dart` : porte d'âge (13+) avant création de compte (RGPD art.8 / COPPA). Bloquer < 13.
- [ ] **Questionnaire de classification d'âge dans App Store Connect** [FONDATEUR] — répondre honnêtement (le blocage d'apps / contenu n'est pas mature → visé 13+/4+ selon contenu).
- Note 2026 : Declared Age Range API concerne surtout le contenu 18+ et certains états/pays (AU, BR, SG, Utah, Louisiane). Pour un lancement 13+ global, l'age gate in-app + la bonne classification suffisent en v1.

### 1.3 Documents légaux publiés à des URLs publiques [MIXTE]
- [ ] **Déployer Privacy Policy + Terms à des URLs publiques cliquables** [FONDATEUR] (ex. site/Notion/GitHub Pages). Apple ET Google l'exigent dans la fiche + le paywall pointe dessus.
- [ ] **Remplir les placeholders `<INSERT ...>`** [CODE] dans `site_privacy_policy.md`, `site_account_deletion.md` (entité légale, email privacy, adresse, URL).
- [ ] Ajouter section "Connexions amis = données visibles dans le leaderboard" [CODE].

---

## 2. APP STORE CONNECT — configuration de soumission [FONDATEUR] (Claude prépare les textes)

- [ ] **Abonnement auto-renouvelable** créé + localisé (EN/FR) : nom d'affichage, durée, description, **prix par territoire**, screenshot de review de l'abonnement.
- [ ] **RevenueCat** : offerings/products mappés aux product IDs ASC ; clé API publique dans l'app (via dart-define) ; **secret du webhook** configuré côté Supabase + RevenueCat dashboard.
- [ ] **App Privacy (nutrition labels)** : déclarer exactement les données collectées (email, profil, stats/streaks, contacts amis) + tiers (Supabase, RevenueCat, Apple/Google Sign-In). Doit correspondre à la privacy policy.
- [ ] **Account deletion** déclarée (Guideline 5.1.1(v)) — flow déjà fonctionnelle in-app ✅.
- [ ] **Export Compliance** (chiffrement) déclaré.
- [ ] **Support URL + Marketing URL + Privacy Policy URL** renseignées.
- [ ] **App Review Notes** : utiliser `docs/app_store_submission_packet.md` (déjà rédigé) + comptes de test + explication Screen Time on-device.
- [ ] **Screenshots** (toutes tailles requises) + description + mots-clés (ASO minimal pour v1).
- [ ] **Démo de revue** : si Family Controls nécessite un device réel, fournir vidéo/instructions.

---

## 3. BACKEND / OPS pré-lancement

- [ ] **Injection des clés Supabase en build release** [MIXTE] — confirmer que le build prod passe `--dart-define=SUPABASE_URL=... SUPABASE_ANON_KEY=...` (cf. `supabase_config.dart`, fallback hardcodé sinon). Documenter la commande de build.
- [ ] **Rate limits edge functions** [FONDATEUR] — activer dans le dashboard Supabase (revenuecat-webhook, grant-beta-premium, delete-account). ~15 min.
- [ ] **Supabase Auth** : "Confirm email" activé ; redirections OAuth (Apple/Google) configurées pour le bundle id de prod.
- [ ] **RLS** : déjà OK (C0-1/2/3 résolus) ✅ — re-vérif rapide avant submit.
- [ ] Décision free-limits serveur : laisser en NO-OP pour la v1 (pas une modif de feature, juste un risque coût à surveiller). [DÉCISION HUB]

---

## 4. BUILD & SIGNING

- [ ] **iOS** : entitlement family-controls présent sur TOUS les targets (Runner + extensions Shield/Monitor/Report) — déjà constaté présent, re-vérifier. Provisioning profiles de distribution. Bump version/build (`pubspec.yaml` 1.0.0+18 → +19).
- [ ] **Android** (track parallèle, après iOS) : `key.properties` (signing) présent localement, non committé ✅. Build app bundle signé. Min SDK 26 OK.
- [ ] `flutter analyze` propre + `flutter test` au vert avant build.

---

## 5. TESTS RÉELS (obligatoire pour un blocking stack)

- [ ] **Validation sur device réel** du blocage (Focus / CEO Mode / Screen Time) — plan existant : `docs/real_device_test_plan_blocking_stack.md`.
- [ ] Parcours achat → activation premium → restore → annulation (sandbox StoreKit).
- [ ] Parcours suppression de compte de bout en bout.
- [ ] Parcours hors-ligne (pas de crash).

---

## 6. SOUMISSION

- [ ] TestFlight build de review final (mode review Apple actif).
- [ ] Soumettre pour review une fois 0.1 accordé + section 1 corrigée + section 2 remplie.
- [ ] Préparer réponses-types aux questions de review (Screen Time on-device, démo).

---

## SÉQUENCE RECOMMANDÉE
1. **[FONDATEUR] 0.1 entitlement Distribution** (aujourd'hui, lead time long) + confirmer 0.3.
2. En parallèle, **[CODE]** sections 1.1, 1.2 (age gate), 1.3 (placeholders) — les agents bossent pendant l'attente Apple.
3. **[FONDATEUR]** déployer URLs légales (1.3) + remplir ASC (section 2).
4. Build + tests réels (4, 5).
5. Soumettre (6).

## Liens de référence (Apple 2026)
- App Review Guidelines : https://developer.apple.com/app-store/review/guidelines/
- Requesting the Family Controls entitlement : https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement
- Subscriptions / 3.1.2 : https://developer.apple.com/app-store/subscriptions/
- Declared Age Range API : https://developer.apple.com/documentation/declaredagerange/
- Age requirements (regions, 2026) : https://developer.apple.com/news/?id=f5zj08ey
