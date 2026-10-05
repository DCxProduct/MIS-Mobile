import 'package:html/dom.dart';
import 'package:html/parser.dart';

bool containsEditorHtml(String value) => RegExp(
  r'</?[a-zA-Z][a-zA-Z0-9]*(?:\s[^<>]*|\s*)/?>',
).hasMatch(decodeEditorHtml(value));

bool containsEditorFormatting(String value) => RegExp(
  r'<(?:strong|b|em|i|u|s|strike|mark|a|h[1-6]|ul|ol|li|table|img|span|blockquote|pre|code)\b|<[^>]+\bstyle\s*=',
  caseSensitive: false,
).hasMatch(decodeEditorHtml(value));

/// Some API records contain entity-escaped editor markup instead of HTML.
String decodeEditorHtml(String value) {
  for (var depth = 0; depth < 3; depth++) {
    if (RegExp(r'<[a-zA-Z][^>]*>').hasMatch(value)) break;
    final decoded = parseFragment(value).text ?? '';
    if (decoded == value || !decoded.contains('<')) break;
    value = decoded;
  }
  return value;
}

String sanitizedEditorHtml(String value) {
  final fragment = parseFragment(decodeEditorHtml(value));
  for (final element in fragment.querySelectorAll(
    'script, style, iframe, object, embed, form, input, button, meta, link',
  )) {
    element.remove();
  }
  for (final element in fragment.querySelectorAll('*')) {
    element.attributes.removeWhere((key, _) => key.toString().startsWith('on'));
    final style = element.attributes['style'];
    if (style != null) {
      // Editor theme variables are defined on the web app, not in mobile HTML.
      element.attributes['style'] = style.replaceAllMapped(
        RegExp(r'var\(--tt-color-highlight-([a-z]+)\s*(?:,[^)]*)?\)'),
        (match) => editorHighlightColors[match[1]] ?? '#fff2b3',
      );
    }
  }
  return fragment.outerHtml;
}

const editorHighlightColors = {
  'red': '#ffd6d6',
  'orange': '#ffe3c2',
  'yellow': '#fff2b3',
  'green': '#d0f0d0',
  'blue': '#cce5ff',
  'purple': '#e5d6ff',
  'pink': '#ffd6eb',
};

/// Decode entities and preserve paragraph/list boundaries without rendering HTML.
String htmlToPlainText(String html) {
  final fragment = parseFragment(sanitizedEditorHtml(html));
  String text(Node node) {
    if (node is Text) return node.data;
    if (node is Element && ['script', 'style'].contains(node.localName)) {
      return '';
    }
    final content = node.nodes.map(text).join();
    if (node is Element &&
        [
          'p',
          'li',
          'div',
          'br',
          'ol',
          'ul',
          'blockquote',
          'tr',
          'h1',
          'h2',
          'h3',
          'h4',
          'h5',
          'h6',
          'pre',
        ].contains(node.localName)) {
      return '$content\n';
    }
    return content;
  }

  return text(fragment)
      .replaceAll(RegExp(r'[ \t\r]+'), ' ')
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'\n\s*\n+'), '\n')
      .trim();
}
