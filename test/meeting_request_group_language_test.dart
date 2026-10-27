import 'package:flutter_test/flutter_test.dart';
import 'package:gpsf_app/features/shared/meetings/data/meeting_request.dart';
import 'package:gpsf_app/translations/app_language.dart';

void main() {
  test('API Khmer names switch language without changing filter values', () {
    final request = MeetingRequest({
      'user': {
        'stakeholders': [
          {
            'stakeholder': {
              'id': 14,
              'name': 'Agriculture & Agro-Industry',
              'khName': 'ក្រុមការងារ ក៖ ផ្នែកកសិកម្ម កសិ-ឧស្សាហកម្ម',
            },
          },
          {
            'stakeholder': {'id': 15, 'name': 'Tourism', 'khName': null},
          },
        ],
      },
    });
    expect(
      request.displayGroup(AppLanguage.khmer),
      'ក្រុមការងារ ក៖ ផ្នែកកសិកម្ម កសិ-ឧស្សាហកម្ម, Tourism',
    );
    expect(
      request.displayGroup(AppLanguage.english),
      'Agriculture & Agro-Industry, Tourism',
    );
    expect(request.filterValues['local.workingGroup'], [
      'Agriculture & Agro-Industry',
      'Tourism',
    ]);
    expect(MeetingRequest({}).displayGroup(AppLanguage.khmer), isEmpty);
  });
}
