import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/features/shared/issues/data/working_group_issue.dart';
import 'package:gpsf_app/features/shared/issues/widgets/issue_agency_logo.dart';

void main() {
  test(
    'logo follows primary agency order rather than submitting stakeholder',
    () {
      final issue = WorkingGroupIssue.fromJson({
        'id': 12,
        'title': 'Issue',
        'stakeholder': {'name': 'Private Sector', 'logo': '/wrong-logo.jpg'},
        'governmentAgencies': [
          {
            'agencyOrder': 2,
            'stakeholder': {'name': 'MEF', 'logo': '/mef.jpg'},
          },
          {
            'agencyOrder': 1,
            'stakeholder': {
              'name': 'MAFF',
              'logo': '/uploads/stakeholders/1788369688560-MAFF.jpg',
            },
          },
        ],
      });
      expect(issue.agency, 'MAFF');
      expect(issue.agencyLogo, '/uploads/stakeholders/1788369688560-MAFF.jpg');
    },
  );

  testWidgets(
    'relative ministry logo uses the API host and handles image failure',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IssueAgencyLogo(
            path: '/uploads/stakeholders/1788369688560-MAFF.jpg',
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://admin-mis-stage.datacolabx.com/uploads/stakeholders/1788369688560-MAFF.jpg',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing logo retains the fallback icon', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IssueAgencyLogo(path: '')));
    expect(find.byIcon(Icons.account_balance), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
