import '../../../../core/network/api_client.dart';
import 'cdc_issue_page.dart';
import 'wg_issue_summary.dart';
import 'working_group_issue.dart';

/// CDC endpoints used by the CDC Issue Matrix's existing card layout.
/// Supply AuthRepository.apiClient to reuse the current authenticated session.
class CdcIssueMatrixRepository {
  CdcIssueMatrixRepository(
    this._api, {
    Set<String> wrappedListEndpoints = const {},
  }) : wrappedListEndpoints = Set.unmodifiable(wrappedListEndpoints);

  final ApiClient _api;

  /// Set endpoints explicitly when their data envelope contains {items: [...]}
  /// instead of a direct array. Each dropdown makes one GET request.
  final Set<String> wrappedListEndpoints;

  Future<WgIssueSummary> getSummary() async {
    const endpoint = 'issues/summary';
    final data = await _api.get(endpoint);
    try {
      return WgIssueSummary.fromJson(data);
    } on FormatException {
      throw const ApiException(
        'Invalid CDC issue summary.',
        endpoint: endpoint,
      );
    }
  }

  Future<CdcIssuePage> getIssues({int page = 1, int limit = 50}) async {
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'Must be positive');
    }
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive');
    }
    const endpoint = 'issues';
    final response = await _api.getListPage(
      endpoint,
      query: {'page': '$page', 'limit': '$limit'},
    );
    try {
      if (response['meta'] is! Map<String, dynamic>) {
        throw const FormatException('Missing CDC pagination metadata');
      }
      return CdcIssuePage.fromJson({
        'items': response['data'],
        'pagination': response['meta'],
      });
    } on FormatException {
      throw const ApiException('Invalid CDC issue page.', endpoint: endpoint);
    }
  }

  /// Loads server pages for the existing scrolling list without demo fallback.
  Future<List<WorkingGroupIssue>> getDisplayIssues() async {
    final first = await getIssues();
    final records = [...first.items];
    for (var page = 2; page <= first.totalPages; page++) {
      records.addAll((await getIssues(page: page)).items);
    }
    try {
      final issues = <WorkingGroupIssue>[];
      // Some list responses omit attachment relations. Missing fields must not
      // be interpreted as a confirmed count of zero. Limit concurrent requests.
      for (var start = 0; start < records.length; start += 6) {
        issues.addAll(
          await Future.wait(
            records.skip(start).take(6).map((record) async {
              final issue = _displayIssue(record);
              if (!record.containsKey('attachment') ||
                  (record['attachment'] == null &&
                      record['attachmentId'] != null)) {
                final detail = await getIssue(issue.id);
                return _displayIssue({
                  ...record,
                  'attachment': detail['attachment'],
                });
              }
              return issue;
            }),
          ),
        );
      }
      return List.unmodifiable(issues);
    } on FormatException {
      throw const ApiException(
        'Invalid CDC issue records.',
        endpoint: 'issues',
      );
    }
  }

  Future<WorkingGroupIssue> getDisplayIssue(int issueId) async {
    final record = await getIssue(issueId);
    try {
      return _displayIssue(record);
    } on FormatException {
      throw ApiException(
        'Invalid CDC issue detail.',
        endpoint: 'issues/$issueId',
      );
    }
  }

  WorkingGroupIssue _displayIssue(Map<String, dynamic> record) {
    final primary = record['primaryAgency'];
    final agencies = record['governmentAgencies'];
    return WorkingGroupIssue.fromJson({
      ...record,
      'id': record['issueId'] ?? record['id'],
      'issueStatus': record['status'] ?? record['issueStatus'],
      'stakeholder': record['workingGroup'] ?? record['stakeholder'],
      'createdAt': record['submittedAt'] ?? record['createdAt'],
      if (primary is Map<String, dynamic>)
        'governmentAgencies': [
          {'agencyOrder': 0, 'stakeholder': primary['stakeholder'] ?? primary},
        ]
      else if (agencies is List)
        'governmentAgencies': agencies.map((agency) {
          if (agency is! Map<String, dynamic>) {
            throw const FormatException('Invalid CDC agency');
          }
          return {...agency, 'stakeholder': agency['stakeholder'] ?? agency};
        }).toList(),
    });
  }

  /// Keeps all server fields, including attachment and RGC decision data.
  Future<Map<String, dynamic>> getIssue(int issueId) async {
    if (issueId < 1) {
      throw ArgumentError.value(issueId, 'issueId', 'Must be positive');
    }
    return Map.unmodifiable(await _api.get('issues/$issueId'));
  }

  Future<List<Map<String, dynamic>>> getWorkingGroups() =>
      _records('stakeholders/working-groups');

  Future<List<Map<String, dynamic>>> getGovernmentAgencies() =>
      _records('working-group-issues/government-agencies');

  Future<List<Map<String, dynamic>>> getStatuses() =>
      _records('working-group-issues/statuses');

  Future<Map<String, dynamic>> getDictionary({String language = 'km'}) async {
    if (language.trim().isEmpty) {
      throw ArgumentError.value(language, 'language', 'Must not be empty');
    }
    return Map.unmodifiable(
      await _api.get(
        'translations/dictionary',
        query: {'language': language, 'module': 'cdc', 'page': 'issue-matrix'},
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _records(String endpoint) async {
    final Object? data = wrappedListEndpoints.contains(endpoint)
        ? (await _api.get(endpoint))['items']
        : await _api.getList(endpoint);
    if (data is! List || data.any((item) => item is! Map<String, dynamic>)) {
      throw ApiException('Invalid CDC dropdown data.', endpoint: endpoint);
    }
    return List.unmodifiable(
      data.map(
        (item) =>
            Map<String, dynamic>.unmodifiable(item as Map<String, dynamic>),
      ),
    );
  }
}
