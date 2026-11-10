import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/text/html_text.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/issues/data/issues_repository.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:gpsf_app/features/shared/issues/widgets/wg_issues_list.dart';
import 'package:gpsf_app/screens/issues/issues_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';

void main() {
  final fixture = File('test/fixtures/wg_issues.json').readAsStringSync();
  final title = (jsonDecode(fixture)['data']['items'][0]['title']) as String;
  test(
    'maps returned records, null relations, ordered agencies and deduplicated links',
    () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/working-group-issues/my');
          return http.Response.bytes(
            utf8.encode(jsonEncode(jsonDecode(fixture))),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final items = await IssuesRepository(api).getMyWorkingGroupIssues();
      expect(items.map((item) => item.id), [12, 11]);
      expect(items.first.title, title);
      expect(items.first.category, 'Regulation');
      expect(items.first.agency, 'MAFF');
      expect(items.first.statusCode, 'SOLVED');
      expect(items.first.attachmentCount, 1);
      expect(items.first.linkCount, 3);
      expect(items.first.description, isNot(contains('<p>')));
      expect(items.first.description, contains('\n'));
      expect(items.last.meetingDate, isNull);
      expect(items.last.category, isEmpty);
      expect(items.last.description, 'Plain description & details');
      expect(items.last.statusName, 'Draft');
    },
  );

  test('HTML preview decodes entities and excludes scripts', () {
    expect(
      htmlToPlainText(
        '<p>First &amp; second</p><script>secret()</script><p>Next</p>',
      ),
      'First & second\nNext',
    );
  });

  test(
    'rejects a malformed list rather than silently using demo issues',
    () async {
      final api = ApiClient(
        client: MockClient(
          (_) async =>
              http.Response('{"success":true,"data":{"items":{}}}', 200),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        IssuesRepository(api).getMyWorkingGroupIssues(),
        throwsA(isA<ApiException>()),
      );
    },
  );

  for (final role in AppModuleType.values) {
    testWidgets('$role shows each API record below summary cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var listCalls = 0;
      final settings =
          AppSettingsController(
              authRepository: AuthRepository(
                ApiClient(
                  client: MockClient((request) async {
                    if (request.url.path.endsWith('/summary/my') ||
                        request.url.path.endsWith('/issue-matrix/summary')) {
                      return http.Response(
                        File(
                          'test/fixtures/wg_issue_summary.json',
                        ).readAsStringSync(),
                        200,
                      );
                    }
                    listCalls++;
                    return http.Response.bytes(
                      utf8.encode(jsonEncode(jsonDecode(fixture))),
                      200,
                    );
                  }),
                ),
              ),
            )
            ..setLanguage(AppLanguage.english)
            ..setModuleType(role);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: Scaffold(body: IssuesScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(find.text('Second API issue'), findsOneWidget);
      expect(find.text('Regulation'), findsOneWidget);
      expect(
        find.text('Draft'),
        role == AppModuleType.lineMinistry ? findsNothing : findsOneWidget,
      );
      expect(listCalls, 1);
      await tester.ensureVisible(find.text(title));
      if (role == AppModuleType.cdcSecretariat) {
        await tester.ensureVisible(find.text('View Details').first);
        await tester.tap(find.text('View Details').first);
      } else {
        await tester.tap(find.text(title));
      }
      await tester.pumpAndSettle();
      expect(find.text('ស្នើសុំអន្តរាគមន៍ជួយប្រមូលទិញត្រី'), findsOneWidget);
    });
  }

  testWidgets('ministry issue list and details follow language changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var listCalls = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/summary/my') ||
                request.url.path.endsWith('/issue-matrix/summary')) {
              return http.Response(
                File('test/fixtures/wg_issue_summary.json').readAsStringSync(),
                200,
              );
            }
            listCalls++;
            return http.Response.bytes(utf8.encode(fixture), 200);
          }),
        ),
      ),
    )..setModuleType(AppModuleType.lineMinistry);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: Scaffold(body: IssuesScreen())),
      ),
    );
    await tester.pumpAndSettle();
    for (final language in [
      AppLanguage.khmer,
      AppLanguage.english,
      AppLanguage.khmer,
    ]) {
      settings.setLanguage(language);
      await tester.pumpAndSettle();
      final l10n = AppLocalizations(language);
      expect(find.text(l10n.text('submissionDate')), findsWidgets);
      expect(find.text(l10n.text('submittedBy')), findsWidgets);
    }
    await tester.ensureVisible(find.text(title));
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    for (final language in [
      AppLanguage.khmer,
      AppLanguage.english,
      AppLanguage.khmer,
    ]) {
      settings.setLanguage(language);
      await tester.pumpAndSettle();
      final l10n = AppLocalizations(language);
      for (final key in [
        'issueDetails',
        'governmentAgency',
        'status',
        'category',
        'meetingRequestDocument',
        'descriptions',
        'progressReport',
        'issuesDescription',
        'recommendation',
      ]) {
        expect(find.text(l10n.text(key)), findsOneWidget);
      }
      expect(
        find.textContaining(l10n.text('submittedDate'), findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n.text('meetingDate'), findRichText: true),
        findsOneWidget,
      );
      expect(find.text(title), findsOneWidget);
    }
    expect(listCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry returns empty state without demo cards', (tester) async {
    var calls = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((_) async {
            calls++;
            return calls == 1
                ? http.Response('', 502)
                : http.Response('{"success":true,"data":{"items":[]}}', 200);
          }),
        ),
      ),
    )..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: WgIssuesList(itemBuilder: (issue) => Text(issue.title)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No issues found.'), findsOneWidget);
    expect(calls, 2);
  });
  for (final module in AppModuleType.values) {
    testWidgets(
      '$module matrix content switches language through detail and report',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final record = <String, dynamic>{
          'id': 77,
          'title': 'English matrix title',
          'titleKh': 'ចំណងជើងបញ្ហាខ្មែរ',
          'description': 'English issue description',
          'descriptionKh': 'ការពិពណ៌នាបញ្ហាខ្មែរ',
          'recommendation': 'English recommendation',
          'recommendationKh': 'អនុសាសន៍ខ្មែរ',
          'category': {'name': 'Governance', 'khName': 'អភិបាលកិច្ច'},
          'stakeholder': {
            'name': 'Working group',
            'khName': 'ក្រុមការងារខ្មែរ',
          },
          'issueStatus': {'code': 'IN_PROGRESS', 'name': 'In Progress'},
          'governmentAgencies': [
            {
              'agencyOrder': 1,
              'stakeholder': {'name': 'Agency', 'khName': 'ស្ថាប័នខ្មែរ'},
            },
          ],
          'progressReports': [
            {
              'semester': 'S1',
              'year': 2026,
              'sourceOfVerification': 'English reference',
              'sourceOfVerificationKh': 'ឯកសារយោងខ្មែរ',
              'progressSolution': 'English progress',
              'progressSolutionKh': 'វឌ្ឍនភាពខ្មែរ',
              'indicators': 'English indicators',
              'indicatorsKh': 'សូចនាករខ្មែរ',
              'rgcDecision': 'English decision',
              'rgcDecisionKh': 'សេចក្តីសម្រេចខ្មែរ',
            },
          ],
        };
        var listCalls = 0;
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      Object data;
                      final path = request.url.path;
                      if (path.endsWith('/summary/my') ||
                          path.endsWith('/issue-matrix/summary')) {
                        return http.Response(
                          File(
                            'test/fixtures/wg_issue_summary.json',
                          ).readAsStringSync(),
                          200,
                        );
                      } else if (path.endsWith('/my') ||
                          path.endsWith('/issue-matrix')) {
                        listCalls++;
                        data = {
                          'items': [record],
                        };
                      } else if (path.endsWith('/77')) {
                        data = record;
                      } else {
                        data = [];
                      }
                      return http.Response.bytes(
                        utf8.encode(
                          jsonEncode({'success': true, 'data': data}),
                        ),
                        200,
                      );
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
            child: const MaterialApp(home: Scaffold(body: IssuesScreen())),
          ),
        );
        await tester.pumpAndSettle();
        if (module == AppModuleType.privateSector ||
            module == AppModuleType.cdcSecretariat) {
          await tester.tap(
            find
                .text(
                  AppLocalizations(AppLanguage.english).text('issuesMatrix'),
                )
                .last,
          );
        }
        await tester.pumpAndSettle();
        final callsBeforeSwitch = listCalls;
        for (final language in [
          AppLanguage.khmer,
          AppLanguage.english,
          AppLanguage.khmer,
        ]) {
          settings.setLanguage(language);
          await tester.pumpAndSettle();
          final kh = language == AppLanguage.khmer;
          expect(
            find.text(record[kh ? 'titleKh' : 'title'] as String),
            findsOneWidget,
          );
          expect(
            find.text(record[kh ? 'descriptionKh' : 'description'] as String),
            findsOneWidget,
          );
          expect(find.text(kh ? 'អភិបាលកិច្ច' : 'Governance'), findsOneWidget);
          expect(
            find.text(kh ? 'ក្រុមការងារខ្មែរ' : 'Working group'),
            findsOneWidget,
          );
        }
        expect(listCalls, callsBeforeSwitch);
        if (module == AppModuleType.privateSector) {
          await tester.enterText(find.byType(TextField), 'ចំណងជើងបញ្ហាខ្មែរ');
          await tester.pumpAndSettle();
          expect(find.text('ចំណងជើងបញ្ហាខ្មែរ'), findsWidgets);
          await tester.enterText(find.byType(TextField), 'does not match');
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('wg-issue-77')), findsNothing);
          await tester.enterText(find.byType(TextField), '');
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('ចំណងជើងបញ្ហាខ្មែរ'));
        await tester.pumpAndSettle();
        for (final language in [AppLanguage.english, AppLanguage.khmer]) {
          settings.setLanguage(language);
          await tester.pumpAndSettle();
          final kh = language == AppLanguage.khmer;
          expect(
            find.text(record[kh ? 'titleKh' : 'title'] as String),
            findsOneWidget,
          );
          expect(
            find.text(record[kh ? 'descriptionKh' : 'description'] as String),
            findsOneWidget,
          );
          expect(
            find.text(
              record[kh ? 'recommendationKh' : 'recommendation'] as String,
            ),
            findsOneWidget,
          );
          expect(find.text(kh ? 'ស្ថាប័នខ្មែរ' : 'Agency'), findsOneWidget);
        }
        await tester.tap(
          find.text(AppLocalizations(AppLanguage.khmer).text('progressReport')),
        );
        await tester.pumpAndSettle();
        expect(find.text('ឯកសារយោងខ្មែរ'), findsOneWidget);
        await tester.tap(
          find.text(AppLocalizations(AppLanguage.khmer).text('viewDetails')),
        );
        await tester.pumpAndSettle();
        for (final language in [
          AppLanguage.english,
          AppLanguage.khmer,
          AppLanguage.english,
        ]) {
          settings.setLanguage(language);
          await tester.pumpAndSettle();
          final kh = language == AppLanguage.khmer;
          expect(
            find.text(record[kh ? 'titleKh' : 'title'] as String),
            findsOneWidget,
          );
          for (final pair in [
            ['English reference', 'ឯកសារយោងខ្មែរ'],
            ['English progress', 'វឌ្ឍនភាពខ្មែរ'],
            ['English indicators', 'សូចនាករខ្មែរ'],
            ['English decision', 'សេចក្តីសម្រេចខ្មែរ'],
          ]) {
            expect(
              find.text(pair[kh ? 1 : 0], findRichText: true),
              findsOneWidget,
            );
            expect(
              find.text(pair[kh ? 0 : 1], findRichText: true),
              findsNothing,
            );
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'issue translations keep filter codes and fall back when a language is missing',
    () {
      final issue = WorkingGroupIssue.fromJson({
        'id': 1,
        'title': 'Original title',
        'titleKh': '  ',
        'description': '',
        'descriptionKh': '<p>ការពិពណ៌នា</p>',
        'recommendation': 'Original recommendation',
        'recommendationKh': '<p><br></p>',
        'category': {'name': 'Governance', 'khName': 'អភិបាលកិច្ច'},
        'issueStatus': {'code': 'IN_PROGRESS'},
      });
      expect(issue.localizedText('title', AppLanguage.khmer), 'Original title');
      expect(
        issue.localizedText('description', AppLanguage.english),
        '<p>ការពិពណ៌នា</p>',
      );
      expect(
        issue.localizedText('recommendation', AppLanguage.khmer),
        'Original recommendation',
      );
      expect(issue.filterValues['local.category'], ['Governance']);
      expect(issue.statusCode, 'IN_PROGRESS');
      expect(issue.title, 'Original title');
    },
  );
}
