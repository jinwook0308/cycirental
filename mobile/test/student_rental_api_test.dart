import 'dart:async';
import 'dart:convert';

import 'package:dept_rental/auth_api.dart';
import 'package:dept_rental/item_model.dart';
import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_auth_api.dart';

const _item = RentalItem(
  id: 5,
  name: 'VR 기기',
  category: '전자기기',
  location: '3401호',
  total: 3,
  initialAvailable: 3,
  kind: ProductKind.vr,
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _rental(int id, String status) => {
  'id': id,
  'itemId': _item.id,
  'itemName': _item.name,
  'rentedAt': '2026-11-17',
  'dueAt': '2026-11-20',
  'returnedAt': null,
  'status': status,
};

void main() {
  testWidgets('학생이 앱에서 신청하고 서버 내역을 확인한 뒤 취소한다', (tester) async {
    Map<String, Object?>? saved;
    var applicationCount = 0;
    var cancellationCount = 0;
    var listCount = 0;
    final api = AuthApi(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return _json({
            'userId': 1,
            'loginId': '20260001',
            'studentNumber': '20260001',
            'displayName': '학생',
            'accessToken': 'student-token',
          });
        }
        expect(request.headers['authorization'], 'Bearer student-token');
        switch ((request.method, request.url.path)) {
          case ('GET', '/api/rentals/me'):
            listCount++;
            return _json([?saved]);
          case ('POST', '/api/rentals'):
            applicationCount++;
            final body = jsonDecode(request.body) as Map;
            expect(body['itemId'], _item.id);
            expect(body['dueAt'], matches(r'^\d{4}-\d{2}-\d{2}$'));
            saved = _rental(42, 'PENDING');
            return _json(saved!, 201);
          case ('POST', '/api/rentals/42/cancel'):
            cancellationCount++;
            saved = _rental(42, 'CANCELLED');
            return _json(saved!);
          default:
            fail('Unexpected request: ${request.method} ${request.url.path}');
        }
      }),
    );
    final store = ItemStore(initialItems: [_item], rentalApi: api);
    addTearDown(api.close);
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await loginTestStudent(tester);
    expect(listCount, greaterThanOrEqualTo(1));

    await tester.tap(find.text('물품'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_item.name));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '대여 신청'));
    await tester.pumpAndSettle();
    expect(applicationCount, 1);
    expect(find.text('승인 대기'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '신청 취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '신청 취소'));
    await tester.pumpAndSettle();
    expect(cancellationCount, 1);
    expect(find.text('취소됨'), findsOneWidget);
    expect(store.requests, isEmpty);
    expect(store.available(_item), 3);
  });

  test('서버가 신청을 거절하면 서버 안내를 전달하고 로컬 신청을 만들지 않는다', () async {
    final api = AuthApi(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        return request.method == 'GET'
            ? _json([])
            : _json({'detail': '지금은 대여 가능한 수량이 없습니다.'}, 409);
      }),
    );
    final store = ItemStore(initialItems: [_item], rentalApi: api);
    addTearDown(api.close);
    addTearDown(store.dispose);
    store.setRentalSession('student-token');

    await expectLater(
      store.submitRental(_item, DateTime.now().add(const Duration(days: 3))),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.message,
          'message',
          '지금은 대여 가능한 수량이 없습니다.',
        ),
      ),
    );
    expect(store.myRequests, isEmpty);
    expect(store.requests, isEmpty);
    expect(store.rentalActionPending, isFalse);
  });

  test('로그아웃 전에 시작한 조회는 새 학생의 신청 목록에 반영되지 않는다', () async {
    final lateList = Completer<http.Response>();
    final api = AuthApi(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        if (request.headers['authorization'] == 'Bearer first-token') {
          return lateList.future;
        }
        return _json([_rental(2, 'CANCELLED')]);
      }),
    );
    final store = ItemStore(initialItems: [_item], rentalApi: api);
    addTearDown(api.close);
    addTearDown(store.dispose);
    store.setRentalSession('first-token');
    store.setRentalSession(null);
    expect(store.myRequests, isEmpty);
    store.setRentalSession('second-token');
    await Future<void>.delayed(Duration.zero);
    expect(store.myRequests.single.serverId, 2);

    lateList.complete(_json([_rental(1, 'PENDING')]));
    await Future<void>.delayed(Duration.zero);
    expect(store.myRequests.single.serverId, 2);
    expect(store.myRequests.single.status, RequestStatus.cancelled);
  });
}
