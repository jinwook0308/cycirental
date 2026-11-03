import 'dart:convert';

import 'package:dept_rental/account_screens.dart';
import 'package:dept_rental/auth_api.dart';
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
