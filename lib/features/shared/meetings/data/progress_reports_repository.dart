import '../../../../core/network/api_client.dart';
import 'progress_report.dart';

class ProgressReportsRepository {
  ProgressReportsRepository(this._api);
  final ApiClient _api;

  Future<List<ProgressReport>> getReports({
    Map<String, String> filters = const {},
  }) async {
    final data = await _api.getAllPages('progress-reports', query: filters);
    try {
      return List.unmodifiable(
        data.map((item) => ProgressReport(item as Map<String, dynamic>)),
      );
    } on FormatException {
      throw const ApiException('The server returned invalid progress reports.');
    } on TypeError {
      throw const ApiException('The server returned invalid progress reports.');
    }
  }
}
