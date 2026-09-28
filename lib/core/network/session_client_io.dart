import 'dart:io';
import 'package:http/http.dart' as http;

http.Client createSessionClient() => _SessionClient();

class _SessionClient extends http.BaseClient {
  final _inner = http.Client();
  final _cookies = <String, Cookie>{};
  Uri? _origin;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _origin ??= request.url;
    if (request.url.origin != _origin!.origin) {
      throw http.ClientException('Unexpected API origin');
    }
    _cookies.removeWhere(
      (_, cookie) => cookie.expires?.isBefore(DateTime.now().toUtc()) ?? false,
    );
    if (_cookies.isNotEmpty) {
      request.headers['Cookie'] = _cookies.values
          .map((cookie) => '${cookie.name}=${cookie.value}')
          .join('; ');
    }
    request.followRedirects = false;
    final response = await _inner.send(request);
    final header = response.headers['set-cookie'];
    if (header != null) {
      for (final value in header.split(RegExp(r',(?=\s*[^\s;,=]+=)'))) {
        final cookie = Cookie.fromSetCookieValue(value.trim());
        // The documented API authenticates with this cookie only.
        if (cookie.name != 'accessToken') continue;
        if (cookie.maxAge != null) {
          cookie.expires = DateTime.now().toUtc().add(
            Duration(seconds: cookie.maxAge!),
          );
        }
        _cookies[cookie.name] = cookie;
      }
    }
    return response;
  }

  @override
  void close() {
    _cookies.clear();
    _inner.close();
  }
}
