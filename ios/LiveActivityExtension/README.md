# Live Activity — Xcode setup (Livraison 2)

> ⚠️ **CocoaPods + Xcode 16 workaround**
> Le fichier `ios/Runner.xcodeproj/project.pbxproj` doit garder `objectVersion = 60;`
> (pas 70). CocoaPods 1.16.x utilise `xcodeproj 1.27.0` qui ne supporte pas v70.
> Si Xcode bump cette valeur lors d'un gros refactor projet, `pod install` échouera
> avec `Unable to find compatibility version string for object version '70'`.
> **Fix** : ré-éditer le fichier, repasser à `objectVersion = 60;`, relancer
> `pod install`. À surveiller jusqu'à ce que CocoaPods 1.17.x sorte.


Les fichiers Swift de ce dossier sont prêts à l'emploi mais **ne sont pas encore liés à un target Xcode**. Cette étape doit se faire dans l'UI Xcode (éditer manuellement `project.pbxproj` est trop risqué). Le tout prend ~5 min.

## Pré-requis

- Xcode 14.1+ (iOS 16.1 SDK)
- Device iOS réel 16.1+ pour tester (Live Activities ne fonctionnent **pas** sur simulator pre iOS 17)
- `flutter pub get` lancé après l'ajout de `live_activities` au `pubspec.yaml`

## Étapes

### 1. Créer le Widget Extension target

1. Ouvre `ios/Runner.xcworkspace` dans Xcode (pas `.xcodeproj`).
2. `File → New → Target…` → catégorie **iOS** → **Widget Extension** → `Next`.
3. Remplis :
   - **Product Name** : `LiveActivityExtension`
   - **Include Live Activity** : ✅ **coche cette case** (sinon il ne génère pas le squelette ActivityKit)
   - **Include Configuration Intent** : ❌ décoche
   - **Team / Bundle Identifier** : Xcode appliquera `com.wakeapp.ceoos.LiveActivityExtension` (préfixe = bundle de Runner `com.wakeapp.ceoos`)
4. `Finish`, puis **Activate scheme** si demandé.

### 2. Remplacer les fichiers auto-générés par ceux de ce dossier

Xcode aura créé ces fichiers dans `ios/LiveActivityExtension/` :
- `LiveActivityExtension.swift` (entry point auto)
- `LiveActivityExtensionLiveActivity.swift` (squelette ActivityKit auto)
- `LiveActivityExtensionAttributes.swift` (struct auto, parfois inline)
- `Info.plist` (auto)
- `Assets.xcassets` (auto)

**Action** :
- **Supprime** les fichiers `.swift` auto-générés (move to trash dans Xcode).
- **Ajoute au target** les 3 fichiers de ce dossier via `File → Add Files to "Runner"…` :
  - `LiveActivityAttributes.swift`
  - `LiveActivityExtensionBundle.swift`
  - `CeoOsSessionLiveActivity.swift`
  - Coche **uniquement** la case `LiveActivityExtension` dans "Add to targets" (pas Runner).
- Garde le `Info.plist` auto-généré.

### 3. App Group (partage state entre Runner et l'extension)

L'App Group permet au plugin `live_activities` de communiquer entre l'app et le widget. **À configurer sur les deux targets** :

1. Sélectionne le projet `Runner` en haut du Project Navigator.
2. **Target `Runner`** → `Signing & Capabilities` → `+ Capability` → `App Groups` → ajoute `group.com.wakeapp.ceoos.liveactivity` (le même ID que dans `live_activity_service.dart`).
3. **Target `LiveActivityExtension`** → `Signing & Capabilities` → `+ Capability` → `App Groups` → **coche** ce même App Group.
4. Si tu as besoin de modifier l'ID, change aussi `_appGroupId` dans `lib/core/services/live_activity_service.dart`.

### 4. Build settings (déploiement target)

`LiveActivityExtension` → `Build Settings` → `Deployment` :
- **iOS Deployment Target** : `16.1` (les Live Activities sont 16.1+)

`Runner` reste sur `16.0` (configuré dans Podfile).

### 5. Signing

`LiveActivityExtension` → `Signing & Capabilities` :
- Team : ton équipe Apple Developer
- Bundle Identifier : `com.wakeapp.ceoos.LiveActivityExtension` (préfixé par le bundle de Runner `com.wakeapp.ceoos`)
- Provisioning profile : automatique

### 6. Build & run

```bash
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter run --release   # release pour tester le rendu propre
```

## Sanity check

Au build, dans les logs Xcode, tu dois voir :
```
Building target: LiveActivityExtension
Embed Foundation Extensions
```

Si tu vois `LiveActivityExtension is not embedded` → vérifie `Runner → Build Phases → Embed Foundation Extensions` et assure-toi que `LiveActivityExtension.appex` y figure en `Embed`.

## Une fois L2 fait

Préviens-moi → je passe à **L3 : binding `FocusProvider` et `CeoModeProvider`** sur les start/end de session pour déclencher le Live Activity.
