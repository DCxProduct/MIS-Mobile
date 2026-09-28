import '../../../../core/network/api_client.dart';
import 'working_group_summary.dart';
import 'pswg_dashboard.dart';

enum DashboardScope { pswg, plenary }

class DashboardRepository {
  DashboardRepository(this._api);

  final ApiClient _api;

  Future<PswgDashboard> getLiveDashboard({
    DashboardScope scope = DashboardScope.pswg,
  }) async {
    final data = await _api.get('dashboards/${scope.name}/live');
    try {
      return PswgDashboard.fromJson(data);
    } on FormatException {
      throw const ApiException('The server returned invalid dashboard data.');
    }
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
