import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/widgets/primary_button.dart';
import 'package:gpsf_app/features/private_sector/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/config/role_modules.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/auth/data/auth_user.dart';
import 'package:gpsf_app/screens/auth/login_screen.dart';
import 'package:gpsf_app/screens/account/logout_sheet.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  test(
    'defaults and verified roles select the module independently of email',
    () {
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      expect(settings.themeMode, ThemeMode.light);
      expect(settings.language, AppLanguage.khmer);
      for (final entry in {
        'admin': AppModuleType.cdcSecretariat,
        'cdc_secretariat': AppModuleType.cdcSecretariat,
        'cdc_section': AppModuleType.cdcSection,
        'line_ministry': AppModuleType.lineMinistry,
        'private_sector': AppModuleType.privateSector,
        'PSWG': AppModuleType.privateSector,
        'Private Sector': AppModuleType.privateSector,
        'cefp': AppModuleType.cefp,
      }.entries) {
        final user = AuthUser.fromJson({
          'id': 1,
          'email': 'ministry@example.com',
          'name': 'User',
          'isActive': true,
          'roles': [
            {'name': entry.key},
          ],
        });
        settings.setCurrentUser(user);
        expect(settings.moduleType, entry.value);
      }
      expect(
        () => settings.setCurrentUser(
          const AuthUser(
            id: 2,
            email: 'secretariat@example.com',
            name: 'Unknown',
            isActive: true,
          ),
        ),
        throwsA(isA<UnsupportedRoleException>()),
      );
    },
  );

  testWidgets(
    'Private Sector login opens its dashboard with PSWG and admin roles',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient(
              (request) async => http.Response(
                request.url.path.startsWith('/api/v1/dashboards/')
                    ? File('test/fixtures/plenary.json').readAsStringSync()
                    : jsonEncode({
                        'success': true,
                        'data': {
                          'user': {
                            'id': 42,
                            'email': 'member@example.com',
                            'name': 'Member',
                            'isActive': true,
                            'roles': [
                              {'name': 'admin'},
                              {'name': 'PSWG'},
                            ],
                          },
                        },
                      }),
                200,
              ),
            ),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'member@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'test-password');
      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(settings.moduleType, AppModuleType.privateSector);
      expect(find.byType(DashboardPage), findsOneWidget);
    },
  );

  test(
    'specific Private Sector roles override generic admin in either order',
    () {
      expect(
        moduleForRoles(['admin', 'private_sector']),
        AppModuleType.privateSector,
      );
      expect(moduleForRoles(['PSWG', 'admin']), AppModuleType.privateSector);
      expect(
        moduleForRoles(['CDC Secretariat User']),
        AppModuleType.cdcSecretariat,
      );
      expect(
        moduleForRoles(['cdc_secretariat_admin']),
        AppModuleType.cdcSecretariat,
      );
      expect(moduleForRoles(['cdc_g-psf']), AppModuleType.cdcSecretariat);
      expect(moduleForRoles(['unknown']), isNull);
    },
  );

  test(
    'actions support message-only and empty success without hiding errors',
    () async {
      final responses = [
        http.Response('{"success":true,"message":"Sent"}', 200),
        http.Response('', 204),
        http.Response('{"success":false,"message":"Invalid OTP"}', 400),
      ];
      final api = ApiClient(
        client: MockClient((_) async => responses.removeAt(0)),
      );
      addTearDown(api.close);
      final auth = AuthRepository(api);
      await auth.forgotPassword('user@example.com');
      await auth.resetPassword(
        email: 'user@example.com',
        otp: '012345',
        newPassword: 'test',
      );
      await expectLater(
        auth.resetPassword(
          email: 'user@example.com',
          otp: 'bad',
          newPassword: 'test',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Invalid OTP',
          ),
        ),
      );
    },
  );

  testWidgets(
    'forgot password sends email, rejects mismatch, resets and returns to login',
    (tester) async {
      final requests = <http.Request>[];
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              requests.add(request);
              return http.Response('{"success":true,"message":"OK"}', 200);
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.ensureVisible(find.text('Forgot Password'));
      await tester.tap(find.text('Forgot Password'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('recovery-email')),
        'user@example.com',
      );
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(requests.single.url.path, '/api/v1/auth/forgot-password');
      expect(jsonDecode(requests.single.body), {'email': 'user@example.com'});
      await tester.enterText(
        find.byKey(const ValueKey('recovery-otp')),
        '012345',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recovery-password')),
        'NewPassword123',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recovery-confirm')),
        'wrong',
      );
      await tester.ensureVisible(
        find.widgetWithText(PrimaryButton, 'Reset password'),
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'Reset password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(requests.length, 1);
      await tester.enterText(
        find.byKey(const ValueKey('recovery-confirm')),
        'NewPassword123',
      );
      await tester.ensureVisible(
        find.widgetWithText(PrimaryButton, 'Reset password'),
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'Reset password'));
      await tester.pumpAndSettle();
      expect(requests.last.url.path, '/api/v1/auth/reset-password');
      expect(jsonDecode(requests.last.body), {
        'email': 'user@example.com',
        'otp': '012345',
        'newPassword': 'NewPassword123',
      });
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('Password reset successfully. Please sign in.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'logout failure stays open; retry calls server then clears user',
    (tester) async {
      var count = 0;
      final settings = AppSettingsController(
        authRepository: AuthRepository(
          ApiClient(
            client: MockClient((request) async {
              expect(request.method, 'POST');
              expect(request.url.path, '/api/v1/auth/logout');
              expect(request.body, isEmpty);
              count++;
              return count == 1
                  ? http.Response('', 502)
                  : http.Response('', 204);
            }),
          ),
        ),
      )..setLanguage(AppLanguage.english);
      settings.setCurrentUser(
        const AuthUser(
          id: 1,
          email: 'user@example.com',
          name: 'User',
          isActive: true,
          roles: ['admin'],
        ),
      );
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        AppSettings(
          controller: settings,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showLogoutSheet(context),
                  child: const Text('Open logout'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
      await tester.pumpAndSettle();
      expect(settings.currentUser, isNotNull);
      expect(find.textContaining('502'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
      await tester.pumpAndSettle();
      expect(settings.currentUser, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(count, 2);
    },
  );
}
