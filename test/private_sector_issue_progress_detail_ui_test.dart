import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/widgets/editor_content.dart';
import 'package:gpsf_app/features/private_sector/issues/issue_progress_report_detail_screen.dart';
import 'package:gpsf_app/features/shared/issues/data/issue_progress_report.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  test('report reference attachment stays separate from other documents', () {
    final report = IssueProgressReport.fromJson({
      'referenceDocument': {'path': '/uploads/other.pdf'},
      'linkToVerificationSource': 'https://example.com/drive',
      'progressReport': {
        'attachment': {'path': '/uploads/report.pdf', 'name': 'Report.pdf'},
      },
    });
    expect(report.attachmentPath, '/uploads/report.pdf');
    expect(report.attachmentName, 'Report.pdf');
    expect(report.attachmentPaths, contains('/uploads/other.pdf'));
    final missing = IssueProgressReport.fromJson({
      'attachment': null,
      'referenceDocument': {'path': '/uploads/other.pdf'},
      'linkToVerificationSource': 'https://example.com/drive',
    });
    expect(missing.attachmentPath, isEmpty);
    expect(missing.attachmentPaths, contains('/uploads/other.pdf'));
    expect(missing.verificationLink, 'https://example.com/drive');
  });

  testWidgets('detail metadata and expandable content fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('KhBattambang')
      ..addFont(rootBundle.load('assets/fonts/KhBattambang.ttf'));
    await font.load();
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final raw = Map<String, dynamic>.from(
      jsonDecode(
            File(
              'test/fixtures/private_sector_issue_detail.json',
            ).readAsStringSync(),
          )['data']['progressReports'][0]
          as Map,
    );
    raw['progressSolution'] = List.filled(
      12,
      raw['progressSolution'],
    ).join('\n');
    raw['indicators'] = List.filled(8, raw['indicators']).join(' ');
    raw['sourceOfVerification'] = 'Report reference';
    raw['attachment'] = {
      'path': '/uploads/report-reference.pdf',
      'name': 'Report Doc',
    };
    final report = IssueProgressReport.fromJson(raw);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'KhBattambang'),
          home: RepaintBoundary(
            key: const ValueKey('preview'),
            child: IssueProgressReportDetailScreen(
              title: 'Climate Issue',
              report: report,
              issueStatus: 'SOLVED',
              meetingDocumentPath: '/uploads/meeting-reference.pdf',
              meetingDocumentName: 'Request Doc',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Report S2 2026'), findsOneWidget);
    expect(find.text('Solved'), findsOneWidget);
    expect(find.text('Report Doc'), findsOneWidget);
    expect(find.text('Request Doc'), findsNothing);
    final datePosition = tester.getTopLeft(find.text('Implementation Date'));
    final statusPosition = tester.getTopLeft(find.text('Status :'));
    expect(datePosition.dy, statusPosition.dy);
    expect(statusPosition.dx, greaterThan(datePosition.dx));
    final description = find.byKey(const ValueKey('report-description'));
    await tester.scrollUntilVisible(
      description,
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.widget<EditorContent>(description).maxLines, 12);
    final toggle = find.byKey(const ValueKey('report-description-toggle'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<EditorContent>(description).maxLines, isNull);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<EditorContent>(description).maxLines, 12);

    final indicators = find.byKey(const ValueKey('report-indicators'));
    await tester.scrollUntilVisible(
      indicators,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    final inlineText = find.descendant(
      of: indicators,
      matching: find.byWidgetPredicate(
        (widget) => widget is Text && widget.textSpan != null,
      ),
    );
    TextSpan action() =>
        (tester.widget<Text>(inlineText).textSpan as TextSpan).children!.last
            as TextSpan;
    expect(action().text, 'Read more');
    (action().recognizer as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();
    expect(action().text, 'Show less');
    (action().recognizer as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();
    expect(action().text, 'Read more');
    final decision = find.byKey(const ValueKey('report-rgcDecision'));
    await tester.scrollUntilVisible(
      decision,
      350,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('RGC Decision'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final language in AppLanguage.values) {
    for (final mode in ['populated', 'empty', 'emptyHtml']) {
      testWidgets('Web report fields remain visible: $language $mode', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const fields = {
          'referenceName': 'reference_name',
          'referenceLink': 'reference_link',
          'progressSolution': 'progress_solution',
          'indicators': 'solution_indicators',
          'implementationChallenges': 'challenges',
          'requests': 'requests',
          'rgcDecision': 'rgc_decision',
        };
        final noData = language == AppLanguage.khmer ? 'មិនមាន' : 'None';
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient(
                      (_) async => http.Response(
                        jsonEncode({
                          'success': true,
                          'data': {
                            'success': true,
                            'data': {
                              'module': 'pswg',
                              'language': language == AppLanguage.khmer
                                  ? 'km'
                                  : 'en',
                              'translations': {
                                for (final field in fields.values)
                                  'issue_matrix.report_labels.$field':
                                      'API $field',
                                'issue_matrix.report_labels.implementation_date':
                                    'API implementation_date',
                                'issue_matrix.value_labels.no_data': noData,
                              },
                            },
                          },
                        }),
                        200,
                        headers: {
                          'content-type': 'application/json; charset=utf-8',
                        },
                      ),
                    ),
                  ),
                ),
              )
              ..setModuleType(AppModuleType.privateSector)
              ..setLanguage(language);
        addTearDown(settings.dispose);
        await settings.loadTranslations();
        final populated = mode == 'populated';
        final empty = mode == 'emptyHtml' ? '<p><br></p>' : '';
        final values = {
          'referenceName': populated ? 'Report reference' : empty,
          'referenceLink': populated ? 'Report attachment.pdf' : '',
          'progressSolution': populated ? '- First line\n- Second line' : empty,
          'indicators': populated ? 'Indicators value' : empty,
          'implementationChallenges': populated ? 'Challenges value' : empty,
          'requests': populated ? 'Requests value' : empty,
          'rgcDecision': populated ? 'Decision value' : empty,
        };
        final report = IssueProgressReport.fromJson({
          ...values,
          'linkToVerificationSource': 'https://example.com/not-the-attachment',
          'attachment': populated
              ? {'path': '/uploads/report.pdf', 'name': values['referenceLink']}
              : null,
        });
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: IssueProgressReportDetailScreen(
                meetingDocumentPath: '/uploads/not-the-report.pdf',
                meetingDocumentName: 'Meeting document',
                title: 'Authored title',
                report: report,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('API implementation_date'), findsOneWidget);
        expect(find.text(noData), findsWidgets);
        for (final field in fields.entries) {
          final panel = find.byKey(ValueKey('report-${field.key}'));
          await tester.scrollUntilVisible(
            panel,
            150,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: panel,
              matching: find.text('API ${field.value}'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: panel,
              matching: find.text(
                populated ? values[field.key]! : noData,
                findRichText: true,
              ),
            ),
            findsWidgets,
          );
          if (field.key == 'referenceLink') {
            expect(
              find.descendant(
                of: panel,
                matching: find.textContaining(
                  'not-the-attachment',
                  findRichText: true,
                ),
              ),
              findsNothing,
            );
            final preview = find.descendant(
              of: panel,
              matching: find.byType(PdfAttachmentPreview),
            );
            if (populated) {
              expect(
                tester.widget<PdfAttachmentPreview>(preview).path,
                '/uploads/report.pdf',
              );
            } else {
              expect(preview, findsNothing);
            }
            expect(find.text('Meeting document'), findsNothing);
          }
          expect(
            find.descendant(
              of: panel,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration as BoxDecoration).border != null,
              ),
            ),
            findsWidgets,
          );
        }
        if (!populated) {
          expect(find.byType(PdfAttachmentPreview), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
