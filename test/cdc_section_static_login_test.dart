import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/config/role_modules.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_section/dashboard/dashboard_screen.dart';
import 'package:gpsf_app/screens/auth/login_screen.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:gpsf_app/widgets/primary_button.dart';

void main() {
  test('CDC and CDC GPSF roles open their separate modules', () {
    expect(moduleForRoles(['cdc']), AppModuleType.cdcSection);
    expect(moduleForRoles(['cdc', 'admin']), AppModuleType.cdcSection);
    expect(moduleForRoles(['cdcgpsf']), AppModuleType.cdcSecretariat);
    expect(moduleForRoles(['cdc_gpsf']), AppModuleType.cdcSecretariat);
    expect(moduleForRoles(['cdc_secretariat']), AppModuleType.cdcSecretariat);
  });
  late AuthRepository auth;
  late int requests;

  setUp(() {
    requests = 0;
    auth = AuthRepository(
      ApiClient(
        client: MockClient((_) async {
          requests++;
          throw StateError('Static login must not contact the backend');
        }),
      ),
    );
  });
  tearDown(() => auth.dispose());

  test(
    'static credentials create a CDC Section session and logout locally',
    () async {
      final user = await auth.login(' CDC@gmail.com ', '12345678');
      expect(user.email, 'cdc@gmail.com');
      expect(user.roles, ['cdc_section']);
      expect(auth.isStaticSession, isTrue);
      expect(await auth.getCurrentUser(), same(user));
      await auth.logout();
      expect(auth.isStaticSession, isFalse);
      expect(requests, 0);
    },
  );

  test(
    'wrong password rejects static login and clears an existing session',
    () async {
      await auth.login('cdc@gmail.com', '12345678');
      await expectLater(
        auth.login('cdc@gmail.com', 'wrong'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
      expect(auth.isStaticSession, isFalse);
      expect(requests, 0);
    },
  );

  testWidgets('login opens the CDC Section sample dashboard without requests', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController(authRepository: auth)
      ..setLanguage(AppLanguage.english);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'cdc@gmail.com');
    await tester.enterText(find.byType(TextFormField).last, '12345678');
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(settings.moduleType, AppModuleType.cdcSection);
    expect(find.byType(CdcSectionDashboardScreenView), findsOneWidget);
    await tester.tap(find.text('CDC Issues'));
    await tester.pumpAndSettle();
    expect(find.text('CDC Issues Matrix'), findsOneWidget);
    expect(find.text('Meeting Requests'), findsNothing);
    expect(find.text('56'), findsOneWidget);
    expect(find.text('30/56'), findsOneWidget);
    expect(find.text('16/56'), findsOneWidget);
    expect(find.text('10/56'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('Joint Inspection'), findsOneWidget);
    await tester.tap(find.text('Joint Inspection'));
    await tester.pumpAndSettle();
    expect(find.text('Issue Details'), findsOneWidget);
    expect(find.text('Submit Detail'), findsOneWidget);
    expect(find.text('Government Primary Agency:'), findsOneWidget);
    expect(find.text('MAFF'), findsOneWidget);
    expect(find.text('Request Doc'), findsOneWidget);
    expect(find.text('Descriptions'), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'Read more').first);
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Show less'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Link to Verification Source'));
    await tester.pumpAndSettle();
    for (final key in [
      'indicators',
      'progressSolution',
      'implementationChallenges',
      'request',
      'nextStep',
      'sourceOfVerification',
      'linkToVerificationSource',
    ]) {
      expect(find.byKey(ValueKey('cdc-detail-$key')), findsOneWidget);
    }
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('CDC Issues Matrix'), findsOneWidget);
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Solved'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Joint Inspection'), findsNothing);
    expect(find.text('No issues found.'), findsOneWidget);
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Joint Inspection'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    expect(requests, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    settings.dispose();
  });
}
