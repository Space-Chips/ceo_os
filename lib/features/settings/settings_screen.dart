import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../components/components.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          Positioned(
            top: 200,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withValues(alpha: 0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: CupertinoColors.transparent),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: NeoMonoText(
                  'SYSTEM_CONFIG',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: AppColors.background,
                border: null,
              ),
              SliverToBoxAdapter(
                child: Consumer2<AuthProvider, FocusProvider>(
                  builder: (context, auth, focus, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryOrange.withValues(
                                    alpha: 0.1,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primaryOrange.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: NeoMonoText(
                                    (auth.userName ?? 'U')[0].toUpperCase(),
                                    fontSize: 24,
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    NeoMonoText(
                                      auth.userName ?? 'OPERATOR',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    Text(
                                      auth.userEmail ?? 'ID_UNKNOWN',
                                      style: AppTypography.mono.copyWith(
                                        fontSize: 10,
                                        color: AppColors.tertiaryLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        _sectionHeader('FOCUS_PROTOCOLS'),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _SettingRow(
                                label: 'SESSION_DURATION',
                                trailing: NeoMonoText(
                                  '${focus.focusDurationMinutes}M',
                                  fontSize: 14,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              _divider(),
                              _SettingRow(
                                label: 'SHORT_BREAK',
                                trailing: NeoMonoText(
                                  '${focus.shortBreakMinutes}M',
                                  fontSize: 14,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              _divider(),
                              _SettingRow(
                                label: 'AUTO_START_BREAKS',
                                trailing: CupertinoSwitch(
                                  activeTrackColor: AppColors.primaryOrange,
                                  value: focus.autoStartBreaks,
                                  onChanged: (_) =>
                                      focus.toggleAutoStartBreaks(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        _sectionHeader('SYSTEM_PREFERENCES'),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _SettingRow(
                                label: 'INTERFACE_APPEARANCE',
                                trailing: const Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 16,
                                  color: AppColors.tertiaryLabel,
                                ),
                              ),
                              _divider(),
                              _SettingRow(
                                label: 'NOTIFICATION_CHANNELS',
                                trailing: const Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 16,
                                  color: AppColors.tertiaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        _sectionHeader('IDENTITY_MANAGEMENT'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            onPressed: () => auth.logout(),
                            child: NeoMonoText(
                              'TERMINATE_SESSION',
                              fontSize: 14,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: AppTypography.mono.copyWith(
        color: AppColors.secondaryLabel,
        fontSize: 10,
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _divider() => Container(
    height: 0.5,
    color: AppColors.glassBorder,
    margin: const EdgeInsets.only(left: 20),
  );
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  const _SettingRow({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: AppTypography.mono.copyWith(fontSize: 12)),
        ),
        trailing,
      ],
    ),
  );
}
