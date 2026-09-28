import '../../../../core/network/api_client.dart';
import 'meeting_request.dart';

class MeetingRequestsRepository {
  MeetingRequestsRepository(this._api);
  final ApiClient _api;

  Future<List<MeetingRequest>> getRequests() async {
    final data = await _api.getList('meeting-requests');
    try {
      return List.unmodifiable(
        data.map((item) => MeetingRequest(item as Map<String, dynamic>)),
      );
    } on FormatException {
      throw const ApiException('The server returned invalid meeting requests.');
    } on TypeError {
      throw const ApiException('The server returned invalid meeting requests.');
    }
  }
}
