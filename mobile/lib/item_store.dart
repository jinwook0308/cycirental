import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'item_api.dart';
import 'item_model.dart';

enum RequestStatus { pending, approved, rejected, cancelled, expired }

String requestStatusLabel(RequestStatus status) => switch (status) {
  RequestStatus.pending => '승인 대기',
  RequestStatus.approved => '승인 완료',
  RequestStatus.rejected => '거절됨',
  RequestStatus.cancelled => '취소됨',
  RequestStatus.expired => '만료됨',
};

class DemoRequest {
  DemoRequest({
    required this.item,
    required this.student,
    required this.studentId,
    required this.due,
    DateTime? requestedAt,
  }) : requestedAt = dateOnly(requestedAt ?? DateTime.now());
  final DateTime requestedAt;
  RentalItem item;
  final String student;
  final String studentId;
  final DateTime due;
  RequestStatus status = RequestStatus.pending;
  String? rejectionReason;
}

class RentalRecord {
  RentalRecord({
    required this.item,
    required this.start,
    required this.due,
    this.returnedAt,
    this.student = '데모 학생',
    this.studentId = 'demo_student',
  });

  RentalItem item;
  final String student;
  final String studentId;
  final DateTime start;
  final DateTime due;
  DateTime? returnedAt;
  DateTime? returnRequestedAt;
  bool get isReturnPending => isActive && returnRequestedAt != null;

  bool get isActive => returnedAt == null;
}

const maxRentalDays = 14;

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime latestReturnDate(DateTime start) =>
    dateOnly(start).add(const Duration(days: maxRentalDays));

bool isValidReturnDate(DateTime due, {DateTime? start, DateTime? now}) {
  final date = dateOnly(due);
  final today = dateOnly(now ?? DateTime.now());
  final requested = dateOnly(start ?? today);
  return date.isAfter(today) &&
      date.isAfter(requested) &&
      !date.isAfter(latestReturnDate(requested));
}

String dateText(DateTime date) =>
    '${date.year}. ${date.month.toString().padLeft(2, '0')}. '
    '${date.day.toString().padLeft(2, '0')}.';

class ItemStore extends ChangeNotifier {
  ItemStore({
    ItemApi? api,
    List<RentalItem>? initialItems,
    DateTime Function()? now,
  }) : _api = api ?? (initialItems == null ? ItemApi() : null),
       _items = List<RentalItem>.of(initialItems ?? const []),
       _now = now ?? DateTime.now;

  final DateTime Function() _now;

  void refreshExpiredRequests() {
    final today = dateOnly(_now());
    var changed = false;
    for (final request in requests) {
      if (request.status == RequestStatus.pending &&
          !dateOnly(request.due).isAfter(today)) {
        request.status = RequestStatus.expired;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  final ItemApi? _api;
  final List<RentalItem> _items;
  final List<RentalRecord> rentals = [];

  String currentUserId = 'demo_student';
  final List<DemoRequest> requests = [];
  final Map<int, RentalItem> _localItems = {};
  final Map<int, int> _stockAdjustments = {};
  int _nextLocalId = -1;
  bool _adminDemoPrepared = false;
  bool _adminDemoRequested = false;

  List<RentalRecord> get allActiveRentals =>
      rentals.where((rental) => rental.isActive).toList();
  List<DemoRequest> get pendingRequests => requests
      .where((request) => request.status == RequestStatus.pending)
      .toList();

  // Sample approvals are created from loaded items; no request is sent to the API.
  void prepareAdminDemo() {
    _adminDemoRequested = true;
    if (_adminDemoPrepared || items.isEmpty) return;
    _adminDemoPrepared = true;
    final due = dateOnly(DateTime.now()).add(const Duration(days: 3));
    for (final (index, item) in items.take(2).indexed) {
      requests.add(
        DemoRequest(
          item: item,
          student: '샘플 학생 ${index + 1}',
          studentId: 'sample_${index + 1}',
          due: due,
        ),
      );
    }
    notifyListeners();
  }

  bool approveRequest(DemoRequest request) {
    refreshExpiredRequests();
    final candidates = items.where((item) => item.id == request.item.id);
    if (!requests.contains(request) ||
        request.status != RequestStatus.pending ||
        candidates.isEmpty ||
        available(candidates.first) <= 0 ||
        !isValidReturnDate(
          request.due,
          start: request.requestedAt,
          now: _now(),
        )) {
      return false;
    }
    request.item = candidates.first;
    request.status = RequestStatus.approved;
    rentals.insert(
      0,
      RentalRecord(
        item: request.item,
        start: dateOnly(_now()),
        due: request.due,
        student: request.student,
        studentId: request.studentId,
      ),
    );
    notifyListeners();
    return true;
  }

  bool rejectRequest(DemoRequest request, {required String reason}) {
    refreshExpiredRequests();
    if (!requests.contains(request) ||
        request.status != RequestStatus.pending ||
        reason.trim().isEmpty ||
        reason.trim().length > 300) {
      return false;
    }
    request.rejectionReason = reason.trim();
    request.status = RequestStatus.rejected;
    notifyListeners();
    return true;
  }

  bool cancelRequest(DemoRequest request) {
    refreshExpiredRequests();
    if (!requests.contains(request) ||
        request.studentId != currentUserId ||
        request.status != RequestStatus.pending) {
      return false;
    }
    request.status = RequestStatus.cancelled;
    notifyListeners();
    return true;
  }

  bool saveItem({
    RentalItem? original,
    required String name,
    required String category,
    required String location,
    required int total,
    required int availableCount,
    required ProductKind kind,
  }) {
    if (name.trim().isEmpty ||
        location.trim().isEmpty ||
        total < 1 ||
        availableCount < 0 ||
        availableCount > total) {
      return false;
    }
    final matching = original == null
        ? null
        : _items.where((item) => item.id == original.id).firstOrNull;
    if (original != null && matching == null) return false;
    final current = matching == null ? 0 : available(matching);
    if (matching != null &&
        total - availableCount != matching.total - current) {
      return false;
    }
    final item = RentalItem(
      id: matching?.id ?? _nextLocalId--,
      name: name.trim(),
      category: category,
      location: location.trim(),
      total: total,
      initialAvailable: matching?.initialAvailable ?? availableCount,
      kind: kind,
      unit: matching?.unit ?? '대',
    );
    if (matching == null) {
      _items.add(item);
    } else {
      _stockAdjustments[item.id] =
          (_stockAdjustments[item.id] ?? 0) + availableCount - current;
      _items[_items.indexOf(matching)] = item;
    }
    _localItems[item.id] = item;
    _updateReferences();
    if (_adminDemoRequested) prepareAdminDemo();
    notifyListeners();
    return true;
  }

  void _updateReferences() {
    final byId = {for (final item in _items) item.id: item};
    for (final rental in rentals) {
      rental.item = byId[rental.item.id] ?? rental.item;
    }
    for (final request in requests) {
      request.item = byId[request.item.id] ?? request.item;
    }
  }

  bool isLoading = false;
  String? errorMessage;

  UnmodifiableListView<RentalItem> get items => UnmodifiableListView(_items);

  List<RentalRecord> get activeRentals => rentals
      .where((rental) => rental.isActive && rental.studentId == currentUserId)
      .toList(growable: false);

  List<RentalRecord> get history => rentals
      .where((rental) => !rental.isActive && rental.studentId == currentUserId)
      .toList(growable: false);

  List<DemoRequest> get myRequests => requests
      .where((request) => request.studentId == currentUserId)
      .toList(growable: false);

  List<DemoRequest> get myUnapprovedRequests => myRequests
      .where((request) => request.status != RequestStatus.approved)
      .toList(growable: false);

  Future<void> loadItems() async {
    if (isLoading || _api == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _api.fetchItems();
      // Preserve explicit local demo edits across an API refresh.
      final merged = {for (final item in loaded) item.id: item, ..._localItems};
      _items
        ..clear()
        ..addAll(merged.values);
      _updateReferences();
      if (_adminDemoRequested) prepareAdminDemo();
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
      item.initialAvailable +
      (_stockAdjustments[item.id] ?? 0) -
      rentals
          .where((rental) => rental.isActive && rental.item.id == item.id)
          .length;

  bool requestRental(RentalItem item, DateTime due) {
    refreshExpiredRequests();
    final current = _items
        .where((candidate) => candidate.id == item.id)
        .firstOrNull;
    if (current == null ||
        available(current) <= 0 ||
        !isValidReturnDate(due, now: _now()) ||
        requests.any(
          (request) =>
              request.studentId == currentUserId &&
              request.item.id == current.id &&
              request.status == RequestStatus.pending,
        )) {
      return false;
    }
    requests.insert(
      0,
      DemoRequest(
        item: current,
        due: dateOnly(due),
        requestedAt: _now(),
        studentId: currentUserId,
        student: currentUserId == 'demo_admin' ? '데모 관리자' : '데모 학생',
      ),
    );
    // Waiting requests do not consume stock. Approval rechecks stock atomically.
    notifyListeners();
    return true;
  }

  bool requestReturn(RentalRecord rental) {
    if (!rentals.contains(rental) ||
        !rental.isActive ||
        rental.isReturnPending ||
        rental.studentId != currentUserId) {
      return false;
    }
    rental.returnRequestedAt = _now();
    notifyListeners();
    return true;
  }

  bool confirmReturn(RentalRecord rental) {
    if (!rentals.contains(rental) ||
        !rental.isActive ||
        !rental.isReturnPending) {
      return false;
    }
    rental.returnedAt = dateOnly(_now());
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _api?.close();
    super.dispose();
  }
}
