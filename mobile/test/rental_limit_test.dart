import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_items.dart';

void main() {
  test('대여는 다음 날부터 14일 뒤까지 가능하고 경계를 넘으면 거절된다', () {
    final store = testItemStore();
    addTearDown(store.dispose);
    final item = store.items.first;
    final today = dateOnly(DateTime.now());
    final before = store.available(item);
    expect(store.requestRental(item, today), isFalse);
    expect(
      store.requestRental(item, today.add(const Duration(days: 15))),
      isFalse,
    );
    expect(store.available(item), before);
    expect(
      store.requestRental(item, today.add(const Duration(days: 1))),
      isTrue,
    );
    expect(store.approveRequest(store.requests.first), isTrue);
    expect(
      store.requestRental(item, today.add(const Duration(days: 14))),
      isTrue,
    );
    expect(store.available(item), before - 1);
    expect(store.approveRequest(store.requests.first), isTrue);
    expect(store.available(item), before - 2);
  });

  test('관리자 승인도 원래 신청일로부터 14일을 초과할 수 없다', () {
    final store = testItemStore();
    addTearDown(store.dispose);
    final today = dateOnly(DateTime.now());
    final item = store.items.first;
    final valid = DemoRequest(
      item: item,
      student: '테스트',
      studentId: 'sample',
      due: today.add(const Duration(days: 14)),
      requestedAt: today,
    );
    final invalid = DemoRequest(
      item: item,
      student: '테스트',
      studentId: 'sample',
      due: today.add(const Duration(days: 15)),
      requestedAt: today,
    );
    final delayed = DemoRequest(
      item: item,
      student: '테스트',
      studentId: 'sample',
      due: today.add(const Duration(days: 14)),
      requestedAt: today.subtract(const Duration(days: 1)),
    );
    store.requests.addAll([valid, invalid, delayed]);
    expect(store.approveRequest(invalid), isFalse);
    expect(store.approveRequest(delayed), isFalse);
    expect(store.approveRequest(valid), isTrue);
    expect(store.allActiveRentals.length, 1);
  });

  testWidgets('반납일 달력은 다음 날부터 14일까지 제한된다', (tester) async {
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(item: store.items.first, store: store),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('반납 예정일 (최대 14일)'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('반납 예정일 (최대 14일)'));
    await tester.pumpAndSettle();
    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    final today = dateOnly(DateTime.now());
    expect(picker.firstDate, today.add(const Duration(days: 1)));
    expect(picker.lastDate, today.add(const Duration(days: 14)));
    expect(tester.takeException(), isNull);
  });
}
