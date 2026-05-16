import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../components/liquid_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../control_center_setup_models.dart';
import 'control_center_preview.dart';
import 'fly_to_slot_overlay.dart';
import 'module_card.dart';
import 'module_info_sheet.dart';

class ModulePickerScreen extends StatefulWidget {
  final ControlCenterSetupState state;
  final void Function(MainModule module) onAdd;
  final VoidCallback onContinue;

  const ModulePickerScreen({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onContinue,
  });

  @override
  State<ModulePickerScreen> createState() => _ModulePickerScreenState();
}

class _ModulePickerScreenState extends State<ModulePickerScreen>
    with TickerProviderStateMixin {
  final List<GlobalKey> _slotKeys = List.generate(4, (_) => GlobalKey());
  final Map<String, GlobalKey> _cardKeys = {};
  int? _pulsingIndex;
  Timer? _pulseTimer;

  @override
  void dispose() {
    _pulseTimer?.cancel();
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

  Future<void> _handleAdd(ControlCenterModuleItem moduleItem) async {
    if (widget.state.remainingSlots <= 0) return;
    if (widget.state.containsItemId(moduleItem.id)) return;

    final targetIndex = _firstEmptySlotIndex(widget.state);
    final fromKey = _cardKeys[moduleItem.id];
    final fromRect = fromKey == null ? null : _globalRectForKey(fromKey);
    final toRect = _globalRectForKey(_slotKeys[targetIndex]);

    widget.onAdd(moduleItem.module);

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
        item: moduleItem,
      );
    }
  }

  Future<void> _openInfo(ControlCenterModuleItem item) async {
    final canAdd = widget.state.remainingSlots > 0 &&
        !widget.state.containsItemId(item.id);
    await showCupertinoModalPopup<void>(
      context: context,
      barrierColor: AppColors.background.withValues(alpha: 0.72),
      builder: (_) => ModuleInfoSheet(
        module: item,
        canAdd: canAdd,
        onAdd: () => widget.onAdd(item.module),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final selectedIds = {
      for (final item in state.selectedModules) item.id,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisis tes apps de contrôle',
            style: AppTypography.largeTitle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoute les modules que tu veux garder à portée de main.',
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
                for (int i = 0; i < ControlCenterCatalog.mainModules.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Builder(
                      builder: (context) {
                        final module = ControlCenterCatalog.mainModules[i];
                        final item = ControlCenterModuleItem(module);
                        final key = _cardKeys.putIfAbsent(
                          item.id,
                          () => GlobalKey(),
                        );
                        return Container(
                          key: key,
                          child: ModuleCard(
                            module: item,
                            added: selectedIds.contains(item.id),
                            onAdd: () => _handleAdd(item),
                            onInfo: () => _openInfo(item),
                            jigglePhase: i * 0.18,
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
        ],
      ),
    );
  }
}
