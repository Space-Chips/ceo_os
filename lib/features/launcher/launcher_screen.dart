import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/launcher_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/focus_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class LauncherBlockPayload {
  final String appName;
  final String packageName;

  const LauncherBlockPayload({
    required this.appName,
    required this.packageName,
  });
}

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LauncherProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onAppTap(AndroidLaunchableApp app) async {
    if (app.isBlocked) {
      if (!mounted) return;
      context.push(
        '/launcher/block',
        extra: LauncherBlockPayload(
          appName: app.name,
          packageName: app.packageName,
        ),
      );
      return;
    }

    await context.read<LauncherProvider>().launch(app);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Consumer<LauncherProvider>(
      builder: (context, launcher, _) {
        final apps = launcher.visibleApps;
        return CupertinoPageScaffold(
          backgroundColor: AppColors.systemBackground,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WakeApp Launcher',
                        style: AppTypography.largeTitle.copyWith(
                          color: AppColors.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Blocked apps stay dimmed and open their blocking screen instead of launching.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.secondaryLabel,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CupertinoSearchTextField(
                        controller: _searchController,
                        onChanged: launcher.updateQuery,
                        placeholder: 'Search apps',
                        backgroundColor: AppColors.cardBackgroundAlt,
                        style: AppTypography.body.copyWith(
                          color: AppColors.label,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: launcher.isLoading && !launcher.isInitialized
                      ? const Center(child: CupertinoActivityIndicator())
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: apps.length,
                          itemBuilder: (context, index) {
                            final app = apps[index];
                            return _LauncherAppTile(
                              app: app,
                              onTap: () => _onAppTap(app),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LauncherAppTile extends StatelessWidget {
  final AndroidLaunchableApp app;
  final VoidCallback onTap;

  const _LauncherAppTile({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tileOpacity = app.isBlocked ? 0.42 : 1.0;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: tileOpacity,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: app.isBlocked
                      ? AppColors.border
                      : AppColors.borderStrong.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              child: Center(
                child: app.iconBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          app.iconBytes!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        CupertinoIcons.app_fill,
                        color: AppColors.secondaryLabel,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption1.copyWith(
                color: AppColors.label,
                fontSize: 12,
                fontWeight: app.isBlocked ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LauncherBlockScreen extends StatelessWidget {
  final LauncherBlockPayload payload;

  const LauncherBlockScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.chevron_back, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Launcher',
                        style: AppTypography.callout.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackgroundAlt,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: AppColors.primaryOrange,
                      size: 44,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${payload.appName} is blocked',
                      textAlign: TextAlign.center,
                      style: AppTypography.title2.copyWith(
                        color: AppColors.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'WakeApp is preventing access right now. Return to your launcher or open WakeApp to change your protections.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.secondaryLabel,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: () => context.go('/launcher'),
                        child: const Text('Return to Launcher'),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
