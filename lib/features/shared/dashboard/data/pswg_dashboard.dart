import '../../../../core/widgets/filters/filter_models.dart';
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

  PswgDashboard filtered(FilterSelection selection) {
    final statuses = selection['local.status'];
    List<WorkingGroupSummary> filterRows(
      List<WorkingGroupSummary> rows,
      String key,
    ) => [
      for (final row in rows)
        if (selection[key].isEmpty || selection[key].contains(row.name))
          WorkingGroupSummary(
            id: row.id,
            name: row.name,
            khmerName: row.khmerName,
            total: statuses.isEmpty
                ? row.total
                : (statuses.contains('SOLVED') ? row.solved : 0) +
                      (statuses.contains('IN_PROGRESS') ? row.inProgress : 0) +
                      (statuses.contains('NOT_ADDRESSED')
                          ? row.notAddressed
                          : 0),
            solved: statuses.isEmpty || statuses.contains('SOLVED')
                ? row.solved
                : 0,
            inProgress: statuses.isEmpty || statuses.contains('IN_PROGRESS')
                ? row.inProgress
                : 0,
            notAddressed: statuses.isEmpty || statuses.contains('NOT_ADDRESSED')
                ? row.notAddressed
                : 0,
          ),
    ];
    final filteredCards = {...cards};
    if (statuses.isNotEmpty &&
        [
          'solved',
          'inProgress',
          'notAddressed',
        ].every((key) => cards[key] != null)) {
      for (final entry in const {
        'SOLVED': 'solved',
        'IN_PROGRESS': 'inProgress',
        'NOT_ADDRESSED': 'notAddressed',
      }.entries) {
        if (!statuses.contains(entry.key)) filteredCards[entry.value] = 0;
      }
      filteredCards['totalIssues'] =
          filteredCards['solved']! +
          filteredCards['inProgress']! +
          filteredCards['notAddressed']!;
      if (!statuses.contains('IN_PROGRESS')) {
        for (final key in ['midProgress', 'earlyProgress']) {
          if (filteredCards[key] != null) filteredCards[key] = 0;
        }
      }
    }
    // These are independent aggregate breakdowns. They cannot be joined across
    // dimensions without issue-level data.
    return PswgDashboard(
      cards: Map.unmodifiable(filteredCards),
      workingGroups: filterRows(workingGroups, 'local.workingGroup'),
      agencies: filterRows(agencies, 'local.primaryAgency'),
      categories: filterRows(categories, 'local.category'),
    );
  }

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
            'workingGroupKhName': value[nameKey.replaceFirst('Name', 'KhName')],
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
