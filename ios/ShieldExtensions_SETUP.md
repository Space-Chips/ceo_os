# Shield Extensions — Xcode setup (Livraison 3)

Les 2 dossiers `ios/ShieldConfiguration/` et `ios/ShieldAction/` contiennent
chacun un `.swift` + un `Info.plist` **prêts à l'emploi** mais **pas encore
liés à un target Xcode**. Cette étape se fait manuellement dans l'UI Xcode
(éditer `project.pbxproj` à la main est trop risqué).

## Pré-requis

- Xcode 14.1+ (iOS 16 SDK)
- Family Controls Distribution déjà accordé sur ton équipe (✅ tu l'as)
- App Group `group.com.wakeapp.ceoos` déjà configuré sur le target Runner
  et les extensions existantes (LiveActivityExtension, FocusActivityMonitor,
  ScreenTimeReport)

---

## Étape 1 — Créer le **Shield Configuration Extension** target

1. **Ferme tout simulator / device run.**
2. `File → New → Target…` → iOS → **Shield Configuration Extension** → `Next`.
3. Remplis :
   - **Product Name** : `ShieldConfiguration`
   - **Team** : Timo Francois (CGXFXXRW4Q)
   - **Bundle Identifier** : laisse Xcode appliquer →
     `com.wakeapp.ceoos.ShieldConfiguration`
   - **Project** : ⚠️ **`Runner`** (pas Pods)
   - **Embed in Application** : ⚠️ **`Runner`**
4. `Finish`, puis **Activate scheme** si demandé.

### Remplacer les fichiers auto-générés

Xcode aura créé dans `ios/ShieldConfiguration/` :
- `ShieldConfigurationExtension.swift` (template auto)
- `Info.plist` (auto)

**Action** :
- **Supprime** (Move to Trash) le `ShieldConfigurationExtension.swift` auto.
- **Add Files to "Runner"…** sur `ShieldConfigurationExtension.swift` du
  dossier (celui que je viens de créer). Coche uniquement
  `ShieldConfiguration` dans Target Membership.
- Garde le `Info.plist` auto si tu veux, ou écrase-le par celui fourni
  (ils sont équivalents).

---

## Étape 2 — Créer le **Shield Action Extension** target

1. `File → New → Target…` → iOS → **Shield Action Extension** → `Next`.
2. Remplis :
   - **Product Name** : `ShieldAction`
   - **Team** : Timo Francois (CGXFXXRW4Q)
   - **Bundle Identifier** :
     `com.wakeapp.ceoos.ShieldAction`
   - **Project** : `Runner`
   - **Embed in Application** : `Runner`
3. `Finish`, puis **Activate scheme** si demandé.
4. Remplace le `ShieldActionExtension.swift` auto-généré par celui de
   `ios/ShieldAction/`, en suivant la même procédure qu'en étape 1.

---

## Étape 3 — App Group sur les 2 nouveaux targets

L'App Group doit être identique pour que les 3 acteurs (host app,
ShieldAction, FocusActivityMonitor) puissent lire/écrire les mêmes flags
de "extra time".

Pour **chacun** des nouveaux targets (`ShieldConfiguration`, `ShieldAction`) :

1. Sélectionne le target.
2. `Signing & Capabilities` → `+ Capability` → **App Groups**.
3. Coche **`group.com.wakeapp.ceoos`** (déjà créé sur les autres targets).
4. Vérifie que `Signing & Capabilities → Team` est bien `CGXFXXRW4Q`.

---

## Étape 4 — Family Controls capability

`ShieldAction` mute `ManagedSettingsStore.shield.applications` — pour ça il
faut l'entitlement Family Controls.

Pour **`ShieldAction`** uniquement (pas ShieldConfiguration) :

1. `Signing & Capabilities` → `+ Capability` → **Family Controls**.

`ShieldConfiguration` n'a pas besoin de Family Controls — il lit seulement
les tokens passés par iOS pour construire l'UI.

---

## Étape 5 — Embed Foundation Extensions

Vérifie que les 2 `.appex` sont embeddés dans Runner :

1. Target `Runner` → `Build Phases` → cherche **`Embed Foundation Extensions`**.
2. Tu dois voir, en plus des extensions existantes (CeoWidgetsExtension,
   FocusActivityMonitor, LiveActivityExtension, ScreenTimeReport) :
   - `ShieldConfiguration.appex`
   - `ShieldAction.appex`
3. Sinon click `+` et ajoute les `.appex` manquants.

---

## Étape 6 — pod install + premier build

Comme à chaque ajout de target, Xcode va bumper `objectVersion` à 70 et
casser CocoaPods. Procédure habituelle :

```bash
# 1. Ferme Xcode
# 2. Downgrade pbxproj
sed -i '' 's/objectVersion = 70;/objectVersion = 60;/' \
  ios/Runner.xcodeproj/project.pbxproj
# 3. pod install
cd ios && pod install && cd ..
# 4. Rouvre Xcode (Don't apply Recommended Settings au prompt)
open ios/Runner.xcworkspace
```

Build sur device → si tout est vert, tu peux passer à **L4** (binding Dart
pour observer le flag `wakeapp.extra_time.<token>` dans
SharedPreferences/UserDefaults app group, et schedule de re-block après
5 min via `DeviceActivityEvent` threshold).

---

## Comportement actuel (sans L4)

- L'utilisateur ouvre une app/site bloqué → iOS affiche le shield WakeApp
  (titre "Time's up", bouton orange "Get 5 more minutes", bouton "Close").
- Tap "Get 5 more minutes" → l'écran reste affiché 20 s pendant que
  `ShieldActionExtension` await sans rendu visible (Apple limit). C'est la
  friction protectrice.
- Au bout des 20 s, le token est retiré du `ManagedSettingsStore` → iOS
  laisse l'utilisateur ouvrir l'app.
- ⚠️ **Sans L4**, le re-block automatique après 5 min **n'est pas câblé**.
  L'app reste débloquée jusqu'au prochain `DeviceActivitySchedule` (= minuit
  par défaut). L4 ajoutera un `DeviceActivityEvent` threshold de 5 min qui
  remet le token dans le shield via `FocusActivityMonitorExtension`.

## Une fois L3 fait

Préviens-moi → je passe à **L4 : wiring Dart pour observer
`wakeapp.extra_time.*` + schedule de re-block via DeviceActivityEvent**.
