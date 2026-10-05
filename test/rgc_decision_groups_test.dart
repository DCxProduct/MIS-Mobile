import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_section/issues/detail_widgets.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decisions_repository.dart';
import 'package:gpsf_app/screens/report/report_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> record(
  int id,
  int ministry,
  int plenary,
  String category,
) => {
  'id': id,
  'stakeholderId': ministry,
  'stakeholder': {'id': ministry, 'name': ministry == 1 ? 'MAFF' : 'MEF'},
  'plenaryId': plenary,
  'plenary': {
    'id': plenary,
    'name': plenary == 3 ? '21th' : '20th',
    'deadline': '2026-10-05',
    'meetingDate': '2026-09-13T17:00:00.000Z',
  },
  'category': category,
  'meetingDate': category == 'Communication' ? '2026-10-03' : '2026-09-14',
  'status': 'In Progress',
  'decision': '$category decision',
  'verificationLink': 'https://example.com/decision/$id',
  'issues': [
    {
      // The same issue can belong to two decisions; retain each parent context.
      'id': 500,
      'attachment': '/uploads/shared.pdf',
      'description': '$category description',
      'recommendation': '$category recommendation',
      'issueStatus': {'name': 'In Progress'},
      'category': {'name': 'General'},
      'meetingRequest': {
        'meetings': [
          {'meetingDate': '2026-09-03T00:00:00.000Z'},
        ],
      },
      'stakeholder': {'name': 'Working Group'},
    },
  ],
};

void main() {
  test(
    'loads plenary date even with an existing status and deadline',
    () async {
      final data = record(101, 1, 3, 'Communication');
      final plenary = data['plenary'] as Map<String, dynamic>;
      plenary['status'] = 'Sent';
      plenary.remove('meetingDate');
      expect(RgcDecisionGroup([RgcDecision(data)]).meetingDate, isNull);
      final calls = <String>[];
      final api = ApiClient(
        client: MockClient((request) async {
          calls.add(request.url.path);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': request.url.path == '/api/v1/plenaries/3'
                  ? {
                      'id': 3,
                      'status': 'Sent',
                      'meetingDate': '2026-09-13T17:00:00.000Z',
                    }
                  : request.url.path == '/api/v1/rgc-decisions'
                  ? {
                      'items': [data],
                      'meta': {'totalPages': 1},
                    }
                  : data,
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final repository = RgcDecisionsRepository(api);
      final detail = await repository.getDecision(
        101,
        includePlenaryDetails: true,
      );
      expect(detail.decision.plenaryMeetingDate, DateTime.utc(2026, 9, 13, 17));
      expect(detail.decision.meetingDate, DateTime(2026, 10, 3));
      expect(detail.deadline, DateTime(2026, 10, 5));
      final list = await repository.getDecisions(includePlenaryDetails: true);
      expect(RgcDecisionGroup(list).meetingDate, DateTime.utc(2026, 9, 13, 17));
      expect(calls, [
        '/api/v1/rgc-decisions/101',
        '/api/v1/plenaries/3',
        '/api/v1/rgc-decisions',
        '/api/v1/plenaries/3',
      ]);
    },
  );

  test('group status belongs to the plenary, not its decisions', () {
    final first = record(101, 1, 3, 'Communication');
    final second = record(104, 1, 3, 'Climate')..['status'] = 'Not Addressed';
    expect(
      RgcDecisionGroup([RgcDecision(first), RgcDecision(second)]).status,
      '',
    );
    (first['plenary'] as Map<String, dynamic>)['status'] = 'Sent';
    final group = RgcDecisionGroup([RgcDecision(first), RgcDecision(second)]);
    expect(group.status, 'Sent');
    expect(group.decisions.map((decision) => decision.status), [
      'In Progress',
      'Not Addressed',
    ]);
  });

  test(
    'loads a fresh parent status once per plenary across ministries',
    () async {
      final calls = <String>[];
      var parentStatus = 'Sent';
      final api = ApiClient(
        client: MockClient((request) async {
          calls.add(request.url.path);
          final data = request.url.path == '/api/v1/rgc-decisions'
              ? {
                  'items': [
                    record(101, 1, 3, 'Communication'),
                    record(104, 1, 3, 'Climate'),
                    record(102, 2, 3, 'Climate'),
                    record(103, 1, 4, 'Climate'),
                  ],
                  'meta': {'totalPages': 1},
                }
              : {
                  'id': int.parse(request.url.path.split('/').last),
                  'status': parentStatus,
                  'meetingDate': request.url.path.endsWith('/3')
                      ? '2026-09-13T17:00:00.000Z'
                      : '2026-10-01T17:00:00.000Z',
                };
          return http.Response(
            jsonEncode({'success': true, 'data': data}),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final repository = RgcDecisionsRepository(api);
      final decisions = await repository.getDecisions(
        includePlenaryDetails: true,
      );
      expect(
        RgcDecisionGroup.fromDecisions(decisions).map((group) => group.status),
        ['Sent', 'Sent', 'Sent'],
      );
      expect(
        RgcDecisionGroup.fromDecisions(
          decisions,
        ).map((group) => group.meetingDate),
        [
          DateTime.utc(2026, 9, 13, 17),
          DateTime.utc(2026, 9, 13, 17),
          DateTime.utc(2026, 10, 1, 17),
        ],
      );
      expect(calls, [
        '/api/v1/rgc-decisions',
        '/api/v1/plenaries/3',
        '/api/v1/plenaries/4',
      ]);
      parentStatus = 'Draft';
      final refreshed = await repository.getDecisions(
        includePlenaryDetails: true,
      );
      expect(refreshed.first.plenaryStatus, 'Draft');
      expect(calls.where((path) => path == '/api/v1/plenaries/3').length, 2);
    },
  );

  test(
    'unavailable plenary does not replace its status with decision status',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path.startsWith('/api/v1/plenaries/')) {
            return http.Response('{"success":false}', 403);
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [record(101, 1, 3, 'Climate')],
                'meta': {'totalPages': 1},
              },
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final decisions = await RgcDecisionsRepository(
        api,
      ).getDecisions(includePlenaryDetails: true);
      expect(decisions.single.status, 'In Progress');
      expect(RgcDecisionGroup(decisions).status, '');
    },
  );

  test(
    'groups by ministry and plenary identity, deduplicating records and links',
    () {
      final first = record(101, 1, 3, 'Communication');
      final groups = RgcDecisionGroup.fromDecisions([
        RgcDecision(first),
        RgcDecision(record(102, 2, 3, 'Climate')),
        RgcDecision(record(103, 1, 4, 'Climate')),
        RgcDecision(record(104, 1, 3, 'Climate')),
        RgcDecision(first),
      ]);
      expect(groups.length, 3);
      expect(groups.first.decisionIds, [101, 104]);
      expect(groups.first.category, 'Communication, Climate');
      expect(groups.first.meetingDate, DateTime.utc(2026, 9, 13, 17));
      expect(groups.first.linkCount, 3);
      expect(groups[1].decisionIds, [102]);
      expect(groups[2].decisionIds, [103]);
    },
  );

  test(
    'uses nested IDs and keeps records with missing identities separate',
    () {
      final nested = record(101, 1, 3, 'Climate')
        ..remove('stakeholderId')
        ..remove('plenaryId');
      final groups = RgcDecisionGroup.fromDecisions([
        RgcDecision(nested),
        RgcDecision(record(102, 1, 3, 'Communication')),
        RgcDecision({
          'id': 103,
          'stakeholder': {'name': 'MAFF'},
          'plenaryId': 3,
        }),
        RgcDecision({
          'id': 104,
          'stakeholder': {'name': 'MAFF'},
          'plenaryId': 3,
        }),
        RgcDecision(
          record(105, 2, 3, 'Climate')
            ..['stakeholder'] = {'id': 2, 'name': 'MAFF'},
        ),
      ]);
      expect(groups.map((group) => group.decisionIds), [
        [101, 102],
        [103],
        [104],
        [105],
      ]);
    },
  );

  test('keeps a decision visible when it has no linked issues', () {
    final detail = RgcDecisionDetail.fromJson(
      record(101, 1, 3, 'Climate')..['issues'] = [],
    );
    expect(detail.issues.single.rgcDecision, 'Climate decision');
    expect(detail.issues.single.category, 'Climate');
  });

  for (final module in [AppModuleType.cdcSection, AppModuleType.cefp]) {
    testWidgets(
      '$module groups across pages and opens every decision with retry',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final records = {
          101: record(101, 1, 3, 'Communication')..['status'] = 'Not Addressed',
          102: record(102, 2, 3, 'Climate'),
          103: record(103, 1, 4, 'Climate'),
          104: record(104, 1, 3, 'Climate'),
        };
        final pages = <String>[];
        final plenaries = <int>[];
        final details = <int>[];
        var failSecond = true;
        http.Response ok(Object data) =>
            http.Response(jsonEncode({'success': true, 'data': data}), 200);
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      if (request.url.path == '/api/v1/rgc-decisions') {
                        final page = request.url.queryParameters['page']!;
                        pages.add(page);
                        return ok({
                          'items': page == '1'
                              ? [records[101], records[102], records[103]]
                              : [records[104], records[101]],
                          'meta': {'totalPages': 2},
                        });
                      }
                      final id = int.parse(request.url.path.split('/').last);
                      if (request.url.path.startsWith('/api/v1/plenaries/')) {
                        plenaries.add(id);
                        return ok({
                          'id': id,
                          'status': 'Sent',
                          'statusCode': 'SENT',
                          'meetingDate': '2026-09-13T17:00:00.000Z',
                        });
                      }
                      details.add(id);
                      if (id == 104 && failSecond) {
                        failSecond = false;
                        return http.Response('{"success":false}', 503);
                      }
                      return ok(records[id]!);
                    }),
                  ),
                ),
              )
              ..setModuleType(module)
              ..setLanguage(AppLanguage.english);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: const MaterialApp(home: Scaffold(body: ReportScreen())),
          ),
        );
        await tester.pumpAndSettle();
        expect(pages, ['1', '2']);
        expect(plenaries, [3, 4]);
        expect(find.text('Sent'), findsNWidgets(3));
        expect(find.text('Sep 13, 2026'), findsNWidgets(3));
        expect(find.text('Oct 3, 2026'), findsNothing);
        expect(find.text('In Progress, Solved'), findsNothing);
        expect(find.text('View Details'), findsNWidgets(3));
        expect(find.text('MAFF'), findsNWidgets(2));
        expect(find.text('MEF'), findsOneWidget);
        expect(find.text('Communication, Climate'), findsOneWidget);
        expect(find.text('3 Link'), findsOneWidget);
        await tester.tap(find.text('View Details').first);
        await tester.pumpAndSettle();
        expect(details, [101, 104]);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Communication decision'), findsNothing);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(details, [101, 104, 101, 104]);
        final count = find.ancestor(
          of: find.text('Number of RGC Decision'),
          matching: find.byType(CdcDetailInfoValue),
        );
        expect(
          find.descendant(of: count, matching: find.text('2')),
          findsOneWidget,
        );
        expect(find.text('Communication decision'), findsOneWidget);
        expect(find.text('Climate decision'), findsOneWidget);
        final meetingDate = find.ancestor(
          of: find.text('Meeting Date'),
          matching: find.byType(CdcDetailInfoValue),
        );
        expect(
          find.descendant(of: meetingDate, matching: find.text('Sep 13, 2026')),
          findsOneWidget,
        );
        expect(find.text('Oct 3, 2026'), findsOneWidget);
        final communicationCard = find.ancestor(
          of: find.text('Communication decision'),
          matching: find.byType(InkWell),
        );
        final climateCard = find.ancestor(
          of: find.text('Climate decision'),
          matching: find.byType(InkWell),
        );
        for (final (card, date, category, status) in [
          (communicationCard, 'Oct 3, 2026', 'Communication', 'Not Addressed'),
          (climateCard, 'Sep 14, 2026', 'Climate', 'In Progress'),
        ]) {
          expect(
            find.descendant(of: card, matching: find.text(date)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: card, matching: find.text(category)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: card, matching: find.text(status)),
            findsOneWidget,
          );
        }
        expect(find.text('General'), findsNothing);
        expect(find.text('Sep 3, 2026'), findsNothing);
        final status = find.ancestor(
          of: find.text('Status'),
          matching: find.byType(CdcDetailInfoValue),
        );
        expect(
          find.descendant(of: status, matching: find.text('Sent')),
          findsOneWidget,
        );
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Not Addressed'), findsOneWidget);
        await tester.tap(find.text('Climate decision'));
        await tester.pumpAndSettle();
        expect(find.text('Climate description'), findsOneWidget);
        expect(find.text('Climate recommendation'), findsOneWidget);
        expect(find.text('General'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Communication description'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
