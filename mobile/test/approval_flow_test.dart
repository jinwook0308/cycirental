import 'package:dept_rental/item_model.dart';
import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_items.dart';

void main() {
  test('대기는 대여·재고에 반영되지 않고 승인만 대여를 생성한다', () {
    final store = testItemStore();
    addTearDown(store.dispose);
    final item = store.items.first;
    final before = store.available(item);
    final due = DateTime.now().add(const Duration(days: 3));
    expect(store.requestRental(item, due), isTrue);
    expect(store.requestRental(item, due), isFalse);
    expect(store.myUnapprovedRequests.length, 1);
    expect(store.allActiveRentals, isEmpty);
    expect(store.available(item), before);
    final request = store.requests.first;
    expect(store.approveRequest(request), isTrue);
    expect(store.approveRequest(request), isFalse);
    expect(store.myUnapprovedRequests, isEmpty);
    expect(store.activeRentals.length, 1);
    expect(store.available(item), before - 1);
    final rental = store.activeRentals.first;
    expect(store.requestReturn(rental), isTrue);
    expect(store.confirmReturn(rental), isTrue);
    expect(store.history.length, 1);
    expect(store.available(item), before);
  });

  test('마지막 재고는 승인 한 건에만 배정되고 거절 내역은 신청자에게 남는다', () {
    final store = ItemStore(
      initialItems: const [
        RentalItem(
          id: 1,
          name: '노트북',
          category: '전자기기',
          location: '사무실',
          total: 1,
          initialAvailable: 1,
          kind: ProductKind.laptop,
        ),
      ],
    );
    addTearDown(store.dispose);
    final item = store.items.first;
    final due = DateTime.now().add(const Duration(days: 3));
    expect(store.requestRental(item, due), isTrue);
    final first = store.requests.first;
    store.currentUserId = 'another_student';
    expect(store.requestRental(item, due), isTrue);
    final second = store.requests.first;
    expect(store.approveRequest(first), isTrue);
    expect(store.approveRequest(second), isFalse);
    store.rejectRequest(second, reason: '학과 운영 일정 변경');
    expect(store.myUnapprovedRequests.single.status, RequestStatus.rejected);
    expect(store.activeRentals, isEmpty);
    expect(store.available(item), 0);
    expect(store.approveRequest(second), isFalse);
  });

  testWidgets('학생 신청 → 관리자 로그인·승인 → 학생 대여 중 및 거절 상태 확인', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store));
    await tester.ensureVisible(find.text('로그인 · 데모 체험'));
    await tester.tap(find.text('로그인 · 데모 체험'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('물품'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('item-search')), '3401');
    await tester.pump();
    await tester.tap(find.text('VR 기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대여 신청'));
    await tester.pumpAndSettle();
    expect(find.text('승인 대기'), findsOneWidget);
    expect(store.allActiveRentals, isEmpty);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login-id')), 'admin');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'admin1234',
    );
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('관리자'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대여 승인'));
    await tester.pumpAndSettle();
    expect(find.text('데모 학생 · demo_student'), findsOneWidget);
    await tester.tap(find.text('승인'));
    await tester.pumpAndSettle();
    expect(find.text('승인 완료'), findsOneWidget);
    expect(store.allActiveRentals.length, 1);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그인 · 데모 체험'));
    await tester.tap(find.text('로그인 · 데모 체험'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 대여'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대여 중 (1)'));
    await tester.pumpAndSettle();
    expect(find.text('VR 기기'), findsOneWidget);
    expect(find.text('승인 대기'), findsNothing);
    expect(
      store.requestRental(
        store.items.first,
        DateTime.now().add(const Duration(days: 3)),
      ),
      isTrue,
    );
    store.rejectRequest(store.requests.first, reason: '학과 운영 일정 변경');
    await tester.pumpAndSettle();
    await tester.tap(find.text('신청 내역 (1)'));
    await tester.pumpAndSettle();
    expect(find.text('거절됨'), findsOneWidget);
    expect(store.activeRentals.length, 1);
    expect(tester.takeException(), isNull);
  });
}
