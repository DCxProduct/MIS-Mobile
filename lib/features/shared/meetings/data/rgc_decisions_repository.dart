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
    int? stakeholderId,
    int page = 1,
    int limit = 20,
    Map<String, String> filters = const {},
  }) async {
    if ((stakeholderId != null && stakeholderId <= 0) ||
        page <= 0 ||
        limit <= 0) {
      throw ArgumentError(
        'Ministry, when supplied, page, and limit must be positive.',
      );
    }
    final data = await _api.get(
      'rgc-decisions',
      query: {
        if (stakeholderId != null) 'stakeholderId': '$stakeholderId',
        ...filters,
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

  Future<RgcDecisionDetail> getDecision(
    int id, {
    bool includePlenaryDetails = false,
  }) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    final data = await _api.get('rgc-decisions/$id');
    try {
      final detail = RgcDecisionDetail.fromJson(data);
      if (detail.decision.id != id) throw const FormatException();
      if (detail.deadline != null &&
          (!includePlenaryDetails ||
              (detail.decision.plenaryStatus.isNotEmpty &&
                  detail.decision.plenaryMeetingDate != null))) {
        return detail;
      }
      return RgcDecisionDetail.fromJson(await _withPlenary(data, {}));
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

  Future<List<RgcDecision>> getDecisions({
    Map<String, String> filters = const {},
    bool cdcGpsf = false,
    bool includePlenaryDetails = false,
  }) async {
    final items = await _api.getAllPages(
      cdcGpsf ? 'rgc-decisions/cdc-gpsf' : 'rgc-decisions',
      query: filters,
      objectItems: true,
    );
    try {
      final plenaries = <int, Future<Map<String, dynamic>>>{};
      return List.unmodifiable(
        await Future.wait(
          items.map((item) async {
            if (item is! Map<String, dynamic>) throw const FormatException();
            final decision = RgcDecision(item);
            if (includePlenaryDetails &&
                (decision.plenaryStatus.isEmpty ||
                    decision.plenaryMeetingDate == null)) {
              return RgcDecision(await _withPlenary(item, plenaries));
            }
            return decision;
          }),
        ),
      );
    } on FormatException {
      throw const ApiException('The server returned invalid RGC decisions.');
    }
  }

  Future<List<RgcDecisionDetail>> getDecisionsByPlenary(int plenaryId) async {
    if (plenaryId <= 0) {
      throw ArgumentError.value(plenaryId, 'plenaryId', 'Must be positive');
    }
    final items = await _api.getAllPages(
      'rgc-decisions',
      query: {'plenaryId': '$plenaryId'},
      objectItems: true,
    );
    try {
      return List.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) throw const FormatException();
          final detail = RgcDecisionDetail.fromJson(item);
          if (detail.decision.plenaryId != plenaryId) {
            throw const FormatException();
          }
          return detail;
        }),
      );
    } on FormatException {
      throw const ApiException(
        'The server returned invalid plenary approval reports.',
      );
    }
  }

  Future<Map<String, dynamic>> _withPlenary(
    Map<String, dynamic> data,
    Map<int, Future<Map<String, dynamic>>> plenaries,
  ) async {
    final decision = RgcDecision(data);
    if (decision.plenaryId <= 0) return data;
    try {
      // Share one request across ministries/decisions in this list load.
      // A fresh load fetches fresh metadata rather than keeping a stale cache.
      final plenary = await plenaries.putIfAbsent(
        decision.plenaryId,
        () => _api.get('plenaries/${decision.plenaryId}'),
      );
      if (plenary['id'] != decision.plenaryId) return data;
      final existing = data['plenary'];
      return {
        ...data,
        'plenary': {
          if (existing is Map<String, dynamic>) ...existing,
          ...plenary,
        },
      };
    } on ApiException {
      // The decision remains readable if its plenary is unavailable. Do not
      // substitute a decision status for the missing plenary status.
      return data;
    }
  }
}
