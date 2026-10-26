import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/auth/data/auth_user.dart';
import 'package:gpsf_app/screens/account/account_screen.dart';
import 'package:gpsf_app/screens/account/profile_detail_screen.dart';
import 'package:gpsf_app/translations/account_translation_keys.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/translations/app_localizations.dart';
import 'package:gpsf_app/translations/translation_repository.dart';
import 'package:gpsf_app/translations/translation_sync.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response ok(Object data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
http.Response dictionary(
  http.Request request,
  Map<String, String> values, {
  String? page,
}) => ok({
  'success': true,
  'data': {
    'module': request.url.queryParameters['module'],
    'language': request.url.queryParameters['language'],
    'page': page ?? request.url.queryParameters['page'],
    'translations': values,
  },
});
const profile = {
  'id': 19,
  'name': 'Actual User',
  'email': 'actual@example.com',
  'isActive': true,
  'gender': 'Female',
  'dateOfBirth': '2000-03-09',
  'address': 'Phnom Penh',
  'phoneNumber': '012345678',
  'position': 'Actual Position',
};
const roles = {
  AppModuleType.privateSector: 'pswg',
  AppModuleType.lineMinistry: 'line_ministry',
  AppModuleType.cdcSecretariat: 'cdcgpsf',
  AppModuleType.cdcSection: 'cdc',
  AppModuleType.cefp: 'cefp',
};
AppSettingsController settingsWith(
  Future<http.Response> Function(http.Request) handler, {
  AppModuleType module = AppModuleType.privateSector,
  AppLanguage language = AppLanguage.khmer,
}) {
  return AppSettingsController(
      authRepository: AuthRepository(ApiClient(client: MockClient(handler))),
    )
    ..setLanguage(language)
    ..setCurrentUser(
      AuthUser(
        id: 19,
        email: 'actual@example.com',
        name: 'Actual User',
        isActive: true,
        roles: [roles[module]!],
      ),
    );
}

Widget app(AppSettingsController settings, Widget home) => AppSettings(
  controller: settings,
  child: MaterialApp(home: home),
);

void main() {
  final fixtures =
      jsonDecode(
            File(
              'test/fixtures/account_translation_labels.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final language in AppLanguage.values) {
    final code = language == AppLanguage.khmer ? 'km' : 'en';
    final labels = Map<String, String>.from(fixtures[code] as Map);
    test('$code account aliases match the shared page API', () {
      for (final key in accountTranslationKeys.values) {
        expect(labels[key], isNotNull, reason: key);
      }
      final l10n = AppLocalizations(
        language,
        dictionary: labels,
        page: 'account_setting',
      );
      expect(l10n.text('email'), labels['email_address']);
      expect(l10n.text('phone'), labels['phone_number']);
      expect(l10n.text('personalInformation'), labels['personal_info']);
    });
    test(
      '$code repository sends and validates the requested shared page',
      () async {
        var wrongPage = false;
        final client = ApiClient(
          client: MockClient((request) async {
            expect(request.url.queryParameters, {
              'language': code,
              'module': 'shared',
              'page': 'account_setting',
            });
            expect(request.headers['Cache-Control'], 'no-cache, no-store');
            return dictionary(
              request,
              labels,
              page: wrongPage ? 'login' : 'account_setting',
            );
          }),
        );
        addTearDown(client.close);
        final repository = TranslationRepository(client);
        expect(
          await repository.dictionary(
            language,
            module: 'shared',
            page: 'account_setting',
          ),
          labels,
        );
        wrongPage = true;
        await expectLater(
          repository.dictionary(
            language,
            module: 'shared',
            page: 'account_setting',
          ),
          throwsFormatException,
        );
      },
    );
    for (final module in AppModuleType.values) {
      testWidgets(
        '$code $module profile uses shared labels and preserves user data',
        (tester) async {
          tester.view.physicalSize = const Size(600, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var sharedCalls = 0;
          final settings = settingsWith(
            (request) async {
              if (request.url.path.endsWith('translations/dictionary')) {
                if (request.url.queryParameters['module'] == 'shared') {
                  sharedCalls++;
                  expect(
                    request.url.queryParameters['page'],
                    'account_setting',
                  );
                  return dictionary(request, labels);
                }
                return dictionary(request, {
                  'profile': 'Wrong role label',
                  'gender': 'Wrong role gender',
                });
              }
              expect(request.url.path.endsWith('users/me'), isTrue);
              return ok(profile);
            },
            module: module,
            language: language,
          );
          addTearDown(settings.dispose);
          await settings.loadTranslations();
          await tester.pumpWidget(app(settings, const ProfileDetailScreen()));
          await tester.pumpAndSettle();
          for (final key in [
            'profile',
            'personal_info',
            'gender',
            'female',
            'date_of_birth',
            'address',
            'phone_number',
            'email_address',
          ]) {
            expect(find.text(labels[key]!), findsOneWidget, reason: key);
          }
          for (final value in [
            'Actual User',
            'Actual Position',
            'actual@example.com',
            'Phnom Penh',
            '012345678',
            '2000-03-09',
          ]) {
            expect(find.text(value), findsOneWidget);
          }
          expect(find.text('Wrong role label'), findsNothing);
          expect(settings.translations['profile'], 'Wrong role label');
          expect(sharedCalls, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets(
    'profile refreshes, pauses in background, retries and discards old-language responses',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var label = 'Shared gender v1';
      var fail = false;
      Completer<http.Response>? delayed;
      http.Request? delayedRequest;
      var calls = 0;
      final settings = settingsWith((request) async {
        if (request.url.path.endsWith('translations/dictionary')) {
          if (request.url.queryParameters['module'] != 'shared') {
            return dictionary(request, {});
          }
          calls++;
          if (delayed != null &&
              request.url.queryParameters['language'] == 'km') {
            delayedRequest = request;
            return delayed.future;
          }
          if (fail) return http.Response('{}', 503);
          return dictionary(request, {'gender': label});
        }
        return ok(profile);
      });
      addTearDown(settings.dispose);
      await tester.pumpWidget(app(settings, const ProfileDetailScreen()));
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations(settings.language).number(label)),
        findsOneWidget,
      );
      label = 'Shared gender v2';
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations(settings.language).number(label)),
        findsOneWidget,
      );
      fail = true;
      await tester.pump(TranslationSync.refreshInterval);
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations(settings.language).number(label)),
        findsOneWidget,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final before = calls;
      await tester.pump(const Duration(seconds: 20));
      expect(calls, before);
      fail = false;
      label = 'Resumed label';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations(settings.language).number(label)),
        findsOneWidget,
      );
      delayed = Completer<http.Response>();
      await tester.pump(TranslationSync.refreshInterval);
      expect(delayedRequest, isNotNull);
      label = 'English label';
      settings.setLanguage(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations(settings.language).number(label)),
        findsOneWidget,
      );
      delayed.complete(dictionary(delayedRequest!, {'gender': 'Stale Khmer'}));
      await tester.pumpAndSettle();
      expect(find.text('Stale Khmer'), findsNothing);
      expect(
        find.text(AppLocalizations(settings.language).number(label)),
        findsOneWidget,
      );
      settings.clearSession();
      await tester.pumpAndSettle();
      final loggedOutCalls = calls;
      await tester.pump(const Duration(seconds: 20));
      expect(calls, loggedOutCalls);
      expect(
        find.text(AppLocalizations(settings.language).number(label)),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 20));
      expect(calls, loggedOutCalls);
    },
  );

  testWidgets('account language dialog refreshes shared labels while open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var english = 'Web English';
    final settings = settingsWith((request) async {
      if (request.url.path.endsWith('translations/dictionary')) {
        return dictionary(
          request,
          request.url.queryParameters['module'] == 'shared'
              ? {
                  'page_title': 'Web Account',
                  'language': 'Web Language',
                  'english': english,
                }
              : {},
        );
      }
      return ok(profile);
    });
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      app(settings, const Scaffold(body: AccountScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Web Account'), findsOneWidget);
    await tester.tap(find.text('Web Language'));
    await tester.pumpAndSettle();
    expect(find.text(english), findsOneWidget);
    english = 'Updated Web English';
    await tester.pump(TranslationSync.refreshInterval);
    await tester.pumpAndSettle();
    expect(find.text(english), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
