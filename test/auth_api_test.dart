import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gpsf_app/core/network/api_client.dart';
import 'package:gpsf_app/features/auth/data/auth_repository.dart';

void main() {
  test(
    'login posts credentials then fetches the verified current user',
    () async {
      final requests = <http.Request>[];
      final api = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user': {
                  'id': 1,
                  'email': 'user@example.com',
                  'name': 'User',
                  'isActive': true,
                },
              },
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final user = await AuthRepository(
        api,
      ).login('user@example.com', 'test-password');
      expect(user.email, 'user@example.com');
      expect(requests.map((r) => r.method), ['POST', 'GET']);
      expect(requests.map((r) => r.url.path), [
        '/api/v1/auth/login',
        '/api/v1/auth/me',
      ]);
      expect(jsonDecode(requests.first.body), {
        'email': 'user@example.com',
        'password': 'test-password',
      });
    },
  );

  test('rejects unauthorized, malformed and unsuccessful responses', () async {
    for (final response in [
      http.Response('', 401),
      http.Response('html', 200),
      http.Response('{"success":false,"data":{}}', 200),
    ]) {
      final api = ApiClient(client: MockClient((_) async => response));
      addTearDown(api.close);
      await expectLater(api.get('auth/me'), throwsA(isA<ApiException>()));
    }
  });

  test('preserves validation messages and request endpoint', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'message': ['Email is invalid', 'Password is required'],
          }),
          422,
        ),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.post('auth/login', body: {}),
      throwsA(
        isA<ApiException>()
            .having(
              (e) => e.message,
              'message',
              'Email is invalid\nPassword is required',
            )
            .having((e) => e.statusCode, 'status', 422)
            .having((e) => e.endpoint, 'endpoint', 'auth/login'),
      ),
    );
  });

  test('keeps HTTP status when a proxy returns HTML', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response('<html>Bad gateway</html>', 502),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.get('auth/me'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 502)
            .having((e) => e.message, 'message', contains('502')),
      ),
    );
  });

  test('distinguishes a rejected session from rejected credentials', () async {
    final api = ApiClient(
      client: MockClient(
        (request) async => request.url.path.endsWith('/login')
            ? http.Response('{"success":true,"data":{}}', 200)
            : http.Response('{"success":false,"message":"Unauthorized"}', 401),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      AuthRepository(api).login('user@example.com', 'test'),
      throwsA(
        isA<ApiException>().having((e) => e.endpoint, 'endpoint', 'auth/me'),
      ),
    );
  });

  test('native cookie is reused and cleared on local logout', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final received = <String?>[];
    server.listen((request) async {
      received.add(request.headers.value('cookie'));
      if (request.uri.path.endsWith('/login')) {
        request.response.headers.add(
          'set-cookie',
          'accessToken=test-token; Path=/; HttpOnly; Max-Age=3600',
        );
      }
      request.response.write('{"success":true,"data":{}}');
      await request.response.close();
    });
    final api = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}/api/v1');
    addTearDown(api.close);
    await api.post('auth/login', body: {});
    await api.get('auth/me');
    api.clearSession();
    await api.get('auth/me');
    expect(received, [null, 'accessToken=test-token', null]);
  });
}
