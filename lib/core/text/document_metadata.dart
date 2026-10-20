/// Reads the name stored with the document, including plenary upload URLs.
String documentOriginalName(Object? metadata) {
  if (metadata is Map) {
    for (final key in const ['originalName', 'name']) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    metadata = metadata['path'];
  }
  if (metadata is String) {
    try {
      return Uri.parse(metadata).queryParameters['originalName']?.trim() ?? '';
    } on FormatException {
      // Older uploads may contain an unescaped path or query value.
      return '';
    }
  }
  return '';
}
