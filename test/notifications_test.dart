import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/auth/data/auth_user.dart';
import 'package:gpsf_app/features/shared/notifications/data/notification_destination.dart';
import 'package:gpsf_app/features/shared/notifications/data/notifications_repository.dart';
import 'package:gpsf_app/features/shared/notifications/data/system_notification.dart';
import 'package:gpsf_app/screens/notification/notification_destination_screen.dart';
import 'package:gpsf_app/screens/notification/notification_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/widgets/notification_bell.dart';

Map<String, dynamic> notification({
  String type = 'MEETING_REQUEST',
  Map<String, dynamic> data = const {'meetingRequestId': 17},
}) => {
  'id': 91,
  'type': type,
  'title': 'MAFF',
  'message': 'A real notification',
  'isRead': false,
  'createdAt': '2026-10-01T08:00:00Z',
  'senderUser': {'name': 'MAFF'},
  'data': data,
};
http.Response response(
  Object data, {
  Map<String, Object>? meta,
  String? message,
}) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'success': true,
      'data': data,
      'meta': ?meta,
      'message': ?message,
    }),
  ),
  200,
);
Map<String, Object> meta({
  int page = 1,
  int totalPages = 1,
  int total = 1,
  int unread = 1,
}) => {
  'page': page,
  'limit': 20,
  'totalPages': totalPages,
  'total': total,
  'unreadCount': unread,
};
Map<String, dynamic> preferences({bool markRead = false, bool badge = true}) =>
    {'unreadBadge': badge, 'markReadOnDetail': markRead, 'systemEnabled': true};

void main() {
  test('notification routes use the resource ID and recipient URL', () {
    final cases = [
      (
        'MEETING_REQUEST',
        '/ministry/meeting-requests/17',
        NotificationDestinationKind.meetingRequest,
        17,
      ),
      (
        'MEETING_SCHEDULED',
        '/pswg/meeting-requests?view=calendar&meetingId=22',
        NotificationDestinationKind.scheduledMeeting,
        22,
      ),
      (
        'MEETING_SCHEDULED',
        '/cdc-gpsf/meeting-calendar',
        NotificationDestinationKind.calendar,
        null,
      ),
      (
        'PLENARY_SENT',
        '/ministry/plenary/plenaries/23',
        NotificationDestinationKind.plenary,
        23,
      ),
      (
        'PROGRESS_REPORT_SENT',
        '/ministry/progress-reports/24',
        NotificationDestinationKind.progressReport,
        24,
      ),
      (
        'PROGRESS_REPORT_SHARED',
        '/pswg/progress-report/46',
        NotificationDestinationKind.sharedProgressReport,
        46,
      ),
      (
        'MEETING_SUMMARY_SENT_BACK',
        '/ministry/meeting-summary/25/edit',
        NotificationDestinationKind.editMeetingSummary,
        25,
      ),
      (
        'MEETING_SUMMARY_SHARED',
        '/pswg/meeting-summary/26',
        NotificationDestinationKind.meetingSummary,
        26,
      ),
      (
        'MEETING_SUMMARY_SUBMITTED',
        '/cdc-gpsf/meeting-summary/27',
        NotificationDestinationKind.meetingSummary,
        27,
      ),
      (
        'RGC_DECISION_SUBMITTED',
        '/ministry/plenary/plenaries/28',
        NotificationDestinationKind.plenary,
        28,
      ),
      (
        'RGC_DECISION_SUBMITTED',
        '/cdc-gpsf/plenary/plenaries/29',
        NotificationDestinationKind.plenary,
        29,
      ),
      (
        'RGC_DECISION_SUBMITTED',
        '/cefp/plenary/rgc-decision',
        NotificationDestinationKind.rgcDecisions,
        null,
      ),
      (
        'ISSUE_AGENCY_REASSIGNED',
        '/ministry/issue-matrix',
        NotificationDestinationKind.issueMatrix,
        null,
      ),
      (
        'ISSUE_AGENCY_REASSIGNED',
        '/pswg/wg-issues/30',
        NotificationDestinationKind.issue,
        30,
      ),
    ];
    for (final (type, url, kind, id) in cases) {
      final destination = NotificationDestination.resolve(
        SystemNotification.fromJson(
          notification(type: type, data: {'url': url}),
        ),
        AppModuleType.lineMinistry,
      )!;
      expect(destination.kind, kind);
      expect(destination.id, id);
      expect(destination.route, url);
    }
  });

  test(
    'missing URLs fall back to IDs for the current module, never notification ID',
    () {
      final decision = SystemNotification.fromJson(
        notification(
          type: 'RGC_DECISION_SUBMITTED',
          data: {'rgcDecisionId': 44, 'plenaryId': 3},
        ),
      );
      expect(
        NotificationDestination.resolve(
          decision,
          AppModuleType.lineMinistry,
        )!.endpoint,
        'rgc-decisions/44',
      );
      expect(
        NotificationDestination.resolve(
          decision,
          AppModuleType.cdcSecretariat,
        )!.route,
        '/rgc-decisions/44',
      );
      expect(
        NotificationDestination.resolve(decision, AppModuleType.cefp)!.kind,
        NotificationDestinationKind.rgcDecision,
      );
      final missing = SystemNotification.fromJson(notification(data: {}));
      expect(
        NotificationDestination.resolve(missing, AppModuleType.lineMinistry),
        isNull,
      );
    },
  );

  test(
    'shared report uses assignment ID, never the parent progress report ID',
    () {
      final shared = SystemNotification.fromJson(
        notification(
          type: 'PROGRESS_REPORT_SHARED',
          data: {
            'url': '/pswg/progress-report/46',
            'progressReportId': 4,
            'ministryId': 3,
          },
        ),
      );
      final destination = NotificationDestination.resolve(
        shared,
        AppModuleType.privateSector,
      )!;
      expect(destination.id, 46);
      expect(destination.endpoint, 'progress-reports/assignments/46');
      final missing = SystemNotification.fromJson(
        notification(
          type: 'PROGRESS_REPORT_SHARED',
          data: {'progressReportId': 4, 'ministryId': 3},
        ),
      );
      expect(
        NotificationDestination.resolve(missing, AppModuleType.privateSector),
        isNull,
      );
      final explicit = SystemNotification.fromJson(
        notification(
          type: 'PROGRESS_REPORT_SHARED',
          data: {'assignmentId': 46, 'progressReportId': 4},
        ),
      );
      expect(
        NotificationDestination.resolve(
          explicit,
          AppModuleType.privateSector,
        )!.endpoint,
        'progress-reports/assignments/46',
      );
    },
  );

  test(
    'submitted RGC notification opens its decision while preserving recipient routes',
    () {
      for (final route in [
        '/cdc-gpsf/plenary/plenaries/3',
        '/ministry/plenary/plenaries/3',
        '/cefp/plenary/rgc-decision',
      ]) {
        final item = SystemNotification.fromJson(
          notification(
            type: 'RGC_DECISION_SUBMITTED',
            data: {'url': route, 'rgcDecisionId': 42, 'plenaryId': 3},
          ),
        );
        final destination = NotificationDestination.resolve(
          item,
          AppModuleType.cdcSecretariat,
        )!;
        expect(destination.kind, NotificationDestinationKind.rgcDecision);
        expect(destination.endpoint, 'rgc-decisions/42');
        expect(destination.route, route);
      }
      final invalid = SystemNotification.fromJson(
        notification(
          type: 'RGC_DECISION_SUBMITTED',
          data: {'url': 'https://example.com', 'rgcDecisionId': 42},
        ),
      );
      expect(
        NotificationDestination.resolve(invalid, AppModuleType.cdcSecretariat),
        isNull,
      );
    },
  );

  test(
    'scheduled notifications use meeting IDs for direct detail and preserve the calendar fallback when absent',
    () {
      for (final module in [
        AppModuleType.privateSector,
        AppModuleType.cdcSecretariat,
      ]) {
        final meeting = SystemNotification.fromJson(
          notification(
            type: 'MEETING_SCHEDULED',
            data: {'meetingId': 22, 'meetingRequestId': 17},
          ),
        );
        final destination = NotificationDestination.resolve(meeting, module)!;
        expect(destination.kind, NotificationDestinationKind.scheduledMeeting);
        expect(destination.endpoint, 'meetings/22');
      }
      final withoutId = SystemNotification.fromJson(
        notification(type: 'MEETING_SCHEDULED', data: {}),
      );
      expect(
        NotificationDestination.resolve(withoutId, AppModuleType.privateSector),
        isNull,
      );
      expect(
        NotificationDestination.resolve(
          withoutId,
          AppModuleType.cdcSecretariat,
        )!.kind,
        NotificationDestinationKind.calendar,
      );
    },
  );

  test(
    'escalation, unknown types and unsupported URLs never open another page',
    () {
      for (final row in [
        notification(
          type: 'ISSUE_ESCALATED',
          data: {'url': '/pswg/wg-issues/2'},
        ),
        notification(type: 'UNKNOWN'),
        notification(
          data: {'url': 'https://example.com/ministry/meeting-requests/17'},
        ),
        notification(
          data: {'url': '//example.com/ministry/meeting-requests/17'},
        ),
        notification(data: {'url': '/ministry/meeting-requests/0'}),
        notification(data: {'url': '/ministry/meeting-requests/../17'}),
      ]) {
        expect(
          NotificationDestination.resolve(
            SystemNotification.fromJson(row),
            AppModuleType.lineMinistry,
          ),
          isNull,
        );
      }
    },
  );

  test('list pages retain metadata, filters and real sender values', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/system-notifications');
        expect(request.url.queryParameters, {
          'page': '2',
          'limit': '20',
          'type': 'MEETING_REQUEST',
          'isRead': 'false',
        });
        return response([
          notification(data: {'senderName': 'ក្រសួង', 'meetingRequestId': 17}),
        ], meta: meta(page: 2, totalPages: 3, total: 55));
      }),
    );
    addTearDown(api.close);
    final repo = NotificationsRepository(api);
    addTearDown(repo.dispose);
    final page = await repo.getPage(
      page: 2,
      type: 'MEETING_REQUEST',
      isRead: false,
    );
    expect(page.hasMore, isTrue);
    expect(page.total, 55);
    expect(page.items.first.senderName, 'ក្រសួង');
    expect(
      repo.unreadCount,
      isNull,
    ); // A filtered count is not the global badge.
  });

  test(
    'detail handles interceptor message and rejects a mismatched record',
    () async {
      var wrongId = false;
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/system-notifications/91');
          final row = notification()..remove('message');
          if (wrongId) row['id'] = 92;
          return response(row, message: 'Actual detail message');
        }),
      );
      addTearDown(api.close);
      final repo = NotificationsRepository(api);
      addTearDown(repo.dispose);
      expect((await repo.getNotification(91)).message, 'Actual detail message');
      wrongId = true;
      await expectLater(repo.getNotification(91), throwsA(isA<ApiException>()));
    },
  );

  test(
    'mark read, read all, delete and settings use the correct authenticated paths',
    () async {
      final calls = <String>[];
      final api = ApiClient(
        client: MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          if (request.url.path.endsWith('unread-count')) {
            return response({'count': 0});
          }
          if (request.url.path.endsWith('notification-settings/me')) {
            return response(preferences(markRead: true));
          }
          return response({'updated': 1});
        }),
      );
      addTearDown(api.close);
      final repo = NotificationsRepository(api);
      addTearDown(repo.dispose);
      await repo.markRead(91);
      await repo.markAllRead();
      await repo.delete(91);
      await repo.deleteAll();
      await repo.updatePreferences(markReadOnDetail: true);
      expect(
        calls,
        containsAll([
          'PATCH /api/v1/system-notifications/91/read',
          'PATCH /api/v1/system-notifications/read-all',
          'DELETE /api/v1/system-notifications/91',
          'DELETE /api/v1/system-notifications/all',
          'PATCH /api/v1/notification-settings/me',
        ]),
      );
      expect(repo.preferences!.markReadOnDetail, isTrue);
      expect(repo.unreadCount, 0);
    },
  );

  test(
    'logout ignores pending unread responses from the previous session',
    () async {
      final pending = Completer<http.Response>();
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('unread-count')) return pending.future;
          return response(preferences());
        }),
      );
      addTearDown(api.close);
      final repo = NotificationsRepository(api);
      addTearDown(repo.dispose);
      final refresh = repo.refreshBadge();
      repo.resetSession();
      pending.complete(response({'count': 7}));
      await refresh;
      expect(repo.unreadCount, isNull);
      expect(repo.preferences, isNull);
    },
  );

  for (final markRead in [false, true]) {
    testWidgets('live feed opens correct request; markReadOnDetail=$markRead', (
      tester,
    ) async {
      final calls = <String>[];
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              calls.add('${request.method} ${request.url.path}');
              switch (request.url.path) {
                case '/api/v1/system-notifications':
                  return response([notification()], meta: meta());
                case '/api/v1/system-notifications/91':
                  return response(notification());
                case '/api/v1/notification-settings/me':
                  return response(preferences(markRead: markRead));
                case '/api/v1/system-notifications/91/read':
                  return response({});
                case '/api/v1/system-notifications/unread-count':
                  return response({'count': 0});
                case '/api/v1/meeting-requests/17':
                  return response({
                    'id': 17,
                    'title': 'Actual meeting',
                    'description': '<p>Live meeting description</p>',
                  });
                default:
                  fail('Unexpected notification request ${request.url}');
              }
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A real notification'), findsOneWidget);
      expect(find.text('1 unread notifications'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notification-detail-91')));
      await tester.pumpAndSettle();
      expect(find.text('Actual meeting'), findsOneWidget);
      expect(find.text('Live meeting description'), findsOneWidget);
      expect(
        calls.contains('PATCH /api/v1/system-notifications/91/read'),
        markRead,
      );
      expect(calls, contains('GET /api/v1/meeting-requests/17'));
      expect(calls, isNot(contains('GET /api/v1/meeting-requests/91')));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'pagination and refresh keep all real rows; no-link escalation stays on feed',
    (tester) async {
      var page1Calls = 0;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              if (request.url.path == '/api/v1/system-notifications') {
                if (request.url.queryParameters['page'] == '1') {
                  page1Calls++;
                  return response([
                    notification(),
                  ], meta: meta(totalPages: 2, total: 2));
                }
                return response([
                  {
                    ...notification(type: 'ISSUE_ESCALATED', data: {}),
                    'id': 92,
                    'message': 'Escalated issue',
                  },
                ], meta: meta(page: 2, totalPages: 2, total: 2));
              }
              if (request.url.path == '/api/v1/system-notifications/92') {
                return response({
                  ...notification(type: 'ISSUE_ESCALATED', data: {}),
                  'id': 92,
                });
              }
              if (request.url.path.endsWith('notification-settings/me')) {
                return response(preferences());
              }
              fail('Unexpected request ${request.url}');
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(find.text('Escalated issue'), findsOneWidget);
      expect(find.text('View Detail'), findsOneWidget);
      await tester.tap(find.text('Escalated issue'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationScreen), findsOneWidget);
      expect(find.byType(NotificationDestinationScreen), findsNothing);
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();
      expect(page1Calls, 2);
      expect(find.text('Escalated issue'), findsNothing);
    },
  );

  testWidgets(
    'unauthorized list shows sign-in error with retry and no demo cards',
    (tester) async {
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient(
              (_) async => http.Response(
                jsonEncode({
                  'success': false,
                  'message': 'Please sign in again.',
                }),
                401,
              ),
            ),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Please sign in again.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('MAFF'), findsNothing);
    },
  );

  testWidgets(
    'bell respects unreadBadge and updates from shared unread count',
    (tester) async {
      var showBadge = true;
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    return request.url.path.endsWith('unread-count')
                        ? response({'count': 7})
                        : response(preferences(badge: showBadge));
                  }),
                ),
              ),
            )
            ..setLanguage(AppLanguage.english)
            ..setCurrentUser(
              const AuthUser(
                id: 1,
                email: 'user@example.com',
                name: 'User',
                isActive: true,
                roles: ['ministry'],
              ),
            );
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: Scaffold(body: NotificationBell())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);
      showBadge = false;
      await settings.notifications.refreshBadge();
      await tester.pump();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    },
  );

  testWidgets(
    'sent-back summary editor saves only changed fields to the actual summary',
    (tester) async {
      Map<String, dynamic>? saved;
      final data = {
        'id': 8,
        'status': 'DRAFT',
        'ministryReporter': 'Original',
        'meeting': {'title': 'Returned summary'},
        'issues': [
          {
            'id': 3,
            'issue': 'Actual issue',
            'remark': '<p>Preserve this rich text</p>',
          },
        ],
      };
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              expect(request.url.path, '/api/v1/meeting-summaries/8');
              if (request.method == 'PATCH') {
                saved = jsonDecode(request.body) as Map<String, dynamic>;
                return response({});
              }
              return response(data);
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(
            home: NotificationDestinationScreen(
              destination: NotificationDestination(
                NotificationDestinationKind.editMeetingSummary,
                '/ministry/meeting-summary/8/edit',
                id: 8,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Original'),
        'Corrected',
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, {'ministryReporter': 'Corrected'});
      expect(find.text('Changes saved.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
