import 'package:html/parser.dart' as html_parser;
import '../../../../core/widgets/filters/filter_models.dart';

class RgcDecision {
  RgcDecision(Map<String, dynamic> json)
    : id = _int(json['id']),
      plenaryName = _string(_object(json['plenary'])['name']),
      workingGroups = _workingGroups(json),
      measureCategory = _string(
        json['measureCategory'] is String
            ? json['measureCategory']
            : _object(json['measureCategory'])['name'] ?? json['category'],
      ),
      decisionDate = _date(json['dateOfDecision'] ?? json['meetingDate']),
      agencyName = _string(_object(json['stakeholder'])['name']),
      agencyLogo = _string(_object(json['stakeholder'])['logo']),
      status = _string(json['status']),
      statusCode = _string(json['statusCode']),
      meetingDate = _date(json['meetingDate']),
      category = json['category'] is String
          ? _string(json['category'])
          : _string(_object(json['categoryInfo'])['name']),
      focalPerson = _string(json['focalPerson']),
      linkCount = _links(json).length;

  final int id, linkCount;
  final String plenaryName, measureCategory;
  final List<String> workingGroups;
  final DateTime? decisionDate;
  final String agencyName,
      agencyLogo,
      status,
      statusCode,
      category,
      focalPerson;
  final DateTime? meetingDate;
  Map<String, Iterable<String>> get filterValues => {
    'local.workingGroup': workingGroups,
    'local.dateOfDecision': [FilterSelection.dateValue(decisionDate)],
  };

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static int _int(Object? value) => value is int ? value : 0;

  static String _string(Object? value) => value is String ? value : '';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static List<String> _workingGroups(Map<String, dynamic> json) {
    final names = <String>{};
    final direct = _string(_object(json['workingGroup'])['name']);
    if (direct.isNotEmpty) names.add(direct);
    final issues = json['issues'];
    if (issues is List) {
      for (final issue in issues) {
        final name = _string(_object(_object(issue)['stakeholder'])['name']);
        if (name.isNotEmpty) names.add(name);
      }
    }
    return List.unmodifiable(names);
  }

  static Set<String> _links(Map<String, dynamic> json) {
    final links = <String>{};
    void add(Object? value) {
      if (value is String && value.trim().isNotEmpty) links.add(value);
    }

    add(json['verificationLink']);
    final issues = json['issues'];
    if (issues is List) {
      for (final issue in issues) {
        final item = _object(issue);
        add(item['attachment']);
        add(item['escalation']);
      }
    }
    return links;
  }
}

class RgcMinistry {
  const RgcMinistry({required this.id, required this.name});
  final int id;
  final String name;

  factory RgcMinistry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'] ?? json['nameEn'] ?? json['nameKh'];
    if (id is! int || id <= 0 || name is! String || name.isEmpty) {
      throw const FormatException();
    }
    return RgcMinistry(id: id, name: name);
  }
}

class RgcDecisionPage {
  const RgcDecisionPage({required this.items, required this.totalPages});
  final List<RgcDecision> items;
  final int totalPages;

  factory RgcDecisionPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final meta = json['meta'];
    if (items is! List || meta is! Map<String, dynamic>) {
      throw const FormatException();
    }
    final totalPages = meta['totalPages'];
    if (totalPages is! int || totalPages < 0) throw const FormatException();
    return RgcDecisionPage(
      items: List.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) throw const FormatException();
          final decision = RgcDecision(item);
          if (decision.id <= 0) throw const FormatException();
          return decision;
        }),
      ),
      totalPages: totalPages,
    );
  }
}

class RgcDecisionDetail {
  RgcDecisionDetail.fromJson(
    Map<String, dynamic> json, {
    DateTime? plenaryDeadline,
  }) : decision = RgcDecision(json),
       deadline =
           _date(json['deadline']) ??
           _date(
             json['plenary'] is Map<String, dynamic>
                 ? (json['plenary'] as Map<String, dynamic>)['deadline']
                 : null,
           ) ??
           plenaryDeadline,
       approvalReport = _string(json['approvalReport']),
       issues = List.unmodifiable(_issueList(json));

  final RgcDecision decision;
  final DateTime? deadline;
  final String approvalReport;
  final List<RgcDecisionIssue> issues;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
  static String _string(Object? value) => value is String ? value : '';
  static Iterable<RgcDecisionIssue> _issueList(
    Map<String, dynamic> json,
  ) sync* {
    final value = json['issues'];
    if (value is List) {
      for (final item in value) {
        if (item is Map<String, dynamic>) {
          yield RgcDecisionIssue.fromJson(item, decision: json);
        }
      }
    } else if (json['rgcDecision'] is String || json['decision'] is String) {
      yield RgcDecisionIssue.fromJson(json);
    }
  }
}

class RgcDecisionIssue {
  RgcDecisionIssue.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? decision,
  }) : status = _string(
         _object(json['issueStatus'])['name'] ??
             json['status'] ??
             decision?['status'],
       ),
       submittedBy = _string(
         _object(json['stakeholder'])['name'] ?? json['submittedBy'],
       ),
       submittedByName = _string(
         _nonEmpty(_object(json['user'])['name']) ??
             _nonEmpty(json['submittedBy']) ??
             _object(json['stakeholder'])['name'],
       ),
       submittedDate = _date(
         json['submittedDate'] ??
             json['createdAt'] ??
             decision?['submittedToCdcAt'],
       ),
       governmentAgencies = _agencies(json),
       meetingRequestId = _int(_object(json['meetingRequest'])['id']),
       meetingRequestDocumentPath = _documentPath(json),
       meetingRequestDocumentName = _documentName(json),
       meetingDate = _meetingDate(json) ?? _date(decision?['meetingDate']),
       category = _string(
         _object(json['category'])['name'] ??
             json['category'] ??
             decision?['category'],
       ),
       focalPerson = _string(json['focalPerson'] ?? decision?['focalPerson']),
       description = _string(json['description'] ?? json['issuesDescription']),
       recommendations = _string(
         json['recommendations'] ?? json['recommendation'],
       ),
       rgcDecision = _plainText(
         json['rgcDecision'] ?? json['decision'] ?? decision?['decision'],
       ),
       indicators = _plainText(
         json['indicators'] ??
             _report(decision)['indicators'] ??
             _nonEmpty(decision?['indicatorDescription']) ??
             decision?['indicatorName'],
       ),
       progressSolution = _plainText(
         json['progressSolution'] ?? _report(decision)['progressSolution'],
       ),
       implementationChallenges = _plainText(
         json['implementationChallenges'] ??
             _report(decision)['implementationChallenges'],
       ),
       request = _plainText(json['request'] ?? _report(decision)['requests']),
       nextStep = _string(json['nextStep']),
       sourceOfVerification = _plainText(
         json['sourceOfVerification'] ??
             _report(decision)['sourceOfVerification'] ??
             decision?['verificationSource'],
       ),
       verificationLink = _string(
         json['verificationLink'] ??
             _report(decision)['linkToVerificationSource'] ??
             decision?['verificationLink'],
       );

  final String status,
      submittedBy,
      submittedByName,
      category,
      focalPerson,
      description;
  final String recommendations, rgcDecision, indicators, progressSolution;
  final String implementationChallenges, request, nextStep;
  final String sourceOfVerification, verificationLink;
  final Map<int, String> governmentAgencies;
  final int meetingRequestId;
  final String meetingRequestDocumentPath, meetingRequestDocumentName;
  final DateTime? submittedDate, meetingDate;

  static Object? _nonEmpty(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static Map<String, dynamic> _report(Map<String, dynamic>? decision) {
    final reports = decision?['progressReports'];
    return reports is List && reports.isNotEmpty
        ? _object(reports.last)
        : const {};
  }

  static Map<int, String> _agencies(Map<String, dynamic> json) {
    final agencies = json['governmentAgencies'];
    return Map.unmodifiable({
      if (agencies is List)
        for (final agency in agencies)
          if (_int(_object(agency)['agencyOrder']) > 0)
            _int(_object(agency)['agencyOrder']): _string(
              _object(_object(agency)['stakeholder'])['name'],
            ),
    });
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
  static String _string(Object? value) => value is String ? value : '';
  static int _int(Object? value) => value is int ? value : 0;
  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const {};
  static Object? _meetingDocument(Map<String, dynamic> json) {
    final request = _object(json['meetingRequest']);
    final meetings = request['meetings'];
    final attachment = json['attachment'];
    if (attachment is String && attachment.trim().isNotEmpty) {
      return attachment;
    }
    if (_string(_object(attachment)['path']).trim().isNotEmpty) {
      return attachment;
    }
    return request['meetingRequestLetter'] ??
        request['documentReference'] ??
        (meetings is List && meetings.isNotEmpty
            ? _object(meetings.first)['documentReference']
            : null);
  }

  static String _documentPath(Map<String, dynamic> json) {
    final document = _meetingDocument(json);
    return document is String ? document : _string(_object(document)['path']);
  }

  static String _documentName(Map<String, dynamic> json) {
    final document = _object(_meetingDocument(json));
    return _string(document['originalName'] ?? document['name']);
  }

  static DateTime? _meetingDate(Map<String, dynamic> json) {
    final meetings = _object(json['meetingRequest'])['meetings'];
    if (meetings is List && meetings.isNotEmpty) {
      return _date(_object(meetings.first)['meetingDate']);
    }
    return _date(json['meetingDate']);
  }

  static String _plainText(Object? value) {
    final text = _string(value);
    return text.contains('<')
        ? html_parser.parseFragment(text).text ?? ''
        : text;
  }
}

class RgcDecisionScorecard {
  const RgcDecisionScorecard({
    required this.total,
    required this.solved,
    required this.inProgress,
    required this.notAddressed,
  });

  final int total;
  final int solved;
  final int inProgress;
  final int notAddressed;

  factory RgcDecisionScorecard.fromJson(Map<String, dynamic> json) {
    final total = _count(json['total']);
    final statuses = json['byStatus'];
    if (statuses is! List) throw const FormatException();

    var solved = 0;
    var inProgress = 0;
    var notAddressed = 0;
    for (final value in statuses) {
      if (value is! Map<String, dynamic>) throw const FormatException();
      final status = value['status'];
      final count = _count(value['count']);
      if (status == 'Solved') {
        solved = count;
      } else if (status == 'In Progress') {
        inProgress = count;
      } else if (status == 'Not Addressed') {
        notAddressed = count;
      }
    }
    return RgcDecisionScorecard(
      total: total,
      solved: solved,
      inProgress: inProgress,
      notAddressed: notAddressed,
    );
  }

  static int _count(Object? value) =>
      value is int && value >= 0 ? value : (throw const FormatException());
}
