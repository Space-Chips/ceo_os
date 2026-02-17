import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_native/cupertino_native.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
            backgroundColor: AppColors.systemBackground,
            border: null,
          ),
          SliverToBoxAdapter(
            child: Consumer2<AuthProvider, FocusProvider>(
              builder: (context, auth, focus, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySystemBackground,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusGrouped,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.systemBlue.withValues(
                                alpha: 0.15,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (auth.userName ?? 'U')[0].toUpperCase(),
                                style: AppTypography.title2.copyWith(
                                  color: AppColors.systemBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.userName ?? 'User',
                                style: AppTypography.headline,
                              ),
                              Text(
                                auth.userEmail ?? 'user@ceoos.app',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Focus Settings
                    _sectionHeader('FOCUS SETTINGS'),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondarySystemBackground,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusGrouped,
                        ),
                      ),
                      child: Column(
                        children: [
                          _SettingRow(
                            label: 'Focus Duration',
                            trailing: Text(
                              '${focus.focusDurationMinutes} min',
                              style: AppTypography.body.copyWith(
                                color: AppColors.secondaryLabel,
                              ),
                            ),
                          ),
                          _divider(),
                          _SettingRow(
                            label: 'Short Break',
                            trailing: Text(
                              '${focus.shortBreakMinutes} min',
                              style: AppTypography.body.copyWith(
                                color: AppColors.secondaryLabel,
                              ),
                            ),
                          ),
                          _divider(),
                          _SettingRow(
                            label: 'Long Break',
                            trailing: Text(
                              '${focus.longBreakMinutes} min',
                              style: AppTypography.body.copyWith(
                                color: AppColors.secondaryLabel,
                              ),
                            ),
                          ),
                          _divider(),
                          _SettingRow(
                            label: 'Auto-start Breaks',
                            trailing: CNSwitch(
                              value: focus.autoStartBreaks,
                              onChanged: (_) => focus.toggleAutoStartBreaks(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // General
                    _sectionHeader('GENERAL'),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondarySystemBackground,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusGrouped,
                        ),
                      ),
                      child: Column(
                        children: [
                          _SettingRow(
                            label: 'Notifications',
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 16,
                              color: AppColors.tertiaryLabel,
                            ),
                          ),
                          _divider(),
                          _SettingRow(
                            label: 'Appearance',
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 16,
                              color: AppColors.tertiaryLabel,
                            ),
                          ),
                          _divider(),
                          _SettingRow(
                            label: 'Data & Sync',
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 16,
                              color: AppColors.tertiaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // About
                    _sectionHeader('ABOUT'),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondarySystemBackground,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusGrouped,
                        ),
                      ),
                      child: Column(
                        children: [
                          _SettingRow(
                            label: 'Version',
                            trailing: Text(
                              '1.0.0',
                              style: AppTypography.body.copyWith(
                                color: AppColors.tertiaryLabel,
                              ),
                            ),
                          ),
                          _divider(),
                          _SettingRow(
                            label: 'Privacy Policy',
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 16,
                              color: AppColors.tertiaryLabel,
                            ),
                          ),
                          _divider(),
                          _SettingRow(
                            label: 'Terms of Service',
                            trailing: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 16,
                              color: AppColors.tertiaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Sign out
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: AppColors.systemRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusGrouped,
                        ),
                        onPressed: () => auth.logout(),
                        child: Text(
                          'Sign Out',
                          style: AppTypography.body.copyWith(
                            color: AppColors.systemRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(
    text,
    style: AppTypography.caption2.copyWith(
      color: AppColors.secondaryLabel,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    ),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.only(left: AppSpacing.md),
    child: Container(height: 0.5, color: AppColors.separator),
  );
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  const _SettingRow({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 12,
    ),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.body)),
        trailing,
      ],
    ),
  );
}
