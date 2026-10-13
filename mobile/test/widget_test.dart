import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_items.dart';

void main() {
  testWidgets('로그인에서 물품 목록과 검색으로 이동할 수 있다', (tester) async {
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store));
    expect(find.text('로그인 · 데모 체험'), findsOneWidget);
    await tester.tap(find.text('로그인 · 데모 체험'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.text('물품'));
    await tester.pumpAndSettle();
    expect(find.text('물품 목록'), findsOneWidget);
    expect(find.text('4090본체'), findsWidgets);
    await tester.enterText(find.byKey(const Key('item-search')), '2210');
    await tester.pump();
    expect(find.text('4090본체'), findsOneWidget);
    expect(find.text('모니터'), findsOneWidget);
    expect(find.text('VR 기기'), findsNothing);
  });

  testWidgets('물품 상세에서 임시 대여를 신청할 수 있다', (tester) async {
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store));
    await tester.tap(find.text('로그인 · 데모 체험'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('물품'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('item-search')), '3401');
    await tester.pump();
    await tester.tap(find.text('VR 기기').last);
    await tester.pumpAndSettle();
    expect(find.text('물품 상세'), findsOneWidget);
    await tester.tap(find.text('대여 신청'));
    await tester.pumpAndSettle();
    expect(find.text('내 대여 현황'), findsOneWidget);
    expect(find.text('임시 대여 신청이 완료됐습니다. 내 대여 현황을 확인해 보세요.'), findsOneWidget);
  });
}
