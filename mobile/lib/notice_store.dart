import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'demo_auth.dart';

class AppNotice {
  const AppNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.isImportant,
    required this.createdAt,
    required this.updatedAt,
  });
  final int id;
  final String title;
  final String body;
  final bool isImportant;
  final DateTime createdAt;
  final DateTime updatedAt;
  String get displayTitle => isImportant ? '[중요] $title' : title;
}

// Local UI data. Replace these operations with the notice API when available.
class NoticeStore extends ChangeNotifier {
  NoticeStore() {
    final now = DateTime.now();
    _notices.addAll([
      AppNotice(
        id: 1,
        title: '학과 물품 이용 안내',
        body: '대여 신청은 관리자 승인 후 이용할 수 있습니다.\n최대 대여 기간은 14일이며, 반납은 관리자 확인 후 완료됩니다.\n\n이 공지는 화면 확인용 임시 데이터입니다.',
        isImportant: true,
        createdAt: now,
        updatedAt: now,
      ),
      AppNotice(
        id: 2,
        title: '반납 일정 확인 안내',
        body: '내 대여 화면에서 반납 예정일을 확인해 주세요.\n물품을 전달한 뒤 반납 요청을 하고 관리자 확인을 기다려 주세요.\n\n이 공지는 화면 확인용 임시 데이터입니다.',
        isImportant: false,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }

  final List<AppNotice> _notices = [];
  int _nextId = 3;

  UnmodifiableListView<AppNotice> get notices {
    final sorted = List<AppNotice>.of(_notices)
      ..sort((a, b) {
        if (a.isImportant != b.isImportant) return a.isImportant ? -1 : 1;
        final byDate = b.updatedAt.compareTo(a.updatedAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    return UnmodifiableListView(sorted);
  }

  AppNotice? get featured => notices.firstOrNull;

  bool save({
    required AppUser actor,
    AppNotice? original,
    required String title,
    required String body,
    required bool isImportant,
  }) {
    if (!actor.isAdmin ||
        title.trim().isEmpty ||
        title.trim().length > 80 ||
        body.trim().isEmpty ||
        body.trim().length > 5000) {
      return false;
    }
    final index = original == null
        ? -1
        : _notices.indexWhere((notice) => notice.id == original.id);
    if (original != null && index == -1) return false;
    final now = DateTime.now();
    final notice = AppNotice(
      id: original?.id ?? _nextId++,
      title: title.trim(),
      body: body.trim(),
      isImportant: isImportant,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );
    if (original == null) {
      _notices.add(notice);
    } else {
      _notices[index] = notice;
    }
    notifyListeners();
    return true;
  }

  bool delete(AppNotice notice, {required AppUser actor}) {
    if (!actor.isAdmin) return false;
    final before = _notices.length;
    _notices.removeWhere((candidate) => candidate.id == notice.id);
    if (_notices.length == before) return false;
    notifyListeners();
    return true;
  }
}
