class SystemNotification {
  SystemNotification.fromJson(Map<String, dynamic> json)
    : id = _id(json['id']),
      type = json['type'] as String? ?? '',
      title = json['title'] as String? ?? '',
      message = json['message'] as String? ?? '',
      isRead = json['isRead'] as bool? ?? false,
      createdAt = DateTime.tryParse(json['createdAt'] as String? ?? ''),
      meetingRequestId = _optionalId(json['meetingRequestId']),
      data = Map.unmodifiable(_object(json['data'])),
      sender = _object(json['senderUser']);

  final int id;
  final String type, title, message;
  final bool isRead;
  final DateTime? createdAt;
  final int? meetingRequestId;
  final Map<String, dynamic> data, sender;

  String get senderName =>
      _text(data['senderName']) ?? _text(sender['name']) ?? title;
  String? get avatar => _text(sender['avatar']);
  String? get url => _text(data['url']);
  int? resourceId(String key) => _optionalId(data[key]);

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic> ? value : const {};
  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
  static int _id(Object? value) =>
      _optionalId(value) ??
      (throw const FormatException('Invalid notification ID'));
  static int? _optionalId(Object? value) {
    final id = value is int ? value : int.tryParse('$value');
    return id != null && id > 0 ? id : null;
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.unreadBadge,
    required this.markReadOnDetail,
    required this.systemEnabled,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    if (json['unreadBadge'] is! bool ||
        json['markReadOnDetail'] is! bool ||
        json['systemEnabled'] is! bool) {
      throw const FormatException('Invalid notification settings');
    }
    return NotificationPreferences(
      unreadBadge: json['unreadBadge'] as bool,
      markReadOnDetail: json['markReadOnDetail'] as bool,
      systemEnabled: json['systemEnabled'] as bool,
    );
  }

  final bool unreadBadge, markReadOnDetail, systemEnabled;
}

class NotificationPage {
  const NotificationPage(this.items, this.page, this.totalPages, this.total);
  final List<SystemNotification> items;
  final int page, totalPages, total;
  bool get hasMore => page < totalPages;
}
