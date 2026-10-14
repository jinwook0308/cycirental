import 'dart:convert';

import 'package:dept_rental/admin_screen.dart';
import 'package:dept_rental/demo_auth.dart';
import 'package:dept_rental/item_api.dart';
import 'package:dept_rental/item_model.dart';
import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_items.dart';

void main() {
  test('데모 계정은 올바른 비밀번호에만 권한을 부여한다', () {
    expect(demoSignIn('student', 'student1234')?.isAdmin, isFalse);
    expect(demoSignIn('admin', 'admin1234')?.isAdmin, isTrue);
    expect(demoSignIn('admin', 'wrong'), isNull);
    expect(demoSignIn('someone', 'admin1234'), isNull);
    expect(demoSignIn('', ''), isNull);
  });

  test('승인·거절·반납과 물품 수정이 재고를 일관되게 유지한다', () {
    final store = testItemStore();
    addTearDown(store.dispose);
    store.prepareAdminDemo();
    store.prepareAdminDemo();
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
    store.currentUserId = 'demo_student';
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
    await tester.pumpWidget(DeptRentalApp(store: store));
    await tester.enterText(find.byKey(const Key('login-id')), 'student');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'student1234',
    );
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('관리자'), findsNothing);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminScreen(store: store, user: AppUser.student),
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
    await tester.pumpWidget(DeptRentalApp(store: store));
    await tester.enterText(find.byKey(const Key('login-id')), 'admin');
    await tester.enterText(find.byKey(const Key('login-password')), 'wrong');
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    expect(find.text('아이디와 비밀번호를 확인해 주세요.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'admin1234',
    );
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('프로필 보기'));
    await tester.pumpAndSettle();
    expect(find.text('데모 관리자'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    store.prepareAdminDemo();
    await tester.tap(find.text('관리자'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대여 승인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('승인').first);
    await tester.pumpAndSettle();
    expect(find.text('승인 완료'), findsOneWidget);
    final approvedRental = store.allActiveRentals.first;
    store.currentUserId = approvedRental.studentId;
    store.requestReturn(approvedRental);
    store.currentUserId = 'demo_admin';
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
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그인 · 데모 체험'));
    await tester.tap(find.text('로그인 · 데모 체험'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('관리자'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
