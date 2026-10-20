import 'package:gpsf_app/features/cdc_secretariat/reports/progress_report_status.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_secretariat/reports/progress_report_ministries_screen.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_report.dart';
import 'package:gpsf_app/features/shared/meetings/data/progress_reports_repository.dart';
import 'package:gpsf_app/screens/report/progress_report_detail_loader.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final response =
      jsonDecode(
            File(
              'test/fixtures/cdc_progress_ministries.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final rows = response['data'] as List;
  http.Response ok(Object data, {int pages = 1}) => http.Response(
    jsonEncode({
      'success': true,
      'data': data,
      'meta': {'totalPages': pages},
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  test(
    'CDC ministries loads every page and keeps ministry identity and documents',
    () async {
      final pages = <int>[];
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/progress-reports/2/ministries');
          expect(request.url.queryParameters['limit'], '100');
          final page = int.parse(request.url.queryParameters['page']!);
          pages.add(page);
          return ok(
            page == 1 ? rows.take(5).toList() : rows.skip(5).toList(),
            pages: 2,
          );
        }),
      );
      addTearDown(api.close);
      final ministries = await ProgressReportsRepository(api).getMinistries(2);
      expect(pages, [1, 2]);
      expect(ministries.length, rows.length);
      expect(
        ministries.map((item) => item.name),
        rows.map((row) => row['ministry']['name']),
      );
      expect(ministries.first.ministryId, 1);
      expect(ministries.first.issues, 3);
      expect(ministries.first.logo, rows.first['ministry']['logo']);
      expect(ministries.first.attachmentName, 'Issue_solution_reference.pdf');
      expect(
        ministries.first.requestDocumentName,
        'Approval_progress_report.pdf',
      );
      expect(ministries[1].attachment, isEmpty);
      expect(ministries.last.ministryId, 2);
    },
  );

  test('CDC overview uses Web initial deadline and every workflow status', () {
    final detail =
        jsonDecode(
              File('test/fixtures/cdc_progress_report.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final report = ProgressReport(detail['data']);
    expect(report.deadline, DateTime.parse('2026-09-15'));
    expect(report.initialDeadline, DateTime.parse('2026-12-15'));
    expect(ProgressReport({'id': 1}).initialDeadline, isNull);
    const en = AppLocalizations(AppLanguage.english);
    const km = AppLocalizations(AppLanguage.khmer);
    expect(progressReportMinistryStatusLabel(en, 'COMPLETED'), 'Reviewed');
    expect(progressReportMinistryStatusLabel(km, 'COMPLETED'), 'បានពិនិត្យ');
    expect(progressReportMinistryStatusLabel(km, 'REQUESTED'), 'បានស្នើ');
    for (final status in [
      'REQUESTED',
      'PREPARING',
      'SHARED_WITH_PSWG',
      'PSWG_REVIEWED',
      'SUBMITTED',
      'CDC_UNDER_REVIEW',
      'COMPLETED',
      'RETURNED',
      'UPDATING',
      'RESUBMITTED',
      'CDC_RE_REVIEWING',
    ]) {
      expect(progressReportMinistryStatusLabel(en, status), isNot(status));
      expect(progressReportMinistryStatusLabel(km, status), isNot(status));
      final ministry = ProgressReportMinistry.fromJson({
        ...rows.first as Map<String, dynamic>,
        'status': status,
      });
      expect(
        ministry.submittedToCdc,
        ![
          'REQUESTED',
          'PREPARING',
          'SHARED_WITH_PSWG',
          'PSWG_REVIEWED',
        ].contains(status),
      );
    }
  });

  testWidgets(
    'CDC refreshes changed workflow status from API while visible and after resume',
    (tester) async {
      var status = 'PREPARING';
      var ministryCalls = 0;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              if (request.url.path == '/api/v1/progress-reports/5') {
                return ok({'id': 5, 'title': 'Report 5'});
              }
              expectSync(
                request.url.path,
                '/api/v1/progress-reports/5/ministries',
              );
              ministryCalls++;
              return ok([
                {
                  'ministryId': 4,
                  'ministry': {'name': 'MEF'},
                  'status': status,
                },
              ]);
            }),
          ),
        ),
      )..setLanguage(AppLanguage.khmer);
      addTearDown(settings.dispose);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: CdcProgressReportMinistriesScreen(
              report: ProgressReport({'id': 5}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('កំពុងរៀបចំ'), findsOneWidget);
      status = 'SHARED_WITH_PSWG';
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(ministryCalls, 2);
      expect(find.text('កំពុងរៀបចំ'), findsNothing);
      expect(find.text('បានផ្ញើជូនវិស័យឯកជន'), findsOneWidget);
      final sharedLabel = tester.widget<Text>(find.text('បានផ្ញើជូនវិស័យឯកជន'));
      expect(sharedLabel.style?.color, const Color(0xFF175CD3));

      status = 'PSWG_REVIEWED';
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(ministryCalls, 3);
      expect(find.text('បានផ្ញើជូនវិស័យឯកជន'), findsNothing);
      expect(
        find.text(
          const AppLocalizations(AppLanguage.khmer).text('pswgReviewed'),
        ),
        findsOneWidget,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      status = 'COMPLETED';
      await tester.pump(const Duration(seconds: 31));
      expect(ministryCalls, 3);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(ministryCalls, 4);
      expect(find.text('បានពិនិត្យ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'CDC hides unsubmitted approval document but keeps request document like Web',
    (tester) async {
      final root =
          jsonDecode(
                File(
                  'test/fixtures/cdc_progress_report.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              if (request.url.path == '/api/v1/progress-reports/2') {
                return ok(root['data']);
              }
              expect(request.url.path, '/api/v1/progress-reports/2/ministries');
              return ok([
                {
                  ...rows[1] as Map<String, dynamic>,
                  'attachment': {
                    'path': '/unsubmitted.pdf',
                    'name': 'Unsubmitted approval.pdf',
                  },
                },
              ]);
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: CdcProgressReportMinistriesScreen(
              report: ProgressReport({'id': 2}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final date = MaterialLocalizations.of(
        tester.element(find.byType(CdcProgressReportMinistriesScreen)),
      ).formatMediumDate(DateTime(2026, 12, 15));
      expect(find.text('$date 2026'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Requested'), 250);
      expect(find.text('Unsubmitted approval.pdf'), findsNothing);
      expect(find.text('Requested'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Request Doc'), 150);
      expect(find.text('Issue_reference.pdf'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CDC ministry list scrolls to last record and opens its ministryId',
    (tester) async {
      final root =
          jsonDecode(
                File(
                  'test/fixtures/cdc_progress_report.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              switch (request.url.path) {
                case '/api/v1/progress-reports/2':
                  return ok(root['data']);
                case '/api/v1/progress-reports/2/ministries':
                  return ok(rows);
                case '/api/v1/progress-reports/2/ministries/2':
                  return ok({
                    'id': 11,
                    'progressReportId': 2,
                    'ministryId': 2,
                    'ministry': {'name': 'MoT'},
                  });
                default:
                  throw StateError('Unexpected request: ${request.url}');
              }
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: CdcProgressReportMinistriesScreen(
              report: ProgressReport({'id': 2}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Government Agency (${rows.length})'),
        250,
      );
      expect(find.text('Government Agency (${rows.length})'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('MoT'), 500);
      final card = find
          .ancestor(of: find.text('MoT'), matching: find.byType(Container))
          .first;
      expect(
        find.descendant(of: card, matching: find.text('Requested')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('plenary_document_reference.pdf'),
        ),
        findsOneWidget,
      );
      final button = find.descendant(
        of: card,
        matching: find.text('View Details'),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final loader = tester.widget<ProgressReportDetailLoader>(
        find.byType(ProgressReportDetailLoader),
      );
      expect(loader.id, 2);
      expect(loader.ministryId, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
