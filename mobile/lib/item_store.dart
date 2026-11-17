import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'auth_api.dart';
import 'item_api.dart';
import 'item_model.dart';
import 'notice_store.dart';
import 'rental_response.dart';

String studentDisplayLabel(String name, String studentNumber) =>
    '$name · ${studentNumber.isEmpty ? '학번 미등록' : studentNumber}';

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
    this.studentNumber = '',
    this.serverId,
    required this.due,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();
  final DateTime requestedAt;
  final int? serverId;
  RentalItem item;
  final String student;
  final String studentId;
  final String studentNumber;
  String get studentLabel => studentDisplayLabel(student, studentNumber);
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
    this.student = '',
    this.studentId = '',
    this.studentNumber = '',
    this.serverManaged = false,
    this.serverReturnPending = false,
  });

  RentalItem item;
  final String student;
  final String studentId;
  final String studentNumber;
  String get studentLabel => studentDisplayLabel(student, studentNumber);
  final DateTime start;
  final DateTime due;
  DateTime? returnedAt;
  DateTime? returnRequestedAt;
  final bool serverManaged;
  final bool serverReturnPending;
  bool get isReturnPending =>
      isActive && (returnRequestedAt != null || serverReturnPending);

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
    this._rentalApi,
    List<RentalItem>? initialItems,
    DateTime Function()? now,
  }) : _api = api ?? (initialItems == null ? ItemApi() : null),
       _items = List<RentalItem>.of(initialItems ?? const []),
       _now = now ?? DateTime.now {
    noticeStore.addListener(notifyListeners);
  }

  final NoticeStore noticeStore = NoticeStore();

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
  final AuthApi? _rentalApi;
  final _serverRentals = <int, RentalResponse>{};
  String? _rentalToken;
  int _rentalRevision = 0;
  bool _disposed = false;
  bool loadingRentals = false;
  bool rentalActionPending = false;
  String? rentalLoadError;
  bool _hasRentalSnapshot = false;

  bool get usesServerRentals => _rentalToken != null;
  bool get rentalCountsKnown => !usesServerRentals || _hasRentalSnapshot;

  void setRentalSession(String? token) {
    if (_rentalApi == null) return;
    _rentalRevision++;
    _rentalToken = token;
    _serverRentals.clear();
    loadingRentals = false;
    rentalActionPending = false;
    rentalLoadError = null;
    _hasRentalSnapshot = false;
    if (token != null) unawaited(loadMyRentals());
  }

  bool _isCurrentRentalOperation(int revision) =>
      !_disposed && revision == _rentalRevision;

  Future<void> loadMyRentals() async {
    final token = _rentalToken;
    if (token == null || _disposed || loadingRentals || rentalActionPending) {
      return;
    }
    final revision = _rentalRevision;
    loadingRentals = true;
    rentalLoadError = null;
    notifyListeners();
    try {
      final rows = await _rentalApi!.myRentals(token);
      if (!_isCurrentRentalOperation(revision)) return;
      _serverRentals
        ..clear()
        ..addEntries(rows.map((row) => MapEntry(row.id, row)));
      _hasRentalSnapshot = true;
    } on AuthApiException catch (error) {
      if (_isCurrentRentalOperation(revision)) rentalLoadError = error.message;
    } finally {
      if (_isCurrentRentalOperation(revision)) {
        loadingRentals = false;
        notifyListeners();
      }
    }
  }

  Future<bool> submitRental(RentalItem item, DateTime due) {
    if (_rentalApi == null) return Future.value(requestRental(item, due));
    if (item.id <= 0 || !isValidReturnDate(due, now: _now())) {
      return Future.value(false);
    }
    return _changeRental(
      (token) => _rentalApi.applyRental(token, item.id, due),
    );
  }

  Future<bool> submitCancellation(DemoRequest request) {
    if (_rentalApi == null) return Future.value(cancelRequest(request));
    final id = request.serverId;
    if (id == null ||
        _serverRentals[id]?.status != ServerRentalStatus.pending) {
      return Future.value(false);
    }
    return _changeRental((token) => _rentalApi.cancelRental(token, id));
  }

  Future<bool> _changeRental(
    Future<RentalResponse> Function(String token) submit,
  ) async {
    final token = _rentalToken;
    if (token == null || _disposed || rentalActionPending) return false;
    // A GET started before the write may return older data.
    final revision = ++_rentalRevision;
    loadingRentals = false;
    rentalActionPending = true;
    notifyListeners();
    try {
      final rental = await submit(token);
      if (!_isCurrentRentalOperation(revision)) return false;
      _serverRentals[rental.id] = rental;
      return true;
    } finally {
      if (_isCurrentRentalOperation(revision)) {
        rentalActionPending = false;
        notifyListeners();
        unawaited(loadMyRentals());
      }
    }
  }

  List<RentalResponse> get _orderedServerRentals =>
      _serverRentals.values.toList()..sort((a, b) => b.id.compareTo(a.id));

  RentalItem _itemForRental(RentalResponse rental) =>
      _items.where((item) => item.id == rental.itemId).firstOrNull ??
      RentalItem(
        id: rental.itemId,
        name: rental.itemName,
        category: '',
        location: '',
        total: 0,
        initialAvailable: 0,
        kind: ProductKind.desktop,
      );

  DemoRequest _serverRequest(RentalResponse row) =>
      DemoRequest(
          item: _itemForRental(row),
          student: currentUserName,
          studentId: currentUserId,
          studentNumber: currentUserStudentNumber,
          due: row.dueAt,
          requestedAt: row.rentedAt,
          serverId: row.id,
        )
        ..status = switch (row.status) {
          ServerRentalStatus.pending => RequestStatus.pending,
          ServerRentalStatus.rejected => RequestStatus.rejected,
          ServerRentalStatus.cancelled => RequestStatus.cancelled,
          ServerRentalStatus.expired => RequestStatus.expired,
          _ => RequestStatus.approved,
        };

  RentalRecord _serverRecord(RentalResponse row) => RentalRecord(
    item: _itemForRental(row),
    start: row.rentedAt,
    due: row.dueAt,
    returnedAt: row.returnedAt,
    student: currentUserName,
    studentId: currentUserId,
    studentNumber: currentUserStudentNumber,
    serverManaged: true,
    serverReturnPending: row.status == ServerRentalStatus.returnRequested,
  );

  final List<RentalItem> _items;
  final List<RentalRecord> rentals = [];

  String currentUserId = '';
  String currentUserName = '';
  String currentUserStudentNumber = '';
  final List<DemoRequest> requests = [];
  final Map<int, RentalItem> _localItems = {};
  final Map<int, int> _stockAdjustments = {};
  int _nextLocalId = -1;

  List<RentalRecord> get allActiveRentals =>
      rentals.where((rental) => rental.isActive).toList();
  List<DemoRequest> get pendingRequests => requests
      .where((request) => request.status == RequestStatus.pending)
      .toList();

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
        studentNumber: request.studentNumber,
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

  List<RentalRecord> get activeRentals => usesServerRentals
      ? _orderedServerRentals
            .where(
              (row) =>
                  row.status == ServerRentalStatus.rented ||
                  row.status == ServerRentalStatus.returnRequested,
            )
            .map(_serverRecord)
            .toList(growable: false)
      : rentals
            .where(
              (rental) => rental.isActive && rental.studentId == currentUserId,
            )
            .toList(growable: false);

  List<RentalRecord> get history => usesServerRentals
      ? _orderedServerRentals
            .where((row) => row.status == ServerRentalStatus.returned)
            .map(_serverRecord)
            .toList(growable: false)
      : rentals
            .where(
              (rental) => !rental.isActive && rental.studentId == currentUserId,
            )
            .toList(growable: false);

  List<DemoRequest> get myRequests => usesServerRentals
      ? _orderedServerRentals.map(_serverRequest).toList(growable: false)
      : requests
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
    } catch (_) {
      if (_disposed) return;
      errorMessage =
          '백엔드와 연결할 수 없습니다. '
          '주소와 실행 상태를 확인한 뒤 다시 시도해 주세요.';
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  int available(RentalItem item) {
    final remaining =
        item.initialAvailable +
        (_stockAdjustments[item.id] ?? 0) -
        rentals
            .where((rental) => rental.isActive && rental.item.id == item.id)
            .length;
    // Server snapshots can change while rentals are still local. Never expose
    // negative stock or permit an approval based on an out-of-range value.
    return remaining.clamp(0, item.total);
  }

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
        studentNumber: currentUserStudentNumber,
        student: currentUserName,
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
    _disposed = true;
    noticeStore.removeListener(notifyListeners);
    noticeStore.dispose();
    _api?.close();
    super.dispose();
  }
}
