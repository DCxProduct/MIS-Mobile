import '../../../../core/network/api_client.dart';
import 'working_group_summary.dart';
import 'pswg_dashboard.dart';

enum DashboardScope { pswg, plenary }

class DashboardRepository {
  DashboardRepository(this._api);

  final ApiClient _api;

  Future<PswgDashboard> getLiveDashboard({
    DashboardScope scope = DashboardScope.pswg,
    int? progressReportId,
    String? year,
  }) async {
    if (progressReportId == null && year != null) {
      progressReportId = await resolveReportId(scope: scope, year: year);
    }
    final data = await _api.get(
      progressReportId == null
          ? 'dashboards/${scope.name}/live'
          : 'progress-reports/$progressReportId/dashboards/${scope.name}/final',
    );
    try {
      return PswgDashboard.fromJson(data);
    } on FormatException {
      throw const ApiException('The server returned invalid dashboard data.');
    }
  }

  /// A year without a semester uses the latest finalized semester.
  Future<int> resolveReportId({
    required DashboardScope scope,
    required String year,
  }) async {
    final saved =
        (await _api.getList(
              'dashboards/${scope.name}/saved',
              query: const {'finalOnly': 'true'},
            ))
            .whereType<Map>()
            .where(
              (row) =>
                  '${row['year']}' == year && row['progressReportId'] is int,
            )
            .toList()
          ..sort((a, b) => '${b['semester']}'.compareTo('${a['semester']}'));
    if (saved.isEmpty) {
      throw const ApiException('No published dashboard for the selected year.');
    }
    return saved.first['progressReportId'] as int;
  }

  Future<List<WorkingGroupSummary>> getWorkingGroups() async {
    final data = await _api.get('dashboards/pswg/live');
    try {
      final rows = data['byWorkingGroup'];
      if (rows is! List) throw const FormatException();
      return List.unmodifiable(
        rows.map((row) {
          if (row is! Map<String, dynamic>) throw const FormatException();
          return WorkingGroupSummary.fromJson(row);
        }),
      );
    } on FormatException {
      throw const ApiException(
        'The server returned invalid working group data.',
      );
    }
  }
}
