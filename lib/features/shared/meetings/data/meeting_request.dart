import '../../../../core/widgets/filters/filter_models.dart';
import '../../../../core/text/html_text.dart';
import '../../issues/data/working_group_issue.dart';

class MeetingRequest {
  MeetingRequest(Map<String, dynamic> json)
    : id = _int(json['id']),
      title = _string(json['title']),
      status = _string(json['status']),
      description = htmlToPlainText(_string(json['description'])),
      meetingDate = _date(json['meetingDate']),
      submittedAt = _date(json['submittedAt']),
      submittedBy = _string(_object(json['user'])['name']),
      groupNames = (_object(json['user'])['stakeholders'] as List? ?? [])
          .map((entry) => _string(_object(entry)['stakeholder']?['name']))
          .where((name) => name.isNotEmpty)
          .toList(),
      agencyNames = (json['governmentAgencies'] as List? ?? [])
          .map((entry) => _string(_object(entry)['stakeholder']?['name']))
          .where((name) => name.isNotEmpty)
          .toList(),
      group = (_object(json['user'])['stakeholders'] as List? ?? [])
          .map((entry) => _string(_object(entry)['stakeholder']?['name']))
          .where((name) => name.isNotEmpty)
          .join(', '),
      agencies = (json['governmentAgencies'] as List? ?? [])
          .map((entry) => _string(_object(entry)['stakeholder']?['name']))
          .where((name) => name.isNotEmpty)
          .join(', '),
      letterName = _string(_object(json['meetingRequestLetter'])['name']),
      letterPath = _string(_object(json['meetingRequestLetter'])['path']),
      meetingReferencePath = _string(json['meetingReference']),
      letterSize = _object(json['meetingRequestLetter'])['size'] as int?,
      attachmentCount = <String>{
        if (json['meetingRequestLetter']?['path'] case final String path
            when path.isNotEmpty)
          path,
        if (json['meetingReference'] case final String path
            when path.isNotEmpty)
          path,
      }.length,
      issuesCount =
          json['issuesCount'] as int? ?? (json['issues'] as List? ?? []).length,
      issues = List.unmodifiable(
        (json['issues'] as List? ?? []).map(
          (issue) => WorkingGroupIssue.fromJson({
            ...issue as Map<String, dynamic>,
            'user': issue['user'] ?? json['user'],
          }),
        ),
      );

  final List<String> groupNames, agencyNames;
  Map<String, Iterable<String>> get filterValues => {
    'local.workingGroup': groupNames,
    'local.primaryAgency': agencyNames,
    'local.status': [status],
    'local.year': [
      if (meetingDate != null)
        FilterSelection.dateValue(meetingDate).substring(0, 4),
    ],
    'local.issueCount': ['$issuesCount'],
    'local.date': [FilterSelection.dateValue(meetingDate)],
  };
  final int id, issuesCount, attachmentCount;
  final String title,
      status,
      description,
      submittedBy,
      group,
      agencies,
      letterName,
      letterPath,
      meetingReferencePath;
  final int? letterSize;
  final DateTime? meetingDate, submittedAt;
  final List<WorkingGroupIssue> issues;

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static int _int(Object? value) => value is int ? value : 0;

  static String _string(Object? value) => value is String ? value : '';

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}
