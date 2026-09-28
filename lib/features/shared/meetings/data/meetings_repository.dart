import '../../../../core/network/api_client.dart';
import 'calendar_meeting.dart';

class MeetingsRepository {
  MeetingsRepository(this._api);
  final ApiClient _api;
  Future<List<CalendarMeeting>> getMeetings() async {
    final data = await _api.get('meetings');
    try {
      return List.unmodifiable(
        (data['items'] as List).map(
          (item) => CalendarMeeting.fromJson(item as Map<String, dynamic>),
        ),
      );
    } on FormatException {
      throw const ApiException('Invalid meeting data.');
    } on TypeError {
      throw const ApiException('Invalid meeting data.');
    }
  }
}
