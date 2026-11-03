import 'package:dept_rental/auth_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AuthApi testAuthApi() => AuthApi(
  baseUrl: 'http://example.test',
  client: MockClient((request) async {
    if (request.url.path == '/api/auth/login') {
      return http.Response('{"userId":1,"loginId":"new_student","displayName":"데모 학생","accessToken":"test-token","tokenType":"Bearer"}', 200);
    }
    if (request.url.path == '/api/auth/logout') return http.Response('', 204);
    if (request.url.path == '/api/auth/signup') return http.Response('', 201);
    return http.Response('{"detail":"not found"}', 404);
  }),
);
