import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gpsf_app/app.dart';
import 'package:gpsf_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('shows splash then login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GpsfApp());

    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Get Start Now'), findsNothing);
  });
}
