import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit, RenderProxyBox;
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../text/html_text.dart';
import '../../translations/app_localizations.dart';

/// Displays editor HTML as formatted content, and ordinary text as ordinary text.
class EditorContent extends StatelessWidget {
  const EditorContent(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textAlign,
    this.onOverflowChanged,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;
  final ValueChanged<bool>? onOverflowChanged;

  @override
  Widget build(BuildContext context) {
    final text = htmlToPlainText(data);
    final html = sanitizedEditorHtml(data);
    if (!containsEditorFormatting(html)) {
      final content = Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
      if (onOverflowChanged == null || maxLines == null) return content;
      return LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: DefaultTextStyle.of(context).style.merge(style),
            ),
            maxLines: maxLines,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            textAlign: textAlign ?? TextAlign.start,
          )..layout(maxWidth: constraints.maxWidth);
          final overflowed = painter.didExceedMaxLines;
          painter.dispose();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) onOverflowChanged?.call(overflowed);
          });
          return content;
        },
      );
    }
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final content = HtmlWidget(
      html,
      baseUrl: Uri.parse(
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://admin-mis-stage.datacolabx.com/api/v1',
        ),
      ).resolve('/'),
      textStyle: effectiveStyle,
      customStylesBuilder: (element) {
        if (element.localName == 'p') return {'margin': '0 0 8px 0'};
        if (element.localName != 'mark') return null;
        final color =
            element.attributes['data-color'] ??
            element.attributes['style'] ??
            '';
        return {
          'background-color':
              editorHighlightColors.entries
                  .where((entry) => color.contains('highlight-${entry.key}'))
                  .map((entry) => entry.value)
                  .firstOrNull ??
              '#fff2b3',
        };
      },
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri == null ||
            !['http', 'https', 'mailto', 'tel'].contains(uri.scheme)) {
          return false;
        }
        try {
          if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            return true;
          }
        } catch (_) {
          // Still allow copying the link when no external handler is available.
        }
        if (!context.mounted) return false;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: SelectableText(url),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
        return true;
      },
    );
    if (maxLines == null) return content;
    // Preserve HTML formatting in collapsed previews; expanding removes the
    // height limit so lists and paragraphs can be read in full.
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(effectiveStyle.fontSize ?? 14) *
        (effectiveStyle.height ?? 1.4);
    return ClipRect(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: lineHeight * maxLines!),
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minHeight: 0,
          maxHeight: double.infinity,
          fit: OverflowBoxFit.deferToChild,
          child: onOverflowChanged == null
              ? content
              : _EditorOverflowReporter(
                  maxHeight: lineHeight * maxLines!,
                  onChanged: onOverflowChanged!,
                  child: content,
                ),
        ),
      ),
    );
  }
}

class _EditorOverflowReporter extends SingleChildRenderObjectWidget {
  const _EditorOverflowReporter({
    required this.maxHeight,
    required this.onChanged,
    required super.child,
  });
  final double maxHeight;
  final ValueChanged<bool> onChanged;

  @override
  _RenderEditorOverflowReporter createRenderObject(BuildContext context) =>
      _RenderEditorOverflowReporter(maxHeight, onChanged);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEditorOverflowReporter renderObject,
  ) {
    renderObject.maxHeight = maxHeight;
    renderObject.onChanged = onChanged;
    renderObject.markNeedsLayout();
  }
}

class _RenderEditorOverflowReporter extends RenderProxyBox {
  _RenderEditorOverflowReporter(this.maxHeight, this.onChanged);
  double maxHeight;
  ValueChanged<bool> onChanged;
  bool? _lastOverflow;

  @override
  void performLayout() {
    super.performLayout();
    final overflowed = size.height > maxHeight + .5;
    if (_lastOverflow != overflowed) {
      _lastOverflow = overflowed;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onChanged(overflowed),
      );
    }
  }
}

class ExpandableEditorContent extends StatefulWidget {
  const ExpandableEditorContent(
    this.data, {
    super.key,
    this.style,
    this.collapsedLines = 5,
    this.buttonStyle,
  });
  final String data;
  final TextStyle? style;
  final int collapsedLines;
  final ButtonStyle? buttonStyle;
  @override
  State<ExpandableEditorContent> createState() =>
      _ExpandableEditorContentState();
}

class _ExpandableEditorContentState extends State<ExpandableEditorContent> {
  bool _expanded = false;
  bool _canExpand = false;

  @override
  void didUpdateWidget(covariant ExpandableEditorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _expanded = false;
  }

  void _overflowChanged(bool value) {
    if (mounted && _canExpand != value) setState(() => _canExpand = value);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = DefaultTextStyle.of(context).style.merge(widget.style);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorContent(
            widget.data,
            style: style,
            maxLines: _expanded ? null : widget.collapsedLines,
            overflow: TextOverflow.ellipsis,
            onOverflowChanged: _overflowChanged,
          ),
          if (_canExpand)
            TextButton(
              style: widget.buttonStyle,
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                AppLocalizations.of(
                  context,
                ).text(_expanded ? 'showLess' : 'readMore'),
              ),
            ),
        ],
      );
    },
  );
}
