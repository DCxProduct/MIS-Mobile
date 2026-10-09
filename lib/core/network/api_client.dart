import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'session_client.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.endpoint});
  final String message;
  final int? statusCode;
  final String? endpoint;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? createSessionClient(),
      _baseUri = Uri.parse(
        '${(baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://admin-mis-stage.datacolabx.com/api/v1')).replaceFirst(RegExp(r'/+$'), '')}/',
      );

  http.Client _client;
  final Uri _baseUri;
  Uri get serverOrigin => Uri.parse(_baseUri.origin);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    Map<String, String> headers = const {},
    bool background = false,
  }) => _request(
    'GET',
    path,
    query: query,
    headers: headers,
    background: background,
  ).then((data) => data as Map<String, dynamic>);

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    bool background = false,
  }) => _request(
    'POST',
    path,
    body: body,
    background: background,
  ).then((data) => data as Map<String, dynamic>);

  Future<List<dynamic>> getList(String path) async =>
      await _request('GET', path, expectList: true) as List<dynamic>;

  /// List endpoints in this API expose totalPages in their pagination metadata.
  Future<List<dynamic>> getAllPages(
    String path, {
    Map<String, String> query = const {},
    bool objectItems = false,
    int limit = 100,
    Map<String, String> headers = const {},
  }) async {
    final items = <dynamic>[];
    var totalPages = 1;
    for (var page = 1; page <= totalPages; page++) {
      final params = {...query, 'page': '$page', 'limit': '$limit'};
      final response = objectItems
          ? await getObjectPage(path, query: params, headers: headers)
          : await getListPage(path, query: params, headers: headers);
      final data = response['data'];
      final rows = objectItems && data is Map ? data['items'] : data;
      if (rows is! List) {
        throw ApiException('Invalid paginated list.', endpoint: path);
      }
      items.addAll(rows);
      final meta = objectItems && data is Map
          ? data['meta'] ?? response['meta']
          : response['meta'];
      if (meta != null) {
        if (meta is! Map ||
            meta['totalPages'] is! int ||
            (meta['totalPages'] as int) < 0) {
          throw ApiException('Invalid pagination metadata.', endpoint: path);
        }
        if (page == 1) totalPages = meta['totalPages'] as int;
      }
    }
    return List.unmodifiable(items);
  }

  /// Retains top-level pagination metadata alongside an array of data.
  Future<Map<String, dynamic>> getListPage(
    String path, {
    Map<String, String>? query,
    Map<String, String> headers = const {},
    bool background = false,
  }) async =>
      await _request(
            'GET',
            path,
            query: query,
            headers: headers,
            expectList: true,
            preserveEnvelope: true,
            background: background,
          )
          as Map<String, dynamic>;

  Future<void> postAction(String path, {Map<String, dynamic>? body}) async {
    await _request('POST', path, body: body, expectData: false);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async => await _request('PATCH', path, body: body) as Map<String, dynamic>;

  Future<void> patchAction(String path, {Map<String, dynamic>? body}) async {
    await _request('PATCH', path, body: body, expectData: false);
  }

  Future<void> deleteAction(String path, {Map<String, dynamic>? body}) async {
    await _request('DELETE', path, body: body, expectData: false);
  }

  Future<Map<String, dynamic>> getObjectPage(
    String path, {
    Map<String, String>? query,
    Map<String, String> headers = const {},
  }) async =>
      await _request(
            'GET',
            path,
            query: query,
            headers: headers,
            preserveEnvelope: true,
          )
          as Map<String, dynamic>;

  Future<Uint8List> getBytes(String path, {Map<String, String>? query}) async =>
      await _request('GET', path, query: query, expectBytes: true) as Uint8List;

  Future<Object> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, String> headers = const {},
    Map<String, dynamic>? body,
    bool expectData = true,
    bool expectList = false,
    bool preserveEnvelope = false,
    bool expectBytes = false,
    bool background = false,
  }) async {
    if (path.startsWith('/') ||
        path.contains('..') ||
        Uri.parse(path).hasScheme) {
      throw ArgumentError.value(path, 'path', 'Use a relative API endpoint');
    }
    final request = http.Request(
      method,
      _baseUri.resolve(path).replace(queryParameters: query),
    );
    request.headers.addAll(headers);
    request.headers['Accept'] = expectBytes
        ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        : 'application/json';
    if (background) request.headers['x-background-poll'] = '1';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(const Duration(seconds: 30));
      if (!expectData &&
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.body.trim().isEmpty) {
        return {};
      }
      Map<String, dynamic>? decoded;
      try {
        final value = jsonDecode(utf8.decode(response.bodyBytes));
        if (value is Map<String, dynamic>) decoded = value;
      } on FormatException {
        // Error responses from a proxy may be HTML or empty.
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded?['success'] == false) {
        throw ApiException(
          _errorMessage(response.statusCode, decoded),
          statusCode: response.statusCode,
          endpoint: path,
        );
      }
      if (expectBytes) {
        if (decoded != null || response.bodyBytes.isEmpty) {
          throw const FormatException();
        }
        return response.bodyBytes;
      }
      if (decoded == null || decoded['success'] != true) {
        throw const FormatException();
      }
      if (!expectData) return {};
      final data = decoded['data'];
      if (expectList) {
        if (data is! List) throw const FormatException();
        return preserveEnvelope ? decoded : data;
      }
      if (data is! Map<String, dynamic>) throw const FormatException();
      return preserveEnvelope ? decoded : data;
    } on TimeoutException {
      throw const ApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const ApiException(
        'Unable to connect. Check your internet connection.',
      );
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    }
  }

  String _errorMessage(int status, Map<String, dynamic>? body) {
    // Only display the API's public message, never its error/stack payload.
    if (status < 500) {
      final message = body?['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      if (message is List) {
        final messages = message
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }
    }
    return switch (status) {
      401 => 'Please sign in again.',
      403 => 'Access denied. Your account cannot access this service.',
      404 => 'The requested service was not found (404).',
      429 => 'Too many attempts. Please wait before trying again.',
      >= 500 => 'The server is unavailable ($status). Please try again later.',
      _ => 'The request failed ($status). Please try again.',
    };
  }

  void clearSession() {
    _client.close();
    _client = createSessionClient();
  }

  void close() => _client.close();
}
