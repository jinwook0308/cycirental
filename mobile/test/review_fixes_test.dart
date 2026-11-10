import 'dart:async';
import 'dart:convert';

import 'package:dept_rental/auth_api.dart';
import 'package:dept_rental/admin_screen.dart';
import 'package:dept_rental/item_api.dart';
import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Future<void> signIn(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('login-id')), '001');
  await tester.enterText(find.byKey(const Key('login-password')), 'admin');
  await tester.ensureVisible(find.text('로그인'));
  await tester.tap(find.text('로그인'));
  await tester.pumpAndSettle();
}

Map<String, Object> account(String token) => {
  'userId': 9,
  'loginId': '001',
  'studentNumber': '001',
  'displayName': '관리자',
  'accessToken': token,
  'isAdmin': true,
};
Future<void> openRecovery(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('admin-account-support')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byKey(const Key('admin-account-support')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('비밀번호 초기화 요청'));
}

void main() {
  test('재고 새로고침 후 음수 표시와 추가 승인을 방지한다', () async {
    var available = 2;
    final store = ItemStore(
      api: ItemApi(
        client: MockClient(
          (_) async => json([
            {
              'id': 1,
              'name': '노트북',
              'category': '전자기기',
              'description': '사무실',
              'totalQuantity': 2,
              'availableQuantity': available,
            },
          ]),
        ),
      ),
    );
    addTearDown(store.dispose);
    store.currentUserId = 'user:1';
    store.currentUserName = '학생';
    await store.loadItems();
    store.requestRental(
      store.items.single,
      DateTime.now().add(const Duration(days: 2)),
    );
    expect(store.approveRequest(store.requests.single), isTrue);
    expect(store.available(store.items.single), 1);
    available = 0;
    await store.loadItems();
    expect(store.available(store.items.single), 0);
    expect(
      store.requestRental(
        store.items.single,
        DateTime.now().add(const Duration(days: 2)),
      ),
      isFalse,
    );
    available = 2;
    await store.loadItems();
    expect(store.available(store.items.single), 1);
    expect(store.requestReturn(store.rentals.single), isTrue);
    expect(store.confirmReturn(store.rentals.single), isTrue);
    expect(store.available(store.items.single), 2);
  });
  testWidgets('401 응답 시 관리자 경로를 닫고 사용자 정보를 비운다', (tester) async {
    var recoveryQueries = 0;
    final api = AuthApi(
      client: MockClient((r) async {
        if (r.url.path.endsWith('/login')) return json(account('expired'));
        if (r.method == 'GET' && recoveryQueries++ == 0) return json([]);
        return json({'detail': 'Session expired'}, 401);
      }),
    );
    final store = ItemStore(initialItems: const []);
    addTearDown(api.close);
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await signIn(tester);
    await openRecovery(tester);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AppShell, skipOffstage: false), findsNothing);
    expect(store.currentUserId, isEmpty);
    expect(store.currentUserName, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('늦게 도착한 이전 토큰의 401은 새 로그인을 해제하지 않는다', (tester) async {
    final pending = Completer<http.Response>();
    var logins = 0;
    final api = AuthApi(
      client: MockClient((r) async {
        if (r.url.path.endsWith('/login')) {
          return json(account('token-${++logins}'));
        }
        if (r.url.path.endsWith('/logout')) return http.Response('', 204);
        if (r.headers['Authorization'] == 'Bearer token-2') {
          return json([]);
        }
        return pending.future;
      }),
    );
    final store = ItemStore(initialItems: const []);
    addTearDown(api.close);
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await signIn(tester);
    await openRecovery(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Return from the loading screen without waiting for its API response.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await signIn(tester);
    pending.complete(json({'detail': 'Old session expired'}, 401));
    await tester.pumpAndSettle();
    expect(find.byType(AdminScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(store.currentUserId, 'user:9');
    expect(tester.takeException(), isNull);
  });
  testWidgets('서버 로그아웃 응답이 늦어도 앱은 즉시 로그인 화면으로 돌아간다', (tester) async {
    final pending = Completer<http.Response>();
    final api = AuthApi(
      client: MockClient(
        (r) async => r.url.path.endsWith('/login')
            ? json(account('token'))
            : pending.future,
      ),
    );
    final store = ItemStore(initialItems: const []);
    addTearDown(api.close);
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await signIn(tester);
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(store.currentUserId, isEmpty);
    pending.complete(http.Response('', 204));
    await tester.pumpAndSettle();
  });
  test('비밀번호 변경과 승인 API의 401만 해당 토큰 만료 이벤트를 발생시킨다', () async {
    final api = AuthApi(
      client: MockClient((_) async => json({'detail': 'Unauthorized'}, 401)),
    );
    addTearDown(api.close);
    final expired = <String>[];
    final sub = api.expiredSessions.listen(expired.add);
    addTearDown(sub.cancel);
    await expectLater(
      api.login('001', 'wrong'),
      throwsA(isA<AuthApiException>()),
    );
    await expectLater(
      api.changePassword('limited', 'current123', 'newPassword123'),
      throwsA(isA<AuthApiException>()),
    );
    await expectLater(
      api.processRecovery('admin', 1, true),
      throwsA(isA<AuthApiException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(expired, ['limited', 'admin']);
  });
}
