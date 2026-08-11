import 'package:flutter/cupertino.dart';

import '../services/focus_service.dart';

class AndroidProtectionDisclosureCopy {
  final String title;
  final String message;

  const AndroidProtectionDisclosureCopy({
    required this.title,
    required this.message,
  });
}

AndroidProtectionDisclosureCopy androidProtectionDisclosureCopyForStep(
  AndroidProtectionStep step,
) {
  switch (step) {
    case AndroidProtectionStep.overlay:
      return const AndroidProtectionDisclosureCopy(
        title: 'Overlay required',
        message:
            'WakeApp uses the overlay permission to show the blocking screen instantly when a protected app or website is opened. The overlay is only used for focus protections on this device.',
      );
    case AndroidProtectionStep.accessibility:
      return const AndroidProtectionDisclosureCopy(
        title: 'Accessibility required',
        message:
            'WakeApp uses Android Accessibility to detect when a selected distracting app or supported website is opened and to apply blocking on-device during Focus Mode, Blackout Mode, scheduled pauses, and daily-limit enforcement. It is not used for ads, hidden UI manipulation, or unrelated analytics.',
      );
    case AndroidProtectionStep.usageAccess:
      return const AndroidProtectionDisclosureCopy(
        title: 'Usage Access required',
        message:
            'WakeApp uses Usage Access to measure real time spent on selected apps and supported websites so daily limits can be enforced accurately on-device. It is not used for advertising, profiling, or unrelated analytics.',
      );
    case AndroidProtectionStep.complete:
      return const AndroidProtectionDisclosureCopy(
        title: 'Protection ready',
        message: 'Android protection access is already enabled on this device.',
      );
    case AndroidProtectionStep.unknown:
      return const AndroidProtectionDisclosureCopy(
        title: 'Android protection required',
        message:
            'WakeApp requests Android protection permissions progressively and only for on-device focus protections.',
      );
  }
}

Future<bool> showAndroidProtectionDisclosure({
  required BuildContext context,
  required Future<AndroidProtectionStep> Function() nextStep,
  String continueLabel = 'Continue',
  String cancelLabel = 'Not now',
}) async {
  final step = await nextStep();
  if (step == AndroidProtectionStep.complete) return true;
  if (!context.mounted) return false;

  final copy = androidProtectionDisclosureCopyForStep(step);
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(copy.title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(copy.message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(continueLabel),
        ),
      ],
    ),
  );

  return result ?? false;
}
