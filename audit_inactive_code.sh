#!/bin/bash
# Audit complet : tout code physiquement présent mais inactif
cd /Users/timo/ceo_os

echo "=========================================="
echo "A. ORPHELINS — fichiers jamais importés"
echo "=========================================="
for f in $(find lib -name "*.dart"); do
  base=$(basename "$f" .dart)
  refs=$(grep -rl "$base" lib --include="*.dart" | grep -v "^$f$" | wc -l | tr -d ' ')
  if [ "$refs" = "0" ]; then echo "ORPHAN: $f"; fi
done

echo ""
echo "=========================================="
echo "B. ROUTAGE — écrans sans route"
echo "=========================================="
echo "-- Total écrans :"
find lib -name "*_screen.dart" -o -name "*_sheet.dart" -o -name "*_modal.dart" | wc -l
echo "-- Routes définies :"
grep -rcE "GoRoute|MaterialPageRoute|CupertinoPageRoute" lib/core/router/ 2>/dev/null
echo "-- Routes listées :"
grep -rhE "path:\s*['\"][^'\"]+['\"]" lib/core/router/ 2>/dev/null
echo "-- Écrans non référencés (potentiellement non routés) :"
for f in $(find lib -name "*_screen.dart"); do
  base=$(basename "$f" .dart)
  refs=$(grep -rl "$base" lib --include="*.dart" | grep -v "^$f$" | wc -l | tr -d ' ')
  if [ "$refs" -le "1" ]; then echo "  $refs ref(s): $f"; fi
done

echo ""
echo "=========================================="
echo "C. PROVIDERS — déclarés vs enregistrés"
echo "=========================================="
echo "-- Classes Provider/ChangeNotifier déclarées :"
grep -rhE "^class (\w+(Provider|Notifier|Controller))" lib --include="*.dart" | sed -E 's/^class ([A-Za-z_]+).*/\1/' | sort -u
echo ""
echo "-- Providers présents dans main.dart :"
grep -E "Provider|Notifier" lib/main.dart | grep -oE "[A-Z][A-Za-z]+(Provider|Notifier|Controller)" | sort -u

echo ""
echo "=========================================="
echo "D. METHOD CHANNELS — Dart vs iOS vs Android"
echo "=========================================="
echo "-- Channels Dart :"
grep -rhE "MethodChannel\(['\"][^'\"]+['\"]\)" lib --include="*.dart" 2>/dev/null | grep -oE "['\"][^'\"]+['\"]" | sort -u | head -30
echo "-- Channels iOS Swift :"
grep -rhE "name:\s*\"[^\"]+\"" ios --include="*.swift" 2>/dev/null | grep -oE "\"[^\"]+\"" | sort -u | head -30
echo "-- Channels Android Kotlin :"
grep -rhE "MethodChannel\([^,]+,\s*\"[^\"]+\"" android --include="*.kt" 2>/dev/null | grep -oE "\"[^\"]+\"" | sort -u | head -30

echo ""
echo "=========================================="
echo "E. PREMIUM GATES"
echo "=========================================="
grep -rnE "if\s*\(.*?(isPremium|isUnlocked|hasPremium|requirePremium)" lib --include="*.dart" 2>/dev/null | head -15

echo ""
echo "=========================================="
echo "F. BRANCHES MORTES — if (false), if (kDebugMode)…"
echo "=========================================="
grep -rnE "if\s*\(\s*(false|kDebugMode|kReleaseMode|kProfileMode)\s*\)" lib --include="*.dart" 2>/dev/null

echo ""
echo "=========================================="
echo "G. EXCLUDES analyzer/pubspec"
echo "=========================================="
echo "-- analysis_options.yaml exclude :"
grep -A 15 "exclude:" analysis_options.yaml 2>/dev/null

echo ""
echo "=========================================="
echo "H. CACHE/PREFS qui peuvent skipper des features"
echo "=========================================="
grep -rnE "(setBool|setString|setInt)\s*\(" lib --include="*.dart" 2>/dev/null | grep -iE "onboarding|intro|seen|completed|first_(launch|run)|setup_done|tutorial" | head -20

echo ""
echo "=========================================="
echo "I. BUILD METHODS SUSPECTS — coquilles vides"
echo "=========================================="
grep -rnE "return\s+(const\s+)?(SizedBox\.shrink|SizedBox\(\)|Container\(\))\s*;" lib/features --include="*.dart" 2>/dev/null | head -20

echo ""
echo "=========================================="
echo "J. CLASSES PUBLIQUES JAMAIS INSTANCIÉES"
echo "=========================================="
for cls in $(grep -rhE "^class [A-Z]\w+" lib --include="*.dart" | sed -E 's/^class ([A-Za-z_]+).*/\1/' | sort -u | head -100); do
  if [ "${cls:0:1}" != "_" ]; then
    instances=$(grep -rE "[^A-Za-z_]$cls\s*\(" lib --include="*.dart" 2>/dev/null | grep -v "class $cls" | wc -l | tr -d ' ')
    if [ "$instances" = "0" ]; then echo "  UNUSED CLASS: $cls"; fi
  fi
done | head -30

echo ""
echo "=========================================="
echo "K. STUBS LAISSÉS PAR CODEX"
echo "=========================================="
grep -rnE "throw\s+(UnimplementedError|UnsupportedError)|return\s+(false|null|\[\]|\{\})\s*;\s*//.*(stub|todo|implement)" lib --include="*.dart" 2>/dev/null | head -20

echo ""
echo "=========================================="
echo "FIN DE L'AUDIT"
echo "=========================================="
