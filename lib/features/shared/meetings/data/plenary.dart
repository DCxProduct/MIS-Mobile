class Plenary {
  Plenary(Map<String, dynamic> json)
    : id = _int(json['id']),
      name = _string(json['name']).isNotEmpty
          ? _string(json['name'])
          : _string(json['title']),
      meetingDate = _date(json['meetingDate']),
      deadline = _date(json['deadline']),
      status = _string(json['status']),
      statusCode = _string(json['statusCode']),
      numberOfRgcDecisions = _int(json['numberOfRgcDecisions']),
      ministryCount = _listLength(json['ministries']),
      documentReference = _documentPath(json['documentReference']),
      documentName = _documentName(json['documentReference']),
      attachmentCount = _documentPath(json['documentReference']) == null
          ? 0
          : 1;

  final int id;
  final String name;
  final DateTime? meetingDate;
  final DateTime? deadline;
  final String status;
  final String statusCode;
  final int numberOfRgcDecisions;
  final int ministryCount;
  final String? documentReference;
  final String? documentName;
  final int attachmentCount;

  bool get isSent =>
      (statusCode.trim().isEmpty ? status : statusCode).trim().toUpperCase() ==
      'SENT';

  static int _int(Object? value) => value is int ? value : 0;

  static String _string(Object? value) => value is String ? value : '';

  static String? _nullableString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static int _listLength(Object? value) => value is List ? value.length : 0;

  static String? _documentPath(Object? value) =>
      _nullableString(value is Map<String, dynamic> ? value['path'] : value);

  static String? _documentName(Object? value) => value is Map<String, dynamic>
      ? _nullableString(value['originalName']) ?? _nullableString(value['name'])
      : null;
}
