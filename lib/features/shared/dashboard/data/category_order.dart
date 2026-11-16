import 'working_group_summary.dart';

/// Presentation order used by the Web category chart, independent of counts
/// and display language. New categories follow in their original API order.
List<WorkingGroupSummary> sortCategoriesForDashboard(
  List<WorkingGroupSummary> categories,
) {
  const names = [
    'regulation',
    'governance',
    'procedure',
    'taxation',
    'legislation',
    'licensing',
    'market access',
    'finance',
    'policy',
    'human resources',
    'digital / it',
    'infrastructure',
    'trade',
    'customs',
    'security',
    'strategy',
    'communication',
  ];
  int rank(WorkingGroupSummary category) {
    final index = names.indexOf(category.name.trim().toLowerCase());
    return index < 0 ? names.length : index;
  }

  final indexed = categories.indexed.toList()
    ..sort((a, b) {
      final order = rank(a.$2).compareTo(rank(b.$2));
      return order == 0 ? a.$1.compareTo(b.$1) : order;
    });
  return [for (final entry in indexed) entry.$2];
}
