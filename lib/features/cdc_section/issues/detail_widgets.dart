import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../core/app_colors.dart';
import '../../../translations/app_localizations.dart';

class CdcDetailInfoValue extends StatelessWidget {
  const CdcDetailInfoValue({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
      ),
      const SizedBox(height: 8),
      Text(
        value.isEmpty ? '—' : value,
        style: TextStyle(
          fontSize: 13,
          color: color ?? AppColors.primaryText(context),
        ),
      ),
    ],
  );
}

class CdcDetailDateChip extends StatelessWidget {
  const CdcDetailDateChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.fieldBackground(context),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: AppColors.border(context)),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: const TextStyle(color: AppColors.mutedText),
          ),
          TextSpan(text: value),
        ],
      ),
      style: const TextStyle(fontSize: 12),
    ),
  );
}

class CdcDetailTextPanel extends StatefulWidget {
  const CdcDetailTextPanel({
    required this.label,
    required this.body,
    required this.collapsedLines,
    this.inlineLink = false,
  });
  final String label;
  final String body;
  final int collapsedLines;
  final bool inlineLink;

  @override
  State<CdcDetailTextPanel> createState() => _CdcDetailTextPanelState();
}

class _CdcDetailTextPanelState extends State<CdcDetailTextPanel> {
  bool _expanded = false;
  late final TapGestureRecognizer _linkRecognizer = TapGestureRecognizer()
    ..onTap = () => setState(() => _expanded = !_expanded);

  @override
  void dispose() {
    _linkRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final link = TextButton(
      onPressed: () => setState(() => _expanded = !_expanded),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent(context),
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 20),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
        textStyle: const TextStyle(
          fontSize: 13,
          decoration: TextDecoration.underline,
        ),
      ),
      child: Text(l10n.text(_expanded ? 'showLess' : 'readMore')),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.pageBackground(context),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.inlineLink && widget.body.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final style = TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: AppColors.primaryText(context),
                    );
                    final linkText = l10n.text(
                      _expanded ? 'showLess' : 'readMore',
                    );
                    var body = widget.body;
                    if (!_expanded) {
                      final painter = TextPainter(
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                        maxLines: widget.collapsedLines,
                      );
                      var start = 0;
                      var end = body.length;
                      while (start < end) {
                        final midpoint = (start + end + 1) ~/ 2;
                        painter.text = TextSpan(
                          text: '${body.substring(0, midpoint)} $linkText',
                          style: style,
                        );
                        painter.layout(maxWidth: constraints.maxWidth);
                        if (painter.didExceedMaxLines) {
                          end = midpoint - 1;
                        } else {
                          start = midpoint;
                        }
                      }
                      if (start < body.length) {
                        final prefix = body.substring(0, start);
                        final lastSpace = prefix.lastIndexOf(' ');
                        body = prefix.substring(
                          0,
                          lastSpace > 0 ? lastSpace : prefix.length,
                        );
                      }
                      painter.dispose();
                    }
                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$body '),
                          TextSpan(
                            text: linkText,
                            style: TextStyle(
                              color: AppColors.accent(context),
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _linkRecognizer,
                          ),
                        ],
                      ),
                      style: style,
                    );
                  },
                )
              else
                Text(
                  widget.body,
                  maxLines: _expanded ? null : widget.collapsedLines,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: AppColors.primaryText(context),
                  ),
                ),
              if (!widget.inlineLink && widget.body.isNotEmpty) ...[
                const SizedBox(height: 5),
                link,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
