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
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';

void main() {
  final response =
      jsonDecode(
            File('test/fixtures/cdc_progress_report.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final data = response['data'] as Map<String, dynamic>;
  test(
    'schedule pairs all meetings and revision deadlines in creation order',
    () {
      final report = ProgressReport({
        ...data,
        'deadlines': (data['deadlines'] as List).reversed.toList(),
        'meetings': (data['meetings'] as List).reversed.toList(),
      });
      expect(
        report.schedule.map((row) => (row.isMeeting, row.number, row.date)),
        [
          (false, 0, DateTime(2026, 12, 15)),
          (true, 1, DateTime(2026, 9, 3)),
          (false, 1, DateTime(2026, 9, 29)),
          (true, 2, DateTime(2026, 9, 4)),
          (false, 2, DateTime(2026, 9, 24)),
          (true, 3, DateTime(2026, 9, 14)),
          (false, 3, DateTime(2026, 9, 15)),
        ],
      );
      for (final key in ['meetings', 'deadlines']) {
        final partial = ProgressReport({...data, key: null});
        expect(partial.schedule.length, key == 'meetings' ? 4 : 3);
      }
      expect(ProgressReport({'id': 1}).schedule, isEmpty);
    },
  );
  for (final retry in [false, true]) {
    for (final language in AppLanguage.values) {
      testWidgets(
        'CDC root report shows Web schedule and documents; retry=$retry, $language',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final l10n = AppLocalizations(language);
          var detailCalls = 0;
          final settings = AppSettingsController(
            authRepository: AuthRepository(
              ApiClient(
                client: MockClient((request) async {
                  if (request.url.path == '/api/v1/progress-reports/2') {
                    if (++detailCalls == 1 && retry) {
                      return http.Response('{}', 503);
                    }
                    return http.Response(
                      jsonEncode(response),
                      200,
                      headers: {
                        'content-type': 'application/json; charset=utf-8',
                      },
                    );
                  }
                  expect(
                    request.url.path,
                    '/api/v1/progress-reports/2/ministries',
                  );
                  return http.Response(
                    jsonEncode({
                      'success': true,
                      'data': [],
                      'meta': {'totalPages': 0},
                    }),
                    200,
                  );
                }),
              ),
            ),
          )..setLanguage(language);
          addTearDown(settings.dispose);
          await tester.pumpWidget(
            AppSettings(
              controller: settings,
              child: MaterialApp(
                home: CdcProgressReportMinistriesScreen(
                  report: ProgressReport({
                    'id': 2,
                    'title': 'Stale list title',
                    'year': 2028,
                  }),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (retry) {
            expect(find.text(data['title']), findsNothing);
            await tester.tap(find.text(l10n.text('retry')));
            await tester.pumpAndSettle();
          }
          expect(find.text(data['title']), findsOneWidget);
          expect(find.text('Stale list title'), findsNothing);
          expect(find.text('${l10n.text('year')}: 2026'), findsOneWidget);
          expect(find.text('${l10n.text('semester')}: S2'), findsOneWidget);
          expect(
            find.text('${l10n.text('status')}: ${l10n.status('SENT')}'),
            findsOneWidget,
          );
          final labels = language == AppLanguage.english
              ? [
                  'Deadline',
                  '1st Meeting',
                  '1st Revision Deadline',
                  '2nd Meeting',
                  '2nd Revision Deadline',
                  '3rd Meeting',
                  '3rd Revision Deadline',
                ]
              : [
                  'ផុតកំណត់កែសម្រួល',
                  'កិច្ចប្រជុំទី១',
                  'ផុតកំណត់កែសម្រួលទី១',
                  'កិច្ចប្រជុំទី២',
                  'ផុតកំណត់កែសម្រួលទី២',
                  'កិច្ចប្រជុំទី៣',
                  'ផុតកំណត់កែសម្រួលទី៣',
                ];
          for (final label in labels) {
            await tester.scrollUntilVisible(find.text(label), 150);
            expect(find.text(label), findsOneWidget);
          }
          for (final key in ['draftSemesterReport', 'finalSemesterReport']) {
            final document = data[key] as Map<String, dynamic>;
            await tester.scrollUntilVisible(find.text(document['name']), 150);
            final preview = tester.widget<PdfAttachmentPreview>(
              find.ancestor(
                of: find.text(document['name']),
                matching: find.byType(PdfAttachmentPreview),
              ),
            );
            expect(preview.path, document['path']);
            expect(preview.name, document['name']);
          }
          await tester.scrollUntilVisible(find.text(data['description']), 150);
          expect(find.text(data['description']), findsOneWidget);
          expect(find.byType(ExpansionTile), findsNothing);
          expect(find.text('Attachment'), findsNothing);
          expect(detailCalls, retry ? 2 : 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
