import 'dart:async';
import 'dart:convert';

import 'package:dept_rental/admin_screen.dart';
import 'package:dept_rental/auth_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_auth_api.dart';
import 'test_items.dart';

http.Response response(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object> pending(int id) => {
  'id': id,
  'displayName': '학생 $id',
  'studentNumber': '2026000$id',
  'status': 'PENDING',
};

Finder summaryText(String text) => find.descendant(
  of: find.byKey(const Key('admin-recovery-summary')),
  matching: find.text(text),
);

Future<void> revealSummary(WidgetTester tester) async {
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('admin-recovery-summary')),
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('홈에서 서버 대기 건수를 조회하고 거절 후 복귀하면 갱신한다', (tester) async {
    final rows = [pending(1), pending(2)];
    final api = AuthApi(
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer admin-token');
        if (request.method == 'GET') return response(rows);
        expect(request.url.path, '/api/admin/password-reset-requests/1/reject');
        rows.removeAt(0);
        return http.Response('', 200);
      }),
    );
    final store = testItemStore();
    addTearDown(api.close);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminScreen(
          store: store,
          user: testAdmin,
          authApi: api,
          accessToken: 'admin-token',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await revealSummary(tester);
    expect(summaryText('2건'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('admin-recovery-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-recovery-summary')));
    await tester.pumpAndSettle();
    expect(find.text('학생 1 · 20260001'), findsOneWidget);
    await tester.tap(find.text('거절').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('거절')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await revealSummary(tester);
    expect(summaryText('1건'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('초기화 요청 조회 실패를 0건으로 표시하지 않고 재조회한다', (tester) async {
    var fail = true;
    final api = AuthApi(
      client: MockClient(
        (_) async => fail ? response({'detail': '조회 실패'}, 500) : response([]),
      ),
    );
    final store = testItemStore();
    addTearDown(api.close);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminScreen(
          store: store,
          user: testAdmin,
          authApi: api,
          accessToken: 'admin-token',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await revealSummary(tester);
    expect(summaryText('0건'), findsNothing);
    await revealSummary(tester);
    expect(summaryText('—'), findsOneWidget);
    fail = false;
    await tester.ensureVisible(find.text('다시 조회'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 조회'));
    await tester.pumpAndSettle();
    await revealSummary(tester);
    expect(summaryText('0건'), findsOneWidget);
    expect(find.text('다시 조회'), findsNothing);
  });

  testWidgets('조회 중에는 요청이 없다고 단정하지 않는다', (tester) async {
    final request = Completer<http.Response>();
    final api = AuthApi(client: MockClient((_) => request.future));
    final store = testItemStore();
    addTearDown(api.close);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminScreen(
          store: store,
          user: testAdmin,
          authApi: api,
          accessToken: 'admin-token',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await revealSummary(tester);
    expect(summaryText('조회 중…'), findsOneWidget);
    await revealSummary(tester);
    expect(summaryText('0건'), findsNothing);
    request.complete(response([]));
    await tester.pumpAndSettle();
    await revealSummary(tester);
    expect(summaryText('0건'), findsOneWidget);
  });

  testWidgets('이전 세션의 늦은 조회 결과가 새 세션의 건수를 덮어쓰지 않는다', (tester) async {
    final oldRequest = Completer<http.Response>();
    final api = AuthApi(
      client: MockClient(
        (request) => request.headers['Authorization'] == 'Bearer old-token'
            ? oldRequest.future
            : Future.value(response([pending(1), pending(2), pending(3)])),
      ),
    );
    final store = testItemStore();
    addTearDown(api.close);
    addTearDown(store.dispose);
    Widget app(String token) => MaterialApp(
      home: AdminScreen(
        store: store,
        user: testAdmin,
        authApi: api,
        accessToken: token,
      ),
    );
    await tester.pumpWidget(app('old-token'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app('new-token'));
    await tester.pumpAndSettle();
    await revealSummary(tester);
    expect(summaryText('3건'), findsOneWidget);
    oldRequest.complete(response([pending(9)]));
    await tester.pumpAndSettle();
    await revealSummary(tester);
    expect(summaryText('3건'), findsOneWidget);
    await revealSummary(tester);
    expect(summaryText('1건'), findsNothing);
  });
}
