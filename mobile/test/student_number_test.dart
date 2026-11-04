import 'dart:convert';

import 'package:dept_rental/account_screens.dart';
import 'package:dept_rental/auth_api.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('가입 요청은 이메일 없이 숫자 학번을 문자열로 전송한다', () async {
    Map<String, dynamic>? sent;
    final api = AuthApi(
      client: MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 201);
      }),
    );
    addTearDown(api.close);
    await api.signUp(
      password: 'password123',
      displayName: 'Tester',
      studentNumber: '00012345',
      phoneNumber: '01012345678',
    );
    expect(sent!['studentNumber'], '00012345');
    expect(sent!['phoneNumber'], '01012345678');
    expect(sent!.containsKey('email'), isFalse);
    expect(sent!.containsKey('loginId'), isFalse);
  });

  test('로그인은 학번과 비밀번호만 보내고 관리자 응답을 유지한다', () async {
    final api = AuthApi(
      baseUrl: 'http://example.test/',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://example.test/api/auth/login');
        expect(jsonDecode(request.body), {
          'studentNumber': '001',
          'password': 'server-password',
        });
        return http.Response(
          jsonEncode({
            'userId': 1,
            'loginId': '001',
            'studentNumber': '001',
            'displayName': '관리자',
            'accessToken': 'test-token',
            'isAdmin': true,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    final session = await api.login('001', 'server-password');
    expect(session.isAdmin, isTrue);
    expect(session.studentNumber, '001');
  });

  testWidgets('로그인 화면은 학번·비밀번호 입력과 다음/완료 키를 제공한다', (tester) async {
    final api = AuthApi(
      client: MockClient((_) async => http.Response('', 401)),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authApi: api, onEnter: (_, _) {}),
      ),
    );
    final studentField = tester.widget<TextField>(
      find.byKey(const Key('login-id')),
    );
    final passwordField = tester.widget<TextField>(
      find.byKey(const Key('login-password')),
    );
    expect(studentField.decoration!.hintText, '학번');
    expect(studentField.keyboardType, TextInputType.number);
    expect(studentField.textInputAction, TextInputAction.next);
    expect(passwordField.obscureText, isTrue);
    expect(passwordField.textInputAction, TextInputAction.done);
    expect(find.text('로그인 · 데모 체험'), findsNothing);
  });

  testWidgets('가입 화면은 이메일을 표시하지 않고 숫자 학번의 앞자리 0을 유지한다', (tester) async {
    final api = AuthApi(
      client: MockClient((_) async => http.Response('', 201)),
    );
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(home: SignupScreen(authApi: api)));
    final field = find.byKey(const Key('signup-student-number'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '00AB123456');
    expect(tester.widget<TextFormField>(field).controller!.text, '00123456');
    expect(find.text('이메일'), findsNothing);
    expect(find.byKey(const Key('signup-login-id')), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(5));
    expect(
      tester
          .widgetList<TextField>(
            find.descendant(
              of: find.byType(TextFormField),
              matching: find.byType(TextField),
            ),
          )
          .map((field) => field.decoration?.labelText),
      ['이름', '학번', '비밀번호', '비밀번호 확인', '전화번호'],
    );
    final phoneField = find.byKey(const Key('signup-phone'));
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '010-1234-5678');
    final phone = tester.widget<TextFormField>(phoneField);
    expect(phone.controller!.text, '01012345678');
    expect(phone.validator!(''), isNotNull);
    expect(phone.validator!('12345'), isNotNull);
    expect(phone.validator!('01012345678'), isNull);
    expect(tester.takeException(), isNull);
  });
}
