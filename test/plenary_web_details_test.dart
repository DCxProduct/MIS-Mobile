import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';
import 'package:gpsf_app/core/widgets/editor_content.dart';
import 'package:gpsf_app/screens/report/plenary_detail_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';

void main() {
  final response =
      jsonDecode(
            File('test/fixtures/plenary_decisions_web.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final raw =
      (response['data']['items'] as List).single as Map<String, dynamic>;
  test('maps the supplied web response without dropping details', () {
    final decision = RgcDecision(raw);
    expect(decision.indicatorName, 'Milestone 1');
    expect(decision.issueTitles, ['Problems on direct flights to Cambodia']);
    expect(decision.verificationSource, contains('<ul>'));
    expect(decision.verificationSource, contains('<li>'));
    expect(decision.decisionHtml, raw['decision']);
    expect(decision.statusCode, 'NOT_ADDRESSED');
    final fallback = RgcDecision({...raw, 'indicatorName': null});
    expect(fallback.indicatorName, 'Milestone 1');
  });

  for (final language in [AppLanguage.english, AppLanguage.khmer]) {
    testWidgets('web decision fields fit mobile and translate: $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/plenaries/6') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'id': 6,
                  'meetingDate': raw['meetingDate'],
                  'status': 'Sent',
                  'numberOfRgcDecisions': 1,
                },
              }),
              200,
            );
          }
          expect(request.url.path, '/api/v1/rgc-decisions');
          expect(request.url.queryParameters['plenaryId'], '6');
          return http.Response(
            jsonEncode(response),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final settings = AppSettingsController(
        authRepository: AuthRepository(api),
      )..setLanguage(language);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(
            home: PlenaryDetailScreen(title: 'Plenary', plenaryId: 6),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Taxation'));
      await tester.pumpAndSettle();
      final sheet = find.byType(DraggableScrollableSheet);
      final context = tester.element(sheet);
      final l10n = AppLocalizations.of(context);
      expect(find.text(raw['plenary']['name']), findsOneWidget);
      expect(find.text('MoT'), findsOneWidget);
      expect(find.text('• ${l10n.status('Not Addressed')}'), findsOneWidget);
      final status = tester.widget<Text>(
        find.text('• ${l10n.status('Not Addressed')}'),
      );
      expect(status.style?.color, const Color(0xFFE53935));
      expect(find.text('Milestone 1'), findsOneWidget);
      expect(
        find.text('Problems on direct flights to Cambodia'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text(l10n.text('sourceOfVerification')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is EditorContent &&
              widget.data == raw['verificationSource'],
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text(raw['verificationLink']),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(raw['verificationLink']), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
