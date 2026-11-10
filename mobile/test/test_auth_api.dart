import 'package:dept_rental/app_user.dart';
import 'package:dept_rental/item_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';

import 'package:dept_rental/auth_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AuthApi testAuthApi() => AuthApi(
  baseUrl: 'http://example.test',
  client: MockClient((request) async {
    if (request.url.path == '/api/auth/login') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final admin = body['studentNumber'] == '20269999';
      if ((!admin && body['studentNumber'] != '20260001') ||
          body['password'] != 'password123') {
        return http.Response(
          '{"detail":"학번과 비밀번호를 확인해 주세요."}',
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(
        jsonEncode({
          'userId': admin ? 99 : 1,
          'loginId': admin ? '20269999' : '20260001',
          'studentNumber': admin ? '20269999' : '20260001',
          'displayName': admin ? '테스트 관리자' : '테스트 학생',
          'accessToken': 'test-token',
          'isAdmin': admin,
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (request.url.path == '/api/auth/logout') return http.Response('', 204);
    if (request.url.path == '/api/auth/signup') return http.Response('', 201);
    return http.Response('{"detail":"not found"}', 404);
  }),
);

const testStudent = AppUser(
  userId: 1,
  studentNumber: '20260001',
  id: '20260001',
  name: '테스트 학생',
  role: UserRole.student,
);
const testAdmin = AppUser(
  userId: 99,
  studentNumber: '20269999',
  id: '20269999',
  name: '테스트 관리자',
  role: UserRole.admin,
);
Future<void> loginTestStudent(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('login-id')), '20260001');
  await tester.enterText(
    find.byKey(const Key('login-password')),
    'password123',
  );
  await tester.ensureVisible(find.text('로그인'));
  await tester.tap(find.text('로그인'));
  await tester.pumpAndSettle();
}

void seedTestRequests(ItemStore store) {
  if (store.requests.isNotEmpty) return;
  for (final (index, item) in store.items.take(2).indexed) {
    store.requests.add(
      DemoRequest(
        item: item,
        student: '테스트 학생 ${index + 1}',
        studentId: 'fixture:${index + 1}',
        studentNumber: '2026000${index + 1}',
        due: DateTime.now().add(const Duration(days: 3)),
      ),
    );
  }
}
