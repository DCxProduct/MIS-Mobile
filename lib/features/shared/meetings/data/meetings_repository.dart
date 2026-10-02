import '../../../../core/network/api_client.dart';
import 'calendar_meeting.dart';

class MeetingsRepository {
  MeetingsRepository(this._api);
  final ApiClient _api;
  Future<List<CalendarMeeting>> getMeetings({
    Map<String, String> filters = const {},
  }) async {
    final items = await _api.getAllPages(
      'meetings',
      objectItems: true,
      query: filters,
    );
    try {
      return List.unmodifiable(
        items.map(
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
