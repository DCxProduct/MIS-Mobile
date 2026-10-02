import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/private_sector/reports/meeting_summary_detail_screen.dart';
import 'package:gpsf_app/features/cdc_section/reports/rgc_decision_details.dart';
import 'package:gpsf_app/features/shared/notifications/data/notification_destination.dart';
import 'package:gpsf_app/screens/notification/notification_destination_screen.dart';
import 'package:gpsf_app/screens/notification/notification_screen.dart';
import 'package:gpsf_app/screens/report/report_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';

http.Response ok(Object data, {Map<String, dynamic>? meta}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode({'success': true, 'data': data, 'meta': ?meta})),
      200,
    );

Widget destinationApp(
  AppSettingsController settings,
  NotificationDestination destination,
) => AppSettings(
  controller: settings,
  child: MaterialApp(
    home: NotificationDestinationScreen(destination: destination),
  ),
);

void main() {
  for (final (module, route) in [
    (AppModuleType.cdcSecretariat, '/cdc-gpsf/plenary/plenaries/3'),
    (AppModuleType.lineMinistry, '/ministry/plenary/plenaries/3'),
    (AppModuleType.cefp, '/cefp/plenary/rgc-decision'),
  ]) {
    testWidgets(
      '$module RGC notification opens the submitted decision overview directly',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <String>[];
        final item = {
          'id': 91,
          'type': 'RGC_DECISION_SUBMITTED',
          'title': 'MAFF',
          'message': 'MAFF submitted an RGC Decision for "21th".',
          'isRead': false,
          'createdAt': '2026-09-14T08:00:00Z',
          'data': {'rgcDecisionId': 42, 'plenaryId': 3, 'url': route},
        };
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      calls.add('${request.method} ${request.url.path}');
                      switch (request.url.path) {
                        case '/api/v1/system-notifications':
                          return ok(
                            [item],
                            meta: {
                              'page': 1,
                              'limit': 20,
                              'totalPages': 1,
                              'total': 1,
                              'unreadCount': 1,
                            },
                          );
                        case '/api/v1/system-notifications/91':
                          return ok(item);
                        case '/api/v1/notification-settings/me':
                          return ok({
                            'unreadBadge': true,
                            'markReadOnDetail': false,
                            'systemEnabled': true,
                          });
                        case '/api/v1/rgc-decisions/42':
                          return ok({
                            'id': 42,
                            'plenaryId': 3,
                            'deadline': '2026-10-03',
                            'meetingDate': '2026-09-14',
                            'status': 'Not Addressed',
                            'statusCode': 'NOT_ADDRESSED',
                            'stakeholder': {'name': 'MAFF'},
                            'category': 'Climate',
                            'focalPerson': 'H.E. Mr. DITH TINA',
                            'issues': [
                              {
                                'id': 5,
                                'rgcDecision': 'Actual linked RGC decision',
                                'category': {'name': 'Market Access'},
                                'meetingDate': '2026-09-03',
                                'issueStatus': {'name': 'In Progress'},
                              },
                            ],
                          });
                        default:
                          fail('Unexpected request ${request.url}');
                      }
                    }),
                  ),
                ),
              )
              ..setLanguage(AppLanguage.english)
              ..setModuleType(module);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(home: NotificationScreen()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('View Detail'));
        await tester.pumpAndSettle();
        expect(find.byType(CdcRgcDecisionOverviewScreen), findsOneWidget);
        expect(find.text('RGC Decision Details'), findsOneWidget);
        expect(find.text('Oct 3, 2026'), findsOneWidget);
        expect(find.text('Sep 14, 2026'), findsOneWidget);
        expect(find.text('Not Addressed'), findsOneWidget);
        expect(find.text('Sep 3, 2026'), findsOneWidget);
        expect(find.text('Market Access'), findsOneWidget);
        expect(find.text('Actual linked RGC decision'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(calls, contains('GET /api/v1/rgc-decisions/42'));
        expect(calls, isNot(contains('GET /api/v1/rgc-decisions/91')));
        expect(calls, isNot(contains('GET /api/v1/rgc-decisions/3')));
        expect(calls, isNot(contains('GET /api/v1/plenaries/3')));
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(
          find.text('MAFF submitted an RGC Decision for "21th".'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('RGC notification detail can retry a failed API request', (
    tester,
  ) async {
    var requests = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((request) async {
            expect(request.url.path, '/api/v1/rgc-decisions/42');
            requests++;
            if (requests == 1) {
              return http.Response(
                jsonEncode({'success': false, 'message': 'Unavailable'}),
                503,
              );
            }
            return ok({
              'id': 42,
              'status': 'Solved',
              'deadline': '2026-10-03',
              'issues': [],
            });
          }),
        ),
      ),
    )..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      destinationApp(
        settings,
        const NotificationDestination(
          NotificationDestinationKind.rgcDecision,
          '/cdc-gpsf/plenary/plenaries/3',
          id: 42,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Solved'), findsOneWidget);
    expect(find.text('No RGC decisions found.'), findsOneWidget);
    expect(requests, 2);
    expect(tester.takeException(), isNull);
  });

  for (final (module, route) in [
    (
      AppModuleType.privateSector,
      '/pswg/meeting-requests?view=calendar&meetingId=22',
    ),
    (AppModuleType.cdcSecretariat, '/cdc-gpsf/meeting-calendar'),
  ]) {
    testWidgets(
      '$module scheduled notification opens actual meeting detail directly',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <String>[];
        final notification = {
          'id': 91,
          'type': 'MEETING_SCHEDULED',
          'title': 'MAFF',
          'message': 'Meeting scheduled: Actual scheduled meeting',
          'isRead': false,
          'createdAt': '2026-09-14T08:00:00Z',
          'meetingRequestId': 17,
          'data': {'meetingId': 22, 'meetingRequestId': 17, 'url': route},
        };
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      calls.add('${request.method} ${request.url.path}');
                      switch (request.url.path) {
                        case '/api/v1/system-notifications':
                          return ok(
                            [notification],
                            meta: {
                              'page': 1,
                              'limit': 20,
                              'totalPages': 1,
                              'total': 1,
                              'unreadCount': 1,
                            },
                          );
                        case '/api/v1/system-notifications/91':
                          return ok(notification);
                        case '/api/v1/notification-settings/me':
                          return ok({
                            'unreadBadge': true,
                            'markReadOnDetail': false,
                            'systemEnabled': true,
                          });
                        case '/api/v1/meetings/22':
                          return ok({
                            'id': 22,
                            'title': 'Actual scheduled meeting',
                            'status': 'SCHEDULED',
                            'description':
                                '<p>Actual scheduled description</p>',
                            'meetingDate': '2026-09-14T00:00:00Z',
                            'documentReference': {
                              'path': '/uploads/meeting_document.pdf',
                              'name': 'meeting_document.pdf',
                              'size': 2048,
                            },
                            'user': {'name': 'MAFF'},
                            'meetingRequest': {
                              'id': 17,
                              'privateSectorWG': 'Agriculture & Agro-Industry',
                              'governmentAgencies': [
                                {
                                  'stakeholder': {'id': 4, 'name': 'MAFF'},
                                },
                              ],
                              'issues': [
                                {
                                  'id': 5,
                                  'title': 'Actual linked issue',
                                  'description':
                                      '<p>Actual linked issue description</p>',
                                },
                              ],
                            },
                          });
                        default:
                          fail('Unexpected request ${request.url}');
                      }
                    }),
                  ),
                ),
              )
              ..setLanguage(AppLanguage.english)
              ..setModuleType(module);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(home: NotificationScreen()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('notification-detail-91')));
        await tester.pumpAndSettle();
        expect(find.text('Meeting Request Details'), findsOneWidget);
        expect(find.text('Actual scheduled meeting'), findsOneWidget);
        expect(find.text('Actual scheduled description'), findsOneWidget);
        expect(find.text('meeting_document.pdf'), findsOneWidget);
        expect(find.text('Scheduled'), findsOneWidget);
        expect(calls.where((call) => call.contains('/meetings')), [
          'GET /api/v1/meetings/22',
        ]);
        expect(calls, isNot(contains('GET /api/v1/meeting-requests/17')));
        expect(calls, isNot(contains('GET /api/v1/meetings/91')));
        await tester.tap(find.text('All Issues'));
        await tester.pumpAndSettle();
        expect(find.text('Actual linked issue'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pumpAndSettle();
        expect(
          find.text('Meeting scheduled: Actual scheduled meeting'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'shared summary notification opens the existing summary detail directly using its resource ID',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final calls = <String>[];
      final notification = {
        'id': 91,
        'type': 'MEETING_SUMMARY_SHARED',
        'title': 'MAFF',
        'message': 'Meeting summary shared: Actual summary',
        'isRead': false,
        'createdAt': '2026-09-15T08:00:00Z',
        'data': {'meetingSummaryId': 26, 'url': '/pswg/meeting-summary/26'},
      };
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              calls.add('${request.method} ${request.url.path}');
              switch (request.url.path) {
                case '/api/v1/system-notifications':
                  return ok(
                    [notification],
                    meta: {
                      'page': 1,
                      'limit': 20,
                      'totalPages': 1,
                      'total': 1,
                      'unreadCount': 1,
                    },
                  );
                case '/api/v1/system-notifications/91':
                  return ok(notification);
                case '/api/v1/notification-settings/me':
                  return ok({
                    'unreadBadge': true,
                    'markReadOnDetail': false,
                    'systemEnabled': true,
                  });
                case '/api/v1/meeting-summaries/26':
                  return ok({
                    'id': 26,
                    'status': 'SHARED',
                    'meeting': {
                      'title': 'Actual summary meeting',
                      'meetingDate': '2026-09-14T00:00:00Z',
                      'location': 'Actual meeting room',
                    },
                    'meetingRequest': {
                      'meetingRequestLetter': {'path': '/uploads/request.pdf'},
                    },
                    'issues': [
                      {
                        'id': 1,
                        'issue': 'Actual summary issue',
                        'category': 'General',
                        'status': 'IN_PROGRESS',
                        'issueDescription': '<p>Actual issue description</p>',
                      },
                      {
                        'id': 2,
                        'issue': 'Second summary issue',
                        'category': 'Regulation',
                        'status': 'SOLVED',
                        'issueDescription': '<p>Second description</p>',
                      },
                    ],
                  });
                default:
                  fail('Unexpected request ${request.url}');
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
      await tester.tap(find.byKey(const ValueKey('notification-detail-91')));
      await tester.pumpAndSettle();
      expect(find.byType(MeetingSummaryDetailScreen), findsOneWidget);
      expect(find.text('Meeting Summary Details'), findsOneWidget);
      expect(find.text('Actual summary meeting'), findsOneWidget);
      expect(find.text('Actual meeting room'), findsOneWidget);
      expect(find.text('Actual summary issue'), findsOneWidget);
      expect(find.text('Second summary issue'), findsOneWidget);
      expect(find.text('IN_PROGRESS'), findsOneWidget);
      expect(find.text('SOLVED'), findsOneWidget);
      expect(calls.where((call) => call.contains('meeting-summaries')), [
        'GET /api/v1/meeting-summaries/26',
      ]);
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();
      expect(
        find.text('Meeting summary shared: Actual summary'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'summary detail retry uses the same resource ID after a failed fetch',
    (tester) async {
      var summaryCalls = 0;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              expect(request.url.path, '/api/v1/meeting-summaries/26');
              summaryCalls++;
              if (summaryCalls == 1) return http.Response('', 503);
              return ok({
                'id': 26,
                'meeting': {'title': 'Recovered summary'},
                'issues': [],
              });
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        destinationApp(
          settings,
          const NotificationDestination(
            NotificationDestinationKind.meetingSummary,
            '/pswg/meeting-summary/26',
            id: 26,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Meeting Summary Details'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered summary'), findsOneWidget);
      expect(find.text('No issues found.'), findsOneWidget);
      expect(find.text('Climate Issue'), findsNothing);
      expect(summaryCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'plenary notification fetches its plenary and decisions filtered by plenaryId',
    (tester) async {
      final requests = <Uri>[];
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              requests.add(request.url);
              if (request.url.path == '/api/v1/plenaries/3') {
                return ok({
                  'id': 3,
                  'name': 'Actual plenary',
                  'status': 'Sent',
                  'meetingDate': '2026-10-03T00:00:00Z',
                });
              }
              if (request.url.path == '/api/v1/rgc-decisions') {
                expect(request.url.queryParameters['plenaryId'], '3');
                return ok({
                  'items': [
                    {
                      'id': 42,
                      'stakeholder': {'name': 'Actual ministry'},
                      'category': 'Climate',
                      'status': 'Solved',
                    },
                  ],
                  'meta': {'totalPages': 1},
                });
              }
              fail('Unexpected request ${request.url}');
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        destinationApp(
          settings,
          const NotificationDestination(
            NotificationDestinationKind.plenary,
            '/ministry/plenary/plenaries/3',
            id: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Actual plenary'), findsOneWidget);
      expect(find.text('Actual ministry'), findsOneWidget);
      expect(requests.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('calendar page selects its initial meeting across months', (
    tester,
  ) async {
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((request) async {
            expect(request.url.path, '/api/v1/meetings');
            return ok({
              'items': [
                {
                  'id': 1,
                  'title': 'First meeting',
                  'meetingDate': '2026-01-01T00:00:00Z',
                },
                {
                  'id': 22,
                  'title': 'Notification meeting',
                  'meetingDate': '2026-10-05T00:00:00Z',
                },
              ],
              'meta': {'totalPages': 1},
            });
          }),
        ),
      ),
    )..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      destinationApp(
        settings,
        const NotificationDestination(
          NotificationDestinationKind.calendar,
          '/pswg/meeting-requests?view=calendar&meetingId=22',
          id: 22,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Notification meeting'), findsOneWidget);
    expect(find.text('First meeting'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'progress-report notification uses existing detail UI with actual content and documents',
    (tester) async {
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              expect(
                request.url.path,
                '/api/v1/progress-reports/4/ministries/me',
              );
              return ok({
                'id': 46,
                'progressReportId': 4,
                'title': 'Actual semester report',
                'year': 2026,
                'semester': 'S2',
                'status': 'SENT',
                'description': '<p>Actual report content</p>',
                'deadlines': [
                  {'date': '2026-11-12T00:00:00Z'},
                ],
                'meetings': [
                  {
                    'title': 'Actual report meeting',
                    'meetingDate': '2026-10-05T00:00:00Z',
                  },
                ],
                'draftSemesterReport': {'path': '/uploads/draft.pdf'},
                'finalSemesterReport': {'path': '/uploads/final.pdf'},
              });
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        destinationApp(
          settings,
          const NotificationDestination(
            NotificationDestinationKind.progressReport,
            '/ministry/progress-reports/4',
            id: 4,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReportDetailScreen), findsOneWidget);
      expect(find.text('Actual semester report'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('S2'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Actual report content'), 250);
      await tester.tap(find.text('Attachment'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('final.pdf'), 250);
      expect(find.text('draft.pdf'), findsOneWidget);
      expect(find.text('final.pdf'), findsOneWidget);
      expect(find.text('June 07, 2025'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared progress notification has View Detail and opens the correct assignment',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final calls = <String>[];
      final notification = {
        'id': 91,
        'type': 'PROGRESS_REPORT_SHARED',
        'title': 'MAFF',
        'message': 'Progress report shared: Actual shared report',
        'isRead': false,
        'createdAt': '2026-09-15T08:00:00Z',
        'data': {
          'progressReportId': 4,
          'ministryId': 3,
          'url': '/pswg/progress-report/46',
        },
      };
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    calls.add('${request.method} ${request.url.path}');
                    switch (request.url.path) {
                      case '/api/v1/system-notifications':
                        return ok(
                          [notification],
                          meta: {
                            'page': 1,
                            'limit': 20,
                            'totalPages': 1,
                            'total': 1,
                            'unreadCount': 1,
                          },
                        );
                      case '/api/v1/system-notifications/91':
                        return ok(notification);
                      case '/api/v1/notification-settings/me':
                        return ok({
                          'unreadBadge': true,
                          'markReadOnDetail': false,
                          'systemEnabled': true,
                        });
                      case '/api/v1/progress-reports/assignments/46':
                        return ok({
                          'id': 46,
                          'progressReportId': 4,
                          'ministryId': 3,
                          'ministry': {'name': 'Actual ministry'},
                          'status': 'SHARED_WITH_PSWG',
                          'submittedAt': '2026-09-15T08:00:00Z',
                          'updatedAt': '2026-09-16T08:00:00Z',
                          'preparedBy': {'name': 'Actual preparer'},
                          'reviewedBy': {'name': 'Actual reviewer'},
                          'attachment': {'path': '/uploads/approval.pdf'},
                          'progressReport': {
                            'id': 4,
                            'title': 'Actual shared report',
                            'year': 2026,
                            'semester': 'S2',
                            'description':
                                '<p>Actual shared report description</p>',
                            'requestDocument': {'path': '/uploads/request.pdf'},
                            'draftSemesterReport': {
                              'path': '/uploads/shared_draft.pdf',
                            },
                            'latestMeeting': {
                              'meetingDate': '2026-09-14',
                              'startTime': '13:00:00',
                            },
                          },
                          'openIssues': [
                            {
                              'id': 5,
                              'title': 'Actual shared issue',
                              'description': 'Actual issue content',
                              'status': {'name': 'In Progress'},
                              'category': {'name': 'General'},
                            },
                          ],
                          'rgcDecisions': [],
                        });
                      default:
                        fail('Unexpected request ${request.url}');
                    }
                  }),
                ),
              ),
            )
            ..setLanguage(AppLanguage.english)
            ..setModuleType(AppModuleType.privateSector);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('View Detail'), findsOneWidget);
      await tester.tap(find.text('View Detail'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportDetailScreen), findsOneWidget);
      expect(find.text('Progress Report Details'), findsOneWidget);
      expect(find.text('Actual ministry'), findsOneWidget);
      expect(find.text('SHARED_WITH_PSWG'), findsOneWidget);
      expect(
        find.textContaining('Actual preparer', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Actual reviewer', findRichText: true),
        findsNWidgets(2),
      );
      expect(find.text('15/9/2026'), findsOneWidget);
      expect(find.text('14/9/2026\n13:00:00'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Actual shared report description'),
        150,
      );
      await tester.tap(find.text('All Issues'));
      await tester.pumpAndSettle();
      expect(find.text('Actual shared issue'), findsOneWidget);
      expect(find.text('Climate Issue'), findsNothing);
      await tester.tap(find.text('RGC Decision'));
      await tester.pumpAndSettle();
      expect(find.text('No issues found.'), findsOneWidget);
      await tester.tap(find.text('Attachment'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('shared_draft.pdf'), 150);
      expect(find.text('shared_draft.pdf'), findsOneWidget);
      expect(
        find.textContaining('Ouk Sabda', findRichText: true),
        findsNothing,
      );
      expect(find.text('June 07, 2025'), findsNothing);
      expect(calls, contains('GET /api/v1/progress-reports/assignments/46'));
      expect(calls, isNot(contains('GET /api/v1/progress-reports/4')));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(
        find.text('Progress report shared: Actual shared report'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'settings failure still opens the accessible detail without marking it read',
    (tester) async {
      final calls = <String>[];
      final item = {
        'id': 91,
        'type': 'MEETING_REQUEST',
        'title': 'MAFF',
        'message': 'Real notification',
        'isRead': false,
        'data': {'meetingRequestId': 17},
        'createdAt': '2026-10-01T00:00:00Z',
      };
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              calls.add('${request.method} ${request.url.path}');
              if (request.url.path == '/api/v1/system-notifications') {
                return ok(
                  [item],
                  meta: {
                    'page': 1,
                    'limit': 20,
                    'totalPages': 1,
                    'total': 1,
                    'unreadCount': 1,
                  },
                );
              }
              if (request.url.path == '/api/v1/system-notifications/91') {
                return ok(item);
              }
              if (request.url.path == '/api/v1/notification-settings/me') {
                return http.Response('', 503);
              }
              if (request.url.path == '/api/v1/meeting-requests/17') {
                return ok({'id': 17, 'title': 'Accessible meeting'});
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
      await tester.tap(find.byKey(const ValueKey('notification-detail-91')));
      await tester.pumpAndSettle();
      expect(find.text('Accessible meeting'), findsOneWidget);
      expect(calls.where((call) => call.startsWith('PATCH')), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty notification feed fits mobile screen in Khmer without sample rows',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient(
              (_) async => ok(
                [],
                meta: {
                  'page': 1,
                  'limit': 20,
                  'totalPages': 0,
                  'total': 0,
                  'unreadCount': 0,
                },
              ),
            ),
          ),
        ),
      );
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: NotificationScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('មិនទាន់មានការជូនដំណឹងទេ។'), findsOneWidget);
      expect(find.text('MAFF'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
