import 'package:dept_rental/item_api.dart';
import 'package:dept_rental/item_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Backend 물품 JSON을 앱 모델로 변환한다', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://example.test/api/items');
      return http.Response(
        '''
        [
          {
            "id": 1,
            "name": "4090본체",
            "category": "전자기기",
            "description": "2210호에 배치된 본체",
            "totalQuantity": 18,
            "availableQuantity": 18
          }
        ]
        ''',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = ItemApi(client: client, baseUrl: 'http://example.test/');

    final items = await api.fetchItems();

    expect(items, hasLength(1));
    expect(items.single.name, '4090본체');
    expect(items.single.location, '2210호에 배치된 본체');
    expect(items.single.total, 18);
    expect(items.single.initialAvailable, 18);
    expect(items.single.kind, ProductKind.desktop);
  });

  test('Backend 오류 응답을 사용자용 예외로 변환한다', () async {
    final api = ItemApi(
      client: MockClient((_) async => http.Response('', 500)),
      baseUrl: 'http://example.test',
    );

    expect(api.fetchItems(), throwsA(isA<ItemApiException>()));
  });
}
