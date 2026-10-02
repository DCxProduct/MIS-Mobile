import '../../../../core/network/api_client.dart';
import 'progress_report.dart';

enum ProgressReportDetailScope { report, ministry, sharedAssignment }

enum ProgressReportItemType { issue, rgcDecision }

class ProgressReportsRepository {
  ProgressReportsRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> getItemDetail(
    Map<String, dynamic> item, {
    required ProgressReportItemType type,
  }) async {
    final id = item['id'];
    if (id is! int || id <= 0) throw const ApiException('Invalid report item.');
    final endpoint = type == ProgressReportItemType.issue
        ? 'working-group-issues/$id'
        : 'rgc-decisions/$id';
    final data = await _api.get(endpoint);
    if (data['id'] != id) {
      throw const ApiException('The server returned a different record.');
    }
    // Keep this report's progress fields while supplementing the row with the
    // original record's submitter, date, documents and linked issues.
    final linked = data['issues'];
    final reportLinked = item['issues'];
    final result = <String, dynamic>{
      ...data,
      ...item,
      // A null progress field means this report has no update. Do not fill it
      // with a progress update from another report on the master record.
      'progressUpdate': item['progressUpdate'],
      'recordAttachment': data['attachment'],
    };
    if (linked is List && reportLinked is List) {
      final byId = {
        for (final issue in linked.whereType<Map<String, dynamic>>())
          issue['id']: issue,
      };
      result['issues'] = [
        for (final issue in reportLinked.whereType<Map<String, dynamic>>())
          {...?byId[issue['id']], ...issue},
      ];
    }
    return Map.unmodifiable(result);
  }

  Future<ProgressReport> getDetail(
    int id, {
    ProgressReportDetailScope scope = ProgressReportDetailScope.report,
  }) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    final endpoint = switch (scope) {
      ProgressReportDetailScope.report => 'progress-reports/$id',
      ProgressReportDetailScope.ministry =>
        'progress-reports/$id/ministries/me',
      ProgressReportDetailScope.sharedAssignment =>
        'progress-reports/assignments/$id',
    };
    final data = await _api.get(endpoint);
    try {
      // Ministry detail has an assignment ID of its own. Validate its parent
      // report ID instead of confusing the two records.
      final resourceId = scope == ProgressReportDetailScope.ministry
          ? data['progressReportId']
          : data['id'];
      if (resourceId != id) throw const FormatException();
      return ProgressReport(data);
    } on FormatException {
      throw const ApiException(
        'The server returned invalid progress report details.',
      );
    } on TypeError {
      throw const ApiException(
        'The server returned invalid progress report details.',
      );
    }
  }

  Future<List<ProgressReport>> getReports({
    Map<String, String> filters = const {},
  }) async {
    final data = await _api.getAllPages('progress-reports', query: filters);
    try {
      return List.unmodifiable(
        data.map((item) => ProgressReport(item as Map<String, dynamic>)),
      );
    } on FormatException {
      throw const ApiException('The server returned invalid progress reports.');
    } on TypeError {
      throw const ApiException('The server returned invalid progress reports.');
    }
  }
}
