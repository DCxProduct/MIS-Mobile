import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import 'system_notification.dart';

/// Uses the login session's API client. The server scopes every operation to
/// the current user and their stakeholders; no receiver IDs are invented here.
class NotificationsRepository extends ChangeNotifier {
  NotificationsRepository(this._api);
  final ApiClient _api;
  int? unreadCount;
  NotificationPreferences? preferences;
  int _session = 0;

  Future<NotificationPage> getPage({
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) async {
    final session = _session;
    final response = await _api.getListPage(
      'system-notifications',
      query: {
        'page': '$page',
        'limit': '$limit',
        'type': ?type,
        if (isRead != null) 'isRead': '$isRead',
      },
    );
    try {
      final meta = response['meta'] as Map<String, dynamic>;
      final items = (response['data'] as List)
          .map(
            (row) => SystemNotification.fromJson(row as Map<String, dynamic>),
          )
          .toList();
      final result = NotificationPage(
        List.unmodifiable(items),
        _count(meta['page']),
        _count(meta['totalPages']),
        _count(meta['total']),
      );
      if (type == null && isRead == null && session == _session) {
        unreadCount = _count(meta['unreadCount']);
        notifyListeners();
      }
      return result;
    } on FormatException {
      throw const ApiException('The server returned invalid notifications.');
    } on TypeError {
      throw const ApiException('The server returned invalid notifications.');
    }
  }

  Future<SystemNotification> getNotification(int id) async {
    _checkId(id);
    final envelope = await _api.getObjectPage('system-notifications/$id');
    try {
      final data = envelope['data'] as Map<String, dynamic>;
      // The backend interceptor lifts a resource's message into the envelope.
      final notification = SystemNotification.fromJson({
        ...data,
        'message': data['message'] ?? envelope['message'],
      });
      if (notification.id != id) {
        throw const FormatException('Invalid detail ID');
      }
      return notification;
    } on FormatException {
      throw const ApiException('The server returned an invalid notification.');
    } on TypeError {
      throw const ApiException('The server returned an invalid notification.');
    }
  }

  Future<NotificationPreferences> getPreferences() async {
    final session = _session;
    final data = await _api.get('notification-settings/me');
    try {
      final result = NotificationPreferences.fromJson(data);
      if (session == _session) {
        preferences = result;
        notifyListeners();
      }
      return result;
    } on FormatException {
      throw const ApiException(
        'The server returned invalid notification settings.',
      );
    }
  }

  Future<void> refreshBadge() async {
    final session = _session;
    final results = await Future.wait([
      _api.get('system-notifications/unread-count'),
      getPreferences(),
    ]);
    final count = _count((results.first as Map<String, dynamic>)['count']);
    if (session == _session) {
      unreadCount = count;
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    _checkId(id);
    final session = _session;
    await _api.patchAction('system-notifications/$id/read');
    if (session != _session) return;
    // Refresh rather than decrement: another device may have read the item.
    try {
      final data = await _api.get('system-notifications/unread-count');
      if (session == _session) unreadCount = _count(data['count']);
    } catch (_) {
      if (session == _session) unreadCount = null;
    }
    if (session == _session) notifyListeners();
  }

  Future<NotificationPreferences> updatePreferences({
    bool? unreadBadge,
    bool? markReadOnDetail,
    bool? systemEnabled,
  }) async {
    await _api.patch(
      'notification-settings/me',
      body: {
        'unreadBadge': ?unreadBadge,
        'markReadOnDetail': ?markReadOnDetail,
        'systemEnabled': ?systemEnabled,
      },
    );
    return getPreferences();
  }

  Future<void> markAllRead() async {
    final session = _session;
    await _api.patchAction('system-notifications/read-all');
    if (session == _session) {
      unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    _checkId(id);
    await _api.deleteAction('system-notifications/$id');
    await refreshBadge();
  }

  Future<void> deleteAll() async {
    final session = _session;
    await _api.deleteAction('system-notifications/all');
    if (session == _session) {
      unreadCount = 0;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getResource(String endpoint) =>
      _api.get(endpoint);

  Future<void> updateSummary(int id, Map<String, dynamic> changes) async {
    _checkId(id);
    await _api.patchAction('meeting-summaries/$id', body: changes);
  }

  void resetSession() {
    _session++;
    unreadCount = null;
    preferences = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _session++;
    super.dispose();
  }

  static int _count(Object? value) {
    if (value is! int || value < 0) {
      throw const FormatException('Invalid count');
    }
    return value;
  }

  static void _checkId(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
  }
}
