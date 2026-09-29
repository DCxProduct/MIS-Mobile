import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_section/issues/cdc_issues_matrix_screen.dart';
import 'package:gpsf_app/features/shared/issues/data/cdc_issue_matrix_repository.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final empty in [true, false]) {
    testWidgets('CDC uses CDC endpoints and displays server empty=$empty', (
      tester,
    ) async {
      final paths = <String>[];
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    paths.add(request.url.path);
                    Object data;
                    if (request.url.path == '/api/v1/issues/summary') {
                      data = {
                        'totalIssues': empty ? 0 : 1,
                        'solved': 0,
                        'inProgress': empty ? 0 : 1,
                        'notAddressed': 0,
                        'totalPrimaryAgencies': empty ? 0 : 1,
                      };
                    } else if (request.url.path == '/api/v1/issues/17') {
                      data = {
                        'issueId': 17,
                        'title': 'Only CDC issue',
                        'category': 'General',
                        'primaryAgency': {
                          'name':
                              'Ministry of Agriculture, Forestry and Fisheries',
                        },
                        'status': {'code': 'SAVED', 'name': 'Saved'},
                        'description': 'Full detail from CDC API',
                        'attachment': {
                          'path': '/uploads/issues/reference-17.pdf',
                          'name': 'Issue_reference.pdf',
                          'size': 1947246,
                        },
                      };
                    } else {
                      expect(request.url.path, '/api/v1/issues');
                      expect(request.url.queryParameters, {
                        'page': '1',
                        'limit': '50',
                      });
                      data = {
                        'items': empty
                            ? []
                            : [
                                {
                                  'issueId': 17,
                                  'title': 'Only CDC issue',
                                  'status': {
                                    'code': 'IN_PROGRESS',
                                    'name': 'In Progress',
                                  },
                                  'workingGroup': {'name': 'CDC working group'},
                                  'submittedAt': '2026-09-14T00:00:00.000Z',
                                },
                              ],
                        'page': 1,
                        'limit': 50,
                        'total': empty ? 0 : 1,
                        'totalPages': empty ? 0 : 1,
                      };
                    }
                    return http.Response(
                      jsonEncode({
                        'success': true,
                        'data': request.url.path == '/api/v1/issues'
                            ? (data as Map<String, dynamic>)['items']
                            : data,
                        if (request.url.path == '/api/v1/issues')
                          'meta': {
                            'page': 1,
                            'limit': 50,
                            'total': empty ? 0 : 1,
                            'totalPages': empty ? 0 : 1,
                          },
                      }),
                      200,
                    );
                  }),
                ),
              ),
            )
            ..setLanguage(AppLanguage.english)
            ..setModuleType(AppModuleType.cdcSection);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(
            home: Scaffold(body: CdcSectionIssuesMatrixScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        paths,
        unorderedEquals([
          '/api/v1/issues/summary',
          '/api/v1/issues',
          if (!empty) '/api/v1/issues/17',
        ]),
      );
      expect(
        find.text(empty ? '0/0' : '1/1'),
        empty ? findsNWidgets(3) : findsOneWidget,
      );
      expect(
        find.text('Only CDC issue'),
        empty ? findsNothing : findsOneWidget,
      );
      expect(find.text('Joint Inspection'), findsNothing);
      expect(find.text('56'), findsNothing);
      if (empty) expect(find.text('No issues found.'), findsOneWidget);
      if (!empty) {
        expect(find.text('1 Attachments'), findsOneWidget);
        await tester.ensureVisible(find.text('Only CDC issue'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Only CDC issue'));
        await tester.pumpAndSettle();
        expect(paths.last, '/api/v1/issues/17');
        expect(
          find.text('Ministry of Agriculture, Forestry and Fisheries'),
          findsOneWidget,
        );
        expect(find.text('Issue_reference.pdf'), findsOneWidget);
        expect(find.text('1.9 MB'), findsOneWidget);
        expect(find.text('Saved'), findsOneWidget);
        expect(find.text('Full detail from CDC API'), findsOneWidget);
        final preview = tester.widget<PdfAttachmentPreview>(
          find.byType(PdfAttachmentPreview),
        );
        expect(preview.path, '/uploads/issues/reference-17.pdf');
        expect(preview.name, 'Issue_reference.pdf');
        expect(tester.takeException(), isNull);
      }
    });
  }

  test('CDC display list maps fields and loads later pages', () async {
    final pages = <String>[];
    final api = ApiClient(
      client: MockClient((request) async {
        pages.add(request.url.queryParameters['page']!);
        final page = int.parse(pages.last);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'issueId': page,
                'title': 'CDC page $page',
                'status': {'code': 'SOLVED', 'name': 'Solved'},
                'workingGroup': {'name': 'Tourism'},
                'submittedAt': '2026-09-14T00:00:00.000Z',
                'attachment': null,
              },
            ],
            'meta': {'page': page, 'limit': 50, 'total': 51, 'totalPages': 2},
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final issues = await CdcIssueMatrixRepository(api).getDisplayIssues();
    expect(pages, ['1', '2']);
    expect(issues.map((issue) => issue.id), [1, 2]);
    expect(issues.first.submittedBy, 'Tourism');
    expect(issues.first.statusCode, 'SOLVED');
    expect(issues.first.createdAt, DateTime.utc(2026, 9, 14));
  });
}
