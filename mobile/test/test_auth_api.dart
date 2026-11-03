import 'dart:convert';

import 'package:dept_rental/auth_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AuthApi testAuthApi() => AuthApi(
  baseUrl: 'http://example.test',
  client: MockClient((request) async {
    if (request.url.path == '/api/auth/login') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['loginId'] != 'new_student' ||
          body['password'] != 'password123') {
        return http.Response(
          '{"detail":"아이디와 비밀번호를 확인해 주세요."}',
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(
        '{"userId":1,"loginId":"new_student","displayName":"데모 학생","accessToken":"test-token","tokenType":"Bearer"}',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path == '/api/auth/logout') return http.Response('', 204);
    if (request.url.path == '/api/auth/signup') return http.Response('', 201);
    return http.Response('{"detail":"not found"}', 404);
  }),
);
