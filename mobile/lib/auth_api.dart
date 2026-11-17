import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'item_api.dart';
import 'rental_response.dart';

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

  Future<List<RentalResponse>> myRentals(String token) => _rentalRequest(
    token,
    '/api/rentals/me',
    expectedStatus: 200,
    decode: (json) => (json as List)
        .map((row) => RentalResponse.fromJson(row as Map<String, dynamic>))
        .toList(),
  );

  Future<RentalResponse> applyRental(String token, int itemId, DateTime due) =>
      _rentalRequest(
        token,
        '/api/rentals',
        expectedStatus: 201,
        body: {
          'itemId': itemId,
          'dueAt': DateTime(
            due.year,
            due.month,
            due.day,
          ).toIso8601String().split('T').first,
        },
        decode: (json) => RentalResponse.fromJson(json as Map<String, dynamic>),
      );

  Future<RentalResponse> cancelRental(String token, int id) => _rentalRequest(
    token,
    '/api/rentals/$id/cancel',
    expectedStatus: 200,
    body: const {},
    decode: (json) => RentalResponse.fromJson(json as Map<String, dynamic>),
  );

  Future<T> _rentalRequest<T>(
    String token,
    String path, {
    required int expectedStatus,
    required T Function(Object?) decode,
    Map<String, dynamic>? body,
  }) async {
    final http.Response response;
    try {
      if (body == null) {
        response = await _client
            .get(
              Uri.parse('$_baseUrl$path'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 10));
        _checkSession(response, token);
      } else {
        response = await _request(path, body, token: token);
      }
    } on TimeoutException {
      throw const AuthApiException('서버 응답이 늦습니다. 내 대여 내역을 확인해 주세요.');
    } on http.ClientException {
      throw const AuthApiException('서버에 연결할 수 없습니다. 연결을 확인해 주세요.');
    }
    if (response.statusCode != expectedStatus) {
      final detail = _responseDetail(response);
      throw AuthApiException(
        detail ??
            switch (response.statusCode) {
              401 => '다시 로그인해 주세요.',
              403 => '대여 요청을 처리할 권한이 없습니다.',
              404 => '물품 또는 대여 요청을 찾을 수 없습니다.',
              409 => '대여 상태나 재고가 바뀌었습니다. 목록을 확인해 주세요.',
              >= 500 => '서버에서 대여 요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.',
              _ => '대여 요청을 처리하지 못했습니다.',
            },
      );
    }
    try {
      return decode(jsonDecode(utf8.decode(response.bodyBytes)));
    } on FormatException {
      throw const AuthApiException('서버의 대여 응답 형식을 확인해 주세요.');
    } on TypeError {
      throw const AuthApiException('서버의 대여 응답에 필요한 정보가 없습니다.');
    }
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

  String? _responseDetail(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return null;
  }

  String _message(http.Response response) {
    final detail = _responseDetail(response);
    if (detail != null) return detail;
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
