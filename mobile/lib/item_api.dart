import 'dart:convert';

import 'package:http/http.dart' as http;

import 'item_model.dart';

class ApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static String get baseUrl =>
      _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
}

class ItemApi {
  ItemApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(
        RegExp(r'/+$'),
        '',
      );

  final http.Client _client;
  final String _baseUrl;

  Future<List<RentalItem>> fetchItems() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/items'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ItemApiException(
        '물품 정보를 불러오지 못했습니다. '
        '(HTTP ${response.statusCode})',
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException('응답이 목록 형식이 아닙니다.');
      }
      return decoded
          .map(
            (value) =>
                RentalItem.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(growable: false);
    } on FormatException catch (error) {
      throw ItemApiException('물품 응답 형식을 확인해 주세요: ${error.message}');
    } on TypeError {
      throw const ItemApiException('물품 응답에 올바르지 않은 항목이 있습니다.');
    }
  }

  void close() => _client.close();
}

class ItemApiException implements Exception {
  const ItemApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
