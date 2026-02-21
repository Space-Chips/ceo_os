# CEO OS Native Focus Plugin Architecture

The "Native Focus Plugin" refers to the custom Swift code implemented directly in this project to bridge Flutter with Apple's powerful Screen Time API. It is **not** a third-party package downloaded from pub.dev, but rather a bespoke integration essential for the app's core functionality.

## 1. What is it?
The native plugin is the **`FocusEngine`** class located in:
`ios/Runner/AppDelegate.swift`

## 2. What does it do?
It handles all the heavy lifting that Flutter cannot do on its own because of Apple's strict sandboxing rules:
- **Shielding Apps:** It uses the `ManagedSettings` framework to block access to specific apps and websites.
- **App Picker:** It uses the `FamilyControls` framework (via a SwiftUI bridge) to show the secure, privacy-preserving app selection screen.
- **Permissions:** It requests authorization from the user to access these sensitive controls.

## 3. Why is it "Missing"?
If you see the error:
`CRITICAL: Native focus plugin missing. Please STOP the app and run 'flutter run' again...`

It means the running instance of your app **does not contain the compiled Swift code** for the `FocusEngine`.

- **Hot Restart:** Only updates Dart/Flutter code. It *cannot* update native iOS (Swift) or Android (Kotlin) code.
- **Full Rebuild:** Running `flutter run` stops the app, recompiles the native binaries with the new Swift code, and re-installs it on the device.

## 4. Distinction from `screen_time` package
The project also includes a package named `screen_time` in `pubspec.yaml`.
- **`screen_time` (Package):** Used solely for *reading* usage statistics (how long you spent on apps).
- **`FocusEngine` (Custom):** Used for *controlling* access (blocking apps and picking them).

Both require a full rebuild to function correctly if they were added or modified recently.
