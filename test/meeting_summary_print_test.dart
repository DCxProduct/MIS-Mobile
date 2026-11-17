import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/features/private_sector/reports/meeting_summary_detail_screen.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_summary.dart';
import 'package:gpsf_app/features/shared/meetings/printing/meeting_summary_printer.dart';
import 'package:gpsf_app/translations/app_language.dart';
import 'package:html/parser.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'support/print_preview_webview.dart';

MeetingSummary fixture() => MeetingSummary(
  (jsonDecode(File('test/fixtures/ministry_summary_14.json').readAsStringSync())
          as Map<String, dynamic>)['data']
      as Map<String, dynamic>,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'prints API issues, rich text and all participant roles in Khmer',
    () async {
      final data =
          jsonDecode(
                File(
                  'test/fixtures/ministry_summary_14.json',
                ).readAsStringSync(),
              )['data']
              as Map<String, dynamic>;
      data['pswgReporter'] = 'PSWG Reporter';
      data['pswgRepresentative'] = 'PSWG Representative';
      data['ministryReporter'] = 'Ministry Reporter';
      data['ministryRepresentative'] = 'Ministry Representative';
      final summary = MeetingSummary(data);
      final document = parse(
        await MeetingSummaryPrinter.buildDocument(summary),
      );
      expect(document.documentElement!.attributes['lang'], 'km');
      expect(
        document.querySelectorAll('.issue'),
        hasLength(summary.issues.length),
      );
      expect(
        document.querySelectorAll('.issue-table > tbody > tr'),
        hasLength(8),
      );
      expect(
        document.querySelector('.issue')!.text,
        contains(summary.issues.first.title),
      );
      expect(
        document.querySelector('.heading')!.text,
        contains(summary.pswgKhName),
      );
      expect(document.querySelectorAll('.signature'), hasLength(4));
      expect(document.querySelectorAll('.signature-name').map((e) => e.text), [
        'PSWG Reporter',
        'PSWG Representative',
        'Ministry Reporter',
        'Ministry Representative',
      ]);
      expect(
        document
            .querySelectorAll('img')
            .every((e) => e.attributes['src']!.startsWith('data:')),
        isTrue,
      );
      expect(
        document.querySelector('style')!.text,
        contains('@page{size:A4 portrait'),
      );
      expect(
        document.querySelectorAll('.issue-table td').last.text,
        contains('MISTI'),
      );
    },
  );

  test('print rich text keeps lists and formatting without active content', () {
    final value = meetingSummaryPrintRichText(
      '''<h2>Title</h2><ul><li><b>Item</b></li></ul>
<p onclick="alert(1)" style="text-align:center;background-image:url(https://bad)">Text</p>
<script>alert(1)</script><svg onload="alert(1)"></svg><img src="https://bad">
<a href="javascript:alert(1)">Link</a>''',
    );
    expect(value, contains('<ul><li><b>Item</b></li></ul>'));
    expect(value, contains('text-align:center'));
    for (final unsafe in [
      'onclick',
      'alert',
      '<svg',
      '<img',
      '<script',
      'href=',
      'https://bad',
    ]) {
      expect(value, isNot(contains(unsafe)));
    }
    expect(meetingSummaryPrintRichText('A & B\nC'), 'A &amp; B<br>C');
    expect(
      meetingSummaryPrintRichText('&lt;p&gt;&lt;b&gt;Bold&lt;/b&gt;&lt;/p&gt;'),
      '<p><b>Bold</b></p>',
    );
  });

  for (final module in [
    AppModuleType.privateSector,
    AppModuleType.lineMinistry,
    AppModuleType.cdcSecretariat,
  ]) {
    testWidgets(
      '$module prints loaded summary once and recovers from native error',
      (tester) async {
        final platform = PrintPreviewWebViewPlatform();
        WebViewPlatform.instance = platform;
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = AppSettingsController()
          ..setModuleType(module)
          ..setLanguage(AppLanguage.english);
        addTearDown(settings.dispose);
        final calls = <MethodCall>[];
        final completion = Completer<void>();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MeetingSummaryPrinter.channel, (
              call,
            ) async {
              calls.add(call);
              await completion.future;
              throw PlatformException(code: 'print_failed');
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(MeetingSummaryPrinter.channel, null),
        );
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: MeetingSummaryDetailScreen(summary: fixture()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = find.byKey(const ValueKey('meeting-summary-print'));
        await tester.tap(button);
        await tester.runAsync(() async {
          for (var i = 0; i < 100 && platform.loadedHtml == null; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            await tester.pump();
          }
        });
        await tester.pumpAndSettle();
        expect(find.text('Print preview'), findsOneWidget);
        expect(find.text('A4'), findsOneWidget);
        expect(find.text('Portrait'), findsOneWidget);
        expect(calls, isEmpty);
        expect(platform.loadedHtml, contains(fixture().issues.first.title));
        final printButton = find.byKey(
          const ValueKey('meeting-summary-confirm-print'),
        );
        await tester.tap(printButton);
        await tester.pump();
        expect(calls, hasLength(1));
        expect(calls.single.method, 'printHtml');
        expect(calls.single.arguments['name'], 'Meeting-Summary-14');
        expect(
          calls.single.arguments['html'],
          contains(fixture().issues.first.title),
        );
        expect(tester.widget<FilledButton>(printButton).onPressed, isNull);
        completion.complete();
        await tester.pumpAndSettle();
        expect(
          find.text('Could not open print preview. Please try again.'),
          findsOneWidget,
        );
        expect(tester.widget<FilledButton>(printButton).onPressed, isNotNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(tester.widget<IconButton>(button).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
