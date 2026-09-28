import 'package:html/dom.dart';
import 'package:html/parser.dart';

/// Decode entities and preserve paragraph/list boundaries without rendering HTML.
String htmlToPlainText(String html) {
  final fragment = parseFragment(html);
  String text(Node node) {
    if (node is Text) return node.data;
    if (node is Element && ['script', 'style'].contains(node.localName)) {
      return '';
    }
    final content = node.nodes.map(text).join();
    if (node is Element &&
        ['p', 'li', 'div', 'br', 'ol', 'ul'].contains(node.localName)) {
      return '$content\n';
    }
    return content;
  }

  return text(fragment)
      .replaceAll(RegExp(r'[ \t\r]+'), ' ')
      .replaceAll(RegExp(r'\n\s*\n+'), '\n')
      .trim();
}
