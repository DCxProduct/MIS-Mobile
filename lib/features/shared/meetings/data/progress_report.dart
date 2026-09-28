class ProgressReport {
  ProgressReport(Map<String, dynamic> json)
    : id = _requiredInt(json, 'id'),
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
  final String title, semester, status, reportStatus, ministry, attachmentName;
  final List<String>? attachmentPaths;
  final DateTime? deadline, firstMeeting, secondMeeting, secondDeadline;

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
    final meetings = json['meetings'];
    if (meetings is! List || index >= meetings.length) return null;
    return _date(_object(meetings[index])['meetingDate']);
  }

  static DateTime? _deadlineDate(Map<String, dynamic> json, int index) {
    final deadlines = json['deadlines'];
    if (deadlines is! List || index >= deadlines.length) return null;
    return _date(_object(deadlines[index])['date']);
  }

  static Set<String> _attachmentPaths(Map<String, dynamic> json) {
    final paths = <String>{};
    void add(Object? value) {
      final path = _string(_object(value)['path']);
      if (path != null && path.isNotEmpty) paths.add(path);
    }

    add(json['attachment']);
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
      final name = _string(_object(candidate)['name']);
      if (name != null && name.isNotEmpty) return name;
    }
    return '';
  }
}
