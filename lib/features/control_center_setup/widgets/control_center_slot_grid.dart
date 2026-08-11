import 'package:flutter/cupertino.dart';

import '../control_center_setup_models.dart';
import 'control_center_slot.dart';

class ControlCenterSlotGrid extends StatelessWidget {
  final List<ControlCenterItem?> slots;
  final void Function(int index)? onTapEmptySlot;
  final void Function(String itemId)? onRemoveItem;
  final bool showRemove;
  final List<double>? appearProgressByIndex;
  final int? pulsingIndex;
  final List<GlobalKey>? slotKeys;

  const ControlCenterSlotGrid({
    super.key,
    required this.slots,
    this.onTapEmptySlot,
    this.onRemoveItem,
    this.showRemove = false,
    this.appearProgressByIndex,
    this.pulsingIndex,
    this.slotKeys,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedSlots = slots.take(4).toList(growable: false);
    while (normalizedSlots.length < 4) {
      normalizedSlots.add(null);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleRow = constraints.maxWidth >= 380;
        final items = <Widget>[
          for (int i = 0; i < 4; i++)
            Container(
              key: slotKeys != null && slotKeys!.length > i ? slotKeys![i] : null,
              child: _slotTile(
                index: i,
                item: normalizedSlots[i],
                appear: appearProgressByIndex != null
                    ? (appearProgressByIndex!.length > i
                        ? appearProgressByIndex![i]
                        : 1)
                    : 1,
                pulse: pulsingIndex == i,
              ),
            ),
        ];

        if (useSingleRow) {
          return Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Expanded(child: AspectRatio(aspectRatio: 1, child: items[i])),
                if (i != items.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AspectRatio(aspectRatio: 1, child: items[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(aspectRatio: 1, child: items[1]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AspectRatio(aspectRatio: 1, child: items[2]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(aspectRatio: 1, child: items[3]),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _slotTile({
    required int index,
    required ControlCenterItem? item,
    required double appear,
    required bool pulse,
  }) {
    return ControlCenterSlot(
      item: item,
      appearProgress: appear,
      pulse: pulse,
      showRemove: showRemove,
      onTap: item == null && onTapEmptySlot != null
          ? () => onTapEmptySlot!(index)
          : null,
      onRemove: item != null && onRemoveItem != null
          ? () => onRemoveItem!(item.id)
          : null,
    );
  }
}
