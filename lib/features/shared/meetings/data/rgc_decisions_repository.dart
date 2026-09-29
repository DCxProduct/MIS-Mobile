import '../../../../core/network/api_client.dart';
import 'rgc_decision.dart';

class RgcDecisionsRepository {
  RgcDecisionsRepository(this._api);

  final ApiClient _api;

  Future<RgcDecisionScorecard> getScorecard() async {
    final data = await _api.get('rgc-decisions/scorecard');
    try {
      return RgcDecisionScorecard.fromJson(data);
    } on FormatException {
      throw const ApiException(
        'The server returned invalid RGC scorecard data.',
      );
    }
  }

  Future<List<RgcDecision>> getDecisions() async {
    final data = await _api.get('rgc-decisions');
    try {
      final items = data['items'];
      if (items is! List) throw const FormatException();
      return List.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) throw const FormatException();
          return RgcDecision(item);
        }),
      );
    } on FormatException {
      throw const ApiException('The server returned invalid RGC decisions.');
    }
  }
}
