import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/ceo_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text('Settings', style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.sectionSpacing),
            // Profile card
            CeoCard(
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      (auth.userName ?? 'U')[0].toUpperCase(),
                      style: AppTypography.headingLarge.copyWith(
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.userName ?? 'User',
                          style: AppTypography.headingSmall),
                      Text(
                        auth.userEmail ?? 'user@example.com',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right,
                    color: AppColors.textTertiary, size: 18),
              ]),
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),

            // Preferences section
            _SectionHeader(title: 'PREFERENCES'),
            _SettingsTile(
              icon: CupertinoIcons.bell,
              label: 'Notifications',
              onTap: () {},
            ),
            _SettingsTile(
              icon: CupertinoIcons.timer,
              label: 'Pomodoro Settings',
              onTap: () {},
            ),
            _SettingsTile(
              icon: CupertinoIcons.paintbrush,
              label: 'Appearance',
              onTap: () {},
            ),
            _SettingsTile(
              icon: CupertinoIcons.globe,
              label: 'Language',
              trailing: 'English',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),

            // Data section
            _SectionHeader(title: 'DATA'),
            _SettingsTile(
              icon: CupertinoIcons.cloud,
              label: 'Backup & Sync',
              onTap: () {},
            ),
            _SettingsTile(
              icon: CupertinoIcons.arrow_down_doc,
              label: 'Export Data',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),

            // About section
            _SectionHeader(title: 'ABOUT'),
            _SettingsTile(
              icon: CupertinoIcons.info,
              label: 'About CEO OS',
              onTap: () {},
            ),
            _SettingsTile(
              icon: CupertinoIcons.shield,
              label: 'Privacy Policy',
              onTap: () {},
            ),
            _SettingsTile(
              icon: CupertinoIcons.doc_text,
              label: 'Terms of Service',
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),

            // Version
            Center(
              child: Text('CEO OS v1.0.0', style: AppTypography.caption),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: CeoCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        onTap: onTap,
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          if (trailing != null)
            Text(trailing!, style: AppTypography.caption),
          const SizedBox(width: AppSpacing.sm),
          const Icon(CupertinoIcons.chevron_right,
              size: 16, color: AppColors.textTertiary),
        ]),
      ),
    );
  }
}
