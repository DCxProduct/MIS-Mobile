import '../../../../core/network/api_client.dart';
import 'plenary.dart';

class PlenariesRepository {
  PlenariesRepository(this._api);

  final ApiClient _api;

  Future<Plenary> getPlenary(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    final data = await _api.get('plenaries/$id');
    try {
      final plenary = Plenary(data);
      if (plenary.id != id) throw const FormatException();
      return plenary;
    } on FormatException {
      throw const ApiException('The server returned invalid plenary details.');
    } on TypeError {
      throw const ApiException('The server returned invalid plenary details.');
    }
  }

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
