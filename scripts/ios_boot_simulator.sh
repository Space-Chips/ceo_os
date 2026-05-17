#!/usr/bin/env bash
set -euo pipefail

TARGET_NAME="${1:-iPhone 16e}"

find_device_udid() {
  xcrun simctl list devices available | awk -v target="$TARGET_NAME" '
    index($0, target " (") > 0 {
      if (match($0, /\(([0-9A-F-]+)\)/)) {
        print substr($0, RSTART + 1, RLENGTH - 2)
        exit
      }
    }
  '
}

UDID="$(find_device_udid)"

if [[ -z "$UDID" ]]; then
  echo "No available simulator named '$TARGET_NAME' was found."
  exit 1
fi

open -a Simulator --args -CurrentDeviceUDID "$UDID" >/dev/null 2>&1 || open -a Simulator

is_booted() {
  xcrun simctl list devices | grep -F "$UDID" | grep -F "(Booted)" >/dev/null 2>&1
}

if ! is_booted; then
  xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$UDID" -b
fi

if ! is_booted; then
  xcrun simctl boot "$UDID"
  xcrun simctl bootstatus "$UDID" -b
fi

if ! is_booted; then
  echo "Simulator failed to reach Booted state: $TARGET_NAME ($UDID)"
  exit 1
fi

echo "Simulator ready: $TARGET_NAME ($UDID)"
