#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PBXPROJ="$ROOT_DIR/ios/Runner.xcodeproj/project.pbxproj"

check_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "[FAIL] Missing file: $file"
    return 1
  fi
}

check_contains() {
  local file="$1"; shift
  local pattern="$1"
  if rg -q "$pattern" "$file"; then
    echo "[OK] $file contains: $pattern"
  else
    echo "[FAIL] $file missing: $pattern"
    return 1
  fi
}

main() {
  local ok=0

  check_file "$PBXPROJ" || ok=1

  local runnerEnt="$ROOT_DIR/ios/Runner/Runner.entitlements"
  local focusEnt="$ROOT_DIR/ios/FocusActivityMonitor/FocusActivityMonitor.entitlements"
  local reportEnt="$ROOT_DIR/ios/ScreenTimeReport/ScreenTimeReport.entitlements"

  check_file "$runnerEnt" || ok=1
  check_file "$focusEnt" || ok=1
  check_file "$reportEnt" || ok=1

  check_contains "$PBXPROJ" "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" || ok=1
  check_contains "$PBXPROJ" "CODE_SIGN_ENTITLEMENTS = FocusActivityMonitor/FocusActivityMonitor.entitlements;" || ok=1
  check_contains "$PBXPROJ" "CODE_SIGN_ENTITLEMENTS = ScreenTimeReport/ScreenTimeReport.entitlements;" || ok=1

  for ent in "$runnerEnt" "$focusEnt" "$reportEnt"; do
    /usr/libexec/PlistBuddy -c "Print :com.apple.security.application-groups" "$ent" >/dev/null 2>&1 \
      && echo "[OK] $ent has App Groups" \
      || { echo "[FAIL] $ent missing App Groups"; ok=1; }

    /usr/libexec/PlistBuddy -c "Print :com.apple.security.application-groups:0" "$ent" >/dev/null 2>&1 \
      && echo "[OK] $ent has at least one group id" \
      || { echo "[FAIL] $ent App Groups is empty"; ok=1; }
  done

  /usr/libexec/PlistBuddy -c "Print :com.apple.developer.family-controls" "$runnerEnt" >/dev/null 2>&1 \
    && echo "[OK] Runner has family-controls entitlement" \
    || { echo "[FAIL] Runner missing family-controls entitlement"; ok=1; }

  /usr/libexec/PlistBuddy -c "Print :com.apple.developer.family-controls" "$focusEnt" >/dev/null 2>&1 \
    && echo "[OK] Focus monitor extension has family-controls entitlement" \
    || { echo "[FAIL] Focus monitor extension missing family-controls entitlement"; ok=1; }

  /usr/libexec/PlistBuddy -c "Print :com.apple.developer.family-controls" "$reportEnt" >/dev/null 2>&1 \
    && echo "[OK] Screen report extension has family-controls entitlement" \
    || { echo "[FAIL] Screen report extension missing family-controls entitlement"; ok=1; }

  if [[ "$ok" -ne 0 ]]; then
    echo "\nAudit failed. Fix the failing items before building for device/TestFlight."
    exit 1
  fi

  echo "\nAudit passed. Next verify Apple Developer portal capability assignment for all bundle IDs."
}

main "$@"
