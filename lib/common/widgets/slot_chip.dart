import 'package:flutter/material.dart';

/// Visual slot states.
enum SlotChipState { available, occupied, hold, disabled }

class SlotChip extends StatelessWidget {
  const SlotChip({
    required this.label,
    required this.state,
    super.key,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final SlotChipState state;
  final bool selected;
  final VoidCallback? onTap;

  Color _background(final ColorScheme cs) {
    switch (state) {
      case SlotChipState.available:
        return cs.surfaceContainerHighest;
      case SlotChipState.occupied:
        return cs.errorContainer;
      case SlotChipState.hold:
        return cs.secondaryContainer;
      case SlotChipState.disabled:
        return cs.surfaceContainerHighest.withAlpha(102);
    }
  }

  Color _labelColor(final ColorScheme cs) {
    switch (state) {
      case SlotChipState.available:
        return cs.onSurfaceVariant;
      case SlotChipState.occupied:
        return cs.onErrorContainer;
      case SlotChipState.hold:
        return cs.onSecondaryContainer;
      case SlotChipState.disabled:
        return cs.onSurface.withAlpha(102);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return RawChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onPressed:
          state == SlotChipState.disabled || state == SlotChipState.occupied
          ? null
          : onTap,
      backgroundColor: _background(cs),
      selectedColor: cs.primaryContainer,
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: selected ? cs.onPrimaryContainer : _labelColor(cs),
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}
