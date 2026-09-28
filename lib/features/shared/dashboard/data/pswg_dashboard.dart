import 'working_group_summary.dart';

class PswgDashboard {
  PswgDashboard({
    required this.cards,
    required this.workingGroups,
    required this.agencies,
    required this.categories,
  });

  final Map<String, int?> cards;
  final List<WorkingGroupSummary> workingGroups;
  final List<WorkingGroupSummary> agencies;
  final List<WorkingGroupSummary> categories;

  factory PswgDashboard.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'];
    if (rawCards is! Map<String, dynamic>) throw const FormatException();
    final cards = <String, int?>{};
    for (final key in [
      'totalIssues',
      'solved',
      'inProgress',
      'notAddressed',
      'totalPrimaryAgencies',
      'totalMinistries',
      'midProgress',
      'earlyProgress',
    ]) {
      final value = rawCards[key];
      if (value == null && (key == 'midProgress' || key == 'earlyProgress')) {
        cards[key] = null;
      } else if (value is int && value >= 0) {
        cards[key] = value;
      } else {
        throw FormatException('Invalid $key');
      }
    }
    List<WorkingGroupSummary> rows(String key, String idKey, String nameKey) {
      final values = json[key];
      if (values is! List) throw FormatException('Invalid $key');
      return List.unmodifiable(
        values.map((value) {
          if (value is! Map<String, dynamic>) throw const FormatException();
          return WorkingGroupSummary.fromJson({
            ...value,
            'workingGroupId': value[idKey],
            'workingGroupName': value[nameKey],
          });
        }),
      );
    }

    return PswgDashboard(
      cards: Map.unmodifiable(cards),
      workingGroups: rows(
        'byWorkingGroup',
        'workingGroupId',
        'workingGroupName',
      ),
      agencies: rows('byPrimaryAgency', 'agencyId', 'agencyName'),
      categories: rows('byCategory', 'categoryId', 'categoryName'),
    );
  }
}
