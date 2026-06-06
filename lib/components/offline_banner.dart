import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../core/providers/connectivity_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Compact glass pill that surfaces when the device is offline.
/// Subtle by design — uses the canonical glass-card aesthetic so it
/// blends with the rest of the app rather than shouting.
class OfflineBanner extends StatelessWidget {
  /// Whether to pad above for status bar / safe area.
  final bool useSafeArea;

  const OfflineBanner({super.key, this.useSafeArea = false});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();
    if (conn.isOnline || !conn.initialized) {
      return const SizedBox.shrink();
    }
    final pill = Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.cardBackgroundStrong.withValues(alpha: 0.54),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.30),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.wifi_slash,
                size: 12,
                color: AppColors.secondaryLabel,
              ),
              const SizedBox(width: 6),
              Text(
                'Hors-ligne',
                style: AppTypography.overline.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  color: AppColors.secondaryLabel,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!useSafeArea) return pill;
    return SafeArea(bottom: false, child: pill);
  }
}
