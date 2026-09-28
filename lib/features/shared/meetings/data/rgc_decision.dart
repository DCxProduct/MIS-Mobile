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
