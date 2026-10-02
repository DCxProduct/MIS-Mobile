/// Applied values are copied before editing so closing a filter keeps them intact.
class FilterSelection {
  FilterSelection([Map<String, Set<String>>? values])
    : values = {
        for (final entry in (values ?? <String, Set<String>>{}).entries)
          entry.key: {...entry.value},
      };

  final Map<String, Set<String>> values;
  Set<String> operator [](String key) => values[key] ?? const <String>{};

  /// Section IDs are the API's query names; option values are server IDs/codes.
  Map<String, String> toQuery() => {
    for (final entry in values.entries)
      if (entry.value.isNotEmpty && !entry.key.startsWith('local.'))
        entry.key: (entry.value.toList()..sort()).join(','),
  };
  bool get hasLocalFilters => values.entries.any(
    (entry) => entry.key.startsWith('local.') && entry.value.isNotEmpty,
  );
  bool matchesLocal(Map<String, Iterable<String>> record) => values.entries
      .where(
        (entry) => entry.key.startsWith('local.') && entry.value.isNotEmpty,
      )
      .every(
        (entry) => entry.value.any(
          (value) => (record[entry.key] ?? const <String>[]).any(
            (candidate) => normalize(value) == normalize(candidate),
          ),
        ),
      );
  static String normalize(String value) => value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9\u1780-\u17ff]'), '');
  static String dateValue(DateTime? date) {
    if (date == null) return 'unspecified';
    final local = date.isUtc ? date.add(const Duration(hours: 7)) : date;
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  int get count =>
      values.values.fold(0, (count, items) => count + items.length);
}

/// The stored value can differ from its localized display label.
class FilterOption {
  const FilterOption({
    required this.value,
    required this.label,
    this.enabled = true,
    this.year,
  });
  final String value;
  final String label;
  final bool enabled;

  /// Reporting year for dashboard period options.
  final String? year;
}

class FilterSection {
  const FilterSection({
    required this.id,
    required this.title,
    required this.options,
    this.columns = 1,
    this.collapsedItemCount,
    this.singleSelection = false,
    this.exclusiveValues = const {},
  }) : assert(columns > 0),
       assert(collapsedItemCount == null || collapsedItemCount > 0);

  final String id;
  final String title;
  final List<FilterOption> options;
  final int columns;
  final int? collapsedItemCount;
  final bool singleSelection;

  /// Selecting any of these values clears the other choices in this section.
  final Set<String> exclusiveValues;
}
