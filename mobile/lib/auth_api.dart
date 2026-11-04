import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'item_api.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.loginId,
    required this.displayName,
    required this.accessToken,
    this.isAdmin = false,
    this.studentNumber,
    this.mustChangePassword = false,
  });

  final int userId;
  final String loginId;
  final String displayName;
  final String accessToken;
  final bool isAdmin;
  final String? studentNumber;
  final bool mustChangePassword;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    userId: json['userId'] as int,
    loginId: json['loginId'] as String,
    displayName: json['displayName'] as String,
    accessToken: json['accessToken'] as String,
    isAdmin: json['isAdmin'] == true,
    studentNumber: json['studentNumber'] as String?,
    mustChangePassword: json['mustChangePassword'] == true,
  );
}

class AuthApi {
  AuthApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(
        RegExp(r'/+$'),
        '',
      );

  final http.Client _client;
  final String _baseUrl;
  final _expiredSessions = StreamController<String>.broadcast();
  Stream<String> get expiredSessions => _expiredSessions.stream;

  void _checkSession(http.Response response, String? token) {
    if (response.statusCode == 401 &&
        token != null &&
        !_expiredSessions.isClosed) {
      _expiredSessions.add(token);
    }
  }

  Future<void> signUp({
    required String password,
    required String displayName,
    required String studentNumber,
    required String phoneNumber,
  }) => _send('/api/auth/signup', {
    'password': password,
    'displayName': displayName,
    'studentNumber': studentNumber,
    'phoneNumber': phoneNumber,
  }, expectedStatus: 201);

  Future<AuthSession> login(String studentNumber, String password) async {
    final response = await _request('/api/auth/login', {
      'studentNumber': studentNumber,
      'password': password,
    });
    if (response.statusCode != 200) throw AuthApiException(_message(response));
    try {
      return AuthSession.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map,
        ),
      );
    } on FormatException {
      throw const AuthApiException('로그인 응답 형식을 확인해 주세요.');
    } on TypeError {
      throw const AuthApiException('로그인 응답에 필요한 정보가 없습니다.');
    }
  }

  Future<void> requestPasswordReset(String displayName, String studentNumber) =>
      _send('/api/auth/password-reset/requests', {
        'displayName': displayName,
        'studentNumber': studentNumber,
      }, expectedStatus: 202);

  Future<AuthSession> changePassword(
    String token,
    String current,
    String next,
  ) async {
    final response = await _request('/api/auth/password/change', {
      'currentPassword': current,
      'newPassword': next,
    }, token: token);
    if (response.statusCode != 200) throw AuthApiException(_message(response));
    return AuthSession.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> recoveryRequests(String token) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/api/admin/password-reset-requests'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
    _checkSession(response, token);
    if (response.statusCode != 200) throw AuthApiException(_message(response));
    return (jsonDecode(utf8.decode(response.bodyBytes)) as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> processRecovery(
    String token,
    int id,
    bool approve,
  ) async {
    final response = await _request(
      '/api/admin/password-reset-requests/$id/${approve ? 'approve' : 'reject'}',
      {'identityConfirmed': approve},
      token: token,
    );
    if (response.statusCode != 200) throw AuthApiException(_message(response));
    if (!approve) return null;
    return Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map,
    );
  }

  Future<void> logout(String accessToken) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/auth/logout'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 204) throw AuthApiException(_message(response));
  }

  Future<void> _send(
    String path,
    Map<String, String> body, {
    required int expectedStatus,
  }) async {
    final response = await _request(path, body);
    if (response.statusCode != expectedStatus) {
      throw AuthApiException(_message(response));
    }
  }

  Future<http.Response> _request(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    _checkSession(response, token);
    return response;
  }

  String _message(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return switch (response.statusCode) {
      400 => '입력 형식을 확인해 주세요. 학번·비밀번호 조건을 확인해 주세요.',
      401 => '학번 또는 비밀번호를 확인해 주세요.',
      409 => '이미 사용 중인 학번입니다.',
      >= 500 => '서버 처리 중 오류가 발생했습니다. 잠시 후 다시 시도하거나 관리자에게 문의해 주세요.',
      _ => '요청을 처리하지 못했습니다. (HTTP ${response.statusCode})',
    };
  }

  void close() {
    _client.close();
    unawaited(_expiredSessions.close());
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
