import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_auth_api.dart';
import 'test_items.dart';

void main() {
  testWidgets('학생의 네 메뉴와 프로필·공지·상단 알림·설정 흐름', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testItemStore();
    final api = testAuthApi();
    addTearDown(store.dispose);
    addTearDown(api.close);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await loginTestStudent(tester);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .destinations
          .length,
      4,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('알림'),
      ),
      findsNothing,
    );
    await tester.tap(find.byTooltip('프로필 보기'));
    await tester.pumpAndSettle();
    expect(find.text('테스트 학생'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    Finder homeScroll() => find
        .descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('[중요] 학과 물품 이용 안내'),
      180,
      scrollable: homeScroll(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('[중요] 학과 물품 이용 안내'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('student-all-notices')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('student-all-notices')));
    await tester.pumpAndSettle();
    expect(find.text('반납 일정 확인 안내'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    for (final key in ['student-pending', 'student-active', 'student-due']) {
      tester.state<ScrollableState>(homeScroll()).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('내 대여 현황'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('알림 보기'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('알림')),
      findsOneWidget,
    );
    expect(find.text('확인할 알림이 없습니다.'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('학번 20260001'), findsOneWidget);
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
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-id')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
