import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/app_settings.dart';
import 'package:gpsf_app/core/config/module_config.dart';
import 'package:gpsf_app/core/text/html_text.dart';
import 'package:gpsf_app/core/widgets/editor_content.dart';
import 'package:gpsf_app/features/cdc_section/issues/detail_widgets.dart';
import 'package:gpsf_app/features/cdc_section/reports/rgc_decision_details.dart';
import 'package:gpsf_app/features/shared/meetings/data/rgc_decision.dart';
import 'package:gpsf_app/translations/app_language.dart';

const description =
    '<p><strong>ផ្នែកឯកជន Bold content</strong> &amp; details</p>'
    '<ul><li>First point</li><li>Second point</li></ul>';
const recommendation =
    '<p>Recommend <mark data-color="var(--tt-color-highlight-red)" '
    'style="background-color:var(--tt-color-highlight-red);color:inherit">'
    'ក្រសួង Highlight content</mark></p>';

void main() {
  test(
    'normalizes escaped editor markup while keeping plain text and paragraphs',
    () {
      expect(
        htmlToPlainText(
          '&lt;p&gt;&lt;strong&gt;A &amp;amp; B&lt;/strong&gt;&lt;/p&gt;',
        ),
        'A & B',
      );
      expect(htmlToPlainText('2 < 3 & 5 > 4'), '2 < 3 & 5 > 4');
      expect(htmlToPlainText('<p>First</p><p>Second</p>'), 'First\nSecond');
      expect(
        htmlToPlainText(
          '<p>Visible</p><script>secret()</script><style>body{}</style>',
        ),
        'Visible',
      );
    },
  );

  test(
    'RGC plain fields contain no markup and retain original editor content for display',
    () {
      final issue = RgcDecisionIssue.fromJson({
        'description': description,
        'recommendation': recommendation,
        'nextStep': '<p><em>Next step</em></p>',
        'decision': '<p>First decision</p><p>Second decision</p>',
      });
      expect(issue.description, contains('Bold content'));
      expect(issue.description, isNot(contains('<')));
      expect(issue.recommendations, isNot(contains('data-color')));
      expect(issue.nextStep, 'Next step');
      expect(issue.rgcDecision, 'First decision\nSecond decision');
      expect(issue.richText['issuesDescription'], description);
      expect(issue.richText['recommendations'], recommendation);
    },
  );

  for (final module in [
    AppModuleType.cdcSection,
    AppModuleType.cefp,
    AppModuleType.lineMinistry,
    AppModuleType.cdcSecretariat,
    AppModuleType.privateSector,
  ]) {
    testWidgets(
      '$module RGC detail renders editor formatting without HTML code',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = AppSettingsController()
          ..setModuleType(module)
          ..setLanguage(AppLanguage.english);
        addTearDown(settings.dispose);
        final detail = RgcDecisionDetail.fromJson({
          'id': 3,
          'decision': '<p><em>Decision content</em></p>',
          'issues': [
            {
              'description': description,
              'recommendation': recommendation,
              'attachment': '/uploads/reference.pdf',
              'category': {'name': 'General'},
              'issueStatus': {'name': 'In Progress'},
            },
          ],
        });
        await tester.pumpWidget(
          AppSettings(
            controller: settings,
            child: MaterialApp(
              home: CdcRgcDecisionIssueScreen(
                detail: detail,
                issue: detail.issues.single,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Bold content', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('Highlight content', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('First point', findRichText: true), findsOneWidget);
        final rendered = tester
            .widgetList<RichText>(find.byType(RichText))
            .map((widget) => widget.text.toPlainText())
            .join('\n');
        expect(rendered, isNot(contains('<p>')));
        expect(rendered, isNot(contains('<strong>')));
        expect(rendered, isNot(contains('data-color')));
        expect(rendered, isNot(contains('var(--')));
        final styles = <TextStyle>[];
        void visit(InlineSpan span) {
          if (span.style != null) styles.add(span.style!);
          if (span is TextSpan) {
            for (final child in span.children ?? const <InlineSpan>[]) {
              visit(child);
            }
          }
        }

        for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
          visit(text.text);
        }
        expect(
          styles.any((style) => style.fontWeight == FontWeight.bold),
          isTrue,
        );
        expect(
          styles.any(
            (style) =>
                (style.backgroundColor ?? style.background?.color)
                    ?.toARGB32() ==
                0xffffd6d6,
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('formatted read more expands and collapses on a mobile width', (
    tester,
  ) async {
    final settings = AppSettingsController()..setLanguage(AppLanguage.english);
    addTearDown(settings.dispose);
    final body = List.generate(
      15,
      (index) => '<p><strong>Paragraph $index</strong></p>',
    ).join();
    await tester.pumpWidget(
      AppSettings(
        controller: settings,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: CdcDetailTextPanel(
                  label: 'Description',
                  body: body,
                  collapsedLines: 3,
                  inlineLink: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final content = find.byType(EditorContent);
    final collapsedHeight = tester.getSize(content).height;
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(tester.getSize(content).height, greaterThan(collapsedHeight));
    await tester.ensureVisible(find.text('Show less'));
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(tester.getSize(content).height, collapsedHeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor links can be opened or copied from mobile content', (
    tester,
  ) async {
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      launcher,
      (_) async => false,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        launcher,
        null,
      ),
    );
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EditorContent(
            '<p><a href="https://example.com/reference">Open reference</a></p>',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tapAt(
        tester.getTopLeft(find.text('Open reference', findRichText: true)) +
            const Offset(30, 8),
      );
    });
    await tester.pumpAndSettle();
    // Widget tests have no browser handler; the fallback keeps the link usable.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('https://example.com/reference'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(copied, 'https://example.com/reference');
    expect(tester.takeException(), isNull);
  });
}
