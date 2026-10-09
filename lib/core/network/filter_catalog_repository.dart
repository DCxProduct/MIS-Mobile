import '../../features/shared/meetings/data/meeting_request.dart';
import '../../features/shared/meetings/data/meeting_summary.dart';
import '../../features/shared/meetings/data/calendar_meeting.dart';
import '../../features/shared/issues/data/cdc_issue_matrix_repository.dart';
import '../../features/shared/meetings/data/rgc_decision.dart';
import '../widgets/filters/filter_models.dart';
import 'api_client.dart';

/// Catalogs and query keys are endpoint-specific. Display labels never serve
/// as foreign keys, and options never come from the currently loaded page.
class FilterCatalogRepository {
  FilterCatalogRepository(this._api);
  final ApiClient _api;

  Future<List<FilterSection>> dashboard(String scope) async {
    final responses = await Future.wait([
      _api.getList('dashboards/$scope/saved'),
      _api.get('dashboards/$scope/live'),
    ]);
    final rows = responses[0] as List;
    final snapshot = responses[1] as Map;
    List<FilterOption> breakdown(String key, String nameKey) => [
      for (final row in snapshot[key] as List)
        if (row is Map && row[nameKey] is String)
          FilterOption(
            value: row[nameKey] as String,
            label: row[nameKey] as String,
          ),
    ];
    return [
      FilterSection(
        id: 'local.workingGroup',
        title: 'workingGroup',
        collapsedItemCount: 5,
        options: breakdown('byWorkingGroup', 'workingGroupName'),
      ),
      const FilterSection(
        id: 'local.status',
        title: 'status',
        columns: 3,
        options: [
          FilterOption(value: 'SOLVED', label: 'Solved'),
          FilterOption(value: 'IN_PROGRESS', label: 'In Progress'),
          FilterOption(value: 'NOT_ADDRESSED', label: 'Not Addressed'),
        ],
      ),
      FilterSection(
        id: 'local.primaryAgency',
        title: 'primaryAgency',
        columns: 5,
        collapsedItemCount: 10,
        options: breakdown('byPrimaryAgency', 'agencyName'),
      ),
      FilterSection(
        id: 'local.category',
        title: scope == 'plenary' ? 'measureCategory' : 'filterCategory',
        columns: 2,
        collapsedItemCount: 5,
        options: breakdown('byCategory', 'categoryName'),
      ),
      _strings(
        'local.year',
        'year',
        rows
            .whereType<Map>()
            .where((row) => row['year'] != null)
            .map((row) => '${row['year']}'),
        columns: 4,
        single: true,
      ),
      FilterSection(
        id: 'progressReportId',
        title: 'progressReport',
        singleSelection: true,
        columns: 2,
        options: [
          for (final row in rows)
            if (row is Map &&
                row['progressReportId'] is int &&
                row['year'] is int &&
                row['semester'] is String)
              FilterOption(
                value: '${row['progressReportId']}',
                label: '${row['semester']} ${row['year']}',
                year: '${row['year']}',
              ),
        ],
      ),
    ];
  }

  Future<List<FilterSection>> progressReports() async {
    final rows = await _allArrayPages('progress-reports');
    List<FilterOption> values(String key) => {
      for (final row in rows)
        if (row is Map && row[key] != null) '${row[key]}',
    }.map((value) => FilterOption(value: value, label: value)).toList();
    return [
      FilterSection(
        id: 'year',
        title: 'year',
        options: values('year'),
        columns: 4,
        singleSelection: true,
      ),
      FilterSection(
        id: 'semester',
        title: 'semester',
        options: values('semester'),
        columns: 2,
        singleSelection: true,
      ),
      FilterSection(
        id: 'status',
        title: 'status',
        options: values('status'),
        columns: 3,
        singleSelection: true,
      ),
    ];
  }

  Future<List<FilterSection>> meetingRequests({bool ministry = false}) async {
    final data = await _api.get('meeting-requests/filter-options');
    final records = (await _api.getAllPages(
      'meeting-requests',
      limit: 50,
    )).map((row) => MeetingRequest(row as Map<String, dynamic>)).toList();
    return [
      _section(
        'local.workingGroup',
        'workingGroup',
        data['workingGroups'],
        valueKey: 'name',
        collapsed: 5,
      ),
      _section(
        'local.primaryAgency',
        'primaryAgency',
        data['governmentAgencies'],
        valueKey: 'name',
        columns: 5,
        collapsed: 10,
      ),
      _strings(
        'local.status',
        'status',
        (data['statuses'] as List).cast<String>(),
        columns: 3,
      ),
      if (ministry)
        _strings(
          'local.year',
          'year',
          records.expand((item) => item.filterValues['local.year']!),
          columns: 4,
        ),
      if (ministry)
        _strings(
          'local.issueCount',
          'numberOfIssues',
          records.map((item) => '${item.issuesCount}'),
          columns: 4,
        ),
      _strings(
        'local.date',
        'meetingDate',
        records.map((item) => FilterSelection.dateValue(item.meetingDate)),
        columns: 2,
        collapsed: 4,
      ),
    ];
  }

  Future<List<FilterSection>> meetingSummaries() async {
    final rows = (await _api.getAllPages(
      'meeting-summaries',
      objectItems: true,
    )).map((row) => MeetingSummary(row as Map<String, dynamic>)).toList();
    return [
      _strings(
        'local.status',
        'status',
        rows.map((item) => item.status),
        columns: 3,
      ),
      _strings(
        'local.year',
        'year',
        rows.expand((item) => item.filterValues['local.year']!),
        columns: 4,
      ),
      _strings(
        'local.issueCount',
        'numberOfIssues',
        rows.map((item) => '${item.issueCount}'),
        columns: 4,
      ),
    ];
  }

  Future<List<FilterSection>> meetings() async {
    final records = (await _api.getAllPages('meetings', objectItems: true))
        .map(
          (row) =>
              CalendarMeeting.fromJson(row as Map<String, dynamic>).details,
        )
        .toList();
    return [
      _strings(
        'local.workingGroup',
        'workingGroup',
        records.expand((item) => item.groupNames),
        collapsed: 5,
      ),
      _strings(
        'local.primaryAgency',
        'primaryAgency',
        records.expand((item) => item.agencyNames),
        columns: 5,
        collapsed: 10,
      ),
      _strings(
        'status',
        'status',
        records.map((item) => item.status),
        columns: 3,
        single: true,
      ),
      _strings(
        'local.year',
        'year',
        records.expand((item) => item.filterValues['local.year']!),
        columns: 4,
      ),
      _strings(
        'local.issueCount',
        'numberOfIssues',
        records.map((item) => '${item.issuesCount}'),
        columns: 4,
      ),
      _strings(
        'local.date',
        'meetingDate',
        records.map((item) => FilterSelection.dateValue(item.meetingDate)),
        columns: 2,
        collapsed: 4,
      ),
    ];
  }

  Future<List<FilterSection>> plenaries({bool sentOnly = false}) async {
    final rows = await _allPlenaries(sentOnly: sentOnly);
    final statuses = {
      for (final row in rows)
        if (row is Map &&
            row['status'] is String &&
            (!sentOnly ||
                (row['statusCode'] ?? row['status'])
                        .toString()
                        .trim()
                        .toUpperCase() ==
                    'SENT'))
          row['status'] as String,
    };
    final ministries = await _api.get('plenaries/lookups/ministries');
    return [
      FilterSection(
        id: 'statuses',
        title: 'status',
        columns: 2,
        options: [
          for (final value in statuses)
            FilterOption(value: value.trim().toUpperCase(), label: value),
        ],
      ),
      _section(
        'ministryIds',
        'primaryAgency',
        ministries['items'],
        columns: 3,
        collapsed: 9,
      ),
    ];
  }

  Future<List<dynamic>> _allArrayPages(String endpoint) =>
      _api.getAllPages(endpoint);

  Future<List<FilterSection>> pswgIssues({required bool matrix}) async {
    final sections = await issues(matrix: matrix);
    final reports = await _api.getAllPages('progress-reports');
    final semesters = {
      for (final row in reports)
        if (row is Map && row['semester'] is String) row['semester'] as String,
    };
    return [
      sections.firstWhere((section) => section.id == 'years'),
      sections.firstWhere((section) => section.id == 'issueStatusIds'),
      FilterSection(
        id: 'primaryAgencyIds',
        title: 'primaryAgency',
        columns: 5,
        collapsedItemCount: 10,
        options: sections
            .firstWhere((section) => section.id == 'primaryAgencyIds')
            .options,
      ),
      FilterSection(
        id: 'local.semester',
        title: 'progressReport',
        columns: 3,
        exclusiveValues: const {'Both'},
        options: [
          const FilterOption(value: 'Both', label: 'Both'),
          for (final semester in semesters)
            FilterOption(value: semester, label: semester),
        ],
      ),
    ];
  }

  Future<List<FilterSection>> issues({
    required bool matrix,
    bool cdcDesign = false,
  }) async {
    final data = await _api.get(
      'working-group-issues/${matrix ? 'issue-matrix' : 'my'}/filter-options',
    );
    return [
      _section(
        'categoryIds',
        cdcDesign ? 'filterCategory' : 'categories',
        data['categories'],
        columns: 2,
        collapsed: 5,
      ),
      _section('issueStatusIds', 'status', data['statuses'], columns: 3),
      if (cdcDesign)
        _section(
          'local.pswgs',
          'allPswgs',
          data['workingGroups'] ??
              await _api.getList('stakeholders/working-groups'),
          collapsed: 5,
          valueKey: 'name',
        )
      else
        _section(
          'primaryAgencyIds',
          'primaryAgency',
          data['governmentAgencies'],
          columns: 3,
          collapsed: 9,
        ),
      _section('years', 'year', data['years'], columns: 4),
      if (cdcDesign) _booleans('local.plenaryEscalation', 'plenaryEscalation'),
    ];
  }

  Future<List<FilterSection>> rgc({bool cdcGpsf = false}) async {
    final rows = await _api.getAllPages(
      cdcGpsf ? 'rgc-decisions/cdc-gpsf' : 'rgc-decisions',
      objectItems: true,
    );
    List<FilterOption> relatedOptions(String idKey, String relationKey) {
      final options = <String, FilterOption>{};
      for (final row in rows) {
        if (row is! Map || row[idKey] is! int) continue;
        final relation = row[relationKey];
        if (relation is! Map || relation['name'] is! String) continue;
        final name = (relation['name'] as String).trim();
        if (name.isEmpty) continue;
        final id = '${row[idKey]}';
        options.putIfAbsent(id, () => FilterOption(value: id, label: name));
      }
      return options.values.toList();
    }

    final statuses = <String, FilterOption>{};
    final workingGroups = <String>{};
    final dates = <String>{};
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final decision = RgcDecision(row);
      if (const {
        'SOLVED',
        'IN_PROGRESS',
        'NOT_ADDRESSED',
      }.contains(decision.statusCode)) {
        statuses.putIfAbsent(
          decision.statusCode,
          () => FilterOption(
            value: decision.statusCode,
            label: decision.status.isEmpty
                ? decision.statusCode
                : decision.status,
          ),
        );
      }
      workingGroups.addAll(decision.workingGroups);
      dates.add(FilterSelection.dateValue(decision.decisionDate));
    }
    return [
      FilterSection(
        id: 'plenaryId',
        title: 'plenary',
        options: relatedOptions('plenaryId', 'plenary'),
        columns: 2,
        singleSelection: true,
        collapsedItemCount: 4,
      ),
      FilterSection(
        id: 'status',
        title: 'status',
        options: statuses.values.toList(),
        columns: 3,
        singleSelection: true,
      ),
      _strings(
        'local.workingGroup',
        'workingGroup',
        workingGroups,
        collapsed: 5,
      ),
      FilterSection(
        id: 'stakeholderId',
        title: 'primaryAgency',
        options: relatedOptions('stakeholderId', 'stakeholder'),
        columns: 5,
        singleSelection: true,
        collapsedItemCount: 10,
      ),
      FilterSection(
        id: 'categoryId',
        title: 'measureCategory',
        options: relatedOptions('categoryId', 'categoryInfo'),
        columns: 2,
        singleSelection: true,
        collapsedItemCount: 5,
      ),
      FilterSection(
        id: 'local.dateOfDecision',
        title: 'dateOfDecision',
        columns: 2,
        collapsedItemCount: 4,
        options: dates
            .map(
              (date) => FilterOption(
                value: date,
                label: date == 'unspecified' ? 'Not Specified' : date,
              ),
            )
            .toList(),
      ),
    ];
  }

  Future<List<FilterSection>> cdcIssues() async {
    final issues = await CdcIssueMatrixRepository(_api).getDisplayIssues();
    return [
      _strings(
        'local.category',
        'filterCategory',
        issues.map((issue) => issue.category),
        columns: 2,
        collapsed: 5,
      ),
      FilterSection(
        id: 'local.status',
        title: 'status',
        columns: 3,
        options:
            {for (final issue in issues) issue.statusCode: issue.statusName}
                .entries
                .map(
                  (entry) => FilterOption(value: entry.key, label: entry.value),
                )
                .toList(),
      ),
      _strings(
        'local.pswgs',
        'allPswgs',
        issues.map((issue) => issue.submittedBy),
        collapsed: 5,
      ),
      _strings(
        'local.year',
        'year',
        issues
            .where((issue) => issue.createdAt != null)
            .map(
              (issue) =>
                  FilterSelection.dateValue(issue.createdAt).substring(0, 4),
            ),
        columns: 4,
      ),
      _booleans(
        'local.plenaryEscalation',
        'plenaryEscalation',
        enabled: issues.any((issue) => issue.plenaryEscalation != null),
      ),
    ];
  }

  FilterSection _strings(
    String id,
    String title,
    Iterable<String> values, {
    int columns = 1,
    int? collapsed,
    bool single = false,
  }) => FilterSection(
    id: id,
    title: title,
    columns: columns,
    collapsedItemCount: collapsed,
    singleSelection: single,
    options: values
        .where((value) => value.isNotEmpty)
        .toSet()
        .map(
          (value) => FilterOption(
            value: value,
            label: value == 'unspecified' ? 'Not Specified' : value,
          ),
        )
        .toList(),
  );
  FilterSection _booleans(String id, String title, {bool enabled = true}) =>
      FilterSection(
        id: id,
        title: title,
        columns: 2,
        singleSelection: true,
        options: [
          FilterOption(value: 'true', label: 'Yes', enabled: enabled),
          FilterOption(value: 'false', label: 'No', enabled: enabled),
        ],
      );

  Future<List<dynamic>> _allPlenaries({bool sentOnly = false}) =>
      _api.getAllPages(
        'plenaries',
        objectItems: true,
        query: {if (sentOnly) 'statuses': 'SENT'},
      );

  FilterSection _section(
    String id,
    String title,
    Object? rows, {
    int columns = 1,
    int? collapsed,
    bool single = false,
    String valueKey = 'id',
  }) {
    if (rows is! List) throw ApiException('Invalid filter options: $id');
    final options = rows.map((row) {
      if (row is int || row is String) {
        return FilterOption(value: '$row', label: '$row');
      }
      if (row is! Map || row[valueKey] == null || row['name'] is! String) {
        throw ApiException('Invalid filter option: $id');
      }
      return FilterOption(
        value: '${row[valueKey]}',
        label: row['name'] as String,
      );
    }).toList();
    return FilterSection(
      id: id,
      title: title,
      options: options,
      columns: columns,
      collapsedItemCount: collapsed,
      singleSelection: single,
    );
  }
}
