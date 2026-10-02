import '../../../../core/network/api_client.dart';
import 'meeting_summary.dart';

class MeetingSummariesRepository {
  MeetingSummariesRepository(this._api);
  final ApiClient _api;

  Future<List<MeetingSummary>> getSummaries({
    Map<String, String> filters = const {},
  }) async {
    final items = await _api.getAllPages(
      'meeting-summaries',
      query: filters,
      objectItems: true,
    );
    try {
      return List.unmodifiable(
        items.map((item) => MeetingSummary(item as Map<String, dynamic>)),
      );
    } on FormatException {
      throw const ApiException(
        'The server returned invalid meeting summaries.',
      );
    } on TypeError {
      throw const ApiException(
        'The server returned invalid meeting summaries.',
      );
    }
  }

  Future<MeetingSummary> getSummary(int id) async {
    final data = await _api.get('meeting-summaries/$id');
    try {
      return MeetingSummary(data);
    } on FormatException {
      throw const ApiException(
        'The server returned invalid meeting summary details.',
      );
    } on TypeError {
      throw const ApiException(
        'The server returned invalid meeting summary details.',
      );
    }
  }
}
