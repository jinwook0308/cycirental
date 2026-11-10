import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_auth_api.dart';
import 'test_items.dart';

void main() {
  testWidgets('내 반납일을 가까운 순으로 표시하고 다른 계정·반납 대기는 제외한다', (tester) async {
    final store = testItemStore();
    final api = testAuthApi();
    addTearDown(store.dispose);
    addTearDown(api.close);
    final today = dateOnly(DateTime.now());
    store.rentals.addAll([
      RentalRecord(
        item: store.items[0],
        start: today,
        due: today.add(const Duration(days: 7)),
        studentId: 'user:1',
      ),
      RentalRecord(
        item: store.items[2],
        start: today,
        due: today.add(const Duration(days: 1)),
        studentId: 'user:1',
      ),
      RentalRecord(
        item: store.items.last,
        start: today,
        due: today,
        studentId: 'user:1',
      )..returnRequestedAt = DateTime.now(),
      RentalRecord(
        item: store.items[1],
        start: today,
        due: today.subtract(const Duration(days: 1)),
        studentId: 'user:99',
      ),
    ]);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await loginTestStudent(tester);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('student-next-return')),
        matching: find.text('모니터'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('student-due')),
        matching: find.text('1건'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('student-active')),
        matching: find.text('3건'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('student-active')));
    await tester.pumpAndSettle();
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      1,
    );
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('student-pending')));
    await tester.pumpAndSettle();
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('대여 가능 필터와 검색어 지우기·화면 이동 후 검색 유지', (tester) async {
    final store = testItemStore();
    final api = testAuthApi();
    addTearDown(store.dispose);
    addTearDown(api.close);
    final today = dateOnly(DateTime.now());
    for (var i = 0; i < store.items.last.initialAvailable; i++) {
      store.rentals.add(
        RentalRecord(
          item: store.items.last,
          start: today,
          due: today.add(const Duration(days: 2)),
          studentId: 'user:99',
        ),
      );
    }
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await loginTestStudent(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('물품'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('item-search')), '3401');
    await tester.pumpAndSettle();
    expect(find.text('VR 기기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('student-available-only')));
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('물품'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('item-search')))
          .controller!
          .text,
      '3401',
    );
    await tester.tap(find.byKey(const Key('item-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없습니다.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('이미 신청한 물품 상세는 중복 신청 버튼을 비활성화한다', (tester) async {
    final store = testItemStore();
    final api = testAuthApi();
    addTearDown(store.dispose);
    addTearDown(api.close);
    store.requestRental(
      store.items.last,
      DateTime.now().add(const Duration(days: 3)),
    );
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await loginTestStudent(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('물품'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('item-search')), '3401');
    await tester.pumpAndSettle();
    await tester.tap(find.text('VR 기기'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '승인 대기 중'))
          .onPressed,
      isNull,
    );
    expect(store.requests.length, 1);
    expect(tester.takeException(), isNull);
  });
}
