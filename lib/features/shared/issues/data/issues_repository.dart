import '../../../../core/network/api_client.dart';
import 'wg_issue_summary.dart';
import 'working_group_issue.dart';
import 'dart:typed_data';

class IssuesRepository {
  IssuesRepository(this._api);

  final ApiClient _api;

  Future<List<WorkingGroupIssue>> getMyWorkingGroupIssues() async {
    final data = await _api.get('working-group-issues/my');
    try {
      final items = data['items'];
      if (items is! List) throw const FormatException();
      return List.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) throw const FormatException();
          return WorkingGroupIssue.fromJson(item);
        }),
      );
    } on FormatException {
      throw const ApiException('The server returned invalid issue data.');
    }
  }

  Future<List<WorkingGroupIssue>> getIssueMatrix() async {
    try {
      final issues = <WorkingGroupIssue>[];
      var totalPages = 1;
      for (var page = 1; page <= totalPages; page++) {
        final response = await _api.getObjectPage(
          'working-group-issues/issue-matrix',
          query: {'limit': '50', 'page': '$page'},
        );
        final data = response['data'] as Map<String, dynamic>;
        final items = data['items'];
        if (items is! List) throw const FormatException();
        final meta = data['meta'] ?? response['meta'];
        if (meta != null) {
          if (meta is! Map<String, dynamic> ||
              meta['totalPages'] is! int ||
              (meta['totalPages'] as int) < 0) {
            throw const FormatException();
          }
          if (page == 1) totalPages = meta['totalPages'] as int;
        }
        issues.addAll(
          items.map((item) {
            if (item is! Map<String, dynamic>) throw const FormatException();
            return WorkingGroupIssue.fromJson(item);
          }),
        );
      }
      return List.unmodifiable(issues);
    } on FormatException {
      throw const ApiException(
        'The server returned invalid issue matrix data.',
      );
    } on TypeError {
      throw const ApiException(
        'The server returned invalid issue matrix data.',
      );
    }
  }

  Future<WorkingGroupIssue> getIssue(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    final data = await _api.get('working-group-issues/$id');
    try {
      return WorkingGroupIssue.fromJson(data);
    } on FormatException {
      throw ApiException(
        'Invalid working group issue detail.',
        endpoint: 'working-group-issues/$id',
      );
    }
  }

  Future<Map<String, dynamic>> getMatrixFilterOptions() =>
      _api.get('working-group-issues/issue-matrix/filter-options');

  Future<List<Map<String, dynamic>>> getStatuses() =>
      _dropdown('working-group-issues/statuses');
  Future<List<Map<String, dynamic>>> getCategories() =>
      _dropdown('working-group-issues/categories');
  Future<List<Map<String, dynamic>>> getGovernmentAgencies() =>
      _dropdown('working-group-issues/government-agencies');

  Future<List<Map<String, dynamic>>> _dropdown(String path) async {
    final data = await _api.getList(path);
    if (data.any((item) => item is! Map<String, dynamic>)) {
      throw ApiException('Invalid issue dropdown data.', endpoint: path);
    }
    return List.unmodifiable(
      data.map(
        (item) =>
            Map<String, dynamic>.unmodifiable(item as Map<String, dynamic>),
      ),
    );
  }

  Future<Map<String, dynamic>> getMatrixDictionary({
    String module = 'cdc',
    String language = 'km',
  }) => _api.get(
    'translations/dictionary',
    query: {'module': module, 'page': 'issue_matrix', 'language': language},
  );

  /// Returns XLSX bytes using the authenticated session. Does not save a file.
  Future<Uint8List> exportMatrix({Map<String, String> query = const {}}) =>
      _api.getBytes('working-group-issues/issue-matrix/export', query: query);

  Future<WgIssueSummary> getMyWorkingGroupSummary() async {
    final data = await _api.get('working-group-issues/summary/my');
    try {
      return WgIssueSummary.fromJson(data);
    } on FormatException {
      throw const ApiException(
        'The server returned invalid issue summary data.',
      );
    }
  }

  Future<WgIssueSummary> getIssueMatrixSummary() async {
    final data = await _api.get('working-group-issues/issue-matrix/summary');
    try {
      return WgIssueSummary.fromJson(data);
    } on FormatException {
      throw const ApiException(
        'The server returned invalid issue matrix summary data.',
      );
    }
  }
}
