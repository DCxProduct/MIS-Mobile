import '../../../../core/network/api_client.dart';
import 'dashboard_repository.dart';
import 'dashboard_snapshot.dart';

/// Additional endpoints without changing the current DashboardRepository/UI.
/// Pass the authenticated module's ApiClient so its session cookie is reused.
class DashboardEndpointsRepository {
  DashboardEndpointsRepository(
    this._api, {
    this.wrappedListEndpoints = const {},
  });

  final ApiClient _api;

  /// Endpoints returning data: {items: [...]} instead of data: [...].
  /// Set explicitly from the backend response contract; no retry/extra requests.
  final Set<String> wrappedListEndpoints;

  Future<DashboardSnapshot> getLiveDashboard({required DashboardScope scope}) =>
      _snapshot('dashboards/${scope.name}/live', scope);

  Future<List<Map<String, dynamic>>> getSavedDashboards({
    required DashboardScope scope,
  }) => _records('dashboards/${scope.name}/saved');

  Future<DashboardSnapshot> getFinalDashboard({
    required DashboardScope scope,
    required int progressReportId,
  }) {
    if (progressReportId <= 0) {
      throw ArgumentError.value(
        progressReportId,
        'progressReportId',
        'Must be positive',
      );
    }
    return _snapshot(
      'progress-reports/$progressReportId/dashboards/${scope.name}/final',
      scope,
    );
  }

  Future<List<Map<String, dynamic>>> getStatuses() =>
      _records('working-group-issues/statuses');

  Future<List<Map<String, dynamic>>> getCategories() =>
      _records('working-group-issues/categories');

  Future<List<Map<String, dynamic>>> getGovernmentAgencies() =>
      _records('working-group-issues/government-agencies');

  Future<DashboardSnapshot> _snapshot(
    String endpoint,
    DashboardScope scope,
  ) async {
    final json = await _api.get(endpoint);
    try {
      return DashboardSnapshot.fromJson(json, scope: scope);
    } on FormatException {
      throw ApiException(
        'The server returned invalid dashboard data.',
        endpoint: endpoint,
      );
    }
  }

  // Saved report/dropdown records retain all fields without guessing IDs,
  // year/semester labels, or agency-specific response field names.
  Future<List<Map<String, dynamic>>> _records(String endpoint) async {
    final Object? data = wrappedListEndpoints.contains(endpoint)
        ? (await _api.get(endpoint))['items']
        : await _api.getList(endpoint);
    if (data is! List || data.any((item) => item is! Map<String, dynamic>)) {
      throw ApiException(
        'The server returned an invalid dashboard list.',
        endpoint: endpoint,
      );
    }
    return List.unmodifiable(
      data.map(
        (item) =>
            Map<String, dynamic>.unmodifiable(item as Map<String, dynamic>),
      ),
    );
  }
}
