import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'item_api.dart';
import 'item_model.dart';

class RentalRecord {
  RentalRecord({
    required this.item,
    required this.start,
    required this.due,
    this.returnedAt,
  });

  final RentalItem item;
  final DateTime start;
  final DateTime due;
  DateTime? returnedAt;

  bool get isActive => returnedAt == null;
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String dateText(DateTime date) =>
    '${date.year}. ${date.month.toString().padLeft(2, '0')}. '
    '${date.day.toString().padLeft(2, '0')}.';

class ItemStore extends ChangeNotifier {
  ItemStore({ItemApi? api, List<RentalItem>? initialItems})
    : _api = api ?? (initialItems == null ? ItemApi() : null),
      _items = List<RentalItem>.of(initialItems ?? const []);

  final ItemApi? _api;
  final List<RentalItem> _items;
  final List<RentalRecord> rentals = [];

  bool isLoading = false;
  String? errorMessage;

  UnmodifiableListView<RentalItem> get items => UnmodifiableListView(_items);

  List<RentalRecord> get activeRentals =>
      rentals.where((rental) => rental.isActive).toList(growable: false);

  List<RentalRecord> get history =>
      rentals.where((rental) => !rental.isActive).toList(growable: false);

  Future<void> loadItems() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _api!.fetchItems();
      _items
        ..clear()
        ..addAll(loaded);
    } catch (_) {
      errorMessage =
          '백엔드와 연결할 수 없습니다. '
          '주소와 실행 상태를 확인한 뒤 다시 시도해 주세요.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int available(RentalItem item) =>
      item.initialAvailable -
      rentals
          .where((rental) => rental.isActive && rental.item.id == item.id)
          .length;

  bool rent(RentalItem item, DateTime due) {
    if (available(item) <= 0 ||
        !dateOnly(due).isAfter(dateOnly(DateTime.now()))) {
      return false;
    }
    rentals.insert(
      0,
      RentalRecord(
        item: item,
        start: dateOnly(DateTime.now()),
        due: dateOnly(due),
      ),
    );
    notifyListeners();
    return true;
  }

  void returnItem(RentalRecord rental) {
    if (!rental.isActive) return;
    rental.returnedAt = dateOnly(DateTime.now());
    notifyListeners();
  }

  @override
  void dispose() {
    _api?.close();
    super.dispose();
  }
}
