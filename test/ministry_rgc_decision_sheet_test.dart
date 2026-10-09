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
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/line_ministry/reports/ministry_rgc_decision_sheet.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final fixture =
      jsonDecode(
            File('test/fixtures/ministry_rgc_decision.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final data = fixture['data'] as Map<String, dynamic>;

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
      'Milestone 2',
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
        expect(find.text('Oct 3, 2026'), findsOneWidget);
        expect(find.text('• Not Addressed'), findsOneWidget);
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
