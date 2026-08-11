# Rapport de sécurité pré-lancement — The WakeApp

Revue en 5 axes (RLS, edge functions, secrets, auth/premium, client/natif iOS).
Date : 2026-07-01. Statut global : **C1 corrigé ✅. RLS vérifiée en prod ✅ (H-RLS + M-entitlements résolus).** Il ne reste que de l'anti-abus / conformité (C2, H2, H1) + nettoyage — aucun bloquant data.

### Résultat de la vérification RLS en prod (2026-07-01)
- ① Aucune table avec RLS désactivée. ② Seule `kv_store_1278e773` (interne Supabase, RLS ON = deny par défaut) sans policy.
- ③ Les 6 tables sensibles (`blocked_apps`, `block_lists`, `notes`, `event_types`, `friend_connections`) : policy `ALL using (auth.uid() = created_by)` ✅. `screen_time_logs` absente (supprimée). `user_entitlements` = **SELECT-only** (v3 appliquée) ✅.
- **→ H-RLS RÉSOLU · M-entitlements RÉSOLU.** Le risque de fuite PII inter-utilisateurs n'existe pas en prod.

Légende sévérité : 🔴 Critique (bloquant) · 🟠 Élevé · 🟡 Moyen · 🟢 Faible

---

## 🔴 CRITIQUE — bloquants

### C1 — `devForcePremium = true` : premium gratuit pour tout le monde
- **Fichier :** `lib/core/config/tester_config.dart:9`
- **Risque :** 1er maillon de `isPremiumUser` (`premium_repository.dart:69`) → paywall **entièrement court-circuité**. Le fichier dit lui-même « MUST be false before build ». Fausse aussi ton test actuel (tu es premium forcé).
- **Correctif :** `static const bool devForcePremium = false;` — idéalement `kDebugMode && false` pour qu'un build release ne puisse JAMAIS l'activer. **1 ligne.**

### C2 — Fenêtre de grâce premium écrivable en local
- **Fichier :** `lib/core/repositories/premium_repository.dart:247-251` (`activateClientGraceWindow`) + `340-348` (`_isClientGraceActive`)
- **Risque :** clé `premium_client_grace_until_v1` dans SharedPreferences (éditable sur device jailbreaké / via backup) → premium permanent hors-ligne sans achat.
- **Correctif :** ne jamais accorder l'entitlement depuis un flag local. Ne l'utiliser que comme hint UI optimiste **toujours** réconcilié avec le serveur (RevenueCat/`billing_subscriptions`) dans la fenêtre ; révoquer si non confirmé.

---

## 🟠 ÉLEVÉ

### H-RLS — 6 tables sensibles sans RLS définie dans le code
- **Tables :** `blocked_apps`, `block_lists`, `notes`, `screen_time_logs`, `event_types`, `friend_connections` (existent en prod — référencées par la purge `supabase/migrations/20260629_account_deletion_grace_period.sql:27-29`) mais **aucun `enable row level security` / `create policy`** dans tout le SQL du repo.
- **Risque :** si RLS OFF en prod → **fuite PII inter-utilisateurs** (apps bloquées, notes privées, historique d'écran, amis de tous les users). C'est le vrai risque data du lancement.
- **Action :** VÉRIFIER en prod (SQL ci-dessous). Si RLS manquante → activer + policy owner (migration fournie ci-dessous).

### H2 — Age gate 13+ non vérifié serveur
- **Fichiers :** `auth_provider.dart` (`auth.age_verified.v1` = booléen local) ; router `app_router.dart:289-339` ne check QUE `isAuthenticated`, jamais `isAgeVerified`.
- **Risque :** contournable par deep link / flag pré-positionné ; aucune date de naissance côté serveur → exposition COPPA / RGPD art. 8.
- **Correctif :** persister une attestation d'âge/DOB sur le profil serveur à la création + **ajouter le check d'âge dans le redirect du router** (au minimum).

### H1 — Limites free vérifiées côté client
- **Fichier :** `premium_repository.dart` (`canCreateHabit/Task/Note`, `canStartFocus`…). Counts via requêtes client.
- **Nuance (croisé RLS) :** il existe bien une base serveur (`_wakeapp_is_premium`, `supabase/migrations/20260525_server_free_limits.sql`) + tables billing en lecture seule. Mais l'enforcement des **quotas** sur inserts n'est pas garanti, surtout sur les 6 tables sans RLS (H-RLS).
- **Correctif :** enforcer les quotas premium via RLS `with check` / RPC `SECURITY DEFINER` qui lisent l'entitlement serveur. Priorité après H-RLS.

---

## 🟡 MOYEN

- **M-entitlements** — `user_entitlements` : la migration v2 (`supabase_premium_foundation_v2.sql:62`) autorisait un self-INSERT `is_grandfathered=true` (bypass paywall), corrigé seulement par v3 (`supabase_premium_launch_controls_v3.sql:22-31`, SELECT-only). **Confirmer en prod que v3 a bien tourné** (SQL ci-dessous).
- **M-leaderboard** — `leaderboard_entries` (`supabase_production_update.sql:516`) expose `created_by` (UID auth) + `screen_time_avg_minutes` à tous les connectés quand opt-in. Fix : exposer via une vue qui masque l'UID / le temps brut.
- **M2** — succès d'achat rapporté sur timeout sans confirmation backend (`billing_service.dart:160-164`) — se règle avec C2.
- **M1 (levé)** — annulation de suppression = `profiles.update().eq('id', uid)` : **OK**, l'agent RLS a confirmé que `profiles` a bien une policy owner-scoped.

## 🟢 FAIBLE (nettoyage)

- ~15 `print()` d'erreur Dart non gardés en release (`task_provider.dart`, `habit_provider.dart`, `task_repository.dart`) → router via `AppLogger`.
- `NSLog`/`print` natifs en release (`AppDelegate.swift`) — bénins, gater `#if DEBUG`.
- Edge fn : comparaison bearer non constant-time (`revenuecat-webhook:49`) ; messages d'erreur DB renvoyés au client.
- `codex_recovery/` (5968 fichiers), `.tmp_v1/`, `CEOV1/` suivis par git malgré `.gitignore` → `git rm -r --cached`.
- Clé anon en dur comme fallback (`supabase_config.dart:8-9`) — OK **si** RLS confirmée ; rotation possible pour invalider la copie dans l'historique git.

---

## ✅ Correctement sécurisé (vérifié)
- RLS owner-scoped correcte sur ~30 tables (profiles, habits, tasks, focus_sessions, family_time_*, etc.).
- `billing_subscriptions` / `user_entitlements` **non écrivables** par le client (SELECT-only).
- `delete-account` : **pas d'IDOR** (lié au JWT vérifié, body jamais lu). Purge de suppression = cron-only SECURITY DEFINER.
- Apple Sign-In : nonce SHA-256 (anti-replay). Google via Supabase. RevenueCat : validation reçu **côté serveur**.
- Aucun secret réel dans le client (pas de service_role / .p8 / secret RevenueCat). ATS sécurisé (HTTPS forcé). Deep links allowlistés. Décodage natif anti-crash. Logout purge la file d'écriture.

---

## 🔎 SQL de vérification à lancer en prod (Supabase → SQL Editor)

```sql
-- 1) Tables publiques avec RLS DÉSACTIVÉE (doit être vide, ou ne lister que app_configs)
select c.relname as "table", c.relrowsecurity as rls_enabled
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity = false
order by c.relname;

-- 2) Tables publiques SANS AUCUNE policy
select t.tablename
from pg_tables t
where t.schemaname = 'public'
and not exists (
  select 1 from pg_policies p
  where p.schemaname = 'public' and p.tablename = t.tablename
)
order by t.tablename;

-- 3) Détail des policies sur les tables suspectes + user_entitlements
select tablename, policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
and tablename in (
  'blocked_apps','block_lists','notes','screen_time_logs',
  'event_types','friend_connections','user_entitlements'
)
order by tablename, policyname;
```

**Lecture des résultats :**
- Requête 1/2 : si une des 6 tables sensibles apparaît → **RLS manquante = fuite PII**, appliquer la remédiation ci-dessous.
- Requête 3 : `user_entitlements` ne doit avoir qu'une policy **SELECT** (pas de `with_check` d'insert). Sinon v3 n'a pas tourné → self-grant premium possible.

## 🛠️ Remédiation RLS (à adapter au nom exact de la colonne owner : `created_by` ou `user_id`)

```sql
-- Pour CHAQUE table listée sans RLS/policy :
alter table public.blocked_apps enable row level security;
create policy "blocked_apps_own" on public.blocked_apps
  for all to authenticated
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);
-- Répéter pour block_lists, notes, screen_time_logs, event_types, friend_connections.
-- friend_connections : owner peut être des DEUX côtés → policy à adapter
--   using (auth.uid() = created_by or auth.uid() = friend_id)
```

---

## Plan d'action priorisé avant soumission
1. **C1** — `devForcePremium=false` (1 ligne). *Code — fait maintenant.*
2. **H-RLS** — lancer le SQL de vérif en prod ; activer RLS sur toute table manquante. *Le vrai bloquant data.*
3. **M-entitlements** — confirmer que v3 est appliquée (`user_entitlements` SELECT-only).
4. **C2 + H1** — enforcement premium/quotas côté serveur (RLS `with check` / RPC).
5. **H2** — age gate côté serveur + check router.
6. **🟢** — print()→AppLogger, untrack `codex_recovery/`, hardening edge fn.
</content>
</invoke>
