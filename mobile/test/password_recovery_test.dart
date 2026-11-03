import 'dart:convert';

import 'package:dept_rental/auth_api.dart';
import 'package:dept_rental/main.dart';
import 'package:dept_rental/item_store.dart';
import 'package:dept_rental/recovery_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Map<String, dynamic> session({bool limited = false}) => {
  'userId': 71,
  'loginId': '20260071',
  'studentNumber': '20260071',
  'displayName': '테스트 학생',
  'accessToken': limited ? 'limited-token' : 'new-token',
  'mustChangePassword': limited,
  'isAdmin': false,
};

void main() {
  testWidgets('초기화 요청은 이름과 학번만 전송하며 결과는 일반 안내로 표시한다', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map? sent;
    final api = AuthApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/password-reset/requests');
        sent = jsonDecode(request.body) as Map;
        return http.Response('', 202);
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(home: PasswordResetRequestScreen(authApi: api)),
    );
    final title = find.text('비밀번호 초기화\n요청');
    expect(title, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
      isFalse,
    );
    await tester.enterText(find.byKey(const Key('reset-name')), '학생 이름');
    await tester.enterText(
      find.byKey(const Key('reset-student-number')),
      '00012345',
    );
    await tester.ensureVisible(find.byKey(const Key('reset-submit')));
    await tester.tap(find.byKey(const Key('reset-submit')));
    await tester.pumpAndSettle();
    expect(sent, {'displayName': '학생 이름', 'studentNumber': '00012345'});
    expect(find.textContaining('일치하는 계정이 있으면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('임시 로그인은 새 비밀번호 설정 완료 전 홈에 접근할 수 없다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool changed = false;
    final api = AuthApi(
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        if (request.url.path.endsWith('/login')) {
          expect(body['studentNumber'], '20260071');
          expect(body.containsKey('loginId'), isFalse);
          return jsonResponse(session(limited: true));
        }
        expect(request.url.path, '/api/auth/password/change');
        expect(request.headers['Authorization'], 'Bearer limited-token');
        expect(body, {
          'currentPassword': 'temporary123',
          'newPassword': 'newPassword123',
        });
        changed = true;
        return jsonResponse(session());
      }),
    );
    final store = ItemStore();
    addTearDown(store.dispose);
    addTearDown(api.close);
    await tester.pumpWidget(DeptRentalApp(store: store, authApi: api));
    expect(find.text('아이디 찾기'), findsNothing);
    expect(find.text('비밀번호 초기화 요청'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('login-id')), '20260071');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'temporary123',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    // If the keyboard action is not wired, use the login button.
    if (find.byType(PasswordChangeScreen).evaluate().isEmpty) {
      await tester.ensureVisible(find.text('로그인').last);
      await tester.tap(find.text('로그인').last);
      await tester.pumpAndSettle();
    }
    expect(find.byType(PasswordChangeScreen), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    await tester.enterText(
      find.byKey(const Key('change-current')),
      'temporary123',
    );
    await tester.enterText(
      find.byKey(const Key('change-new')),
      'newPassword123',
    );
    await tester.enterText(
      find.byKey(const Key('change-confirm')),
      'newPassword123',
    );
    await tester.ensureVisible(find.byKey(const Key('change-submit')));
    await tester.tap(find.byKey(const Key('change-submit')));
    await tester.pumpAndSettle();
    expect(changed, isTrue);
    expect(find.byType(AppShell), findsOneWidget);
    expect(store.currentUserId, 'user:71');
    expect(tester.takeException(), isNull);
  });

  testWidgets('관리자 초기화 버튼은 본인 확인 체크 전 비활성화된다', (tester) async {
    bool approved = false;
    final api = AuthApi(
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse(
            approved
                ? []
                : [
                    {
                      'id': 1,
                      'displayName': '학생 이름',
                      'studentNumber': '20260071',
                      'status': 'PENDING',
                    },
                  ],
          );
        }
        expect(request.headers['Authorization'], 'Bearer admin-token');
        expect(jsonDecode(request.body), {'identityConfirmed': true});
        approved = true;
        return jsonResponse({
          'temporaryPassword': 'temporary-once',
          'expiresAt': '2026-11-04T00:00:00Z',
        });
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminRecoveryScreen(authApi: api, token: 'admin-token'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('본인 확인 · 초기화'));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, '초기화');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('temporary-once'), findsOneWidget);
    await tester.tap(find.text('전달할 비밀번호 확인 완료'));
    await tester.pumpAndSettle();
    expect(find.text('대기 중인 요청이 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
