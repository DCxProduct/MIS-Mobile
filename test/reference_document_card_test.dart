import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/core/widgets/pdf_icon.dart';
import 'package:gpsf_app/core/widgets/reference_document_card.dart';

void main() {
  testWidgets('empty reference shows the Web PDF placeholder without a link', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReferenceDocumentCard(path: '', emptyLabel: 'មិនមាន'),
        ),
      ),
    );
    expect(find.byType(PdfIcon), findsOneWidget);
    expect(find.text('មិនមាន'), findsOneWidget);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('PDF reference displays its API filename instead of its URL', (
    tester,
  ) async {
    const path = '/uploads/1788402959624-reference.pdf';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReferenceDocumentCard(
            path: path,
            name: 'Council decision.pdf',
            emptyLabel: 'None',
          ),
        ),
      ),
    );
    expect(find.byType(PdfIcon), findsOneWidget);
    expect(find.text('Council decision.pdf'), findsOneWidget);
    expect(find.text(path), findsNothing);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNotNull);
  });

  testWidgets(
    'Drive folder keeps the full target and can be copied if launch fails',
    (tester) async {
      const path = 'https://drive.google.com/drive/folders/abc?usp=drive_link';
      const launcher = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        launcher,
        (_) async => false,
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
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          launcher,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReferenceDocumentCard(path: path, emptyLabel: 'None'),
          ),
        ),
      );
      expect(find.text(path), findsNothing);
      expect(find.text('drive.google.com'), findsOneWidget);
      expect(find.byType(PdfIcon), findsNothing);
      await tester.runAsync(() => tester.tap(find.byType(InkWell)));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(path), findsOneWidget);
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();
      expect(copied, path);
      expect(tester.takeException(), isNull);
    },
  );
}
