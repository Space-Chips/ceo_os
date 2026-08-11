# UI Design Rules — ceo_os Flutter app

> **Lis ce document INTÉGRALEMENT avant de toucher au moindre fichier UI.**
> Ces règles sont le résultat d'itérations validées par le designer. Toute déviation doit être justifiée par un changement explicite de spec de sa part — pas par ta propre opinion.

---

## 0. Méthode de travail OBLIGATOIRE

### 0.1 — Toujours partir du modèle visuel

Les modèles sont des PNG dans **`/Users/timo/ceo_os/ui_audit/phone/`** :
- `01_menu.PNG` — Home/menu principal
- `02_dashboard.PNG`, `02_dashboard_bis.PNG` — Control Center (Dashboard)
- `screentime1.PNG` — Screen Time
- `habits1.PNG`, `habits2.PNG` — Habits
- `schedule1.PNG`, `schedule2.PNG`, `schedule3.PNG` — Schedule
- `todo1.PNG`, `todo2.PNG`, `todo3.PNG` — Todo
- `focus.PNG`, `focusprep1-3.PNG` — Focus
- `blackout1.PNG`, `blackout2.PNG` — Blackout
- `screentime1.PNG` — Screen Time Manager

**AVANT toute édition**, tu DOIS :
1. Charger le modèle avec `Read` ou crop avec `sips`
2. Identifier visuellement chaque élément (top→bottom)
3. Lister les helpers/widgets dans le code Dart correspondant
4. Cropper le modèle élément par élément (`sips --cropToHeightWidth H W --cropOffset Y X`) pour comparaison précise

### 0.2 — Workflow par élément

Pour CHAQUE élément (top→bottom) :

1. **Crop précis du modèle** + lire le code Dart actuel
2. **Lister les écarts** dans un tableau Markdown (modèle vs actuel)
3. **Proposer un diff** explicite avec `AskUserQuestion` (NE PAS ÉDITER AVANT VALIDATION sauf si l'utilisateur a explicitement dit "applique direct")
4. **Edit ciblé** via `Edit` tool (jamais `Write` pour modifier — `Write` est pour créer)
5. **`flutter analyze [fichier]`** pour vérifier syntax (PAS de full analyze, ça prend 5+ min)
6. **Annoncer** ce qui a été fait avec un récap tableau, demander capture HD
7. **Attendre validation visuelle** avant de passer à l'élément suivant

### 0.3 — Tracking

Utiliser `TaskCreate` / `TaskUpdate` pour tracker chaque élément comme une task séparée. Pattern :
- Task #N : `[Screen] #M — [Element name]`
- Status : `pending` → `in_progress` (avant edit) → `completed` (après validation user)

---

## 1. Standards visuels canoniques

### 1.1 — Borders (LA règle qui a tout changé)

**Toujours :**
```dart
Border.all(
  color: AppColors.border.withValues(alpha: 0.30),  // ou .glassBorder
  width: 0.5,
)
```

- **alpha 0.30** pour cards principales
- **alpha 0.40** quand l'élément doit avoir un peu plus de présence (CTA, élément actif)
- **alpha 0.22** pour les dividers fins horizontaux entre rows
- **JAMAIS** `width > 0.7` sauf justification explicite (CTA accent)
- **JAMAIS** `alpha > 0.5` sauf justification explicite

**Anti-pattern** :
```dart
// ❌ INTERDIT
Border.all(color: AppColors.white.withValues(alpha: 0.82), width: 1.2)
Border.all(color: AppColors.border, width: 0.9)  // alpha implicite 1.0
Border.all(color: AppColors.glassBorder.withValues(alpha: 0.62), width: 0.75)
```

### 1.2 — Gradient des cards glass

```dart
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    AppColors.cardBackgroundStrong.withValues(alpha: 0.72),
    AppColors.cardBase.withValues(alpha: 0.66),
  ],
)
```

Pour pilules/petits éléments :
```dart
colors: [
  AppColors.backgroundLight.withValues(alpha: 0.30),
  AppColors.surface.withValues(alpha: 0.20),
]
```

**JAMAIS** `floatingGlassGradient` (trop clair, casse la cohérence).

### 1.3 — Corner radius

| Élément | Radius |
|---|---|
| Cards principales | 22-30 |
| Pilules top bar | 18 |
| Cercles ⚡/📄/🏠 | 16 (rounded square) ou `BoxShape.circle` |
| Containers internes (icône, badge) | 10-14 |
| Dividers | n/a (height: 0.5) |

### 1.4 — Typographie

| Usage | Style |
|---|---|
| Titre d'écran (Control Center, etc.) | `largeTitle.copyWith(fontSize: 42, height: 0.95, letterSpacing: -1.4, w700)` |
| Section header (YOUR PRIORITIES, HABITS FOR TODAY, etc.) | **`.toUpperCase()`** + `overline.copyWith(fontSize: 15, letterSpacing: 1.9, w800, secondaryLabel)` |
| Card title | `headline.copyWith(fontSize: 16-22, w700, label)` |
| Subtitle | `subhead.copyWith(fontSize: 13-14, w500-w600, secondaryLabel)` |
| Number hero (29, 0m, etc.) | `timer.copyWith(fontSize: 30-64, w700, label)` |
| Caption secondaire | `caption1.copyWith(fontSize: 11, w600, tertiaryLabel)` |

**Règle ALL CAPS** :
- Les section headers sont TOUJOURS en `.toUpperCase()`
- Les petits labels descriptifs ("Start Session", "Access", "Rank") sont en **sentence case** SAUF si le modèle montre explicitement ALL CAPS
- Les labels de tile métriques ("TODAY", "7D AVG") sont en ALL CAPS quand le modèle le montre

### 1.5 — Couleurs d'icônes

| Contexte | Couleur |
|---|---|
| Icône dans cercle/pilule dark glass | `AppColors.secondaryLabel` |
| Icône dans container solid grey (action card) | `AppColors.background` (foncé contre le clair) |
| Icône trailing (→, lock, chevron) | `AppColors.tertiaryLabel.withValues(alpha: 0.85)` |
| Icône accent (CTA) | `AppColors.accentIcon` |

### 1.6 — Action cards (pattern)

```dart
GlassCard(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18-22),
  borderRadius: 18,
  border: Border.all(
    color: AppColors.glassBorder.withValues(alpha: 0.30),
    width: 0.5,
  ),
  child: Row(
    children: [
      // Icône en container SOLID (pas glass) — fond clair, icône foncée
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.secondaryLabel.withValues(alpha: 0.55),
          // PAS de border
        ),
        child: Icon(icon, color: AppColors.background, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: headline.copyWith(fontSize: 17, w700)),
            const SizedBox(height: 3),
            Text(subtitle, maxLines: 2, style: subhead.copyWith(fontSize: 13, w500, secondaryLabel)),
          ],
        ),
      ),
      const SizedBox(width: 10),
      // Trailing : juste l'icône, JAMAIS dans un container
      Icon(
        locked ? CupertinoIcons.lock : CupertinoIcons.arrow_right,
        color: AppColors.tertiaryLabel.withValues(alpha: 0.85),
        size: 18,
      ),
    ],
  ),
)
```

### 1.7 — Performance/Stats card (pattern 4 tiles)

**JAMAIS** d'outer card avec border autour des 4 tiles. Les tiles sont indépendantes.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Expanded(child: _metricTile(...)),  // chaque tile a sa propre border
        const SizedBox(width: 12),
        Expanded(child: _metricTile(...)),
      ],
    ),
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(child: _smallTile(...)),
        const SizedBox(width: 12),
        Expanded(child: _smallTile(...)),
      ],
    ),
  ],
)
```

### 1.8 — Rows avec dividers (Habits, Priorities, etc.)

```dart
for (var i = 0; i < items.length; i++) ...[
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: _itemRow(items[i], i),
  ),
  if (i < items.length - 1)
    Container(
      height: 0.5,
      color: AppColors.border.withValues(alpha: 0.22),
    ),
],
```

**JAMAIS** `.map((e) => Padding(bottom: 16))` pour les rows — ça ne permet pas les dividers et alourdit la dernière row.

### 1.9 — Sticky top bar overlay (pattern menu/dashboard)

```dart
SafeArea(
  child: Stack(
    children: [
      // Contenu scrollable avec padding top pour passer SOUS la top bar
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 60, 0, 120),  // top 60 pour la zone overlay
          children: [...],
        ),
      ),
      // Top bar overlay avec backdrop blur
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: _topBar(),
            ),
          ),
        ),
      ),
    ],
  ),
)
```

Nécessite `import 'dart:ui';` pour `ImageFilter`.

---

## 2. Anti-patterns INTERDITS

### 2.1 — `Transform.scale` + `SizedBox(designHeight)` pour fit
```dart
// ❌ INTERDIT — déforme tout sur petit écran, casse l'ergonomie
LayoutBuilder(
  builder: (ctx, constraints) {
    final scale = (constraints.maxHeight / 780).clamp(0.78, 1.0);
    return Transform.scale(
      scale: scale,
      child: SizedBox(height: 780, child: ...),
    );
  },
)
```
✅ **À la place** : `ListView` ou `Column` avec sizing naturel.

### 2.2 — Container avec border > 0.7 width
```dart
// ❌ INTERDIT
Border.all(color: AppColors.white.withValues(alpha: 0.82), width: 1.2)
```
✅ **À la place** : alpha 0.30 width 0.5 (cf. §1.1).

### 2.3 — Trailing icons dans un container
```dart
// ❌ INTERDIT pour les action cards
Container(
  width: 34, height: 34,
  decoration: BoxDecoration(border: Border.all(...), ...),
  child: Icon(CupertinoIcons.arrow_right, ...),
)
```
✅ **À la place** : juste `Icon(..., size: 18, color: tertiaryLabel.alpha(0.85))`.

### 2.4 — `.asMap().entries.map((entry) => Padding(bottom: 16))`
```dart
// ❌ INTERDIT — pas de dividers possibles, dernière row a padding inutile
..._items.asMap().entries.map((entry) => Padding(padding: EdgeInsets.only(bottom: 16), child: ...)),
```
✅ **À la place** : pattern `for ... ...[]` avec dividers conditionnels (cf. §1.8).

### 2.5 — Section header sans `.toUpperCase()`
```dart
// ❌ INTERDIT
Text('Performance', style: overline.copyWith(letterSpacing: 1.4))
```
✅ **À la place** :
```dart
Text('Performance'.toUpperCase(), style: overline.copyWith(letterSpacing: 1.4))
// OU si le modèle montre que ce header n'existe pas, le SUPPRIMER (ex: pas de "PERFORMANCE" sur screentime1)
```

### 2.6 — Icône d'action card en glass sombre
```dart
// ❌ INTERDIT — icône invisible/peu contrastée
Container(
  decoration: BoxDecoration(color: backgroundLight.alpha(0.7), border: Border.all(...)),
  child: Icon(icon, color: secondaryLabel),  // gris sur gris = nul
)
```
✅ **À la place** : container SOLID gris clair + icône foncée (cf. §1.6).

### 2.7 — `floatingGlassGradient` sur des pilules/avatars
Trop clair, casse la cohérence dark glass. Toujours préférer le gradient sombre §1.2.

---

## 3. Fichiers de référence (canonical implementations)

Avant de coder un nouveau pattern, **lire ces fichiers** pour comprendre l'implémentation existante :

| Pattern | Fichier | Lignes clés |
|---|---|---|
| Sticky top bar + ListView + BackdropFilter | `lib/features/home/home_screen.dart` | 846-960 |
| Sticky top bar (variante Dashboard) | `lib/features/dashboard/dashboard_screen.dart` | 443-470 |
| Dashboard card (titre + ring) | `lib/features/home/home_screen.dart` | 1513-1643 |
| Rows avec dividers (habits) | `lib/features/dashboard/dashboard_screen.dart` | 705-782 |
| Rows avec dividers (priorities) | `lib/features/dashboard/dashboard_screen.dart` | 789-828 |
| Section header (`_sectionHeader`) | `lib/features/dashboard/dashboard_screen.dart` | 1090-1132 |
| Panel decoration shared | `lib/features/dashboard/dashboard_screen.dart` | 1134-1165 |
| Action card pattern | `lib/features/screen_time_manager/screen_time_manager_screen.dart` | `_actionCard` |
| Glass card component | `lib/components/glass_card.dart` | toute |

---

## 4. Tokens AppColors clés

Cf. `lib/core/theme/app_colors.dart`.

| Token | Usage |
|---|---|
| `AppColors.background` | Fond de page |
| `AppColors.backgroundLight` | Léger overlay |
| `AppColors.surface` | Cards basique |
| `AppColors.cardBackgroundStrong` / `cardBase` | Gradient cards |
| `AppColors.border` / `glassBorder` | Bordures (toujours avec `.withValues(alpha: 0.30)`) |
| `AppColors.label` | Texte principal (blanc en dark mode) |
| `AppColors.secondaryLabel` | Texte secondaire (gris clair) |
| `AppColors.tertiaryLabel` | Texte tertiaire (gris) |
| `AppColors.primaryOrange` | Accent orange (errors, warnings) |
| `AppColors.success` | Vert success |
| `AppColors.activeBorder` | Border accent (CTA) |
| `AppColors.focusControlAccent` | Bleu pour Focus Mode subtitle |

**`AppColors.withValues(alpha: X)`** est l'API actuelle (depuis Flutter 3.27). Ne pas utiliser `.withOpacity(X)` (déprécié).

---

## 5. Process de validation avec l'utilisateur

### 5.1 — Avant d'éditer
- Toujours présenter le diff proposé dans un message Markdown clair
- Utiliser `AskUserQuestion` pour confirmer
- **Sauf** si l'utilisateur a explicitement dit "applique direct" / "on enchaîne" — dans ce cas tu peux éditer sans demander

### 5.2 — Après chaque edit
- Annoncer dans un tableau récap : élément modifié, avant → après
- Demander à l'utilisateur une capture HD (≥1170px de large) pour vérifier
- Attendre validation explicite avant de marquer la task `completed` et passer à la suivante

### 5.3 — Si l'utilisateur dit "Non" / corrige
- **Toujours re-lire le modèle** (souvent on découvre qu'on l'a mal interprété)
- Lister ce qu'on a raté
- Re-proposer le diff
- **Ne JAMAIS** présumer qu'on sait mieux que le modèle ou que l'utilisateur

---

## 6. Préférence utilisateur explicite

- Langue : **français** dans les messages, code/identifiants en anglais
- **JAMAIS de suppression de fichier ou de modif massive sans approbation explicite** (cf. memory `feedback_destructive_actions.md`)
- Préfère **petits diffs ciblés** plutôt que rewrite massif
- Si tu trouves du dead code après refactor (méthodes plus appelées), **mentionne-le** mais ne supprime PAS sans approbation

---

## 7. Commandes utiles

### Crop d'un modèle pour analyse
```bash
sips --cropToHeightWidth HEIGHT WIDTH --cropOffset Y X /path/to/model.PNG --out /tmp/crop.png
```
Image typique : 603×1311. Status bar ~80px. Top bar ~80-200. Body commence ~200+.

### Vérification syntax (rapide, sur 1 fichier)
```bash
flutter analyze lib/path/to/file.dart 2>&1 | grep -E "error|warning"
```
**NE JAMAIS** `flutter analyze` sans path — c'est trop long.

### Trouver un widget par mot-clé
```bash
grep -nE "class [A-Z_][A-Za-z0-9_]+ |Widget _[a-z]" lib/features/[screen]/[screen]_screen.dart
```

---

## 8. Récap des écrans déjà alignés (référence vivante)

| Écran | Fichier | Status | Notes |
|---|---|---|---|
| `01_menu` | `lib/features/home/home_screen.dart` | ✅ Aligné | Sticky overlay + cards harmonisées |
| `02_dashboard` | `lib/features/dashboard/dashboard_screen.dart` | ✅ Aligné | Sticky overlay + rows avec dividers |
| `screentime1` | `lib/features/screen_time_manager/screen_time_manager_screen.dart` | 🟡 En cours | Pas de Transform.scale, 4 tiles flottantes, action cards icône solide |
| `habits1-2` | `lib/features/habits/` | ⏳ À faire | |
| `schedule1-3` | `lib/features/calendar/` | ⏳ À faire | |
| `todo1-3` | `lib/features/tasks/` | ⏳ À faire | |
| `focus*` | `lib/features/focus/` | ⏳ À faire | |
| `blackout*` | `lib/features/ceo_mode/` | ⏳ À faire | |

Mettre à jour ce tableau après chaque écran complété.

---

**FIN DES RÈGLES.** Si quelque chose n'est pas couvert ici, demande à l'utilisateur avant d'inventer.
