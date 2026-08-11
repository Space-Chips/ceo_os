# Agent A5 — Build & QA (release-readiness technique)

## Objectif
Garantir que l'app compile, est signée correctement, sans secret exposé, et prête au build de soumission. **Vérification + petits ajustements de config — pas de modif de fonctionnalité.**

## À faire
1. **Entitlements iOS** : confirmer `com.apple.developer.family-controls` présent sur TOUS les targets (Runner + extensions Shield / Monitor / ScreenTimeReport). Lister les fichiers `.entitlements` et leur contenu.
2. **Info.plist** : vérifier que toutes les usage description strings nécessaires sont présentes et honnêtes (caméra, photos, notifications, + Live Activities). Signaler tout manque.
3. **Build release sécurisé** : documenter la commande exacte avec `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` (cf. `lib/core/config/supabase_config.dart`, fallback hardcodé sinon). Vérifier qu'aucun secret réel n'est committé.
4. **Qualité** : lancer `flutter analyze` et `flutter test` ; rapporter les erreurs/échecs (NB : des warnings de strings ont été signalés en session — les documenter, ne pas les masquer).
5. **Versioning** : bump `pubspec.yaml` `version: 1.0.0+18` → `1.0.0+19` (ou supérieur).
6. **Plan de test device réel** : compiler une checklist actionnable à partir de `docs/real_device_test_plan_blocking_stack.md` (blocage Focus / CEO Mode / Screen Time + achat sandbox + restore + suppression de compte + parcours offline).

## Ne PAS toucher
- La logique applicative, les écrans, les features.

## Critères d'acceptation
- Rapport clair : entitlements OK/à corriger, Info.plist OK/manques, commande de build documentée, résultat `analyze`/`test` (vert ou blocages listés), version bumpée, checklist test device réel prête.

## Sortie attendue
- `_HUB/store/build_release_runbook.md` (commande de build + checklist pré-soumission) + rapport inline.
