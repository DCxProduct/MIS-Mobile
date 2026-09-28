import '../../../../core/network/api_client.dart';
import 'wg_issue_summary.dart';
import 'working_group_issue.dart';

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
    final data = await _api.get('working-group-issues/issue-matrix');
    try {
      final items = data['items'];
      if (items is! List) throw const FormatException();
      return List.unmodifiable(
        items.map(
          (item) => WorkingGroupIssue.fromJson(item as Map<String, dynamic>),
        ),
      );
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
