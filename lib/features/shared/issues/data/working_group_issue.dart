import '../../../../core/text/html_text.dart';
import 'issue_progress_report.dart';
import '../../../../core/widgets/filters/filter_models.dart';

class WorkingGroupIssue {
  WorkingGroupIssue({
    required this.id,
    required this.title,
    required this.category,
    required this.statusCode,
    required this.statusName,
    required this.description,
    required this.recommendation,
    required this.submittedBy,
    required this.agency,
    required this.createdAt,
    required this.meetingDate,
    required this.attachmentCount,
    required this.attachmentPath,
    required this.meetingRequestDocumentPath,
    required this.linkCount,
    this.attachmentName = '',
    this.attachmentSize,
    this.agencyLogo = '',
    this.meetingRequestDocumentName = '',
    this.progressReports = const [],
    this.reportsIncluded = false,
    this.issueProgress,
    this.plenaryEscalation,
    this.descriptionHtml,
    this.recommendationHtml,
  });
  final int id;
  final bool? plenaryEscalation;
  final String title,
      category,
      statusCode,
      statusName,
      description,
      recommendation;
  final String submittedBy, agency;
  final String? descriptionHtml, recommendationHtml;
  final String agencyLogo;
  final DateTime? createdAt, meetingDate;
  final int attachmentCount, linkCount;
  final String attachmentPath;
  final String attachmentName;
  final int? attachmentSize;
  final String? meetingRequestDocumentPath;
  final String meetingRequestDocumentName;
  final List<IssueProgressReport> progressReports;
  final bool reportsIncluded;
  final IssueProgressReport? issueProgress;
  Map<String, Iterable<String>> get filterValues => {
    'local.semester': [
      'Both',
      ...progressReports.map((report) => report.semester),
    ],
    'local.category': [category],
    'local.status': [statusCode, statusName],
    'local.pswgs': [submittedBy],
    'local.year': [
      if (createdAt != null)
        FilterSelection.dateValue(createdAt).substring(0, 4),
    ],
    'local.plenaryEscalation': [
      if (plenaryEscalation != null) '$plenaryEscalation',
    ],
  };

  factory WorkingGroupIssue.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> object(Object? value) {
      if (value == null) return {};
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid issue relation');
      }
      return value;
    }

    String string(Object? value) {
      if (value == null) return '';
      if (value is! String) throw const FormatException('Invalid issue text');
      return value;
    }

    List<dynamic> list(Object? value) {
      if (value == null) return [];
      if (value is! List) throw const FormatException('Invalid issue list');
      return value;
    }

    DateTime? date(Object? value) {
      final raw = string(value);
      if (raw.isEmpty) return null;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) throw const FormatException('Invalid issue date');
      return parsed;
    }

    final id = json['id'];
    final title = string(json['title']);
    if (id is! int || title.trim().isEmpty) {
      throw const FormatException('Invalid issue');
    }
    final status = object(json['issueStatus']);
    final request = object(json['meetingRequest']);
    final meetings = [
      ...list(request['meetings']).map(object),
      ...list(
        request['linkedMeetings'],
      ).map((value) => object(object(value)['meeting'])),
    ];
    final links = <String>{};
    void addLink(Object? raw) {
      final value = string(raw);
      if (value.isNotEmpty) links.add(value);
    }

    final attachment = json['attachment'] is String
        ? <String, dynamic>{'path': json['attachment']}
        : object(json['attachment']);
    String path(Object? value) {
      if (value is String) return value;
      return string(object(value)['path']);
    }

    var meetingDocument = request['meetingRequestLetter'];
    var meetingRequestDocumentPath = path(meetingDocument);
    if (meetingRequestDocumentPath.isEmpty) {
      meetingDocument = request['documentReference'];
      meetingRequestDocumentPath = path(meetingDocument);
    }
    if (meetingRequestDocumentPath.isEmpty && meetings.isNotEmpty) {
      meetingDocument = meetings.first['documentReference'];
      meetingRequestDocumentPath = path(meetingDocument);
    }
    addLink(attachment['path']);
    addLink(json['documentReference']);
    for (final meeting in meetings) {
      addLink(meeting['documentReference']);
    }
    final agencies = list(json['governmentAgencies']).map(object).toList();
    int order(Map<String, dynamic> agency) {
      final value = agency['agencyOrder'];
      return value is int ? value : 999999;
    }

    agencies.sort((a, b) => order(a).compareTo(order(b)));
    final stakeholder = string(object(json['stakeholder'])['name']);
    final rawReports = list(json['progressReports']);
    final reports = rawReports.map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid issue progress report');
      }
      return IssueProgressReport.fromJson(
        value,
        issueSourceOfVerification: rawReports.length == 1
            ? string(json['sourceOfVerification'])
            : '',
      );
    }).toList();
    final issueProgress = IssueProgressReport.fromIssueFields(json);
    final hasEscalation =
        json.containsKey('plenaryEscalation') || json.containsKey('escalation');
    final escalation = json['plenaryEscalation'] ?? json['escalation'];
    return WorkingGroupIssue(
      id: id,
      plenaryEscalation: escalation is bool
          ? escalation
          : hasEscalation && escalation == null
          ? false
          : null,
      title: title,
      category: json['category'] is String
          ? string(json['category'])
          : string(object(json['category'])['name']),
      statusCode: string(status['code']),
      statusName: string(status['name']),
      description: htmlToPlainText(string(json['description'])),
      recommendation: htmlToPlainText(string(json['recommendation'])),
      descriptionHtml: string(json['description']),
      recommendationHtml: string(json['recommendation']),
      submittedBy: stakeholder.isNotEmpty
          ? stakeholder
          : string(object(json['user'])['name']),
      agency: agencies.isEmpty
          ? ''
          : string(object(agencies.first['stakeholder'])['name']),
      agencyLogo: agencies.isEmpty
          ? ''
          : string(object(agencies.first['stakeholder'])['logo']),
      createdAt: date(json['createdAt']),
      meetingDate: meetings.isEmpty
          ? null
          : date(meetings.first['meetingDate']),
      attachmentCount: string(attachment['path']).isEmpty ? 0 : 1,
      attachmentPath: string(attachment['path']),
      attachmentName: string(attachment['originalName'] ?? attachment['name']),
      attachmentSize: attachment['size'] is int
          ? attachment['size'] as int
          : null,
      meetingRequestDocumentPath: meetingRequestDocumentPath,
      meetingRequestDocumentName: meetingDocument is Map<String, dynamic>
          ? string(meetingDocument['originalName'] ?? meetingDocument['name'])
          : '',
      progressReports: List.unmodifiable(reports),
      reportsIncluded: json.containsKey('progressReports'),
      issueProgress: issueProgress,
      linkCount: links.length,
    );
  }
}
