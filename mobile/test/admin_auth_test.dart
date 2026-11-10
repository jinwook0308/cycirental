import 'dart:convert';

import 'package:dept_rental/admin_screen.dart';
import 'package:dept_rental/item_api.dart';
import 'package:dept_rental/item_model.dart';
import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_items.dart';
import 'test_auth_api.dart';

void main() {
  test('승인·거절·반납과 물품 수정이 재고를 일관되게 유지한다', () {
    final store = testItemStore();
    addTearDown(store.dispose);
    seedTestRequests(store);
    seedTestRequests(store);
    expect(store.requests.length, 2);
    final request = store.requests.first;
    final before = store.available(request.item);
    expect(store.approveRequest(request), isTrue);
    expect(store.approveRequest(request), isFalse);
    expect(store.available(request.item), before - 1);
    expect(store.activeRentals, isEmpty);
    final rental = store.allActiveRentals.first;
    store.currentUserId = rental.studentId;
    expect(store.requestReturn(rental), isTrue);
    store.confirmReturn(rental);
    store.confirmReturn(rental);
    store.currentUserId = 'user:1';
    expect(store.available(request.item), before);
    store.rejectRequest(store.requests.last, reason: '학과 운영 일정 변경');
    expect(store.approveRequest(store.requests.last), isFalse);
    final item = store.items.first;
    expect(
      store.saveItem(
        original: item,
        name: '수정 물품',
        category: item.category,
        location: item.location,
        total: item.total + 1,
        availableCount: before,
        kind: item.kind,
      ),
      isFalse,
    );
    expect(
      store.saveItem(
        original: item,
        name: '수정 물품',
        category: item.category,
        location: item.location,
        total: item.total + 1,
        availableCount: before + 1,
        kind: item.kind,
      ),
      isTrue,
    );
    expect(store.requests.first.item.name, '수정 물품');
    expect(store.rentals.first.item.name, '수정 물품');
    expect(store.available(store.items.first), before + 1);
    final expired = DemoRequest(
      item: store.items.first,
      student: '예시',
      studentId: 'test',
      due: DateTime.now(),
    );
    store.requests.add(expired);
    expect(store.approveRequest(expired), isFalse);
  });

  testWidgets('관리자 홈에서 신청을 승인하고 계정 관리에 접근한다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testItemStore();
    final api = testAuthApi();
    addTearDown(store.dispose);
    addTearDown(api.close);
    seedTestRequests(store);
    final pendingBefore = store.pendingRequests.length;
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await tester.enterText(find.byKey(const Key('login-id')), '20269999');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password123',
    );
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('✓ 승인').first);
    await tester.tap(find.text('✓ 승인').first);
    await tester.pumpAndSettle();
    expect(store.pendingRequests.length, pendingBefore - 1);
    expect(store.allActiveRentals.length, 1);
    await tester.ensureVisible(find.text('계정 관리'));
    await tester.tap(find.text('계정 관리'));
    await tester.pumpAndSettle();
    expect(find.text('비밀번호 초기화 요청'), findsOneWidget);
    expect(find.text('테스트 관리자'), findsOneWidget);
    expect(find.byType(AppShell, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('API 다시 조회해도 로컬 물품 수정과 등록이 유지된다', () async {
    final api = ItemApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': 1,
              'name': '모니터',
              'category': '전자기기',
              'description': '2210호',
              'totalQuantity': 2,
              'availableQuantity': 2,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final store = ItemStore(api: api);
    addTearDown(store.dispose);
    await store.loadItems();
    expect(store.requests, isEmpty);
    final item = store.items.first;
    expect(
      store.saveItem(
        original: item,
        name: '로컬 수정',
        category: item.category,
        location: item.location,
        total: 3,
        availableCount: 3,
        kind: item.kind,
      ),
      isTrue,
    );
    expect(
      store.saveItem(
        name: '새 물품',
        category: '전자기기',
        location: '사무실',
        total: 1,
        availableCount: 1,
        kind: ProductKind.laptop,
      ),
      isTrue,
    );
    await store.loadItems();
    expect(store.items.length, 2);
    expect(store.items.first.name, '로컬 수정');
    expect(store.available(store.items.first), 3);
    expect(store.items.last.id, lessThan(0));
  });

  testWidgets('학생은 관리자 메뉴와 관리자 화면에 접근할 수 없다', (tester) async {
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DeptRentalApp(store: store, authApi: testAuthApi()),
    );
    await tester.enterText(find.byKey(const Key('login-id')), '20260001');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password123',
    );
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('관리자'), findsNothing);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminScreen(store: store, user: testStudent),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('접근 제한'), findsOneWidget);
    expect(find.text('물품 등록'), findsNothing);
  });

  testWidgets('360픽셀에서 관리자 로그인·관리·로그아웃 후 학생 권한 복구', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DeptRentalApp(store: store, authApi: testAuthApi()),
    );
    await tester.enterText(find.byKey(const Key('login-id')), '20269999');
    await tester.enterText(find.byKey(const Key('login-password')), 'wrong');
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    expect(find.text('학번과 비밀번호를 확인해 주세요.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password123',
    );
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text('내 대여'), findsNothing);
    seedTestRequests(store);
    await tester.tap(find.text('대여 승인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('승인').first);
    await tester.pumpAndSettle();
    expect(find.text('승인 완료'), findsOneWidget);
    final approvedRental = store.allActiveRentals.first;
    store.currentUserId = approvedRental.studentId;
    store.requestReturn(approvedRental);
    store.currentUserId = 'user:99';
    await tester.tap(find.text('반납 관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('반납 확인'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('반납 완료'),
      ),
    );
    await tester.pumpAndSettle();
    expect(store.allActiveRentals, isEmpty);
    await tester.tap(find.text('물품 관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('4090본체 수정').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-item-name')),
      '관리자 수정 물품',
    );
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('관리자 수정 물품'), findsOneWidget);
    await tester.tap(find.text('물품 등록'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('admin-item-name')), '데모 노트북');
    await tester.enterText(
      find.widgetWithText(TextFormField, '보관 장소'),
      '학과 사무실',
    );
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(store.items.last.name, '데모 노트북');
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await loginTestStudent(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('관리자'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
