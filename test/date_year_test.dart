import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/shared/issues/widgets/issue_display.dart';
import 'package:gpsf_app/screens/meeting/meeting_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final fixture = File(
    'test/fixtures/meeting_requests.json',
  ).readAsStringSync();
  final title = jsonDecode(fixture)['data'][0]['title'] as String;

  for (final locale in const [Locale('en'), Locale('km')]) {
    testWidgets(
      '$locale shared dates include one year and preserve missing values',
      (tester) async {
        final settings = AppSettingsController();
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('km')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Builder(
                builder: (context) {
                  final date = DateTime(2026, 9, 14, 9);
                  final year = MaterialLocalizations.of(
                    context,
                  ).formatYear(date);
                  for (final value in [
                    issueDate(context, date),
                    issueDateWithYear(context, date),
                    issueDateWithTime(context, date),
                  ]) {
                    expect(
                      RegExp(RegExp.escape(year)).allMatches(value),
                      hasLength(1),
                    );
                  }
                  expect(issueDate(context, null), '—');
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final module in AppModuleType.values) {
    testWidgets(
      '$module meeting dates keep the year visible in both languages',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = AppSettingsController(
          authRepository: AuthRepository(
            ApiClient(
              client: MockClient((_) async => http.Response(fixture, 200)),
            ),
          ),
        )..setModuleType(module);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: AnimatedBuilder(
              animation: settings,
              builder: (context, _) => MaterialApp(
                locale: settings.locale,
                supportedLocales: const [Locale('en'), Locale('km')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: const Scaffold(body: MeetingScreen()),
              ),
            ),
          ),
        );
        for (final language in [AppLanguage.khmer, AppLanguage.english]) {
          settings.setLanguage(language);
          await tester.pumpAndSettle();
          final context = tester.element(find.text(title));
          final year = MaterialLocalizations.of(
            context,
          ).formatYear(DateTime(2026));
          final date = find.textContaining(year);
          expect(date, findsWidgets);
          for (final element in date.evaluate()) {
            expect(
              tester
                  .renderObject<RenderParagraph>(
                    find.byElementPredicate(
                      (candidate) => candidate == element,
                    ),
                  )
                  .didExceedMaxLines,
              isFalse,
            );
          }
        }
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(find.textContaining('2026', findRichText: true), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
