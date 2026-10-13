import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_items.dart';

void main() {
  testWidgets('홈 바로가기와 프로필, 공지, 설정 및 로그아웃', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store));
    await tester.tap(find.text('로그인 · 데모 체험'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('프로필 보기'));
    await tester.pumpAndSettle();
    expect(find.text('데모 학생'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('[중요] 학과 물품 이용 안내'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('더보기  ›').first);
    await tester.pumpAndSettle();
    expect(find.text('반납 일정 확인 안내'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    for (final entry in {
      '대여 가능한\n물품': '물품 목록',
      '내 대여\n현황': '내 대여 현황',
      '읽지 않은\n알림': '알림',
    }.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(entry.value),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();
    }
    final list = find
        .descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('내 대여 일정'),
      150,
      scrollable: list,
    );
    await tester.scrollUntilVisible(find.text('추천 물품'), 100, scrollable: list);
    expect(
      tester.getTopLeft(find.text('내 대여 일정')).dy,
      lessThan(tester.getTopLeft(find.text('추천 물품')).dy),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.tap(find.text('앱 정보'));
    await tester.pumpAndSettle();
    expect(find.text('CYCIRENTAL'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.text('로그인 · 데모 체험'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
