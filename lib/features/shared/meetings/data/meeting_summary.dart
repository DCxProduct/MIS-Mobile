import '../../../../core/text/document_metadata.dart';
import '../../../../core/widgets/filters/filter_models.dart';
import '../../../../core/text/html_text.dart';

class MeetingSummary {
  MeetingSummary(Map<String, dynamic> json)
    : id = json['id'] as int,
      title = json['summaryTitle'] as String? ?? '',
      date = json['meetingDate'] == null
          ? null
          : DateTime.parse(json['meetingDate'] as String),
      issueCount = json['issueCount'] as int? ?? 0,
      meetingRequestCount = json['meetingRequestCount'] as int? ?? 0,
      governmentAgency = json['governmentAgency'] as String? ?? '',
      pswg = json['pswg'] as String? ?? '',
      status = json['status'] as String? ?? '',
      meetingPswg = json['meetingPswg'] as String? ?? '',
      attachmentPaths = _attachmentPaths(json),
      attachmentCount = _attachmentPaths(json).length,
      detailTitle =
          _string(_object(json['meeting'])['title']) ??
          _string(json['summaryTitle']) ??
          '',
      location = _string(_object(json['meeting'])['location']) ?? '',
      detailDate =
          _date(_object(json['meeting'])['meetingDate']) ??
          _date(json['meetingDate']),
      meetingDocumentPath = _path(
        _object(json['meeting'])['documentReference'],
      ),
      requestDocumentPath = _path(
        _object(json['meetingRequest'])['meetingRequestLetter'],
      ),
      meetingDocumentName = documentOriginalName(
        _object(json['meeting'])['documentReference'],
      ),
      requestDocumentName = documentOriginalName(
        _object(json['meetingRequest'])['meetingRequestLetter'],
      ),
      attachmentNames = _attachmentNames(json),
      issues = _issues(json['issues']);

  Map<String, Iterable<String>> get filterValues => {
    'local.status': [status],
    'local.year': [
      if (date != null) FilterSelection.dateValue(date).substring(0, 4),
    ],
    'local.issueCount': ['$issueCount'],
  };
  final int id;
  final String title, governmentAgency, pswg, status, meetingPswg;
  final DateTime? date;
  final int issueCount, meetingRequestCount, attachmentCount;
  final List<String> attachmentPaths;
  final String detailTitle, location;
  final DateTime? detailDate;
  final String? meetingDocumentPath, requestDocumentPath;
  final String? meetingDocumentName, requestDocumentName;
  final Map<String, String> attachmentNames;
  final List<MeetingSummaryIssue> issues;

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static String? _string(Object? value) => value is String ? value : null;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static String? _path(Object? value) =>
      value is String ? value : _string(_object(value)['path']);

  static Map<String, String> _attachmentNames(Map<String, dynamic> json) => {
    for (final document in [
      json['meetingRequest'],
      json['meetingSummary'],
      _object(json['meeting'])['documentReference'],
      _object(json['meetingRequest'])['meetingRequestLetter'],
    ])
      if (_path(document) case final path?)
        path: documentOriginalName(document),
  };

  static List<MeetingSummaryIssue> _issues(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable(
      value.whereType<Map<String, dynamic>>().map(
        (item) => MeetingSummaryIssue(item),
      ),
    );
  }

  static List<String> _attachmentPaths(Map<String, dynamic> json) =>
      List.unmodifiable(
        _attachmentNames(json).keys.where((path) => path.trim().isNotEmpty),
      );
}

class MeetingSummaryIssue {
  MeetingSummaryIssue(Map<String, dynamic> json)
    : title = _string(json['issue']) ?? _string(json['title']) ?? '',
      category = _string(json['category']) ?? '',
      status = _string(json['status']) ?? '',
      description = htmlToPlainText(_string(json['issueDescription']) ?? ''),
      recommendation = htmlToPlainText(_string(json['recommendation']) ?? ''),
      descriptionHtml = _string(json['issueDescription']) ?? '',
      recommendationHtml = _string(json['recommendation']) ?? '',
      attachmentPath = _path(json['issueReference']),
      referencePath = _path(json['referenceDocument']),
      attachmentName = documentOriginalName(json['issueReference']),
      referenceName = documentOriginalName(json['referenceDocument']),
      agency = _agency(json['agencies']);

  final String title, category, status, description, recommendation, agency;
  final String descriptionHtml, recommendationHtml;
  final String? attachmentPath, referencePath;
  final String? attachmentName, referenceName;

  static String? _string(Object? value) => value is String ? value : null;

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static String? _path(Object? value) =>
      value is String ? value : _string(_object(value)['path']);

  static String _agency(Object? value) {
    if (value is List && value.isNotEmpty) {
      return _string(_object(value.first)['name']) ?? '';
    }
    return '';
  }
}
