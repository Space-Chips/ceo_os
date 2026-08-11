import 'dart:ui';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/block_list_model.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/components.dart';
import 'app_selection_sheet.dart';
import '../../components/glass_card.dart';
import '../../components/glass_input_field.dart';
import '../../components/liquid_button.dart';
import '../../components/neo_mono_text.dart';

class BlockListSheet extends StatefulWidget {
  final BlockList? blockList;
  const BlockListSheet({super.key, this.blockList});

  @override
  State<BlockListSheet> createState() => _BlockListSheetState();
}

class _BlockListSheetState extends State<BlockListSheet> {
  final _nameCtrl = TextEditingController();
  bool _adultBlocking = false;
  List<String> _blockedPackages = [];
  List<String> _blockedCategories = [];

  String _t(String key) => context.read<LanguageProvider>().t(key);

  @override
  void initState() {
    super.initState();
    final blockList = widget.blockList;
    if (blockList != null) {
      _nameCtrl.text = blockList.name;
      _adultBlocking = blockList.adultBlocking;
      _blockedPackages = List.from(blockList.blockedPackageNames);
      _blockedCategories = List.from(blockList.blockedCategories);
    }
  }

  Future<void> _openAppSelector() async {
    if (Platform.isIOS) {
      final provider = context.read<FocusProvider>();
      if (!provider.isAuthorized) {
        final granted = await provider.requestPermissions();
        if (!granted && mounted) {
          await showCupertinoDialog<void>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: Text(
                !provider.protectionStatus.isSupported
                    ? _t('ios_setup_permission_unavailable_title')
                    : provider.protectionStatus.shouldOpenSettings
                    ? _t('focus_turn_on_screen_time_access')
                    : _t('permission_required'),
              ),
              content: Text(
                !provider.protectionStatus.isSupported
                    ? _t('focus_notice_ios_runtime_unavailable')
                    : provider.protectionStatus.shouldOpenSettings
                    ? _t('focus_notice_ios_settings_off')
                    : _t('focus_notice_ios_timer_only'),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_t('ok')),
                ),
                if (provider.protectionStatus.shouldOpenSettings)
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await provider.openSystemSettings();
                    },
                    child: Text(_t('open_settings')),
                  ),
              ],
            ),
          );
          return;
        }
      }
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(_t('focus_use_screen_time_control_title')),
            content: Text(_t('focus_use_screen_time_control_body')),
            actions: [
              CupertinoDialogAction(
                child: Text(_t('ok')),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
    } else {
      // Android / Custom Dart UI
      final result = await showCupertinoModalPopup<Map<String, dynamic>>(
        context: context,
        builder: (_) => AppSelectionSheet(
          initialSelectedPackages: _blockedPackages,
          initialSelectedCategories: _blockedCategories,
        ),
      );

      if (result != null) {
        setState(() {
          _blockedPackages = result['packages'];
          _blockedCategories = result['categories'];
        });
      }
    }
  }

  void _save() {
    if (_nameCtrl.text.isEmpty) return;

    final newList = BlockList(
      id: widget.blockList?.id ?? DateTime.now().toIso8601String(),
      name: _nameCtrl.text,
      adultBlocking: _adultBlocking,
      blockedPackageNames: _blockedPackages,
      blockedCategories: _blockedCategories,
      isActive: widget.blockList?.isActive ?? false,
    );

    context.read<FocusProvider>().saveBlockList(newList);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>().languageCode;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const NeoMonoText(
                      'BLOCK_LIST_CONFIG',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 32),

                    // Name
                    GlassInputField(
                      placeholder: 'LIST_NAME (e.g. DEEP WORK)',
                      controller: _nameCtrl,
                      autofocus: widget.blockList == null,
                    ),
                    const SizedBox(height: 24),

                    // Adult Blocking
                    GestureDetector(
                      onTap: () =>
                          setState(() => _adultBlocking = !_adultBlocking),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                CupertinoIcons.exclamationmark_shield_fill,
                                color: AppColors.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ADULT_CONTENT_SHIELD',
                                    style: AppTypography.mono.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'BLOCK_NSFW_SITES',
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 10,
                                      color: AppColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CupertinoSwitch(
                              value: _adultBlocking,
                              activeColor: AppColors.primaryOrange,
                              onChanged: (v) =>
                                  setState(() => _adultBlocking = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Selection
                    GestureDetector(
                      onTap: _openAppSelector,
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                CupertinoIcons.square_grid_2x2,
                                color: AppColors.primaryOrange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BLOCKED_APPLICATIONS',
                                    style: AppTypography.mono.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _blockedPackages.isEmpty &&
                                            _blockedCategories.isEmpty
                                        ? 'TAP_TO_SELECT'
                                        : (Platform.isIOS
                                              ? 'SELECTED_CONFIGURATION'
                                              : '${_blockedPackages.length} APPS, ${_blockedCategories.length} CATEGORIES'),
                                    style: AppTypography.mono.copyWith(
                                      fontSize: 10,
                                      color: AppColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right,
                              color: AppColors.tertiaryLabel,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: LiquidButton(
                  label: 'SAVE_CONFIGURATION',
                  fullWidth: true,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
