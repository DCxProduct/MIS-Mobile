import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/screens/account/profile_detail_screen.dart';
import 'package:gpsf_app/screens/account/widgets/profile_tile.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  final profile = <String, dynamic>{
    'id': 19,
    'email': 'ministry@example.com',
    'name': 'MAFF',
    'position': 'Ministry of Agriculture',
    'isActive': true,
    'phoneNumber': null,
    'gender': null,
    'address': null,
    'dateOfBirth': null,
    'avatar': null,
  };
  testWidgets('Account and detail load users/me without fabricated values', (
    tester,
  ) async {
    final paths = <String>[];
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((request) async {
            paths.add(request.url.path);
            return http.Response(
              jsonEncode({'success': true, 'data': profile}),
              200,
            );
          }),
        ),
      ),
    )..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: Scaffold(body: ProfileTile())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MAFF'), findsOneWidget);
    expect(find.text('Ministry of Agriculture'), findsOneWidget);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: ProfileDetailScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(paths, ['/api/v1/users/me', '/api/v1/users/me']);
    expect(find.text('MAFF'), findsOneWidget);
    expect(find.text('ministry@example.com'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(4));
    expect(find.text('KHON VAKHIM'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Profile retries failed requests and displays populated fields', (
    tester,
  ) async {
    var calls = 0;
    final settings = AppSettingsController(
      authRepository: AuthRepository(
        ApiClient(
          client: MockClient((request) async {
            if (++calls == 1) {
              return http.Response('{"message":"Unavailable"}', 500);
            }
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  ...profile,
                  'gender': 'Female',
                  'dateOfBirth': '2000-03-09T00:00:00.000Z',
                  'phoneNumber': '012345678',
                  'address': 'Phnom Penh',
                },
              }),
              200,
            );
          }),
        ),
      ),
    )..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: const MaterialApp(home: ProfileDetailScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('2000-03-09'), findsOneWidget);
    expect(find.text('Phnom Penh'), findsOneWidget);
    expect(find.text('012345678'), findsOneWidget);
  });
}
