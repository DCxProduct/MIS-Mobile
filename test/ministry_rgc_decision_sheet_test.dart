import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/editor_content.dart';
import 'package:gpsf_app/core/widgets/pdf_attachment_preview.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/line_ministry/reports/ministry_rgc_decision_sheet.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/screens/report/rgc_decision_detail_screen.dart';

void main() {
  final fixture =
      jsonDecode(
            File('test/fixtures/ministry_rgc_decision.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final data = fixture['data'] as Map<String, dynamic>;

  final suppliedList =
      jsonDecode(
            File(
              'test/fixtures/ministry_plenary_1_decisions.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final suppliedDecision =
      (suppliedList['data']['items'] as List).first as Map<String, dynamic>;

  test(
    'supplied NBC decision retains empty indicators and independent identity',
    () {
      final detail = RgcDecisionDetail.fromJson(suppliedDecision);
      expect(detail.decision.id, 157);
      expect(detail.decision.plenaryId, 1);
      expect(detail.decision.plenaryName, 'វេទិកាទី១៩');
      expect(detail.decision.agencyName, 'NBC');
      expect(
        detail.decision.agencyLogo,
        suppliedDecision['stakeholder']['logo'],
      );
      expect(detail.decision.category, 'Governance');
      expect(detail.decision.statusCode, 'SOLVED');
      expect(detail.decision.focalPerson, 'Chea Serey');
      expect(detail.decision.meetingDate, DateTime.utc(2023, 11, 13));
      expect(detail.decisionContent, suppliedDecision['decision']);
      expect(detail.verificationSource, suppliedDecision['verificationSource']);
      expect(detail.verificationLink, suppliedDecision['verificationLink']);
      expect(detail.indicatorName, isEmpty);
      expect(detail.indicatorDescription, isEmpty);
      expect(detail.issues.where((issue) => issue.title.isNotEmpty), isEmpty);
      expect(detail.progressReports, isEmpty);
    },
  );

  for (final language in [AppLanguage.english, AppLanguage.khmer]) {
    testWidgets(
      '$language NBC decision shows web sections and report periods',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <String>[];
        // The supplied list omits reports. These distinct updates verify the
        // detail endpoint contract without treating list rows as report data.
        final detailData = <String, dynamic>{
          ...suppliedDecision,
          'indicatorName': 'API indicator name',
          'indicatorDescription': '<p>API indicator description</p>',
          'progressReports': [
            for (final period in ['S1', 'S2'])
              {
                'semester': period,
                'year': 2026,
                'dateOfIssueSolution': '2024-11-23T00:00:00Z',
                'referenceName': '$period reference',
                'progressSolution': '<p>$period implementation progress</p>',
                'indicators': '',
                'implementationChallenges': '',
                'requests': '',
                if (period == 'S2')
                  'attachment': {
                    'path': '/uploads/S2-reference.pdf',
                    'name': 'S2-reference.pdf',
                  },
              },
          ],
        };
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      calls.add(request.url.path);
                      expect(request.url.path, '/api/v1/rgc-decisions/157');
                      return http.Response.bytes(
                        utf8.encode(
                          jsonEncode({'success': true, 'data': detailData}),
                        ),
                        200,
                      );
                    }),
                  ),
                ),
              )
              ..setLanguage(language)
              ..setModuleType(AppModuleType.lineMinistry);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(body: MinistryRgcDecisionSheet(decisionId: 157)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(MinistryRgcDecisionSheet));
        final l10n = AppLocalizations.of(
          context,
          page: 'plenary_rgc_decisions',
        );
        expect(find.text('NBC'), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        expect(
          find.descendant(
            of: find.byType(MinistryRgcDecisionSheet),
            matching: find.byType(Scaffold),
          ),
          findsOneWidget,
        );
        expect(find.text('Chea Serey'), findsOneWidget);
        expect(find.text('API indicator name'), findsOneWidget);
        expect(find.text(l10n.text('linkedIssues')), findsOneWidget);
        expect(find.text(l10n.text('indicators')), findsNWidgets(2));
        final scroll = find.byType(Scrollable).first;
        final description = find.byWidgetPredicate(
          (w) =>
              w is EditorContent &&
              w.data == '<p>API indicator description</p>',
        );
        await tester.scrollUntilVisible(description, 180, scrollable: scroll);
        expect(description, findsOneWidget);
        await tester.scrollUntilVisible(
          find.byType(RgcDecisionProgressReports),
          180,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        final reports = find.byType(RgcDecisionProgressReports);
        expect(
          find.descendant(
            of: reports,
            matching: find.byType(PdfAttachmentPreview),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: reports,
            matching: find.text(l10n.text('rgcReportReferenceAttachment')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: reports,
            matching: find.text(l10n.text('rgcReportNoReference')),
          ),
          findsNWidgets(4),
        );
        final s2 = find.byKey(const ValueKey('ministry-rgc-report-tab-1'));
        await tester.ensureVisible(s2);
        await tester.pumpAndSettle();
        await tester.tap(s2);
        await tester.pumpAndSettle();
        expect(find.text('S2 reference'), findsOneWidget);
        expect(find.text('S1 reference'), findsNothing);
        expect(find.text('S2 implementation progress'), findsOneWidget);
        final attachment = tester.widget<PdfAttachmentPreview>(
          find.descendant(
            of: reports,
            matching: find.byType(PdfAttachmentPreview),
          ),
        );
        expect(attachment.path, '/uploads/S2-reference.pdf');
        expect(calls, ['/api/v1/rgc-decisions/157']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('ministry decision shows each report period and its document', (
    tester,
  ) async {
    final detail = RgcDecisionDetail.fromJson({
      ...data,
      'progressReports': [
        for (final semester in ['S1', 'S2'])
          {
            'semester': semester,
            'year': 2028,
            'dateOfIssueSolution': '2026-10-19',
            'referenceName': '$semester reference',
            'progressSolution': '$semester progress',
            'attachment': {
              'path': '/$semester.pdf',
              'name': '$semester.pdf',
              'size': 1947246,
            },
          },
      ],
    });
    final settings = AppSettingsController()
      ..setLanguage(AppLanguage.english)
      ..setModuleType(AppModuleType.lineMinistry);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: MinistryRgcDecisionSheet(
              decisionId: detail.decision.id,
              detail: detail,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Report S1 2028'),
      300,
      scrollable: scroll,
    );
    expect(find.text('S1.pdf'), findsOneWidget);
    final second = find.text('Report S2 2028');
    await tester.ensureVisible(second);
    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(find.text('S2.pdf'), findsOneWidget);
    expect(find.text('S1.pdf'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('preserves web decision fields independently from its linked issue', () {
    final detail = RgcDecisionDetail.fromJson(data);
    expect(detail.decision.agencyName, 'MAFF');
    expect(detail.decision.category, 'Communication');
    expect(detail.decision.meetingDate, DateTime.utc(2026, 10, 3));
    expect(detail.decision.status, 'Not Addressed');
    expect(detail.indicatorName, 'Milestone 2');
    expect(detail.decisionContent, data['decision']);
    expect(detail.verificationSource, data['verificationSource']);
    expect(detail.verificationLink, data['verificationLink']);
    expect(detail.issues.single.submittedBy, 'Agriculture & Agro-Industry');
    expect(detail.issues.single.category, 'General');
    expect(detail.issues.single.meetingDate, DateTime.utc(2026, 9, 14));
    expect(detail.issues.single.status, 'In Progress');
    expect(
      RgcDecisionDetail.fromJson({...data, 'indicatorName': ''}).indicatorName,
      isEmpty,
    );
  });

  for (final language in [AppLanguage.english, AppLanguage.khmer]) {
    testWidgets(
      '$language Ministry detail matches the supplied web record on mobile',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <String>[];
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      calls.add(request.url.path);
                      if (request.url.path == '/api/v1/rgc-decisions/3') {
                        return http.Response.bytes(
                          utf8.encode(jsonEncode(fixture)),
                          200,
                        );
                      }
                      expect(request.url.path, '/api/v1/plenaries/3');
                      return http.Response(
                        jsonEncode({
                          'success': true,
                          'data': {
                            'id': 3,
                            'name': '21th',
                            'meetingDate': '2026-09-13',
                            'deadline': '2026-10-05',
                            'status': 'Sent',
                          },
                        }),
                        200,
                      );
                    }),
                  ),
                ),
              )
              ..setLanguage(language)
              ..setModuleType(AppModuleType.lineMinistry);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () =>
                        showMinistryRgcDecisionSheet(context, decisionId: 3),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(MinistryRgcDecisionSheet), findsOneWidget);
        expect(find.text('21th'), findsOneWidget);
        expect(find.text('MAFF'), findsOneWidget);
        expect(find.text('Communication'), findsOneWidget);
        expect(
          find.text(
            language == AppLanguage.khmer ? '៣ តុលា ២០២៦' : 'Oct 3, 2026',
          ),
          findsOneWidget,
        );
        expect(
          find.text(AppLocalizations(language).status('Not Addressed')),
          findsOneWidget,
        );
        expect(find.text('H.E. Mr. DITH TINA'), findsOneWidget);
        expect(find.text('Milestone 2'), findsWidgets);
        expect(find.text('General'), findsNothing);
        expect(find.text('Agriculture & Agro-Industry'), findsNothing);
        expect(find.text('Sep 14, 2026'), findsNothing);
        expect(find.text('ចូលរួមសហគមន៍កសិកម្មទំនើប'), findsOneWidget);
        final source = find.byWidgetPredicate(
          (widget) =>
              widget is EditorContent &&
              widget.data == data['verificationSource'],
        );
        await tester.scrollUntilVisible(
          source,
          120,
          scrollable: find.byType(Scrollable).last,
        );
        expect(source, findsOneWidget);
        final link = find.textContaining(
          data['verificationLink'] as String,
          findRichText: true,
        );
        await tester.scrollUntilVisible(
          link,
          120,
          scrollable: find.byType(Scrollable).last,
        );
        expect(link, findsOneWidget);
        expect(
          calls.where((path) => path == '/api/v1/rgc-decisions/3'),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
      },
    );
  }
}
