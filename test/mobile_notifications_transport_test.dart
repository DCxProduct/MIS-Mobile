import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/shared/notifications/data/mobile_notifications_transport.dart';
import 'package:gpsf_app/features/shared/notifications/data/notifications_repository.dart';

void main() {
  test(
    'push taps only open a positive notification for the signed-in user',
    () {
      expect(
        notificationIdForUser({'notificationId': '91', 'userId': '7'}, 7),
        91,
      );
      expect(
        notificationIdForUser({'notificationId': '91', 'userId': '7'}, 8),
        isNull,
      );
      expect(
        notificationIdForUser({'notificationId': '91', 'userId': '7'}, null),
        isNull,
      );
      expect(
        notificationIdForUser({'notificationId': '-1', 'userId': '7'}, 7),
        isNull,
      );
      expect(
        notificationIdForUser({'notificationId': 'bad', 'userId': '7'}, 7),
        isNull,
      );
    },
  );

  test(
    'realtime invalidation never fetches detail or starts seven-day retention',
    () async {
      final calls = <http.Request>[];
      final api = ApiClient(
        client: MockClient((request) async {
          calls.add(request);
          final data = request.url.path.endsWith('unread-count')
              ? {'count': 2}
              : {
                  'systemEnabled': true,
                  'unreadBadge': true,
                  'markReadOnDetail': false,
                  'gmailEnabled': false,
                  'gmailAddress': null,
                };
          return http.Response(
            jsonEncode({'success': true, 'data': data}),
            200,
          );
        }),
      );
      final repository = NotificationsRepository(api);
      final changed = expectLater(repository.liveChanges, emits(null));
      repository.notifyRealtimeChanged();
      await changed;
      await repository.refreshBadge(background: true);
      expect(repository.unreadCount, 2);
      expect(calls, hasLength(2));
      expect(
        calls.every((call) => call.headers['x-background-poll'] == '1'),
        isTrue,
      );
      expect(calls.every((call) => !call.url.path.endsWith('/91')), isTrue);
      repository.dispose();
      api.close();
    },
  );

  test(
    'socket ticket requests keep cookie authentication and are marked as background',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(
            request.url.path,
            '/api/v1/mobile/system-notifications/socket-ticket',
          );
          expect(request.headers['x-background-poll'], '1');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'ticket': 'short-lived'},
            }),
            200,
          );
        }),
      );
      expect(
        await api.post(
          'mobile/system-notifications/socket-ticket',
          body: {},
          background: true,
        ),
        {'ticket': 'short-lived'},
      );
      api.close();
    },
  );
}
