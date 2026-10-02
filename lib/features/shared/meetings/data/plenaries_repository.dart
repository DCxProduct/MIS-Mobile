import '../../../../core/network/api_client.dart';
import 'plenary.dart';

class PlenariesRepository {
  PlenariesRepository(this._api);

  final ApiClient _api;

  Future<List<Plenary>> getPlenaries({
    Map<String, String> filters = const {},
  }) async {
    final items = await _api.getAllPages(
      'plenaries',
      query: filters,
      objectItems: true,
    );
    try {
      return List.unmodifiable(
        items.map((item) {
          if (item is! Map<String, dynamic>) throw const FormatException();
          return Plenary(item);
        }),
      );
    } on FormatException {
      throw const ApiException('The server returned invalid plenaries.');
    } on TypeError {
      throw const ApiException('The server returned invalid plenaries.');
    }
  }
}
