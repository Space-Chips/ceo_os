# Security Review — `ceo_os` (iOS Flutter + Supabase)

Date: 2026-05-25
Audit scope: code Dart + Swift + SQL + Supabase Edge Functions + plists/entitlements.
Auditeur: Claude Code (analyse statique).

Classement: **C0 = critique exploitable immédiatement**, **H = haute**, **M = moyenne**, **L = basse / hygiène**.

---

## C0-1. `app_configs` n'a pas de RLS — paywall et limites free contrôlables par n'importe quel utilisateur connecté

**Fichiers**: aucune migration n'active RLS sur `public.app_configs`.
Vérifié par `grep -rEn 'app_configs.*row level|policy.*app_configs|create policy.*app_configs'` → **0 résultat** sur `supabase_*.sql` et `supabase/migrations/`.
Pourtant la table est créée et écrite (`supabase_premium_foundation_v2.sql:6`, `supabase_billing_revenuecat_v4.sql:3`, `supabase_premium_launch_controls_v3.sql:3`, `supabase/migrations/20260510_enable_public_premium.sql`).

**Risque**: par défaut Supabase accorde `SELECT/INSERT/UPDATE/DELETE` à `authenticated` sur le schéma `public`. Sans RLS, n'importe quel utilisateur connecté peut:

```sql
update public.app_configs
set config_value = config_value
  || jsonb_build_object('paywall_enabled', false, 'tasks_free_limit', 999999)
where config_key = 'premium';
```

→ paywall désactivé pour TOUS les utilisateurs, limites freemium contournées globalement.
Lecture: les clés `revenuecat_*_api_key` (mobile SDK keys) sont OK, mais la fuite de la configuration interne (launch dates, discount, themes premium) est exposée.

**Correctif**:

```sql
alter table public.app_configs enable row level security;

drop policy if exists "app_configs_read_authenticated" on public.app_configs;
create policy "app_configs_read_authenticated"
  on public.app_configs
  for select
  to authenticated, anon
  using (true);

-- Pas de policy INSERT/UPDATE/DELETE → seul service_role peut écrire.
```

---

## C0-2. Webhook RevenueCat: l'auth Bearer est **optionnelle** (bypass total si env var non set)

**Fichier**: [supabase/functions/revenuecat-webhook/index.ts](supabase/functions/revenuecat-webhook/index.ts:25-40)

```ts
const revenueCatAuth = Deno.env.get('REVENUECAT_WEBHOOK_AUTH') ?? '';
…
Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });

  if (revenueCatAuth) {                               // ⚠️ si env vide → pas d'auth
    const header = request.headers.get('authorization') ?? '';
    if (header !== `Bearer ${revenueCatAuth}`) {
      return new Response('Unauthorized', { status: 401 });
    }
  }
  …
});
```

Ensuite, `appUserId` est lu **tel quel depuis le JSON**:

```ts
const appUserId = normalizeText(event.app_user_id) ?? normalizeText(event.original_app_user_id);
…
await supabase.from('billing_subscriptions').upsert({
  created_by: appUserId,
  status,                              // active / trialing
  provider: 'revenuecat',
  ...
}, { onConflict: 'created_by' });
```

**Exploit** (si `REVENUECAT_WEBHOOK_AUTH` n'a jamais été configuré sur l'Edge Function, ce que rien dans le repo ne garantit):

```bash
curl -X POST https://fyjojdynapdaoinpooyd.supabase.co/functions/v1/revenuecat-webhook \
  -H "Content-Type: application/json" \
  -d '{"event":{"type":"INITIAL_PURCHASE","app_user_id":"<UUID_VICTIME>","product_id":"x","period_type":"year","expiration_at_ms":4102444800000}}'
```

→ insère `billing_subscriptions{created_by=<UUID_VICTIME>, status='active'}`.
Combiné au calcul client `subscriptionStatus in ('active','trialing')` → premium accordé à n'importe quel UUID.

**Correctifs (à faire LES DEUX)**:

1. Rendre l'auth obligatoire:

```ts
if (!revenueCatAuth) {
  return new Response('Webhook not configured', { status: 503 });
}
const header = request.headers.get('authorization') ?? '';
if (header !== `Bearer ${revenueCatAuth}`) {
  return new Response('Unauthorized', { status: 401 });
}
```

2. Confirmer que `app_user_id` est bien un UUID Supabase et qu'il existe dans `auth.users` (limite l'effet en cas de fuite du Bearer):

```ts
const uuidV4 = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
if (!uuidV4.test(appUserId)) return new Response('Invalid app_user_id', { status: 400 });
const { data: u, error: ue } = await admin.auth.admin.getUserById(appUserId);
if (ue || !u?.user) return new Response('Unknown user', { status: 404 });
```

3. Définir `REVENUECAT_WEBHOOK_AUTH` (secret aléatoire 32+ octets) côté Supabase Functions Secrets ET dans le dashboard RevenueCat (Authorization header).

---

## C0-3. Permissions iOS manquantes (`NSPhotoLibraryUsageDescription`, etc.) — crash + rejet App Store

**Fichier**: [ios/Runner/Info.plist](ios/Runner/Info.plist)

Vérifié par `grep -rE 'NSPhotoLibrary|NSCamera|NSMicrophone|NSContacts|NSLocation|NSFaceID' /Users/timo/ceo_os/ios /Users/timo/ceo_os/macos` → **0 résultat** (hors Pods).

L'app embarque `image_picker: ^1.1.2` ([pubspec.yaml:18](pubspec.yaml:18)) qui requiert ces clés. Sur iOS 13+, l'absence de `NSPhotoLibraryUsageDescription` fait **crash immédiat** quand `pickImage(source: gallery)` est appelé (`SIGABRT: This app has crashed because it attempted to access privacy-sensitive data without a usage description`).

**Conséquence App Store Review**: rejet automatique pour Guideline 5.1.1 (Privacy).

**Correctif**: ajouter dans [ios/Runner/Info.plist](ios/Runner/Info.plist) avant `</dict>`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>WakeApp needs access to your photo library to set your profile picture and attach images.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>WakeApp needs permission to save images to your photo library.</string>
<key>NSCameraUsageDescription</key>
<string>WakeApp uses your camera to capture profile pictures.</string>
```

À retirer celles que vous n'utilisez pas (App Review demande des justifications honnêtes).

---

## H-1. Deep links / Home Widget passent toute URI au router sans allowlist

**Fichier**: [lib/main.dart:104-129](lib/main.dart:104)

```dart
void _handleHomeWidgetUri(Uri? uri) {
  if (uri == null) return;
  final path = uri.path;                         // ⚠️ pas de scheme check
  if (path.isEmpty) return;
  _router.go('$path$query');
}

void _handleDeepLink(Uri? uri) {
  if (uri == null) return;
  if (uri.scheme.toLowerCase() != 'ceoos') return; // ok pour le scheme
  final path = uri.path;                         // ⚠️ allowlist absente
  _router.go('$path$query');
}
```

**Risque**: une page web malveillante peut faire ouvrir l'app sur n'importe quelle route interne via `<a href="ceoos:///settings/account/delete">Cliquez ici</a>` ou via Universal Links — sauter le flow d'onboarding, atterrir directement sur des écrans d'admin/debug, ou contourner des confirmations modales.

**Correctif**:

```dart
static const _allowedDeepLinkPaths = <String>{
  '/', '/home', '/dashboard', '/tasks', '/habits', '/focus', '/calendar',
};

void _handleDeepLink(Uri? uri) {
  if (uri == null) return;
  if (uri.scheme.toLowerCase() != 'ceoos') return;
  final path = uri.path;
  if (path.isEmpty) return;
  final firstSegment = '/${uri.pathSegments.isNotEmpty ? uri.pathSegments.first : ''}';
  if (!_allowedDeepLinkPaths.contains(firstSegment) &&
      !_allowedDeepLinkPaths.contains(path)) {
    return; // ignore silencieusement
  }
  final query = uri.hasQuery ? '?${uri.query}' : '';
  _router.go('$path$query');
}
```

Faire pareil pour `_handleHomeWidgetUri` et ajouter un check du scheme (`if (uri.scheme.isNotEmpty && uri.scheme != 'ceoos') return;`).

---

## H-2. URL & anon key Supabase de **production** codées en dur dans le binaire

**Fichier**: [lib/core/config/supabase_config.dart:2-10](lib/core/config/supabase_config.dart:2)

```dart
static const String _debugUrl = 'https://fyjojdynapdaoinpooyd.supabase.co';
static const String _debugAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5am9qZHluYXBkYW9pbnBvb3lkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5OTk3MTgsImV4cCI6MjA4NjU3NTcxOH0.GcHhxLQF6UA149KQUkph4XYsVnc3K_TlcKWOup3ki_4';
// exp = 2036-02-14 — clé valide ~10 ans

static String get url {
  const env = String.fromEnvironment('SUPABASE_URL');
  if (env.isNotEmpty) return env;
  return _debugUrl;                            // ⚠️ fallback = prod
}
```

L'`anon key` Supabase est conçue pour être publique (RLS protège) — donc **PAS une fuite de secret en soi**. Mais:

- elle pointe le projet de **prod**, qui devient la cible directe si RLS a une faille (cf C0-1)
- elle survit dans tous les binaires distribués ; rotation = obligatoire de releaser une nouvelle build
- `hasRequiredConfiguration` (utilisé par `main.dart:46`) devient cosmétique car le fallback est toujours rempli

**Correctif**: rendre le build incomplet sans `--dart-define`:

```dart
static String get url {
  const env = String.fromEnvironment('SUPABASE_URL');
  if (env.isEmpty) {
    assert(false, 'SUPABASE_URL must be provided via --dart-define');
    return '';
  }
  return env;
}
// idem pour anonKey, supprimer _debugUrl et _debugAnonKey
```

Pipeline CI: injecter via `flutter build ios --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.

---

## H-3. `grant-beta-premium` ne vérifie pas que l'email est confirmé

**Fichier**: [supabase/functions/grant-beta-premium/index.ts:38-52](supabase/functions/grant-beta-premium/index.ts:38)

```ts
const { data: { user }, error } = await userClient.auth.getUser();
…
const email = (user.email ?? '').trim().toLowerCase();
…
const { data: allowlisted } = await admin
  .from('beta_premium_allowlist')
  .select('email').eq('email', email).maybeSingle();
```

Si l'instance Supabase autorise les signups sans email verification, un attaquant peut:

1. Signup avec l'email d'une personne sur l'allowlist (`alice@startup.com`)
2. Sans avoir besoin de cliquer le lien de confirmation
3. Appeler `grant-beta-premium` → reçoit `premium_override=true`

**Correctif**:

```ts
if (!user.email_confirmed_at) {
  return new Response('Email not confirmed', { status: 403 });
}
```

Et, dans le dashboard Supabase Auth, activer **Confirm email** pour les nouveaux comptes.

---

## H-4. `delete-account` détruit l'historique webhook (`billing_webhook_events`) — perte d'audit/preuve

**Fichier**: [supabase/functions/delete-account/index.ts:38](supabase/functions/delete-account/index.ts:38)

La liste `deletableTables` inclut `billing_webhook_events`. Après suppression du compte, vous perdez la trace des événements de facturation RevenueCat (utile pour disputes, remboursements, audit fiscal/RGPD).

**Correctif**: retirer `billing_webhook_events` de la liste; à la place, anonymiser:

```ts
await admin.from('billing_webhook_events')
  .update({ created_by: null })
  .eq('created_by', user.id);
```

Rappel: webhook events contiennent souvent l'email et l'`app_user_id`. Anonymiser puis garder 12–24 mois selon votre politique de rétention RGPD.

---

## H-5. `auth_user_delete_cleanup` change `storage.objects` FK en `ON DELETE SET NULL` → orphelins persistent

**Fichier**: [supabase/migrations/20260509_auth_user_delete_cleanup.sql:10-22](supabase/migrations/20260509_auth_user_delete_cleanup.sql:10)

```sql
execute 'alter table storage.objects drop constraint if exists objects_owner_fkey';
execute 'alter table storage.objects add constraint objects_owner_fkey
         foreign key (owner) references auth.users(id) on delete set null';
```

Les fichiers du user (avatar, exports, etc.) restent dans le bucket avec `owner=null` après suppression du compte. Violation RGPD (droit à l'effacement) + coût stockage.

**Correctif**: avant de delete le user dans `fn_delete_account`, énumérer et supprimer les objets:

```ts
// Dans /Users/timo/ceo_os/supabase/functions/delete-account/index.ts
const { data: objects } = await admin.storage.from('avatars').list(user.id);
if (objects) {
  await admin.storage.from('avatars').remove(objects.map(o => `${user.id}/${o.name}`));
}
// Répéter pour chaque bucket utilisé par l'app
```

Ou, plus simple, repasser le FK en `ON DELETE CASCADE` après vous être assuré que la deletion est faite via Edge Function (pas la dashboard).

---

## H-6. Webhook RevenueCat: pas de validation du contenu `app_user_id` ni d'idempotence stricte

**Fichier**: [supabase/functions/revenuecat-webhook/index.ts:60-75](supabase/functions/revenuecat-webhook/index.ts:60)

```ts
const eventId =
  normalizeText(event.id) ??
  [normalizeText(event.type) ?? 'unknown', …].join(':');
```

Si `event.id` est absent, l'`event_id` est dérivé d'une concaténation faillible. Deux webhooks différents peuvent collisionner et un seul sera persisté.

`onConflict: 'created_by'` sur `billing_subscriptions` veut dire que le **dernier événement reçu écrase tout**. Si un événement `EXPIRATION` arrive APRÈS un `RENEWAL` (re-livraison hors ordre par RevenueCat), l'abonnement devient `inactive`.

**Correctif**:

```ts
// Rejeter les événements sans id
if (!normalizeText(event.id)) {
  return new Response('Missing event.id', { status: 400 });
}

// Avant l'upsert billing_subscriptions, vérifier la fraîcheur:
const incomingTs = event.event_timestamp_ms ? new Date(event.event_timestamp_ms) : new Date();
const { data: existing } = await supabase
  .from('billing_subscriptions')
  .select('last_webhook_event_at')
  .eq('created_by', appUserId)
  .maybeSingle();
if (existing?.last_webhook_event_at &&
    new Date(existing.last_webhook_event_at) > incomingTs) {
  return Response.json({ ok: true, skipped: 'stale' });
}
```

---

## M-1. Pas de vérification serveur stricte du status premium — bypass facile en client modifié

**Fichier**: [lib/core/repositories/premium_repository.dart:33-56](lib/core/repositories/premium_repository.dart:33)

Le statut premium se calcule **côté client** à partir de:

- `billing_subscriptions.status in ('active','trialing')` (RLS = SELECT own → ok)
- `user_entitlements.premium_override` (RLS = SELECT own → ok)
- `user_entitlements.is_grandfathered`, `early_launch_user` (idem)

Les RLS sont OK en READ. Mais le **calcul de `isPremiumUser` est en Dart**, donc tout utilisateur peut patcher le binaire pour forcer `isPremiumUser=true`. C'est inévitable côté mobile **MAIS** les **limites freemium** (`tasks_free_limit`, `habits_free_limit`, `notes_free_limit`, `focus_free_daily_limit`) sont aussi **vérifiées uniquement côté client** ([premium_repository.dart:95-145](lib/core/repositories/premium_repository.dart:95)).

**Conséquence**: un free user techniquement avisé peut créer 10 000 tâches/habitudes/notes en bypassant l'app et appelant directement Supabase via PostgREST. Coût d'infra.

**Correctif**: ajouter un trigger PG qui plafonne par user pour les utilisateurs non-premium:

```sql
create or replace function public.enforce_free_task_limit()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_count int; v_limit int; v_premium boolean;
begin
  select
    coalesce((select status in ('active','trialing') from billing_subscriptions where created_by = new.created_by), false)
    or coalesce((select premium_override from user_entitlements where created_by = new.created_by), false)
    or coalesce((select is_grandfathered from user_entitlements where created_by = new.created_by), false)
  into v_premium;
  if v_premium then return new; end if;
  select (config_value->>'tasks_free_limit')::int into v_limit
    from app_configs where config_key = 'premium';
  select count(*) into v_count from pareto_tasks where created_by = new.created_by;
  if v_count >= coalesce(v_limit, 5) then
    raise exception 'Free tier task limit reached' using errcode = 'P0001';
  end if;
  return new;
end; $$;
create trigger pareto_tasks_enforce_free
  before insert on pareto_tasks
  for each row execute function enforce_free_task_limit();
```

Idem pour `habits`, `notes`, `focus_sessions`.

---

## M-2. Pas de rate limiting sur les Edge Functions

Les 3 Edge Functions (delete-account, grant-beta-premium, revenuecat-webhook) sont accessibles publiquement sans rate limit. `grant-beta-premium` en particulier peut être spammé pour énumérer les emails de l'allowlist (selon le temps de réponse 403 vs 200).

**Correctif**: utiliser Supabase Rate Limits (depuis la dashboard Functions → Settings → Rate Limit) ou implémenter une table `rate_limit_events` avec un check au début de chaque function.

---

## M-3. `delete-account` ne bloque pas le webhook après suppression du compte

Course possible: pendant que `delete-account` itère les 30 tables, RevenueCat peut livrer un événement `EXPIRATION` qui recrée `billing_subscriptions{created_by=<uuid>, status='inactive'}`. Après deletion, des lignes orphelines peuvent persister.

**Correctif**: déplacer `admin.auth.admin.deleteUser(user.id)` en **premier**. Le trigger `_wakeapp_before_auth_user_delete` (déjà installé) supprimera les données. Avantage: si l'auth user n'existe plus, le webhook insère `created_by=<uuid>` qui pointe vers… nulle part (mais la FK `references auth.users` BLOQUERA l'insert → 500 retourné à RevenueCat, qui retry, sans effet de bord).

---

## M-4. iOS — `ITSAppUsesNonExemptEncryption=false` sans déclaration de l'utilisation HTTPS standard

**Fichier**: [ios/Runner/Info.plist:21-22](ios/Runner/Info.plist:21)

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

C'est techniquement vrai (HTTPS/TLS = standard exempt) mais l'App Store demande parfois la confirmation. Pas un bug — vérifier que vous avez bien soumis le formulaire d'exemption dans App Store Connect → App Privacy → Export Compliance.

---

## M-5. Pas de `NSAppTransportSecurity` explicite

**Fichier**: [ios/Runner/Info.plist](ios/Runner/Info.plist) — clé absente.

Pas un bug (ATS par défaut bloque HTTP non-sécurisé) mais à vérifier: si vous chargez des images depuis une URL HTTP non-sécurisée (avatars de friends?), elles n'apparaîtront pas. Forcer toutes les URLs en HTTPS (Supabase storage, RevenueCat, etc. le sont déjà ✓).

---

## L-1. Plein de fichiers `supabase_*.sql` à la racine — incohérence vs `supabase/migrations/`

Vous avez 22 fichiers `.sql` à la racine du repo ET un dossier `supabase/migrations/` avec 4 migrations. **Aucune source de vérité unique**. Risque opérationnel: on ne sait pas quel SQL a été appliqué en prod ni dans quel ordre, et `supabase_premium_foundation_v2.sql` est en conflit avec `supabase_premium_launch_controls_v3.sql` sur la policy `user_entitlements_own` (l'un fait `for all`, l'autre redéfinit en `for select`).

**Correctif**: migrer tous les `supabase_*.sql` racine vers `supabase/migrations/YYYYMMDDHHMMSS_*.sql` numérotés, exécuter `supabase db diff` en dev pour vérifier l'état, et lock le repo prod sur les migrations dans le dossier.

---

## L-2. Code Python de "recovery" à la racine (`smart_recovery_v3.py`, etc.) avec accès potentiel au repo

22 scripts `*.py` ad-hoc à la racine du repo (`pass3_recovery.py`, `partial_snapshot_overlay.py`, `extractor.py`, `fix_smart_quotes.py`, `fichiertxt.txt` 108 KB…). Ces scripts ne sont pas un risque sécurité direct, mais ils:

- gonflent la surface d'analyse (ils restent dans l'image git, exécutables si quelqu'un récupère le repo)
- contiennent potentiellement des chemins/secrets de tests passés (à grep)

**Correctif**: déplacer dans `tools/recovery/` ou `archives/` ou supprimer si plus utilisés. Vérifier `git log --all -p smart_recovery.py | grep -iE 'token|key|password'`.

---

## L-3. `.DS_Store` (14 KB) commité

**Fichier**: [.DS_Store](.DS_Store)

Pas sensible mais leak les noms de fichiers/dossiers locaux à tout monde qui clone le repo. Ajouter à `.gitignore` et `git rm --cached .DS_Store`.

---

## L-4. AppDelegate.swift — `print` statements sensibles en release

L'`AppDelegate` log abondamment via `print` et `NSLog` (cf. extraits): noms de plugins, identifiants de session focus, durées. En release, ces logs vont dans `os_log` accessibles via Console.app pour qui a le device. Pas une fuite catastrophique, mais le `print("WakeApp Native Launching...")` et `print("Failed to schedule focus notification \(identifier)…")` devraient être conditionnés par `#if DEBUG`.

---

## Récap exécutif (à corriger dans l'ordre)

| # | Sévérité | Fichier | Effort | Fix |
|---|---|---|---|---|
| C0-1 | **Critique** | nouvelle migration | 5 min | Activer RLS sur `app_configs` |
| C0-2 | **Critique** | `supabase/functions/revenuecat-webhook/index.ts` | 10 min | Auth Bearer obligatoire + validation `app_user_id` |
| C0-3 | **Critique App Store** | `ios/Runner/Info.plist` | 5 min | Ajouter `NSPhotoLibraryUsageDescription` + variantes |
| H-1 | Haute | `lib/main.dart` | 15 min | Allowlist des paths deep-link |
| H-2 | Haute | `lib/core/config/supabase_config.dart` | 30 min (CI) | Retirer fallbacks prod, injecter via `--dart-define` |
| H-3 | Haute | `supabase/functions/grant-beta-premium/index.ts` | 5 min | Check `email_confirmed_at` |
| H-4 | Haute | `supabase/functions/delete-account/index.ts` | 10 min | Anonymiser `billing_webhook_events` au lieu de delete |
| H-5 | Haute | nouveau dans Edge Function delete-account | 15 min | Supprimer les objets storage du user |
| H-6 | Haute | `supabase/functions/revenuecat-webhook/index.ts` | 20 min | Idempotence + ordering check sur `event_timestamp_ms` |
| M-1 | Moyenne | nouvelle migration | 1h | Triggers `enforce_free_*_limit` côté PG |
| M-2 | Moyenne | dashboard Supabase | 5 min | Activer rate limits sur Functions |
| M-3 | Moyenne | `supabase/functions/delete-account/index.ts` | 5 min | DeleteUser en premier |
| M-4/M-5 | Moyenne | `ios/Runner/Info.plist` + App Store Connect | 5 min | Confirmer export compliance |
| L-1..L-4 | Hygiène | repo / `.gitignore` | 30 min | Nettoyage |

Aucun secret server (`SUPABASE_SERVICE_ROLE_KEY`, `REVENUECAT_WEBHOOK_AUTH`) n'a été trouvé en clair dans le code ou dans l'historique git visible.

**Avant prochain submit App Store**: traiter au minimum **C0-3** (sinon rejet immédiat) et **C0-1, C0-2** (sinon premium contournable jour 1).
