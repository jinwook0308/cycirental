import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_items.dart';

Future<void> login(WidgetTester tester, String id, String password) async {
  await tester.enterText(find.byKey(const Key('login-id')), id);
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tester.ensureVisible(find.text('로그인'));
  await tester.tap(find.text('로그인'));
  await tester.pumpAndSettle();
}

Future<void> logout(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text('설정')),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('로그아웃'));
  await tester.tap(find.text('로그아웃'));
  await tester.pumpAndSettle();
}

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('반납 요청만으로 재고가 복구되지 않고 확인은 한 번만 가능하다', () {
    final store = testItemStore();
    addTearDown(store.dispose);
    final item = store.items.first;
    final before = store.available(item);
    store.requestRental(item, DateTime.now().add(const Duration(days: 3)));
    store.approveRequest(store.requests.first);
    final rental = store.activeRentals.first;
    expect(store.confirmReturn(rental), isFalse);
    store.currentUserId = 'other_student';
    expect(store.requestReturn(rental), isFalse);
    store.currentUserId = rental.studentId;
    expect(store.requestReturn(rental), isTrue);
    expect(store.requestReturn(rental), isFalse);
    expect(store.activeRentals.length, 1);
    expect(store.history, isEmpty);
    expect(store.available(item), before - 1);
    expect(store.confirmReturn(rental), isTrue);
    expect(store.confirmReturn(rental), isFalse);
    expect(store.history.length, 1);
    expect(store.available(item), before);
  });

  test('취소는 본인 대기 신청에만 가능하고 취소 후 다시 신청할 수 있다', () {
    final store = testItemStore();
    addTearDown(store.dispose);
    final item = store.items.first;
    final due = DateTime.now().add(const Duration(days: 3));
    final before = store.available(item);
    store.requestRental(item, due);
    final request = store.requests.first;
    store.currentUserId = 'other_student';
    expect(store.cancelRequest(request), isFalse);
    store.currentUserId = request.studentId;
    expect(store.cancelRequest(request), isTrue);
    expect(store.cancelRequest(request), isFalse);
    expect(store.approveRequest(request), isFalse);
    expect(store.pendingRequests, isEmpty);
    expect(store.myUnapprovedRequests.single.status, RequestStatus.cancelled);
    expect(store.available(item), before);
    expect(store.requestRental(item, due), isTrue);
    final approved = store.requests.first;
    store.approveRequest(approved);
    expect(store.cancelRequest(approved), isFalse);
  });

  test('거절 사유는 공백이나 300자 초과를 거부하고 신청자에게 보존된다', () {
    final store = testItemStore();
    addTearDown(store.dispose);
    store.requestRental(
      store.items.first,
      DateTime.now().add(const Duration(days: 3)),
    );
    final request = store.requests.first;
    expect(store.rejectRequest(request, reason: '   '), isFalse);
    expect(
      store.rejectRequest(request, reason: List.filled(301, '가').join()),
      isFalse,
    );
    expect(request.status, RequestStatus.pending);
    expect(store.rejectRequest(request, reason: '  학과 행사 사용 예정  '), isTrue);
    expect(store.myUnapprovedRequests.single.rejectionReason, '학과 행사 사용 예정');
    expect(store.cancelRequest(request), isFalse);
    expect(store.approveRequest(request), isFalse);
  });

  test('만료는 승인 대기를 제외하고 이미 승인된 대여는 보존한다', () {
    final source = testItemStore();
    final items = source.items.toList();
    source.dispose();
    var now = dateOnly(DateTime.now());
    final store = ItemStore(initialItems: items, now: () => now);
    addTearDown(store.dispose);
    store.requestRental(store.items.first, now.add(const Duration(days: 1)));
    final expired = store.requests.first;
    store.requestRental(store.items.last, now.add(const Duration(days: 2)));
    final approved = store.requests.first;
    store.approveRequest(approved);
    now = now.add(const Duration(days: 1));
    store.refreshExpiredRequests();
    expect(expired.status, RequestStatus.expired);
    expect(store.pendingRequests, isEmpty);
    expect(store.approveRequest(expired), isFalse);
    expect(store.cancelRequest(expired), isFalse);
    expect(store.rejectRequest(expired, reason: '늦음'), isFalse);
    expect(approved.status, RequestStatus.approved);
    expect(store.activeRentals.length, 1);
  });

  testWidgets('학생 반납 요청 → 관리자 실물 확인 → 완료·재고 복구', (tester) async {
    phone(tester);
    final store = testItemStore();
    addTearDown(store.dispose);
    final item = store.items.last;
    final before = store.available(item);
    store.requestRental(item, DateTime.now().add(const Duration(days: 3)));
    store.approveRequest(store.requests.first);
    await tester.pumpWidget(DeptRentalApp(store: store));
    await login(tester, 'student', 'student1234');
    await tester.tap(find.text('내 대여'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대여 중 (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('반납 요청'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.text('반납 요청'),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(find.text('반납 확인 대기'), findsOneWidget);
    expect(store.available(item), before - 1);
    expect(store.history, isEmpty);
    await logout(tester);
    await login(tester, 'admin', 'admin1234');
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('설정'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('관리자'));
    await tester.pumpAndSettle();
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
    expect(store.available(item), before);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await logout(tester);
    await login(tester, 'student', 'student1234');
    await tester.tap(find.text('내 대여'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대여 내역 (1)'));
    await tester.pumpAndSettle();
    expect(find.text('반납 완료'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('신청 취소와 필수 거절 사유 입력 후 학생 사유 확인', (tester) async {
    phone(tester);
    final store = testItemStore();
    addTearDown(store.dispose);
    final due = DateTime.now().add(const Duration(days: 3));
    store.requestRental(store.items.first, due);
    await tester.pumpWidget(DeptRentalApp(store: store));
    await login(tester, 'student', 'student1234');
    await tester.tap(find.text('내 대여'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('신청 취소'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.text('신청 취소'),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(find.text('취소됨'), findsOneWidget);
    expect(store.pendingRequests, isEmpty);
    store.requestRental(store.items.last, due);
    await tester.pumpAndSettle();
    await logout(tester);
    await login(tester, 'admin', 'admin1234');
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('설정'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('관리자'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대여 승인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('거절')),
    );
    await tester.pumpAndSettle();
    expect(find.text('거절 사유를 입력해 주세요.'), findsOneWidget);
    expect(store.requests.first.status, RequestStatus.pending);
    await tester.enterText(
      find.byKey(const Key('rejection-reason')),
      '학과 행사 사용 예정',
    );
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('거절')),
    );
    await tester.pumpAndSettle();
    expect(store.requests.first.rejectionReason, '학과 행사 사용 예정');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await logout(tester);
    await login(tester, 'student', 'student1234');
    await tester.tap(find.text('내 대여'));
    await tester.pumpAndSettle();
    expect(find.text('거절 사유: 학과 행사 사용 예정'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('앱을 열어둔 동안에도 신청 만료가 자동 반영된다', (tester) async {
    final source = testItemStore();
    final items = source.items.toList();
    source.dispose();
    var now = dateOnly(DateTime.now());
    final store = ItemStore(initialItems: items, now: () => now);
    addTearDown(store.dispose);
    store.requestRental(items.first, now.add(const Duration(days: 1)));
    await tester.pumpWidget(DeptRentalApp(store: store));
    await login(tester, 'student', 'student1234');
    await tester.tap(find.text('내 대여'));
    await tester.pumpAndSettle();
    expect(find.text('승인 대기'), findsOneWidget);
    now = now.add(const Duration(days: 1));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('만료됨'), findsOneWidget);
    expect(find.text('신청 취소'), findsNothing);
    expect(store.pendingRequests, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
