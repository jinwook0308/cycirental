import 'package:dept_rental/demo_auth.dart';
import 'package:dept_rental/main.dart';
import 'package:dept_rental/notice_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_items.dart';

void main() {
  test('공지 관리 권한, 중요 우선순위 및 빈 목록', () {
    final notices = NoticeStore();
    addTearDown(notices.dispose);
    expect(
      notices.save(
        actor: AppUser.student,
        title: '학생 공지',
        body: '내용',
        isImportant: true,
      ),
      isFalse,
    );
    expect(
      notices.delete(notices.notices.first, actor: AppUser.student),
      isFalse,
    );
    expect(
      notices.save(
        actor: AppUser.admin,
        title: '새 공지',
        body: '내용',
        isImportant: true,
      ),
      isTrue,
    );
    expect(notices.featured?.title, '새 공지');
    final newest = notices.featured!;
    expect(
      notices.save(
        actor: AppUser.admin,
        original: newest,
        title: '수정 공지',
        body: '수정 내용',
        isImportant: false,
      ),
      isTrue,
    );
    expect(notices.featured?.title, '학과 물품 이용 안내');
    for (final notice in notices.notices.toList()) {
      expect(notices.delete(notice, actor: AppUser.admin), isTrue);
    }
    expect(notices.featured, isNull);
    expect(
      notices.save(
        actor: AppUser.admin,
        title: ' ',
        body: '내용',
        isImportant: false,
      ),
      isFalse,
    );
  });

  testWidgets('관리자 공지 작성·수정·삭제와 홈 반영', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store));
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
    await tester.ensureVisible(find.text('관리자'));
    await tester.tap(find.text('관리자'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('공지 관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('공지 작성'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('notice-title')), '학과 휴무 안내');
    await tester.tap(find.byType(SwitchListTile));
    await tester.enterText(
      find.byKey(const Key('notice-body')),
      '휴무일에는 대여와 반납이 중단됩니다.',
    );
    await tester.ensureVisible(find.text('임시 저장'));
    await tester.tap(find.text('임시 저장'));
    await tester.pumpAndSettle();
    final id = store.noticeStore.featured!.id;
    expect(store.noticeStore.featured!.title, '학과 휴무 안내');
    await tester.tap(find.byKey(ValueKey('edit-notice-$id')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('notice-title')), '휴무 일정 변경');
    await tester.ensureVisible(find.text('임시 저장'));
    await tester.tap(find.text('임시 저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(find.text('[중요] 휴무 일정 변경'), findsOneWidget);
    await tester.tap(find.text('[중요] 휴무 일정 변경'));
    await tester.pumpAndSettle();
    expect(find.text('휴무일에는 대여와 반납이 중단됩니다.'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('관리자'));
    await tester.tap(find.text('관리자'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('공지 관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('delete-notice-$id')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('삭제')),
    );
    await tester.pumpAndSettle();
    expect(store.noticeStore.notices.any((notice) => notice.id == id), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('회원가입 검증과 실제 계정 미생성 안내', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = testItemStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(DeptRentalApp(store: store));
    await tester.ensureVisible(find.text('회원가입'));
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('회원가입 입력 확인'),
      150,
      scrollable: scroll,
    );
    await tester.tap(find.text('회원가입 입력 확인'));
    await tester.pumpAndSettle();
    expect(find.text('회원가입 입력 확인 완료'), findsNothing);
    for (final entry in {
      'signup-name': '테스트 학생',
      'signup-student-id': '20260001',
      'signup-login-id': 'new_student',
      'signup-password': 'password123',
      'signup-confirm': 'password123',
    }.entries) {
      final field = find.byKey(Key(entry.key));
      await tester.scrollUntilVisible(field, -150, scrollable: scroll);
      await tester.enterText(field, entry.value);
    }
    await tester.scrollUntilVisible(
      find.text('회원가입 입력 확인'),
      150,
      scrollable: scroll,
    );
    await tester.tap(find.text('회원가입 입력 확인'));
    await tester.pumpAndSettle();
    expect(find.text('회원가입 입력 확인 완료'), findsOneWidget);
    await tester.tap(find.text('로그인 화면으로'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(demoSignIn('new_student', 'password123'), isNull);
    expect(tester.takeException(), isNull);
  });
}
