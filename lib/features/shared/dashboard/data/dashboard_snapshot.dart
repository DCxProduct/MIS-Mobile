import 'dashboard_repository.dart';
import 'working_group_summary.dart';

/// Live/final API data, including report metadata omitted by older UI models.
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.scope,
    required this.cards,
    required this.workingGroups,
    required this.agencies,
    required this.categories,
    required this.report,
    required this.generatedAt,
  });

  final DashboardScope scope;
  final Map<String, int?> cards;
  final List<WorkingGroupSummary> workingGroups, agencies, categories;
  final Map<String, dynamic>? report;
  final DateTime? generatedAt;

  factory DashboardSnapshot.fromJson(
    Map<String, dynamic> json, {
    required DashboardScope scope,
  }) {
    final source = json['cards'];
    if (source is! Map<String, dynamic>) {
      throw const FormatException('Invalid dashboard cards');
    }
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
      final value = source[key];
      final required = ![
        'totalMinistries',
        'midProgress',
        'earlyProgress',
      ].contains(key);
      if (value == null && !required) {
        cards[key] = null;
      } else if (value is int && value >= 0) {
        cards[key] = value;
      } else {
        throw FormatException('Invalid dashboard $key');
      }
    }

    List<WorkingGroupSummary> rows(String key, String idKey, String nameKey) {
      final values = json[key];
      if (values is! List) throw FormatException('Invalid $key');
      return List.unmodifiable(
        values.map((value) {
          if (value is! Map<String, dynamic>) {
            throw FormatException('Invalid $key row');
          }
          return WorkingGroupSummary.fromJson({
            ...value,
            'workingGroupId': value[idKey],
            'workingGroupName': value[nameKey],
          });
        }),
      );
    }

    final report = json['report'];
    if (report != null && report is! Map<String, dynamic>) {
      throw const FormatException('Invalid dashboard report');
    }
    final timestamp = json['generatedAt'];
    DateTime? generatedAt;
    if (timestamp != null) {
      if (timestamp is! String ||
          (generatedAt = DateTime.tryParse(timestamp)) == null) {
        throw const FormatException('Invalid dashboard generatedAt');
      }
    }
    return DashboardSnapshot(
      scope: scope,
      cards: Map.unmodifiable(cards),
      workingGroups: rows(
        'byWorkingGroup',
        'workingGroupId',
        'workingGroupName',
      ),
      agencies: rows('byPrimaryAgency', 'agencyId', 'agencyName'),
      categories: rows('byCategory', 'categoryId', 'categoryName'),
      report: report == null
          ? null
          : Map.unmodifiable(report as Map<String, dynamic>),
      generatedAt: generatedAt,
    );
  }
}
