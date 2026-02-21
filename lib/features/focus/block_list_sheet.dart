import 'dart:ui';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/block_list_model.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../components/components.dart';
import 'app_selection_sheet.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.blockList != null) {
      _nameCtrl.text = widget.blockList!.name;
      _adultBlocking = widget.blockList!.adultBlocking;
      _blockedPackages = List.from(widget.blockList!.blockedPackageNames);
      _blockedCategories = List.from(widget.blockList!.blockedCategories);
    }
  }

  Future<void> _openAppSelector() async {
    if (Platform.isIOS) {
      // Use native picker bridge via provider
      final provider = context.read<FocusProvider>();
      final tokens = await provider.selectAppsNative();
      if (tokens != null) {
        setState(() {
          // On iOS, we just get opaque tokens. We store them as "packages" for simplicity in the model.
          // In a real app, you might want separate fields or a unified ID system.
          _blockedPackages = tokens; 
        });
      } else {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('SETUP REQUIRED'),
              content: const Text(
                'To select apps on iOS, this application must be rebuilt with native extensions.\n\nPlease stop the running app and restart it using "flutter run".',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          );
        }
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
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
                    const NeoMonoText('BLOCK_LIST_CONFIG', fontSize: 18, fontWeight: FontWeight.bold),
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
                      onTap: () => setState(() => _adultBlocking = !_adultBlocking),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(CupertinoIcons.exclamationmark_shield_fill, color: AppColors.error, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ADULT_CONTENT_SHIELD', style: AppTypography.mono.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('BLOCK_NSFW_SITES', style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.secondaryLabel)),
                                ],
                              ),
                            ),
                            CupertinoSwitch(
                              value: _adultBlocking,
                              activeColor: AppColors.primaryOrange,
                              onChanged: (v) => setState(() => _adultBlocking = v),
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
                                color: AppColors.primaryOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(CupertinoIcons.square_grid_2x2, color: AppColors.primaryOrange, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('BLOCKED_APPLICATIONS', style: AppTypography.mono.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(
                                    _blockedPackages.isEmpty && _blockedCategories.isEmpty 
                                        ? 'TAP_TO_SELECT' 
                                        : (Platform.isIOS 
                                            ? 'SELECTED_CONFIGURATION' 
                                            : '${_blockedPackages.length} APPS, ${_blockedCategories.length} CATEGORIES'),
                                    style: AppTypography.mono.copyWith(fontSize: 10, color: AppColors.secondaryLabel),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(CupertinoIcons.chevron_right, color: AppColors.tertiaryLabel, size: 16),
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
