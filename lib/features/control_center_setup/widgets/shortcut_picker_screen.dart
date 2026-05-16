import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../components/liquid_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../control_center_setup_models.dart';
import 'control_center_preview.dart';
import 'fly_to_slot_overlay.dart';
import 'shortcut_card.dart';
import 'shortcut_info_sheet.dart';

class ShortcutPickerScreen extends StatefulWidget {
  final ControlCenterSetupState state;
  final void Function(ControlShortcut shortcut) onAdd;
  final VoidCallback onContinue;

  const ShortcutPickerScreen({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onContinue,
  });

  @override
  State<ShortcutPickerScreen> createState() => _ShortcutPickerScreenState();
}

class _ShortcutPickerScreenState extends State<ShortcutPickerScreen>
    with TickerProviderStateMixin {
  final List<GlobalKey> _slotKeys = List.generate(4, (_) => GlobalKey());
  final Map<String, GlobalKey> _cardKeys = {};
  int? _pulsingIndex;
  Timer? _pulseTimer;
  Timer? _autoContinueTimer;

  @override
  void didUpdateWidget(covariant ShortcutPickerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.remainingSlots > 0 && widget.state.remainingSlots == 0) {
      _autoContinueTimer?.cancel();
      _autoContinueTimer = Timer(const Duration(milliseconds: 360), () {
        if (!mounted) return;
        widget.onContinue();
      });
    }
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _autoContinueTimer?.cancel();
    super.dispose();
  }

  int _firstEmptySlotIndex(ControlCenterSetupState state) {
    final slots = state.slots;
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] == null) return i;
    }
    return 0;
  }

  Rect? _globalRectForKey(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  Future<void> _handleAdd(ControlCenterShortcutItem shortcutItem) async {
    final state = widget.state;
    if (state.remainingSlots <= 0) return;
    if (state.containsItemId(shortcutItem.id)) return;

    final targetIndex = _firstEmptySlotIndex(state);
    final fromKey = _cardKeys[shortcutItem.id];
    final fromRect = fromKey == null ? null : _globalRectForKey(fromKey);
    final toRect = _globalRectForKey(_slotKeys[targetIndex]);

    widget.onAdd(shortcutItem.shortcut);

    if (!mounted) return;
    setState(() => _pulsingIndex = targetIndex);
    _pulseTimer?.cancel();
    _pulseTimer = Timer(const Duration(milliseconds: 460), () {
      if (!mounted) return;
      setState(() => _pulsingIndex = null);
    });

    if (fromRect != null && toRect != null) {
      await FlyToSlotOverlay.flyItem(
        context: context,
        vsync: this,
        from: fromRect,
        to: toRect,
        item: shortcutItem,
      );
    }
  }

  Future<void> _openInfo(ControlCenterShortcutItem item) async {
    final canAdd = widget.state.remainingSlots > 0 &&
        !widget.state.containsItemId(item.id);
    await showCupertinoModalPopup<void>(
      context: context,
      barrierColor: AppColors.background.withValues(alpha: 0.72),
      builder: (_) => ShortcutInfoSheet(
        shortcut: item,
        canAdd: canAdd,
        onAdd: () => widget.onAdd(item.shortcut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final selectedIds = {
      for (final item in state.selectedShortcuts) item.id,
    };
    final canAddAny = state.remainingSlots > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajoute des actions rapides',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complète ton centre avec ce que tu utilises le plus.',
            style: AppTypography.subhead.copyWith(
              color: AppColors.secondaryLabel.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ControlCenterPreview(
            state: state,
            showDashboard: false,
            pulsingSlotIndex: _pulsingIndex,
            slotKeys: _slotKeys,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                for (int i = 0; i < ControlCenterCatalog.shortcuts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Builder(
                      builder: (context) {
                        final shortcut = ControlCenterCatalog.shortcuts[i];
                        final item = ControlCenterShortcutItem(shortcut);
                        final key = _cardKeys.putIfAbsent(
                          item.id,
                          () => GlobalKey(),
                        );
                        final added = selectedIds.contains(item.id);
                        return Container(
                          key: key,
                          child: ShortcutCard(
                            shortcut: item,
                            added: added,
                            canAdd: canAddAny,
                            onAdd: () => _handleAdd(item),
                            onInfo: () => _openInfo(item),
                            jigglePhase: i * 0.16,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LiquidButton(
            label: 'Continuer',
            onPressed: widget.onContinue,
          ),
          if (!canAddAny) ...[
            const SizedBox(height: 8),
            Text(
              "Tous les slots sont remplis. Tu pourras activer d'autres raccourcis plus tard depuis le menu.",
              style: AppTypography.caption1.copyWith(
                fontSize: 11,
                color: AppColors.tertiaryLabel.withValues(alpha: 0.78),
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
