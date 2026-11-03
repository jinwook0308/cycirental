import 'dart:convert';

import 'package:http/http.dart' as http;

import 'item_api.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.loginId,
    required this.displayName,
    required this.accessToken,
  });

  final int userId;
  final String loginId;
  final String displayName;
  final String accessToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    userId: json['userId'] as int,
    loginId: json['loginId'] as String,
    displayName: json['displayName'] as String,
    accessToken: json['accessToken'] as String,
  );
}

class AuthApi {
  AuthApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<void> signUp({
    required String loginId,
    required String password,
    required String displayName,
    required String email,
  }) => _send(
    '/api/auth/signup',
    {'loginId': loginId, 'password': password, 'displayName': displayName, 'email': email},
    expectedStatus: 201,
  );

  Future<AuthSession> login(String loginId, String password) async {
    final response = await _request('/api/auth/login', {
      'loginId': loginId,
      'password': password,
    });
    if (response.statusCode != 200) throw AuthApiException(_message(response));
    try {
      return AuthSession.fromJson(
        Map<String, dynamic>.from(jsonDecode(utf8.decode(response.bodyBytes)) as Map),
      );
    } on FormatException {
      throw const AuthApiException('로그인 응답 형식을 확인해 주세요.');
    } on TypeError {
      throw const AuthApiException('로그인 응답에 필요한 정보가 없습니다.');
    }
  }

  Future<String> findId(String displayName, String email) async {
    final response = await _request('/api/auth/find-id', {
      'displayName': displayName,
      'email': email,
    });
    if (response.statusCode != 200) throw AuthApiException(_message(response));
    try {
      return (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['loginId'] as String;
    } catch (_) {
      throw const AuthApiException('아이디 찾기 응답 형식을 확인해 주세요.');
    }
  }

  Future<void> requestPasswordReset(String loginId, String email) => _send(
    '/api/auth/password-reset/requests',
    {'loginId': loginId, 'email': email},
    expectedStatus: 202,
  );

  Future<void> logout(String accessToken) async {
    final response = await _client
        .post(Uri.parse('$_baseUrl/api/auth/logout'), headers: {'Authorization': 'Bearer $accessToken'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 204) throw AuthApiException(_message(response));
  }

  Future<void> _send(String path, Map<String, String> body, {required int expectedStatus}) async {
    final response = await _request(path, body);
    if (response.statusCode != expectedStatus) throw AuthApiException(_message(response));
  }

  Future<http.Response> _request(String path, Map<String, String> body) => _client
      .post(Uri.parse('$_baseUrl$path'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
      .timeout(const Duration(seconds: 10));

  String _message(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] is String) return decoded['detail'] as String;
    } catch (_) { }
    return '요청을 처리하지 못했습니다. (HTTP ${response.statusCode})';
  }

  void close() => _client.close();
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
