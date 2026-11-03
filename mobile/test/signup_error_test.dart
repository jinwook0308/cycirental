import 'dart:async';

import 'package:dept_rental/auth_api.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_items.dart';

void main() {
  for (final entry in {
    400: '입력 형식',
    409: '이미 사용 중인',
    500: '서버 처리 중 오류',
  }.entries) {
    test('HTTP ${entry.key}는 이해할 수 있는 오류로 표시된다', () async {
      final api = AuthApi(
        client: MockClient((_) async => http.Response('', entry.key)),
      );
      addTearDown(api.close);
      await expectLater(
        api.signUp(
          password: 'password123',
          displayName: 'Tester',
          studentNumber: '20260002',
          phoneNumber: '01012345678',
        ),
        throwsA(
          isA<AuthApiException>().having(
            (error) => error.message,
            'message',
            contains(entry.value),
          ),
        ),
      );
    });
  }

  test('서버의 필드 검증 사유는 그대로 유지한다', () async {
    final api = AuthApi(
      client: MockClient(
        (_) async => http.Response(
          '{"detail":"학번은 숫자만 입력해 주세요."}',
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.signUp(
        password: 'password123',
        displayName: 'Tester',
        studentNumber: 'invalid',
        phoneNumber: '01012345678',
      ),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.message,
          'message',
          '학번은 숫자만 입력해 주세요.',
        ),
      ),
    );
  });

  testWidgets('로그인 처리 중 키보드 재제출도 차단한다', (tester) async {
    final pending = Completer<http.Response>();
    var calls = 0;
    final api = AuthApi(
      client: MockClient((_) {
        calls++;
        return pending.future;
      }),
    );
    addTearDown(api.close);
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await tester.enterText(find.byKey(const Key('login-id')), 'valid_user');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password123',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.byKey(const Key('login-password')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(calls, 1);
    pending.complete(http.Response('', 401));
    await tester.pumpAndSettle();
    expect(find.text('학번 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
  });
}
