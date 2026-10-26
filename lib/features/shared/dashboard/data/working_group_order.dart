import 'working_group_summary.dart';

/// Sorts by the Khmer working-group letter, independently of display language.
/// Unlabelled groups retain their API order after the labelled groups.
List<WorkingGroupSummary> sortWorkingGroupsByKhmerCode(
  List<WorkingGroupSummary> groups,
) {
  const letters = 'កខគឃងចឆជឈញដឋឌឍណតថទធនបផពភមយរលវសហឡអ';
  final prefix = RegExp(r'^ក្រុមការងារ\s*([ក-អ])(?=\s|[:៖]|$)');
  int rank(WorkingGroupSummary group) {
    final name = group.khmerName.replaceAll('\u200B', '').trim();
    final match = prefix.firstMatch(name);
    return match == null ? letters.length : letters.indexOf(match.group(1)!);
  }

  final indexed = groups.indexed.toList()
    ..sort((a, b) {
      final order = rank(a.$2).compareTo(rank(b.$2));
      return order == 0 ? a.$1.compareTo(b.$1) : order;
    });
  return [for (final entry in indexed) entry.$2];
}
