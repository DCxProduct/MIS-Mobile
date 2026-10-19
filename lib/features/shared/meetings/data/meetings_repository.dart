import '../../../../core/network/api_client.dart';
import 'calendar_meeting.dart';

class MeetingsRepository {
  MeetingsRepository(this._api);
  final ApiClient _api;

  Future<CalendarMeeting> getMeeting(int id) async {
    final data = await _api.get('meetings/$id');
    if (data['id'] != id) {
      throw const ApiException('Invalid meeting detail data.');
    }
    try {
      return CalendarMeeting.fromJson(data);
    } on FormatException {
      throw const ApiException('Invalid meeting detail data.');
    } on TypeError {
      throw const ApiException('Invalid meeting detail data.');
    }
  }

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
