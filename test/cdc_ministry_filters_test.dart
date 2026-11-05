import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/core/widgets/filters/app_filter_sheet.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';
import 'package:gpsf_app/features/cdc_secretariat/issues/issues_screen.dart';
import 'package:gpsf_app/features/private_sector/meetings/meeting_screen.dart';
import 'package:gpsf_app/features/shared/meetings/widgets/monthly_meeting_calendar.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final language in AppLanguage.values) {
    for (final screen in ['calendar', 'summary', 'matrix']) {
      testWidgets('$language $screen offers and applies the ministry filter', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <Uri>[];
        http.Response ok(Object data, {int pages = 1}) => http.Response(
          jsonEncode({
            'success': true,
            'data': data,
            'meta': {'totalPages': pages},
          }),
          200,
        );
        final settings =
            AppSettingsController(
                authRepository: AuthRepository(
                  ApiClient(
                    client: MockClient((request) async {
                      calls.add(request.url);
                      final second = request.url.queryParameters['page'] == '2';
                      final agency = second ? 'MAFF' : 'MEF';
                      switch (request.url.path) {
                        case '/api/v1/meetings':
                          return ok({
                            'items': [
                              {
                                'id': second ? 2 : 1,
                                'title': 'Meeting $agency',
                                'meetingDate': second
                                    ? '2028-06-20T09:00:00'
                                    : '2028-06-10T09:00:00',
                                'meetingRequest': {
                                  'governmentAgencies': [
                                    {
                                      'stakeholder': {
                                        'id': second ? 9 : 3,
                                        'name': agency,
                                      },
                                    },
                                  ],
                                },
                              },
                            ],
                          }, pages: 2);
                        case '/api/v1/meeting-summaries':
                          return ok({
                            'items': [
                              {
                                'id': second ? 2 : 1,
                                'summaryTitle': 'Summary $agency',
                                'governmentAgency': agency,
                                'status': 'DRAFT',
                                'issueCount': second ? 5 : 3,
                              },
                            ],
                          }, pages: 2);
                        case '/api/v1/working-group-issues/issue-matrix/filter-options':
                          return ok({
                            'categories': [],
                            'statuses': [],
                            'years': [],
                            'workingGroups': [],
                            'governmentAgencies': [
                              {'id': 3, 'name': 'MEF'},
                              {'id': 9, 'name': 'MAFF'},
                            ],
                          });
                        case '/api/v1/working-group-issues/issue-matrix/summary':
                          return ok({'total': 0, 'byStatus': []});
                        default:
                          return ok({'items': []});
                      }
                    }),
                  ),
                ),
              )
              ..setModuleType(AppModuleType.cdcSecretariat)
              ..setLanguage(language);
        addTearDown(settings.dispose);
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: Scaffold(
                body: screen == 'matrix'
                    ? const CdcSecretariatIssuesScreenView(
                        initialTab: 1,
                        embedded: true,
                      )
                    : MeetingScreen(
                        initialTab: screen == 'calendar' ? 1 : 2,
                        showTabs: false,
                        embedded: true,
                      ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        expect(
          find.text(language == AppLanguage.khmer ? 'ក្រសួង' : 'Ministry'),
          findsOneWidget,
        );
        final field = screen == 'matrix'
            ? 'primaryAgencyIds'
            : 'local.primaryAgency';
        final option = find.byKey(
          ValueKey('filter-$field-${screen == 'matrix' ? '9' : 'MAFF'}'),
        );
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        if (screen == 'calendar') {
          expect(
            tester
                .widget<MonthlyMeetingCalendar>(
                  find.byType(MonthlyMeetingCalendar),
                )
                .meetingDates,
            [DateTime(2028, 6, 20, 9)],
          );
          expect(find.text('Meeting MAFF'), findsOneWidget);
          expect(find.text('Meeting MEF'), findsNothing);
        } else if (screen == 'summary') {
          expect(find.text('Summary MAFF'), findsOneWidget);
          expect(find.text('Summary MEF'), findsNothing);
        } else {
          expect(
            calls
                .lastWhere((uri) => uri.path.endsWith('/issue-matrix'))
                .queryParameters['primaryAgencyIds'],
            '9',
          );
        }
        // Reopening retains the choice; deselecting and applying clears it.
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        final sheet = tester.widget<AppFilterSheet>(
          find.byType(AppFilterSheet),
        );
        expect(sheet.initial[field], {screen == 'matrix' ? '9' : 'MAFF'});
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        if (screen == 'summary') {
          expect(find.text('Summary MEF'), findsOneWidget);
        } else if (screen == 'matrix') {
          expect(
            calls
                .lastWhere((uri) => uri.path.endsWith('/issue-matrix'))
                .queryParameters
                .containsKey('primaryAgencyIds'),
            isFalse,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
