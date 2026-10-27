import '../../../../core/text/document_metadata.dart';
import '../../../../core/widgets/filters/filter_models.dart';
import '../../../../core/text/html_text.dart';
import '../../issues/data/working_group_issue.dart';
import '../../../../translations/app_language.dart';

class MeetingRequest {
  MeetingRequest(Map<String, dynamic> json)
    : id = _int(json['id']),
      title = _string(json['title']),
      status = _string(json['status']),
      description = htmlToPlainText(_string(json['description'])),
      descriptionHtml = _string(json['description']),
      meetingDate = _date(json['meetingDate']),
      submittedAt = _date(json['submittedAt']),
      submittedBy = _string(_object(json['user'])['name']),
      receivedBy = _personName(json['receivedBy']),
      agencyLogo = _agencyLogo(json),
      groupKhmer = (_object(json['user'])['stakeholders'] as List? ?? [])
          .map((entry) {
            final stakeholder = _object(_object(entry)['stakeholder']);
            final khmer = _string(stakeholder['khName']).trim();
            return khmer.isNotEmpty ? khmer : _string(stakeholder['name']);
          })
          .where((name) => name.isNotEmpty)
          .join(', '),
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
      letterName = documentOriginalName(json['meetingRequestLetter']),
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
            'stakeholder':
                issue['stakeholder'] ??
                _requestIssueStakeholder(issue['user'] ?? json['user']),
          }),
        ),
      );

  final List<String> groupNames, agencyNames;
  final String groupKhmer;

  String displayGroup(AppLanguage language) =>
      language == AppLanguage.khmer && groupKhmer.isNotEmpty
      ? groupKhmer
      : group;

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
      descriptionHtml,
      status,
      description,
      submittedBy,
      receivedBy,
      agencyLogo,
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

  static Map<String, dynamic>? _requestIssueStakeholder(Object? user) {
    final relations = _object(user)['stakeholders'];
    if (relations is! List) return null;
    final names = relations
        .map((entry) => _string(_object(_object(entry)['stakeholder'])['name']))
        .where((name) => name.isNotEmpty)
        .toList();
    return names.isEmpty ? null : {'name': names.join(', ')};
  }

  static int _int(Object? value) => value is int ? value : 0;

  static String _string(Object? value) => value is String ? value : '';

  static String _agencyLogo(Map<String, dynamic> json) {
    final direct = _string(json['governmentAgencyLogo']).trim();
    if (direct.isNotEmpty) return direct;
    final agencies = (json['governmentAgencies'] as List? ?? [])
        .map(_object)
        .toList();
    if (agencies.isEmpty) return '';
    final primary = agencies.firstWhere(
      (entry) => entry['agencyOrder'] == 1,
      orElse: () => agencies.first,
    );
    return _string(_object(primary['stakeholder'])['logo']).trim();
  }

  static String _personName(Object? value) =>
      (value is String ? value : _string(_object(value)['name'])).trim();

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}
