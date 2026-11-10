import 'package:dept_rental/auth_api.dart';
import 'package:dept_rental/admin_screen.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_items.dart';

void main() {
  testWidgets('고정 테스트 계정도 서버가 거절하면 로그인할 수 없다', (tester) async {
    var attempts = 0;
    final api = AuthApi(
      client: MockClient((request) async {
        attempts++;
        return http.Response(
          '{"detail":"인증 실패"}',
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final store = testItemStore();
    addTearDown(api.close);
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    expect(find.text('데모 체험'), findsNothing);
    for (final entry in {
      'student': 'student1234',
      'admin': 'admin1234',
    }.entries) {
      await tester.enterText(find.byKey(const Key('login-id')), entry.key);
      await tester.enterText(
        find.byKey(const Key('login-password')),
        entry.value,
      );
      await tester.ensureVisible(find.text('로그인'));
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsNothing);
      expect(find.text('인증 실패'), findsOneWidget);
    }
    expect(attempts, 2);
  });

  test('관리자 여부가 없거나 올바른 true가 아니면 학생으로 처리한다', () {
    final response = <String, dynamic>{
      'userId': 1,
      'loginId': 'student_a',
      'displayName': 'Student',
      'accessToken': 'local-test',
    };
    expect(AuthSession.fromJson(response).isAdmin, isFalse);
    expect(
      AuthSession.fromJson({...response, 'isAdmin': false}).isAdmin,
      isFalse,
    );
    expect(
      AuthSession.fromJson({...response, 'isAdmin': 'true'}).isAdmin,
      isFalse,
    );
    expect(
      AuthSession.fromJson({...response, 'isAdmin': true}).isAdmin,
      isTrue,
    );
  });

  testWidgets('서버 관리자 응답으로 학생 화면 없이 관리자 홈에 진입한다', (tester) async {
    final api = AuthApi(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/logout')) return http.Response('', 204);
        return http.Response(
          '{"userId":9,"loginId":"001","studentNumber":"001","displayName":"Server Admin","accessToken":"local-test","isAdmin":true}',
          200,
        );
      }),
    );
    addTearDown(api.close);
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await tester.enterText(find.byKey(const Key('login-id')), '001');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password123',
    );
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    expect(store.currentUserId, 'user:9');
    expect(store.currentUserName, 'Server Admin');
    expect(find.byType(AdminScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text('내 대여'), findsNothing);
    expect(find.text('CyciRental'), findsOneWidget);
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(store.currentUserId, '');
    expect(store.currentUserName, '');
    expect(tester.takeException(), isNull);
  });
}
