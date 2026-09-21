import 'package:dept_rental/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('데모 진입 후 물품 목록을 볼 수 있다', (tester) async {
    await tester.pumpWidget(const DeptRentalApp());
    expect(find.text('데모 화면 둘러보기'), findsOneWidget);
    await tester.tap(find.text('데모 화면 둘러보기'));
    await tester.pumpAndSettle();
    expect(find.text('추천 물품'), findsOneWidget);
    await tester.tap(find.text('더보기  ›'));
    await tester.pumpAndSettle();
    expect(find.text('물품 목록'), findsOneWidget);
    expect(find.text('VR 기기'), findsOneWidget);
  });
}
