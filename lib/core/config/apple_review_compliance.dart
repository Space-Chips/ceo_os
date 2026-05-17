import 'package:flutter/foundation.dart';

/// Centralized gates for the iOS build we want to keep strictly aligned with
/// Apple's Family Controls privacy boundaries.
class AppleReviewCompliance {
  const AppleReviewCompliance._();

  static bool get isIosFamilyControlsReviewBuild =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get exposesLocalOnlyFamilyControls =>
      isIosFamilyControlsReviewBuild;

  static bool get allowCloudStatsAndAnalytics =>
      !isIosFamilyControlsReviewBuild;

  static bool get allowAdvancedStats =>
      !isIosFamilyControlsReviewBuild;

  static bool get allowSocialScreenTimeSurfaces =>
      !isIosFamilyControlsReviewBuild;
}
