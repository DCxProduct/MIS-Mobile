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
      issues = _issues(json['issues']);

  final int id;
  final String title, governmentAgency, pswg, status, meetingPswg;
  final DateTime? date;
  final int issueCount, meetingRequestCount, attachmentCount;
  final List<String> attachmentPaths;
  final String detailTitle, location;
  final DateTime? detailDate;
  final String? meetingDocumentPath, requestDocumentPath;
  final List<MeetingSummaryIssue> issues;

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static String? _string(Object? value) => value is String ? value : null;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static String? _path(Object? value) => _string(_object(value)['path']);

  static List<MeetingSummaryIssue> _issues(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable(
      value.whereType<Map<String, dynamic>>().map(
        (item) => MeetingSummaryIssue(item),
      ),
    );
  }

  static List<String> _attachmentPaths(Map<String, dynamic> json) =>
      List.unmodifiable(<String>{
        if (json['meetingRequest'] is String) json['meetingRequest'] as String,
        if (json['meetingSummary'] is String) json['meetingSummary'] as String,
        if (_path(_object(json['meeting'])['documentReference'])
            case final path?)
          path,
        if (_path(_object(json['meetingRequest'])['meetingRequestLetter'])
            case final path?)
          path,
      });
}

class MeetingSummaryIssue {
  MeetingSummaryIssue(Map<String, dynamic> json)
    : title = _string(json['issue']) ?? _string(json['title']) ?? '',
      category = _string(json['category']) ?? '',
      status = _string(json['status']) ?? '',
      description = htmlToPlainText(_string(json['issueDescription']) ?? ''),
      recommendation = htmlToPlainText(_string(json['recommendation']) ?? ''),
      attachmentPath = _path(json['issueReference']),
      referencePath = _path(json['referenceDocument']),
      agency = _agency(json['agencies']);

  final String title, category, status, description, recommendation, agency;
  final String? attachmentPath, referencePath;

  static String? _string(Object? value) => value is String ? value : null;

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static String? _path(Object? value) => _string(_object(value)['path']);

  static String _agency(Object? value) {
    if (value is List && value.isNotEmpty) {
      return _string(_object(value.first)['name']) ?? '';
    }
    return '';
  }
}
