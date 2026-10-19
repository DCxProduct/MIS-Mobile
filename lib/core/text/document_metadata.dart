/// The original filename belongs to the same metadata object as its path.
String documentOriginalName(Object? metadata) {
  if (metadata is! Map) return '';
  for (final key in const ['originalName', 'name']) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
