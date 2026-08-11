# CEO OS

CEO OS is a Flutter mobile app focused on self-control, planning, and digital wellbeing.
Its core submission-sensitive features include:
- Screen Time / Family Controls flows on iOS
- app and website blocking flows
- focus sessions, planned pauses, and daily limits
- account, sync, and premium flows

## Project status

The app is in release-hardening mode for store submission.
Recent work has focused on:
- permanent account deletion
- removal of debug-only release surfaces
- Apple-compliant subscription disclosures
- privacy and permission wording alignment
- cleaner authentication flows
- Family Controls review prep
- isolating iOS Screen Time / Device Activity data to the on-device individual flow

## Useful docs

- Apple review packet: [/Users/timo/ceo_os/docs/app_store_submission_packet.md](/Users/timo/ceo_os/docs/app_store_submission_packet.md)
- Store checklist: [/Users/timo/ceo_os/docs/store_submission_checklist_blocking_stack.md](/Users/timo/ceo_os/docs/store_submission_checklist_blocking_stack.md)
- Review notes and disclosures: [/Users/timo/ceo_os/docs/store_review_notes_and_disclosures.md](/Users/timo/ceo_os/docs/store_review_notes_and_disclosures.md)
- Real-device validation plan: [/Users/timo/ceo_os/docs/real_device_test_plan_blocking_stack.md](/Users/timo/ceo_os/docs/real_device_test_plan_blocking_stack.md)

## Local development

### Requirements
- Flutter `^3.41.1`
- Dart `^3.11.0`

### Install
```bash
flutter pub get
```

### Run
```bash
flutter run
```

### Analyze
```bash
dart analyze
```

### Test
```bash
flutter test
```

## Release notes

Before any store submission, do not skip:
- real-device validation of the blocking stack
- deployment of required backend functions and purchase configuration
- App Store Connect / Play Console privacy answers aligned with the real app behavior

The repo contains submission copy and checklists, but store metadata still needs to be entered manually in the relevant consoles.
