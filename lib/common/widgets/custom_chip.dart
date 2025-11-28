import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  const CustomChip({
    required this.label,
    super.key,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
  });
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;

  @override
  Widget build(final BuildContext context) => FilterChip(
    label: Text(label),
    selected: isSelected,
    onSelected: (_) => onTap?.call(),
    selectedColor:
        selectedColor ?? Theme.of(context).colorScheme.primaryContainer,
    checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
  );
}
