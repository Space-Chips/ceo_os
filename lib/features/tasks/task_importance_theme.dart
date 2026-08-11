import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';

class TaskImportanceBadgeStyle {
  final Color background;
  final Color border;
  final Color text;
  final Color glow;

  const TaskImportanceBadgeStyle({
    required this.background,
    required this.border,
    required this.text,
    required this.glow,
  });
}

class TaskImportanceCardStyle {
  final Color border;
  final Color start;
  final Color end;
  final TaskImportanceBadgeStyle badge;

  const TaskImportanceCardStyle({
    required this.border,
    required this.start,
    required this.end,
    required this.badge,
  });
}

class TaskImportanceTheme {
  TaskImportanceTheme._();

  static const Color _essentialOrange = Color(0xFFF08A32);
  static const Color _averageYellow = Color(0xFFE0B84A);

  static String label(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'crucial':
      case 'critical':
        return 'CRUCIAL';
      case 'essential':
      case 'high':
        return 'ESSENTIAL';
      case 'average':
      case 'medium':
        return 'AVERAGE';
      case 'low':
      default:
        return 'LOW';
    }
  }

  static String dashboardLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'crucial':
      case 'critical':
        return 'CRITICAL';
      case 'essential':
      case 'high':
        return 'HIGH';
      case 'average':
      case 'medium':
        return 'MEDIUM';
      case 'low':
      default:
        return 'LOW';
    }
  }

  static String detailLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'crucial':
      case 'critical':
        return 'Critical';
      case 'essential':
      case 'high':
        return 'High';
      case 'average':
      case 'medium':
        return 'Average';
      case 'low':
      default:
        return 'Low';
    }
  }

  static TaskImportanceBadgeStyle badge(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'crucial':
      case 'critical':
        return TaskImportanceBadgeStyle(
          background: AppColors.error.withValues(alpha: 0.12),
          border: AppColors.error.withValues(alpha: 0.35),
          text: AppColors.error,
          glow: AppColors.error.withValues(alpha: 0.16),
        );
      case 'essential':
      case 'high':
        return TaskImportanceBadgeStyle(
          background: _essentialOrange.withValues(
            alpha: AppColors.isDark ? 0.1 : 0.06,
          ),
          border: _essentialOrange.withValues(
            alpha: AppColors.isDark ? 0.24 : 0.16,
          ),
          text: _essentialOrange,
          glow: _essentialOrange.withValues(
            alpha: AppColors.isDark ? 0.08 : 0.04,
          ),
        );
      case 'average':
      case 'medium':
        return TaskImportanceBadgeStyle(
          background: _averageYellow.withValues(
            alpha: AppColors.isDark ? 0.095 : 0.055,
          ),
          border: _averageYellow.withValues(
            alpha: AppColors.isDark ? 0.2 : 0.14,
          ),
          text: _averageYellow,
          glow: _averageYellow.withValues(
            alpha: AppColors.isDark ? 0.07 : 0.035,
          ),
        );
      case 'low':
      default:
        final tone = Color.lerp(
          AppColors.tertiaryLabel,
          AppColors.secondaryLabel,
          AppColors.isDark ? 0.28 : 0.18,
        ) ?? AppColors.secondaryLabel;
        return TaskImportanceBadgeStyle(
          background: tone.withValues(alpha: AppColors.isDark ? 0.1 : 0.075),
          border: tone.withValues(alpha: AppColors.isDark ? 0.22 : 0.18),
          text: tone,
          glow: tone.withValues(alpha: AppColors.isDark ? 0.08 : 0.04),
        );
    }
  }

  static TaskImportanceCardStyle card(String? raw) {
    final badgeStyle = badge(raw);
    switch ((raw ?? '').toLowerCase()) {
      case 'crucial':
      case 'critical':
        return TaskImportanceCardStyle(
          border: AppColors.error.withValues(alpha: 0.4),
          start: Color.alphaBlend(
            AppColors.error.withValues(alpha: 0.04),
            AppColors.cardBackgroundAlt,
          ),
          end: AppColors.cardBase,
          badge: badgeStyle,
        );
      case 'essential':
      case 'high':
        return TaskImportanceCardStyle(
          border: badgeStyle.border.withValues(
            alpha: AppColors.isDark ? 0.42 : 0.28,
          ),
          start: Color.alphaBlend(
            badgeStyle.text.withValues(alpha: AppColors.isDark ? 0.055 : 0.022),
            AppColors.cardBackgroundAlt,
          ),
          end: AppColors.cardBase,
          badge: badgeStyle,
        );
      case 'average':
      case 'medium':
        return TaskImportanceCardStyle(
          border: badgeStyle.border.withValues(
            alpha: AppColors.isDark ? 0.36 : 0.24,
          ),
          start: Color.alphaBlend(
            badgeStyle.text.withValues(alpha: AppColors.isDark ? 0.045 : 0.018),
            AppColors.cardBackgroundAlt,
          ),
          end: AppColors.cardBase,
          badge: badgeStyle,
        );
      case 'low':
      default:
        return TaskImportanceCardStyle(
          border: badgeStyle.border.withValues(alpha: AppColors.isDark ? 0.72 : 0.86),
          start: Color.alphaBlend(
            badgeStyle.text.withValues(alpha: AppColors.isDark ? 0.05 : 0.025),
            AppColors.cardBackgroundAlt,
          ),
          end: AppColors.cardBase,
          badge: badgeStyle,
        );
    }
  }

  static Color accent(String? raw) => badge(raw).text;
}
