import 'package:flutter/material.dart';

/// Reserves equal space around the title so the close button cannot cover it.
class FilterSheetHeader extends StatelessWidget {
  const FilterSheetHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.titleStyle,
  });

  final String title;
  final VoidCallback onClose;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: Row(
      children: [
        const SizedBox(width: 56),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        SizedBox(
          width: 56,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 23),
          ),
        ),
      ],
    ),
  );
}
