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
      governmentAgency =
          _string(json['governmentAgency']) ??
          _string(_object(json['meetingRequest'])['governmentAgency']) ??
          '',
      agencyLogo =
          _string(json['governmentAgencyLogo']) ??
          _string(_object(json['meetingRequest'])['governmentAgencyLogo']) ??
          '',
      pswg =
          _string(json['pswg']) ??
          _string(_object(json['meetingRequest'])['pswg']) ??
          '',
      requestedDate = _date(_object(json['meetingRequest'])['requestedDate']),
      sentBy = _string(_object(_object(json['meeting'])['user'])['name']) ?? '',
      status = json['status'] as String? ?? '',
      meetingPswg = json['meetingPswg'] as String? ?? '',
      attachmentPaths = _attachmentPaths(json),
      attachmentCount = _attachmentPaths(json).length,
      detailTitle =
          _string(_object(json['meeting'])['title']) ??
          _string(json['summaryTitle']) ??
          '',
      location =
          _string(_object(json['meeting'])['location']) ??
          _string(json['location']) ??
          '',
      startTime =
          _string(_object(json['meeting'])['startTime']) ??
          _string(json['startTime']) ??
          '',
      detailDate =
          _date(_object(json['meeting'])['meetingDate']) ??
          _date(json['meetingDate']),
      meetingDocumentPath = _path(
        _object(json['meeting'])['documentReference'],
      ),
      summaryDocumentPath = _path(json['documentReference']),
      summaryDocumentName = documentOriginalName(json['documentReference']),
      summaryDocumentSize = (_object(json['documentReference'])['size'] as num?)
          ?.toInt(),
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
      issues = _issues(json);

  Map<String, Iterable<String>> get filterValues => {
    'local.status': [status],
    'local.year': [
      if (date != null) FilterSelection.dateValue(date).substring(0, 4),
    ],
    'local.issueCount': ['$issueCount'],
  };
  final int id;
  final String title, governmentAgency, agencyLogo, pswg, status, meetingPswg;
  final DateTime? date;
  final int issueCount, meetingRequestCount, attachmentCount;
  final List<String> attachmentPaths;
  final String detailTitle, location, startTime;
  final DateTime? requestedDate;
  final String sentBy;
  final DateTime? detailDate;
  final String? meetingDocumentPath, requestDocumentPath;
  final String? summaryDocumentPath;
  final String summaryDocumentName;
  final int? summaryDocumentSize;
  final String? meetingDocumentName, requestDocumentName;
  final Map<String, String> attachmentNames;
  final List<MeetingSummaryIssue> issues;

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static String? _path(Object? value) =>
      value is String ? _string(value) : _string(_object(value)['path']);

  static Map<String, String> _attachmentNames(Map<String, dynamic> json) {
    final names = <String, String>{};
    for (final document in [
      json['documentReference'],
      json['meetingRequest'],
      json['meetingSummary'],
      _object(json['meeting'])['documentReference'],
      _object(json['meetingRequest'])['meetingRequestLetter'],
    ]) {
      final path = _path(document);
      if (path != null) names[path] = documentOriginalName(document);
    }
    return names;
  }

  static List<MeetingSummaryIssue> _issues(Map<String, dynamic> json) {
    final value = json['issues'];
    if (value is! List) return const [];
    final meeting = _object(json['meeting']);
    // The summary API's issue rows omit these fields. The web issue dialog
    // receives the scheduling ministry user and meeting date from the parent.
    final sentBy = _string(_object(meeting['user'])['name']);
    final meetingDate = _date(meeting['meetingDate']);
    return List.unmodifiable(
      value.whereType<Map<String, dynamic>>().map(
        (item) => MeetingSummaryIssue(
          item,
          summarySentBy: sentBy,
          summaryMeetingDate: meetingDate,
        ),
      ),
    );
  }

  static List<String> _attachmentPaths(Map<String, dynamic> json) =>
      List.unmodifiable(
        _attachmentNames(json).keys.where((path) => path.trim().isNotEmpty),
      );
}

class MeetingSummaryIssue {
  factory MeetingSummaryIssue(
    Map<String, dynamic> json, {
    String? summarySentBy,
    DateTime? summaryMeetingDate,
  }) {
    // Some responses embed the issue relation; others flatten its fields.
    final source = {
      ..._object(json['issue']),
      for (final entry in json.entries)
        if (entry.value != null) entry.key: entry.value,
    };
    final description = _firstText([
      source['issueDescription'],
      source['description'],
    ]);
    final recommendation = _firstText([
      source['recommendation'],
      source['recommendations'],
    ]);
    final attachment = _document(
      source['issueReference'],
      source['attachment'],
    );
    final reference = _document(source['referenceDocument'], null);
    final agencies = _agencies(
      source['agencies'] is List && (source['agencies'] as List).isNotEmpty
          ? source['agencies']
          : source['governmentAgencies'],
    );
    return MeetingSummaryIssue._(
      title: _firstText([
        source['issue'] is String ? source['issue'] : null,
        source['title'],
      ]),
      category: _name(source['category']),
      status: _firstText([
        _object(source['issueStatus'])['code'],
        source['status'] is String ? source['status'] : null,
        _object(source['status'])['code'],
        _object(source['issueStatus'])['name'],
        _object(source['status'])['name'],
      ]),
      descriptionHtml: description,
      recommendationHtml: recommendation,
      submittedBy: _firstText([
        source['submittedByName'],
        _name(source['submittedBy']),
        _object(source['user'])['name'],
        _object(source['stakeholder'])['name'],
        summarySentBy,
      ]),
      submittedDate:
          _firstDate([
            source['submittedDate'],
            source['submittedAt'],
            source['createdAt'],
          ]) ??
          summaryMeetingDate,
      governmentAgencies: agencies,
      agencyLogos: _agencyLogos(
        source['agencies'] is List && (source['agencies'] as List).isNotEmpty
            ? source['agencies']
            : source['governmentAgencies'],
      ),
      escalation: _firstText([source['escalation']]),
      rgcDecisionHtml: _firstText([source['rgcDecision']]),
      nextStepHtml: _firstText([source['nextStep']]),
      remarkHtml: _firstText([source['remark']]),
      attachmentPath: _path(attachment),
      referencePath: _path(reference),
      attachmentName: documentOriginalName(attachment),
      referenceName: documentOriginalName(reference),
      attachmentSize: (_object(attachment)['size'] as num?)?.toInt(),
      referenceSize: (_object(reference)['size'] as num?)?.toInt(),
    );
  }

  MeetingSummaryIssue._({
    required this.title,
    required this.category,
    required this.status,
    required this.descriptionHtml,
    required this.recommendationHtml,
    required this.submittedBy,
    required this.submittedDate,
    required this.governmentAgencies,
    required this.agencyLogos,
    required this.escalation,
    required this.rgcDecisionHtml,
    required this.nextStepHtml,
    required this.remarkHtml,
    required this.attachmentPath,
    required this.referencePath,
    required this.attachmentName,
    required this.referenceName,
    required this.attachmentSize,
    required this.referenceSize,
  });

  final String title, category, status, submittedBy;
  final String descriptionHtml, recommendationHtml;
  String get description => htmlToPlainText(descriptionHtml);
  String get recommendation => htmlToPlainText(recommendationHtml);
  final DateTime? submittedDate;
  final Map<int, String> governmentAgencies;
  final Map<int, String> agencyLogos;
  final String escalation, rgcDecisionHtml, nextStepHtml, remarkHtml;
  String get agency => governmentAgencies[1] ?? '';
  final String? attachmentPath, referencePath;
  final String? attachmentName, referenceName;
  final int? attachmentSize, referenceSize;

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static String _name(Object? value) => value is String
      ? value.trim()
      : _firstText([
          _object(value)['name'],
          _object(_object(value)['stakeholder'])['name'],
        ]);

  static String _firstText(List<Object?> values) => values
      .whereType<String>()
      .map((value) => value.trim())
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');

  static DateTime? _firstDate(List<Object?> values) {
    for (final value in values.whereType<String>()) {
      final date = DateTime.tryParse(value);
      if (date != null) return date;
    }
    return null;
  }

  static String? _path(Object? value) {
    final path = value is String
        ? value.trim()
        : _firstText([_object(value)['path']]);
    return path.isEmpty ? null : path;
  }

  static Object? _document(Object? preferred, Object? fallback) =>
      _path(preferred) != null ? preferred : fallback;

  static Map<int, String> _agencies(Object? value) {
    if (value is! List) return const {};
    final agencies = <int, String>{};
    for (var index = 0; index < value.length; index++) {
      final entry = value[index];
      final name = _name(entry);
      final order = _object(entry)['order'] ?? _object(entry)['agencyOrder'];
      if (name.isNotEmpty) {
        agencies[order is int && order > 0 ? order : index + 1] = name;
      }
    }
    return Map.unmodifiable(agencies);
  }

  static Map<int, String> _agencyLogos(Object? value) {
    if (value is! List) return const {};
    final logos = <int, String>{};
    for (var index = 0; index < value.length; index++) {
      final entry = _object(value[index]);
      final order = entry['order'] ?? entry['agencyOrder'];
      final logo = _firstText([
        entry['logo'],
        _object(entry['stakeholder'])['logo'],
      ]);
      if (logo.isNotEmpty) {
        logos[order is int && order > 0 ? order : index + 1] = logo;
      }
    }
    return Map.unmodifiable(logos);
  }
}
