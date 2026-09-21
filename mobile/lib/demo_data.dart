import 'package:flutter/material.dart';

enum ProductKind { vr, projector, camera, tripod, light, laptop }

class RentalItem {
  const RentalItem({
    required this.id,
    required this.name,
    required this.category,
    required this.subtitle,
    required this.description,
    required this.total,
    required this.initialAvailable,
    required this.kind,
    required this.location,
    this.unit = '대',
  });

  final String id;
  final String name;
  final String category;
  final String subtitle;
  final String description;
  final int total;
  final int initialAvailable;
  final ProductKind kind;
  final String location;
  final String unit;
}

const rentalItems = <RentalItem>[
  RentalItem(
    id: 'vr',
    name: 'VR 기기',
    category: '실험/기타',
    subtitle: '가상현실 체험 장비',
    description: '교육, 콘텐츠 제작, 전시 등 다양한 용도로 활용 가능한 VR 기기입니다.',
    total: 5,
    initialAvailable: 3,
    kind: ProductKind.vr,
    location: '미디어실 (공학관 3층)',
  ),
  RentalItem(
    id: 'projector',
    name: '빔프로젝터',
    category: '전자기기',
    subtitle: '발표, 강의용',
    description: '수업 발표와 팀 프로젝트에 사용할 수 있는 휴대용 빔프로젝터입니다.',
    total: 3,
    initialAvailable: 2,
    kind: ProductKind.projector,
    location: '학과 사무실 (공학관 2층)',
  ),
  RentalItem(
    id: 'camera',
    name: '카메라 (DSLR)',
    category: '촬영/영상',
    subtitle: '사진·영상 촬영용',
    description: '수업 과제와 프로젝트 촬영을 위한 DSLR 카메라입니다.',
    total: 2,
    initialAvailable: 0,
    kind: ProductKind.camera,
    location: '미디어실 (공학관 3층)',
  ),
  RentalItem(
    id: 'tripod',
    name: '삼각대',
    category: '촬영/영상',
    subtitle: '촬영 보조 장비',
    description: '카메라와 함께 사용할 수 있는 높이 조절 삼각대입니다.',
    total: 5,
    initialAvailable: 4,
    kind: ProductKind.tripod,
    location: '미디어실 (공학관 3층)',
  ),
  RentalItem(
    id: 'light',
    name: '조명 세트',
    category: '촬영/영상',
    subtitle: '영상 촬영 조명',
    description: '실내 촬영을 돕는 LED 조명과 스탠드 세트입니다.',
    total: 4,
    initialAvailable: 2,
    kind: ProductKind.light,
    location: '미디어실 (공학관 3층)',
    unit: '세트',
  ),
  RentalItem(
    id: 'laptop',
    name: '노트북',
    category: '전자기기',
    subtitle: '영상 편집용',
    description: '수업과 팀 프로젝트에서 사용할 수 있는 공용 노트북입니다.',
    total: 1,
    initialAvailable: 0,
    kind: ProductKind.laptop,
    location: '학과 사무실 (공학관 2층)',
  ),
];

class DemoRental {
  DemoRental({
    required this.item,
    required this.start,
    required this.due,
    this.isSample = false,
    this.returnedAt,
  });

  final RentalItem item;
  final DateTime start;
  final DateTime due;
  final bool isSample;
  DateTime? returnedAt;

  bool get isActive => returnedAt == null;
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String dateText(DateTime date) =>
    '${date.year}. ${date.month.toString().padLeft(2, '0')}. '
    '${date.day.toString().padLeft(2, '0')}.';

class DemoStore extends ChangeNotifier {
  DemoStore() {
    final today = dateOnly(DateTime.now());
    rentals.addAll([
      DemoRental(
        item: rentalItems[0],
        start: today.subtract(const Duration(days: 2)),
        due: today.add(const Duration(days: 1)),
        isSample: true,
      ),
      DemoRental(
        item: rentalItems[1],
        start: today.subtract(const Duration(days: 4)),
        due: today.add(const Duration(days: 3)),
        isSample: true,
      ),
      DemoRental(
        item: rentalItems[3],
        start: today.subtract(const Duration(days: 14)),
        due: today.subtract(const Duration(days: 7)),
        returnedAt: today.subtract(const Duration(days: 8)),
        isSample: true,
      ),
    ]);
  }

  final List<DemoRental> rentals = [];

  List<DemoRental> get activeRentals =>
      rentals.where((rental) => rental.isActive).toList();

  List<DemoRental> get history =>
      rentals.where((rental) => !rental.isActive).toList();

  int available(RentalItem item) =>
      item.initialAvailable -
      rentals
          .where(
            (rental) =>
                !rental.isSample &&
                rental.isActive &&
                rental.item.id == item.id,
          )
          .length;

  bool rent(RentalItem item, DateTime due) {
    if (available(item) <= 0 ||
        !dateOnly(due).isAfter(dateOnly(DateTime.now()))) {
      return false;
    }
    rentals.insert(
      0,
      DemoRental(
        item: item,
        start: dateOnly(DateTime.now()),
        due: dateOnly(due),
      ),
    );
    notifyListeners();
    return true;
  }

  void returnItem(DemoRental rental) {
    if (!rental.isActive) return;
    rental.returnedAt = dateOnly(DateTime.now());
    notifyListeners();
  }
}
