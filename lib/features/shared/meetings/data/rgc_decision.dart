class RgcDecision {
  RgcDecision(Map<String, dynamic> json)
    : id = _int(json['id']),
      agencyName = _string(_object(json['stakeholder'])['name']),
      status = _string(json['status']),
      statusCode = _string(json['statusCode']),
      meetingDate = _date(json['meetingDate']),
      category = json['category'] is String
          ? _string(json['category'])
          : _string(_object(json['categoryInfo'])['name']),
      focalPerson = _string(json['focalPerson']),
      linkCount = _links(json).length;

  final int id, linkCount;
  final String agencyName, status, statusCode, category, focalPerson;
  final DateTime? meetingDate;

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static int _int(Object? value) => value is int ? value : 0;

  static String _string(Object? value) => value is String ? value : '';

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

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
