import 'package:flutter/material.dart';

import 'package:barberia/features/booking/data/mock_models.dart';

class SlotChip extends StatelessWidget {
  const SlotChip({
    required this.slot,
    super.key,
    this.isSelected = false,
    this.onTap,
  });
  final Slot slot;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) => FilterChip(
    label: Text(
      '${slot.dateTime.hour}:${slot.dateTime.minute.toString().padLeft(2, '0')}',
    ),
    selected: isSelected,
    onSelected: (_) => onTap?.call(),
    backgroundColor: slot.isAvailable ? null : Colors.grey,
  );
}
