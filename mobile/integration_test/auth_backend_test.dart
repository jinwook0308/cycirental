import 'package:dept_rental/account_screens.dart';
import 'package:dept_rental/auth_api.dart';
import 'package:dept_rental/item_api.dart';
import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Run only against the disposable local H2 server described in DEVELOPMENT.md.
const runBackendTests = bool.fromEnvironment('RUN_BACKEND_INTEGRATION_TESTS');

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(finder, findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Medium Phone: 실제 백엔드 가입 → 학번 로그인 → 물품 조회 → 로그아웃', (
    tester,
  ) async {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    expect(baseUri.host, '10.0.2.2');
    expect(
      baseUri.port,
      18080,
      reason: 'Use only the isolated local H2 test server.',
    );
    final api = AuthApi();
    final store = ItemStore();
    addTearDown(api.close);
    addTearDown(store.dispose);
    await store.loadItems();
    expect(store.items, isNotEmpty);
    final studentNumber = DateTime.now().microsecondsSinceEpoch
        .toString()
        .substring(4, 16);
    const password = 'integration-password-123';

    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('회원가입'));
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(find.text('아이디'), findsNothing);
    expect(find.text('이메일'), findsNothing);
    for (final entry in {
      'signup-name': '연동 테스트',
      'signup-student-number': studentNumber,
      'signup-password': password,
      'signup-confirm': password,
      'signup-phone': '01000000000',
    }.entries) {
      final field = find.byKey(Key(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await waitFor(tester, find.byType(LoginScreen));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login-id')), studentNumber);
    await tester.enterText(find.byKey(const Key('login-password')), password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await waitFor(tester, find.byType(AppShell));
    await tester.pumpAndSettle();
    expect(store.currentUserName, '연동 테스트');
    expect(store.currentUserId, startsWith('user:'));
    await tester.tap(find.text('물품'));
    await tester.pumpAndSettle();
    expect(find.text('VR 기기'), findsWidgets);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await waitFor(tester, find.byType(LoginScreen));
    expect(store.currentUserId, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, skip: !runBackendTests);
}
