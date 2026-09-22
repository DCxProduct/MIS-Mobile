import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/screens/auth/login_screen.dart';
import 'package:gpsf_app/screens/account/profile_detail_screen.dart';
import 'package:gpsf_app/widgets/app_bottom_nav_bar.dart';
import 'package:gpsf_app/widgets/primary_button.dart';
import 'package:gpsf_app/features/cdc_secretariat/dashboard/agencies_tab.dart';

void main() {
  testWidgets('CDC account opens dashboard and displays its profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = AppSettingsController();
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'cdcgpsf@gmail.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(settings.moduleType, AppModuleType.cdcSecretariat);
    expect(find.text('179'), findsOneWidget);
    expect(find.text('166/179'), findsOneWidget);
    expect(find.text('(100)'), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);

    await tester.tap(find.text('Agencies'));
    await tester.pumpAndSettle();
    expect(find.byType(CdcSecretariatAgenciesTab), findsOneWidget);
    expect(find.text('Agencies'), findsNWidgets(2));

    await tester.tap(find.text('Working Group'));
    await tester.pumpAndSettle();
    expect(find.text('(I) Rice and Paddy'), findsOneWidget);
    expect(
      find.text('(N) Non-Bank Financial Services Other issues'),
      findsOneWidget,
    );

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Human Resource'), findsOneWidget);
    expect(find.text('Strategy'), findsOneWidget);
    await tester.ensureVisible(find.text('Strategy'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meeting'));
    await tester.pumpAndSettle();
    expect(find.text('10 Aug, 2025'), findsOneWidget);
    expect(find.text('12 Aug, 2025'), findsNWidgets(2));
    expect(find.text('Submitted'), findsNWidgets(2));
    expect(find.text('Under Review'), findsOneWidget);
    expect(find.text('WG.Meeting'), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);

    await tester.tap(find.text('Issues'));
    await tester.pumpAndSettle();
    expect(find.text('WG Issues'), findsOneWidget);
    expect(find.text('MPWT'), findsNWidgets(2));
    expect(find.text('15/20'), findsOneWidget);
    await tester.tap(find.text('View Details').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Issues Matrix'));
    await tester.pumpAndSettle();
    expect(
      find.text('Law on Contract Farming & Agricultural Production'),
      findsOneWidget,
    );
    expect(find.text('July 24, 2025'), findsNWidgets(2));
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report').last);
    await tester.pumpAndSettle();
    expect(find.text('166/179'), findsOneWidget);
    expect(find.text('92.73%'), findsOneWidget);
    await tester.tap(find.text('Agencies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Working Group'));
    await tester.pumpAndSettle();
    expect(find.text('(D) Law, Tax, and Governance'), findsOneWidget);
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('11. Other issues'), findsOneWidget);
    await tester.tap(find.text('Plenaries'));
    await tester.pumpAndSettle();
    expect(find.text('19th G-PSF. Plenary'), findsOneWidget);
    expect(find.text('Apr 08, 2025'), findsOneWidget);
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RGC Decision').first);
    await tester.pumpAndSettle();
    expect(find.text('MPWT'), findsNWidgets(2));
    expect(find.text('Nov 13, 2023'), findsOneWidget);

    final context = tester.element(find.byType(AppBottomNavBar));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileDetailScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('CDC Secretariat'), findsOneWidget);
    expect(find.text('cdcgpsf@gmail.com'), findsOneWidget);
  });
}
