import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_user.dart';
import 'item_store.dart';
import 'product_visual.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({
    super.key,
    required this.store,
    required this.user,
    required this.onItems,
    required this.onRequests,
    required this.onReturns,
    required this.onRegister,
    required this.onNotice,
    required this.onAccounts,
    required this.onViewAll,
    required this.onRecovery,
    required this.onRecoveryRetry,
    required this.recoveryCount,
    required this.recoveryLoading,
    required this.recoveryError,
    required this.recoveryAvailable,
    required this.onActive,
    required this.onOverdue,
    required this.onApprove,
    required this.onReject,
    required this.onConfirmReturn,
  });

  final int? recoveryCount;
  final bool recoveryLoading;
  final String? recoveryError;
  final bool recoveryAvailable;
  final VoidCallback onRecovery, onRecoveryRetry;
  final ItemStore store;
  final AppUser user;
  final VoidCallback onItems, onRequests, onReturns, onRegister;
  final VoidCallback onNotice, onAccounts, onViewAll, onActive, onOverdue;
  final ValueChanged<DemoRequest> onApprove, onReject;
  final ValueChanged<RentalRecord> onConfirmReturn;

  static const purple = Color(0xFF6654D9);
  static const ink = Color(0xFF17203E);

  @override
  Widget build(BuildContext context) {
    final active = store.allActiveRentals;
    final returns = active.where((r) => r.isReturnPending).toList();
    final overdue = active
        .where((r) => dateOnly(r.due).isBefore(dateOnly(DateTime.now())))
        .length;
    final completed = store.rentals.where((r) => !r.isActive).length;
    final recent = <({DateTime at, Widget row})>[
      for (final request in store.pendingRequests)
        (at: request.requestedAt, row: _requestRow(request)),
      for (final rental in returns)
        (at: rental.returnRequestedAt!, row: _returnRow(rental)),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF49469E), Color(0xFF9B8AE9)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -10,
                bottom: -22,
                child: Icon(
                  Icons.apartment_rounded,
                  size: 155,
                  color: Color(0x30FFFFFF),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CYCIRENTAL  ·  관리자',
                      style: TextStyle(
                        color: Color(0xFFDFDAFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${user.name}님, 안녕하세요!',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '대여 신청과 반납 요청을 확인하고\n학과 물품을 관리하세요.',
                      style: TextStyle(color: Colors.white, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _heading(context, '운영 현황'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metric(
                '승인 대기',
                store.pendingRequests.length,
                Icons.fact_check_outlined,
                const Color(0xFF4161EB),
                const Color(0xFFEAF0FF),
                onRequests,
                constraints.maxWidth,
              ),
              _metric(
                '반납 요청',
                returns.length,
                Icons.sync_rounded,
                const Color(0xFF8851D7),
                const Color(0xFFF0E9FF),
                onReturns,
                constraints.maxWidth,
              ),
              _metric(
                '대여 중',
                active.length,
                Icons.inventory_2_outlined,
                const Color(0xFF07977A),
                const Color(0xFFE1F3EF),
                onActive,
                constraints.maxWidth,
              ),
              _metric(
                '반납 지연',
                overdue,
                Icons.warning_amber_rounded,
                const Color(0xFFD34D6A),
                const Color(0xFFFDEBF0),
                onOverdue,
                constraints.maxWidth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: _heading(context, '처리할 요청')),
            TextButton(onPressed: onViewAll, child: const Text('전체 보기 ›')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _requestShortcut(
              '대여 신청',
              '${store.pendingRequests.length}건',
              Icons.fact_check_outlined,
              onRequests,
              key: const Key('admin-rental-summary'),
            ),
            const SizedBox(width: 8),
            _requestShortcut(
              '반납 요청',
              '${returns.length}건',
              Icons.assignment_return_outlined,
              onReturns,
              key: const Key('admin-return-summary'),
            ),
            const SizedBox(width: 8),
            _requestShortcut(
              '비밀번호\n초기화',
              recoveryLoading
                  ? '조회 중…'
                  : recoveryError != null || recoveryCount == null
                  ? '—'
                  : recoveryCount! >= 100
                  ? '100+건'
                  : '${recoveryCount!}건',
              Icons.lock_reset_rounded,
              onRecovery,
              key: const Key('admin-recovery-summary'),
            ),
          ],
        ),
        if (recoveryError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '초기화 요청을 불러오지 못했습니다.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: onRecoveryRetry,
                  child: const Text('다시 조회'),
                ),
              ],
            ),
          ),
        if (!recoveryAvailable)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '비밀번호 초기화 요청은 관리자 로그인 후 확인할 수 있습니다.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          '최근 대여·반납 요청',
          style: TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('현재 처리할 대여·반납 요청이 없습니다.'),
                ),
              for (var i = 0; i < math.min(recent.length, 5); i++) ...[
                if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                recent[i].row,
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _heading(context, '빠른 관리'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shortcut('물품 등록', Icons.add_box_outlined, onRegister),
            const SizedBox(width: 8),
            _shortcut('물품 관리', Icons.edit_outlined, onItems),
            const SizedBox(width: 8),
            _shortcut('공지 작성', Icons.campaign_outlined, onNotice),
            const SizedBox(width: 8),
            _shortcut(
              '계정 지원',
              Icons.manage_accounts_outlined,
              onAccounts,
              key: const Key('admin-account-support'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(context, '대여 현황 요약'),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _SummaryPainter([
                                active.length - overdue,
                                completed,
                                overdue,
                              ]),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '총 대여',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${active.length + completed}건',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        children: [
                          _legend(
                            '정상 대여 중',
                            active.length - overdue,
                            const Color(0xFF5275F2),
                          ),
                          const SizedBox(height: 12),
                          _legend('반납 완료', completed, const Color(0xFF67CFB1)),
                          const SizedBox(height: 12),
                          _legend('반납 지연', overdue, const Color(0xFFF07884)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _requestShortcut(
    String title,
    String count,
    IconData icon,
    VoidCallback onTap, {
    Key? key,
  }) => Expanded(
    child: Material(
      key: key,
      color: const Color(0xFFF0EDFD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: purple, size: 23),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 24,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      count,
                      style: const TextStyle(
                        color: purple,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _heading(BuildContext context, String text) => Text(
    text,
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
    double width,
  ) => SizedBox(
    width: (width - 10) / 2,
    child: Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$count건',
                        style: const TextStyle(
                          color: ink,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _requestRow(DemoRequest request) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Row(
          children: [
            ProductVisual(item: request.item, width: 52, height: 46),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${request.studentLabel} · 대여 신청',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            _badge('승인 대기', const Color(0xFFB16A2D), const Color(0xFFFFF0DE)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              key: ValueKey(
                'dashboard-approve-${request.studentId}-${request.item.id}',
              ),
              onPressed: () => onApprove(request),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('승인'),
            ),
            TextButton.icon(
              onPressed: () => onReject(request),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('거절'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _returnRow(RentalRecord rental) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Row(
          children: [
            ProductVisual(item: rental.item, width: 52, height: 46),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rental.item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${rental.studentLabel} · 반납 요청',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            _badge('반납 확인', const Color(0xFF4161EB), const Color(0xFFEAF0FF)),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => onConfirmReturn(rental),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('완료'),
          ),
        ),
      ],
    ),
  );

  Widget _badge(String text, Color color, Color background) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );

  Widget _shortcut(
    String label,
    IconData icon,
    VoidCallback onTap, {
    Key? key,
  }) => Expanded(
    child: Material(
      key: key,
      color: const Color(0xFFF1EFFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: purple, size: 27),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _legend(String label, int count, Color color) => Row(
    children: [
      Icon(Icons.circle, size: 8, color: color),
      const SizedBox(width: 7),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      Text(
        '$count건',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _SummaryPainter extends CustomPainter {
  const _SummaryPainter(this.counts);
  final List<int> counts;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(7);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawOval(ring, paint..color = const Color(0xFFEDEBF7));
    final total = counts.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return;
    const colors = [Color(0xFF5275F2), Color(0xFF67CFB1), Color(0xFFF07884)];
    var start = -math.pi / 2;
    for (var i = 0; i < counts.length; i++) {
      final sweep = counts[i] / total * 2 * math.pi;
      canvas.drawArc(ring, start, sweep, false, paint..color = colors[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _SummaryPainter oldDelegate) => List.generate(
    counts.length,
    (i) => counts[i] != oldDelegate.counts[i],
  ).any((changed) => changed);
}
