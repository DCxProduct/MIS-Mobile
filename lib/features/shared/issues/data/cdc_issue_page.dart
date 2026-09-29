/// A server page of CDC issues. Records retain detail and attachment fields.
class CdcIssuePage {
  const CdcIssuePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<Map<String, dynamic>> items;
  final int page, limit, total, totalPages;

  factory CdcIssuePage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List || items.any((item) => item is! Map<String, dynamic>)) {
      throw const FormatException('Invalid CDC issue records');
    }
    final metadata = json['pagination'] ?? json;
    if (metadata is! Map<String, dynamic>) {
      throw const FormatException('Invalid CDC issue pagination');
    }
    int count(String key, int minimum) {
      final value = metadata[key];
      if (value is! int || value < minimum) {
        throw FormatException('Invalid CDC issue $key');
      }
      return value;
    }

    return CdcIssuePage(
      items: List.unmodifiable(
        items.map(
          (item) =>
              Map<String, dynamic>.unmodifiable(item as Map<String, dynamic>),
        ),
      ),
      page: count('page', 1),
      limit: count('limit', 1),
      total: count('total', 0),
      totalPages: count('totalPages', 0),
    );
  }
}
