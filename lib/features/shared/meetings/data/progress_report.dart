import '../../../../core/text/document_metadata.dart';

class ProgressReportScheduleEntry {
  const ProgressReportScheduleEntry({
    required this.isMeeting,
    required this.number,
    required this.date,
  });

  final bool isMeeting;
  // Zero is the original deadline; revision deadlines and meetings start at 1.
  final int number;
  final DateTime? date;
}

class ProgressReportMinistry {
  ProgressReportMinistry.fromJson(Map<String, dynamic> json)
    : ministryId = json['ministryId'] is int ? json['ministryId'] as int : 0,
      name = _string(_object(json['ministry'])['name']),
      description = _string(_object(json['ministry'])['description']),
      logo = _string(_object(json['ministry'])['logo']),
      status = _string(json['status']).trim().toUpperCase(),
      issues = json['issues'] is int ? json['issues'] as int : 0,
      attachment = _string(_object(json['attachment'])['path']),
      attachmentName = documentOriginalName(json['attachment']),
      requestDocument = _string(_object(json['requestDocument'])['path']),
      requestDocumentName = documentOriginalName(json['requestDocument']) {
    if (ministryId <= 0 || name.trim().isEmpty) throw const FormatException();
  }
  bool get submittedToCdc => const {
    'SUBMITTED',
    'RETURNED',
    'UPDATING',
    'RESUBMITTED',
    'CDC_RE_REVIEWING',
    'CDC_UNDER_REVIEW',
    'COMPLETED',
  }.contains(status.toUpperCase());

  final int ministryId, issues;
  final String name, description, logo, status;
  final String attachment, attachmentName, requestDocument, requestDocumentName;

  static Map _object(Object? value) => value is Map ? value : const {};
  static String _string(Object? value) => value is String ? value : '';
}

class ProgressReport {
  ProgressReport(Map<String, dynamic> json)
    : details = Map.unmodifiable(json),
      id = _requiredInt(json, 'id'),
      title =
          _string(json['title']) ??
          _string(_object(json['progressReport'])['title']) ??
          '',
      year =
          _int(json['year']) ??
          _int(_object(json['progressReport'])['year']) ??
          0,
      semester =
          _string(json['semester']) ??
          _string(_object(json['progressReport'])['semester']) ??
          '',
      status = _string(json['status']) ?? '',
      reportStatus =
          _string(json['reportStatus']) ??
          _string(_object(json['progressReport'])['status']) ??
          '',
      issues =
          _int(json['issues']) ??
          _int(_object(json['ministryAssignment'])['issues']) ??
          0,
      ministry = _ministry(json),
      deadline = _date(
        _object(json['activeDeadline'])['date'] ??
            _object(json['activeDeadline'])['deadline'] ??
            _object(
              _object(json['progressReport'])['activeDeadline'],
            )['date'] ??
            _object(
              _object(json['progressReport'])['activeDeadline'],
            )['deadline'],
      ),
      firstMeeting = _meetingDate(json, 0),
      secondMeeting = _meetingDate(json, 1),
      secondDeadline = _deadlineDate(json, 1),
      attachmentName = _attachmentName(json),
      attachmentPaths = List.unmodifiable(_attachmentPaths(json)),
      attachmentCount = _attachmentPaths(json).length;

  final int id, year, issues, attachmentCount;
  final Map<String, dynamic> details;
  final String title, semester, status, reportStatus, ministry, attachmentName;
  final List<String>? attachmentPaths;
  final DateTime? deadline, firstMeeting, secondMeeting, secondDeadline;

  List<ProgressReportScheduleEntry> get schedule {
    List<Map<String, dynamic>> sorted(String key) {
      final rows = _objects(
        details[key] ?? _object(details['progressReport'])[key],
      ).toList();
      rows.sort((a, b) => (_int(a['id']) ?? 0).compareTo(_int(b['id']) ?? 0));
      return rows;
    }

    final meetings = sorted('meetings');
    final deadlines = sorted('deadlines');
    final rows = <ProgressReportScheduleEntry>[];
    void addDeadline(int index) => rows.add(
      ProgressReportScheduleEntry(
        isMeeting: false,
        number: index,
        date: _date(deadlines[index]['date'] ?? deadlines[index]['deadline']),
      ),
    );
    if (deadlines.isNotEmpty) addDeadline(0);
    for (var i = 0; i < meetings.length || i + 1 < deadlines.length; i++) {
      if (i < meetings.length) {
        rows.add(
          ProgressReportScheduleEntry(
            isMeeting: true,
            number: i + 1,
            date: _date(meetings[i]['meetingDate']),
          ),
        );
      }
      if (i + 1 < deadlines.length) addDeadline(i + 1);
    }
    return rows;
  }

  String get draftSemesterDocument =>
      _string(
        _object(
          details['draftSemesterReport'] ??
              _object(details['progressReport'])['draftSemesterReport'],
        )['path'],
      ) ??
      '';

  String get finalSemesterDocument =>
      _string(
        _object(
          details['finalSemesterReport'] ??
              _object(details['progressReport'])['finalSemesterReport'],
        )['path'],
      ) ??
      '';

  // Web uses the earliest-created deadline for the report overview.
  DateTime? get initialDeadline {
    final source =
        details['deadlines'] ?? _object(details['progressReport'])['deadlines'];
    final deadlines = _objects(source);
    if (deadlines.isEmpty) return null;
    deadlines.sort(
      (a, b) => (_int(a['id']) ?? 0).compareTo(_int(b['id']) ?? 0),
    );
    return _date(deadlines.first['date'] ?? deadlines.first['deadline']);
  }

  String get ministryDisplayName {
    final description = _string(_object(details['ministry'])['description']);
    return description?.trim().isNotEmpty == true
        ? description!.trim()
        : ministry;
  }

  DateTime? get reviewedAt => _date(
    _object(details['cdcInformation'])['reviewedAt'] ?? details['reviewedAt'],
  );

  String get description =>
      _string(details['description']) ??
      _string(_object(details['progressReport'])['description']) ??
      '';
  String get preparedBy =>
      _string(
        _object(_object(details['ministryInformation'])['preparedBy'])['name'],
      ) ??
      _string(_object(details['preparedBy'])['name']) ??
      '';
  String get reviewedBy =>
      _string(
        _object(_object(details['cdcInformation'])['reviewedBy'])['name'],
      ) ??
      _string(_object(details['reviewedBy'])['name']) ??
      '';
  String get cdcStatus => details.containsKey('cdcInformation')
      ? _string(_object(details['cdcInformation'])['status']) ?? ''
      : status;
  DateTime? get submittedAt => _date(
    _object(details['ministryInformation'])['submittedAt'] ??
        details['submittedAt'],
  );
  DateTime? get updatedAt => _date(
    details.containsKey('cdcInformation')
        ? _object(details['cdcInformation'])['latestUpdatedAt']
        : details['updatedAt'],
  );
  String? get approvalDocument =>
      _string(
        _object(
          _object(details['ministryInformation'])['approvalProgressReport'],
        )['path'],
      ) ??
      _string(_object(details['attachment'])['path']);
  String? get requestDocument =>
      _string(
        _object(_object(details['cdcInformation'])['requestDocument'])['path'],
      ) ??
      _string(
        _object(_object(details['progressReport'])['requestDocument'])['path'],
      );
  Map<String, String> get documentNames {
    final names = <String, String>{};
    void collect(Object? value) {
      if (value is Map) {
        final path = _string(value['path']);
        final name = documentOriginalName(value);
        if (path != null && name.isNotEmpty) {
          names.putIfAbsent(path, () => name);
        }
        for (final nested in value.values) {
          collect(nested);
        }
      } else if (value is List) {
        for (final nested in value) {
          collect(nested);
        }
      }
    }

    collect(details);
    return names;
  }

  List<Map<String, dynamic>> get openIssues => _objects(details['openIssues']);
  List<Map<String, dynamic>> get rgcDecisions =>
      _objects(details['rgcDecisions']);
  Map<String, dynamic> get latestMeeting =>
      details.containsKey('cdcInformation')
      ? _object(_object(details['cdcInformation'])['meeting'])
      : _object(_object(details['progressReport'])['latestMeeting']).isNotEmpty
      ? _object(_object(details['progressReport'])['latestMeeting'])
      : _objects(details['meetings']).firstOrNull ??
            _objects(
              _object(details['progressReport'])['meetings'],
            ).firstOrNull ??
            const {};

  static List<Map<String, dynamic>> _objects(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList()
      : const [];

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) throw FormatException('Invalid $key');
    return value;
  }

  static int? _int(Object? value) => value is int ? value : null;

  static String? _string(Object? value) => value is String ? value : null;

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static String _ministry(Map<String, dynamic> json) {
    final ministry = _string(_object(json['ministry'])['name']);
    if (ministry != null && ministry.isNotEmpty) return ministry;
    final documents = json['ministryDocuments'];
    if (documents is List && documents.isNotEmpty) {
      final first = _object(documents.first);
      final name = _string(_object(first['ministry'])['name']);
      if (name != null) return name;
    }
    return _string(_object(json['ministry'])['name']) ?? '';
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static DateTime? _meetingDate(Map<String, dynamic> json, int index) {
    final meetings =
        json['meetings'] ?? _object(json['progressReport'])['meetings'];
    if (meetings is! List || index >= meetings.length) return null;
    return _date(_object(meetings[index])['meetingDate']);
  }

  static DateTime? _deadlineDate(Map<String, dynamic> json, int index) {
    final deadlines =
        json['deadlines'] ?? _object(json['progressReport'])['deadlines'];
    if (deadlines is! List || index >= deadlines.length) return null;
    return _date(
      _object(deadlines[index])['date'] ??
          _object(deadlines[index])['deadline'],
    );
  }

  static Set<String> _attachmentPaths(Map<String, dynamic> json) {
    final paths = <String>{};
    void add(Object? value) {
      final path = _string(_object(value)['path']);
      if (path != null && path.isNotEmpty) paths.add(path);
    }

    add(json['attachment']);
    add(_object(json['ministryInformation'])['approvalProgressReport']);
    add(_object(json['cdcInformation'])['requestDocument']);
    add(json['draftSemesterReport']);
    add(json['finalSemesterReport']);
    add(_object(json['ministryAssignment'])['attachment']);
    final documents = json['ministryDocuments'];
    if (documents is List) {
      for (final document in documents) {
        add(_object(document)['document']);
      }
    }
    add(_object(json['progressReport'])['requestDocument']);
    add(_object(json['progressReport'])['draftSemesterReport']);
    add(_object(json['progressReport'])['finalSemesterReport']);
    // Meeting documents belong to this report as well as its semester PDFs.
    for (final source in [json, _object(json['progressReport'])]) {
      for (final meeting in _objects(source['meetings'])) {
        add(meeting['documentReference']);
      }
      add(_object(source['latestMeeting'])['documentReference']);
    }
    return paths;
  }

  static String _attachmentName(Map<String, dynamic> json) {
    final candidates = [
      json['finalSemesterReport'],
      json['draftSemesterReport'],
      _object(json['ministryAssignment'])['attachment'],
      json['attachment'],
      _object(json['progressReport'])['requestDocument'],
    ];
    for (final candidate in candidates) {
      final name = documentOriginalName(candidate);
      if (name.isNotEmpty) return name;
    }
    return '';
  }
}
