import 'package:flutter/material.dart';

import 'app_user.dart';
import 'item_model.dart';
import 'item_store.dart';
import 'notice_store.dart';
import 'product_visual.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({
    super.key,
    required this.user,
    required this.store,
    required this.onItems,
    required this.onItem,
    required this.onRentals,
    required this.onProfile,
    required this.onNotices,
    required this.onNotice,
  });

  final AppUser user;
  final ItemStore store;
  final VoidCallback onItems, onProfile, onNotices;
  final ValueChanged<RentalItem> onItem;
  final ValueChanged<int> onRentals;
  final ValueChanged<AppNotice> onNotice;

  static const purple = Color(0xFF6654D9);
  static const ink = Color(0xFF17203E);

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final active = store.activeRentals;
    final toReturn = active.where((r) => !r.isReturnPending).toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    final nearest = toReturn.isEmpty ? null : toReturn.first;
    final dueSoon = toReturn.where((r) {
      final days = dateOnly(r.due).difference(today).inDays;
      return days >= 0 && days <= 1;
    }).length;
    final pending = store.myRequests
        .where((r) => r.status == RequestStatus.pending)
        .length;
    final available = store.items
        .where((item) => store.available(item) > 0)
        .take(6)
        .toList();
    final featured = store.noticeStore.featured;
    final notices = [
      ?featured,
      ...store.noticeStore.notices.where((n) => n.id != featured?.id),
    ].take(3).toList();

    return RefreshIndicator(
      onRefresh: store.loadItems,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5550B6), Color(0xFF8D7CDE)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CYCIRENTAL  ·  학생',
                        style: TextStyle(
                          color: Color(0xFFE4DFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${user.name}님',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '대여 일정을 확인하세요.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: '프로필 보기',
                  onPressed: onProfile,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEEE9FF),
                  ),
                  icon: const Icon(Icons.person_outline_rounded, color: purple),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _heading(context, '나의 대여 현황'),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric(
                '승인 대기',
                pending,
                Icons.pending_actions_outlined,
                const Color(0xFF6654D9),
                const Color(0xFFEEE9FF),
                () => onRentals(0),
                'student-pending',
              ),
              const SizedBox(width: 8),
              _metric(
                '대여 중',
                active.length,
                Icons.inventory_2_outlined,
                const Color(0xFF248B78),
                const Color(0xFFE4F3EE),
                () => onRentals(1),
                'student-active',
              ),
              const SizedBox(width: 8),
              _metric(
                '반납 임박',
                dueSoon,
                Icons.event_available_outlined,
                const Color(0xFFB56B35),
                const Color(0xFFFFEEDD),
                () => onRentals(1),
                'student-due',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _heading(context, '다음 반납일')),
              TextButton(
                onPressed: () => onRentals(1),
                child: const Text('내 대여 보기 ›'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              key: const Key('student-next-return'),
              borderRadius: BorderRadius.circular(17),
              onTap: () =>
                  nearest == null && active.isEmpty ? onItems() : onRentals(1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: nearest == null
                    ? Row(
                        children: [
                          const Icon(
                            Icons.event_note_outlined,
                            color: purple,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              active.isEmpty
                                  ? '대여 중인 물품이 없습니다.\n필요한 물품을 찾아보세요.'
                                  : '반납 요청이 접수됐습니다.\n관리자 확인을 기다려 주세요.',
                              style: const TextStyle(height: 1.6, fontSize: 13),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      )
                    : Row(
                        children: [
                          ProductVisual(
                            item: nearest.item,
                            width: 56,
                            height: 52,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nearest.item.name,
                                  style: const TextStyle(
                                    color: ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateText(nearest.due),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dueLabel(nearest.due, today),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: dateOnly(nearest.due).isBefore(today)
                                        ? const Color(0xFFC54B65)
                                        : purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: purple,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Material(
            color: const Color(0xFFEFECFB),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: const Key('student-find-items'),
              onTap: onItems,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: purple),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '필요한 물품 찾아보기',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: purple, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _heading(context, '대여 가능한 물품')),
              TextButton(
                key: const Key('student-all-items'),
                onPressed: onItems,
                child: const Text('전체 보기 ›'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (store.isLoading && store.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (store.errorMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('물품 목록을 불러오지 못했습니다.'),
                    TextButton(
                      onPressed: store.loadItems,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          else if (available.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('현재 대여 가능한 물품이 없습니다.'),
              ),
            )
          else
            SizedBox(
              height: 205,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: available.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = available[index];
                  return SizedBox(
                    width: 146,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () => onItem(item),
                        borderRadius: BorderRadius.circular(17),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductVisual(item: item, width: 122, height: 86),
                              const SizedBox(height: 12),
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '대여 가능 ${store.available(item)}${item.unit}',
                                style: const TextStyle(
                                  color: purple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _heading(context, '공지사항')),
              TextButton(
                key: const Key('student-all-notices'),
                onPressed: onNotices,
                child: const Text('전체 보기 ›'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (notices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('등록된 공지사항이 없습니다.'),
              ),
            ),
          for (final notice in notices)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  notice.isImportant
                      ? Icons.push_pin_outlined
                      : Icons.campaign_outlined,
                  color: purple,
                ),
                title: Text(
                  notice.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  dateText(notice.updatedAt),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onNotice(notice),
              ),
            ),
        ],
      ),
    );
  }

  String _dueLabel(DateTime due, DateTime today) {
    final days = dateOnly(due).difference(today).inDays;
    if (days < 0) return '반납 예정일이 지났습니다.';
    if (days == 0) return '오늘 반납 예정';
    if (days == 1) return '내일 반납 예정';
    return '반납까지 $days일';
  }

  Widget _heading(BuildContext context, String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: ink, fontSize: 18, fontWeight: FontWeight.w800),
  );

  Widget _metric(
    String label,
    int count,
    IconData icon,
    Color color,
    Color background,
    VoidCallback onTap,
    String key,
  ) => Expanded(
    child: Material(
      key: Key(key),
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 15),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$count건',
                  style: TextStyle(
                    color: color,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
