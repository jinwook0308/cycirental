enum ProductKind {
  vr,
  desktop,
  monitor,
  projector,
  camera,
  tripod,
  light,
  laptop,
}

class RentalItem {
  const RentalItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.total,
    required this.initialAvailable,
    required this.kind,
    this.unit = '대',
  });

  factory RentalItem.fromJson(Map<String, dynamic> json) {
    return RentalItem(
      id: _readInt(json, 'id'),
      name: _readString(json, 'name'),
      category: _readString(json, 'category'),
      location: _readString(json, 'description'),
      total: _readInt(json, 'totalQuantity'),
      initialAvailable: _readInt(json, 'availableQuantity'),
      kind: _kindFor(_readString(json, 'name')),
    );
  }

  final int id;
  final String name;
  final String category;
  final String location;
  final int total;
  final int initialAvailable;
  final ProductKind kind;
  final String unit;

  String get subtitle => location;

  String get description => switch (kind) {
    ProductKind.desktop => '수업과 팀 프로젝트에 사용할 수 있는 4090 본체입니다.',
    ProductKind.monitor => '실습실에서 본체와 함께 사용할 수 있는 공용 모니터입니다.',
    ProductKind.vr => '교육과 콘텐츠 제작에 활용할 수 있는 VR 기기입니다.',
    _ => '학과 수업과 프로젝트에 사용할 수 있는 대여 물품입니다.',
  };

  static ProductKind _kindFor(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('vr')) return ProductKind.vr;
    if (normalized.contains('모니터')) return ProductKind.monitor;
    if (normalized.contains('본체') || normalized.contains('데스크톱')) {
      return ProductKind.desktop;
    }
    return ProductKind.desktop;
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw FormatException('$key 값이 없거나 문자열이 아닙니다.');
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('$key 값이 숫자가 아닙니다.');
  }
}
