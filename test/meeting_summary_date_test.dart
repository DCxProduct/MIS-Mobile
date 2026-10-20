import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/screens/report/tabs/meeting_summary_tab.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'summary list and detail display the API year in Khmer and English',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final calls = <String>[];
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              calls.add(request.url.path);
              final data = request.url.path.endsWith('/26')
                  ? {
                      'id': 26,
                      'meeting': {
                        'title': 'Summary title',
                        'meetingDate': '2026-10-19T00:00:00Z',
                      },
                    }
                  : {
                      'items': [
                        {
                          'id': 26,
                          'summaryTitle': 'Summary title',
                          'meetingDate': '2026-10-19T00:00:00Z',
                          'status': 'SCHEDULED',
                        },
                      ],
                    };
              return http.Response(
                jsonEncode({'success': true, 'data': data}),
                200,
              );
            }),
          ),
        ),
      );
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: AnimatedBuilder(
            animation: settings,
            builder: (context, _) => MaterialApp(
              locale: settings.locale,
              supportedLocales: const [Locale('en'), Locale('km')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(
                body: SingleChildScrollView(child: MeetingSummaryTab()),
              ),
            ),
          ),
        ),
      );
      for (final language in [AppLanguage.khmer, AppLanguage.english]) {
        settings.setLanguage(language);
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(MeetingSummaryTab));
        final year = MaterialLocalizations.of(
          context,
        ).formatYear(DateTime(2026));
        final date = find.textContaining(year);
        expect(date, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(date).didExceedMaxLines,
          isFalse,
        );
      }
      await tester.tap(find.text('Summary title'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026'), findsOneWidget);
      settings.setLanguage(AppLanguage.khmer);
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Summary title'));
      final year = MaterialLocalizations.of(context).formatYear(DateTime(2026));
      expect(find.textContaining(year), findsOneWidget);
      expect(calls.where((path) => path.endsWith('/26')), hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
