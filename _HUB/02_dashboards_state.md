# État réel des dashboards (vérifié en live — 2026-06-27)

App = **The WakeApp** (ex-CEO OS). App Store Connect App ID **6760942950**.

## SUPABASE (prod)
- Org **The CEO company** (Free Plan) · Projet **CEO OS** · ref `fyjojdynapdaoinpooyd` · `https://fyjojdynapdaoinpooyd.supabase.co`
- Région **eu-central-1 (Frankfurt)** · compute **NANO** (t4g.nano).
- **Était EN PAUSE → réactivé le 2026-06-27, STATUS = Healthy ✅** (action faite par Claude).
- Dernière migration : `create_kv_table_1278e773`. **Pas de backups** (limite Free).

### 🔴 Blocages backend découverts
1. **Suppression de compte CASSÉE.** Le code appelle l'edge function `delete-account` (settings_repository.dart:98), présente dans le repo (`supabase/functions/delete-account/index.ts`) mais **NON déployée**. Fonctions réellement déployées : `grant-beta-premium`, `revenuecat-webhook`, `make-server-1278e773`, `swift-action`. → Apple 5.1.1(v) + RGPD. **Fix : déployer `delete-account`.**
2. **Sign in with Apple & Google CASSÉS.** L'app affiche les boutons et appelle `signInWithIdToken(OAuthProvider.apple/google)` (auth_provider.dart:229/171), mais dans Supabase **Apple = Disabled, Google = Disabled** (seul Email activé). → connexion sociale impossible + Apple 4.8. **Fix : activer + configurer les providers Apple/Google (Client IDs, secrets, redirect URLs).**

### ✅ OK côté backend
- Secrets edge functions : `REVENUECAT_WEBHOOK_AUTH` ✅ (25 mai), `SERVICE_ROLE_KEY` ✅, `TESTFLIGHT_BETA_PREMIUM_KEY` ✅.
- Webhook RevenueCat sécurisé (auth présente).

### 🟠 À surveiller / nettoyer
- **Free Plan = mise en pause après ~7 j d'inactivité.** Risque que l'app se coupe après lancement. → passer en **Pro (~25 $/mois)** avant le lancement public. [DÉCISION COÛT FONDATEUR]
- Fonctions orphelines `make-server-1278e773` & `swift-action` (legacy, absentes du repo) → candidates à suppression (non bloquant).
- Vérifier "Confirm email" activé + "Allow new signups" ON (états non lus).

## REVENUECAT (collecté via screenshots 2026-06-27)
- **Entitlement** : `premium` (display "premium") — 3 products attachés — créé 21 mars 2026.
- **Offering** : `default` ("The standard set of packages") — 3 packages — actif. ✅
- **Products Apple (store WakeApp)** : `com.wakeapp.pro.yearly`, `com.wakeapp.pro.monthly` (créés 10 mai).
- **Test Store** : Lifetime / Yearly / Monthly (chacun 1 entitlement) — ce sont les 3 attachés à `premium`.

### 🔴 Problèmes RevenueCat
1. **Les 2 produits Apple NE SONT PAS rattachés à l'entitlement `premium`** (colonne montre "Attach"). Seuls les produits Test Store le sont. → même payé, le premium ne se débloque pas en prod. **Fix : attacher `com.wakeapp.pro.monthly/yearly` à `premium`.**
2. **Statut produits Apple = "Could not check"** → RevenueCat ne peut pas vérifier les produits auprès d'Apple. Causes probables : contrat Apps payantes pas actif + **App-Specific Shared Secret** non fourni à RevenueCat + abonnements pas "Prêts à la vente" dans ASC.

## APP STORE CONNECT (collecté via screenshots 2026-06-27)
- App **The WakeApp** · Bundle **com.wakeapp.ceoos** · SKU **wakeapp-ios** · Apple ID **6760942950** · langue principale EN-US.
- Version **iOS 1.0 = "À finaliser avant soumission"** (pas encore soumise).
- Titulaire : **Timo François**, 222 chemin de la Brague, 06410 Biot, France (compte **individuel**). Banque : Revolut Bank UAB (EUR→USD).

### 🔴 Bloquants monétisation (chaîne liée)
1. **Contrat "Apps payantes" = "En attente d'infos de l'utilisateur"** → vente d'abonnement IMPOSSIBLE tant qu'il n'est pas Actif. Débloqué par :
   - **Formulaires fiscaux** `W-8BEN` + `Certificate of Foreign Status` = "Informations manquantes" → **à remplir** [FONDATEUR].
   - **Banque** Revolut = "Traitement en cours" → se résout (~24 h).
2. **Contrat de licence Apple Developer mis à jour à ACCEPTER** par le titulaire (sinon impossible de soumettre) [FONDATEUR].
3. **App-Specific Shared Secret** (section ASC) → à générer et coller dans RevenueCat (résout "Could not check") [FONDATEUR].
4. **Abonnements ASC** (`com.wakeapp.pro.monthly/yearly`) : à vérifier qu'ils existent en groupe d'abonnement, avec prix + localisations + statut "Prêt à la vente". (Pas vu en capture — à confirmer.)

### 🟠 À compléter (fiche / conformité)
- **Export Compliance / chiffrement** : documents non fournis → ajouter `ITSAppUsesNonExemptEncryption` (false) dans Info.plist [CODE A5] ou déclarer dans ASC.
- **Sous-titre VIDE** + **catégorie** à confirmer + **Droits relatifs au contenu** non configurés → complétude fiche (A4) [FONDATEUR].
- **Classification par âge = 4+** ⚠️ incohérent avec la collecte de données + social (leaderboard/amis) + l'age gate 13+. Re-passer le questionnaire ; éviter la catégorie enfants. [DÉCISION + A2/A4]
- **App Store Server Notifications** (prod/sandbox) non configurées (optionnel si shared secret fourni).

### ✅ OK
- DSA : "Ce développeur s'est identifié comme commerçant" (trader status déclaré) ✅.
- EULA standard Apple ✅. Entitlement `premium` + offering `default` existent ✅. Product IDs définis ✅.

### Chaîne de monétisation (ordre des dominos)
Formulaires fiscaux + banque → **Contrat Apps payantes Actif** → abonnements ASC "Prêts à la vente" → **Shared Secret** dans RevenueCat → "Could not check" se résout → **attacher entitlement `premium` aux produits Apple** → premium fonctionne en prod.
