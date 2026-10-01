import '../../../../core/network/api_client.dart';
import 'rgc_decision.dart';

class RgcDecisionsRepository {
  RgcDecisionsRepository(this._api);

  final ApiClient _api;

  Future<List<RgcMinistry>> getMinistries() async {
    final data = await _api.get('rgc-decisions/lookups/ministries');
    try {
      final items = data['items'];
      if (items is! List) throw const FormatException();
      return List.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) throw const FormatException();
          return RgcMinistry.fromJson(item);
        }),
      );
    } on FormatException {
      throw const ApiException('The server returned invalid ministries.');
    }
  }

  Future<RgcDecisionPage> getDecisionsPage({
    required int stakeholderId,
    int page = 1,
    int limit = 20,
  }) async {
    if (stakeholderId <= 0 || page <= 0 || limit <= 0) {
      throw ArgumentError('Ministry, page, and limit must be positive.');
    }
    final data = await _api.get(
      'rgc-decisions',
      query: {
        'stakeholderId': '$stakeholderId',
        'page': '$page',
        'limit': '$limit',
      },
    );
    try {
      return RgcDecisionPage.fromJson(data);
    } on FormatException {
      throw const ApiException('The server returned invalid RGC decisions.');
    }
  }

  Future<RgcDecisionDetail> getDecision(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    final data = await _api.get('rgc-decisions/$id');
    try {
      final detail = RgcDecisionDetail.fromJson(data);
      if (detail.deadline != null) return detail;

      final plenary = data['plenary'];
      final plenaryId =
          data['plenaryId'] ??
          (plenary is Map<String, dynamic> ? plenary['id'] : null);
      if (plenaryId is! int || plenaryId <= 0) return detail;

      try {
        final plenaryData = await _api.get('plenaries/$plenaryId');
        final deadline = plenaryData['deadline'];
        return RgcDecisionDetail.fromJson(
          data,
          plenaryDeadline: deadline is String
              ? DateTime.tryParse(deadline)
              : null,
        );
      } on ApiException {
        // Keep the decision readable when its plenary is unavailable.
        return detail;
      }
    } on FormatException {
      throw const ApiException(
        'The server returned invalid RGC decision details.',
      );
    }
  }

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
