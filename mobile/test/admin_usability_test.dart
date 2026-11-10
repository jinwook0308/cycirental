import 'package:dept_rental/admin_screen.dart';
import 'package:dept_rental/item_api.dart';
import 'package:dept_rental/item_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_auth_api.dart';
import 'test_items.dart';

Future<void> showAdmin(WidgetTester tester, ItemStore store) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(store.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: AdminScreen(store: store, user: testAdmin),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> nav(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('홈의 상태 카드는 요청·대여·지연 목록을 각각 선택한다', (tester) async {
    final store = testItemStore();
    final today = dateOnly(DateTime.now());
    store.rentals.addAll([
      RentalRecord(
        item: store.items[0],
        start: today,
        due: today.add(const Duration(days: 2)),
        student: '요청 학생',
        studentNumber: '20260001',
      )..returnRequestedAt = DateTime.now(),
      RentalRecord(
        item: store.items[1],
        start: today.subtract(const Duration(days: 3)),
        due: today.subtract(const Duration(days: 1)),
        student: '지연 학생',
        studentNumber: '20260002',
      ),
      RentalRecord(
        item: store.items[2],
        start: today,
        due: today.add(const Duration(days: 3)),
        student: '대여 학생',
        studentNumber: '20260003',
      ),
    ]);
    await showAdmin(tester, store);
    await tester.tap(find.text('반납 요청').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('admin-returns-반납 요청')))
          .selected,
      isTrue,
    );
    expect(find.text('요청 학생 · 20260001'), findsOneWidget);
    expect(find.text('지연 학생 · 20260002'), findsNothing);
    await nav(tester, '현황');
    await tester.tap(find.text('대여 중').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('admin-returns-대여 중')))
          .selected,
      isTrue,
    );
    expect(find.text('지연 학생 · 20260002'), findsOneWidget);
    await nav(tester, '현황');
    await tester.tap(find.text('반납 지연').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('admin-returns-반납 지연')))
          .selected,
      isTrue,
    );
    expect(find.text('지연 학생 · 20260002'), findsOneWidget);
    expect(find.text('요청 학생 · 20260001'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('전체 보기는 대여와 반납 목적지를 구분한다', (tester) async {
    final store = testItemStore();
    await showAdmin(tester, store);
    await tester.ensureVisible(find.text('전체 보기 ›'));
    await tester.tap(find.text('전체 보기 ›'));
    await tester.pumpAndSettle();
    expect(find.text('대여 신청 전체 보기'), findsOneWidget);
    await tester.tap(find.text('반납 요청 전체 보기'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('admin-returns-반납 요청')))
          .selected,
      isTrue,
    );
    expect(find.text('반납 요청 내역이 없습니다.'), findsOneWidget);
  });

  testWidgets('물품은 이름·카테고리·장소로 검색하고 결과 없음과 구분한다', (tester) async {
    final store = testItemStore();
    await showAdmin(tester, store);
    await nav(tester, '물품 관리');
    final search = find.byKey(const Key('admin-item-search'));
    await tester.enterText(search, store.items.last.location);
    await tester.pumpAndSettle();
    expect(find.text(store.items.last.name), findsOneWidget);
    await nav(tester, '대여 승인');
    await nav(tester, '물품 관리');
    expect(
      tester.widget<TextField>(search).controller!.text,
      store.items.last.location,
    );
    await tester.enterText(search, '없는 물품 999');
    await tester.pumpAndSettle();
    expect(find.text('조건에 맞는 물품이 없습니다.'), findsOneWidget);
    await tester.enterText(search, '전자기기');
    await tester.pumpAndSettle();
    expect(find.text('조건에 맞는 물품이 없습니다.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('승인 취소는 재고를 바꾸지 않고 확정 시에만 처리한다', (tester) async {
    final store = testItemStore();
    seedTestRequests(store);
    final request = store.pendingRequests.first;
    final before = store.available(request.item);
    await showAdmin(tester, store);
    await nav(tester, '대여 승인');
    await tester.tap(find.text('승인').first);
    await tester.pumpAndSettle();
    expect(find.text('대여 승인 확인'), findsOneWidget);
    expect(request.status, RequestStatus.pending);
    expect(store.available(request.item), before);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(request.status, RequestStatus.pending);
    await tester.tap(find.text('승인').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('승인 확정'));
    await tester.pumpAndSettle();
    expect(request.status, RequestStatus.approved);
    expect(store.available(request.item), before - 1);
    expect(store.allActiveRentals.single.studentNumber, request.studentNumber);
  });

  testWidgets('물품 조회 실패는 빈 목록으로 표시하지 않고 재시도로 복구한다', (tester) async {
    var fail = true;
    final store = ItemStore(
      api: ItemApi(
        client: MockClient(
          (_) async => http.Response(fail ? 'error' : '[]', fail ? 500 : 200),
        ),
      ),
    );
    await store.loadItems();
    await showAdmin(tester, store);
    await nav(tester, '물품 관리');
    expect(find.text('등록된 물품이 없습니다.'), findsNothing);
    expect(find.text('물품 조회에 실패했습니다. 다시 시도해 주세요.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.text('등록된 물품이 없습니다.'), findsOneWidget);
  });

  test('신청 시간은 같은 날에도 보존하고 상태별 기록은 유지한다', () {
    final now = DateTime(2026, 11, 10, 14, 35);
    final store = testItemStore();
    addTearDown(store.dispose);
    final request = DemoRequest(
      item: store.items.first,
      student: '학생',
      studentId: 'user:4',
      studentNumber: '00012345',
      due: now.add(const Duration(days: 3)),
      requestedAt: now,
    );
    expect(request.requestedAt, now);
    expect(request.studentLabel, '학생 · 00012345');
  });
}
