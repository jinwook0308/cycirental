import 'package:flutter/material.dart';

import 'item_model.dart';
import 'admin_dashboard.dart';
import 'product_visual.dart';
import 'item_store.dart';
import 'app_user.dart';
import 'notice_screens.dart';
import 'auth_api.dart';
import 'recovery_screens.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.store,
    required this.user,
    this.authApi,
    this.accessToken,
    this.onLogout,
  });
  final AuthApi? authApi;
  final String? accessToken;
  final VoidCallback? onLogout;
  final AppUser user;
  final ItemStore store;
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;
  final itemSearchController = TextEditingController();
  String itemQuery = '';
  String itemFilter = '전체';
  String requestFilter = '전체';
  String returnFilter = '전체';
  int? recoveryCount;
  bool recoveryLoading = false;
  String? recoveryError;
  int recoveryRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) loadRecoverySummary();
    });
  }

  @override
  void didUpdateWidget(covariant AdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accessToken != widget.accessToken ||
        oldWidget.authApi != widget.authApi ||
        oldWidget.user.isAdmin != widget.user.isAdmin) {
      recoveryRevision++;
      recoveryCount = null;
      recoveryError = null;
      recoveryLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) loadRecoverySummary();
      });
    }
  }

  Future<void> loadRecoverySummary() async {
    if (!mounted || !widget.user.isAdmin) return;
    final api = widget.authApi;
    final token = widget.accessToken;
    if (api == null || token == null) return;
    final revision = ++recoveryRevision;
    setState(() {
      recoveryLoading = true;
      recoveryError = null;
    });
    try {
      final rows = await api.recoveryRequests(token);
      if (!mounted ||
          revision != recoveryRevision ||
          widget.accessToken != token) {
        return;
      }
      setState(() {
        recoveryCount = rows.length;
        recoveryLoading = false;
      });
    } catch (_) {
      if (!mounted ||
          revision != recoveryRevision ||
          widget.accessToken != token) {
        return;
      }
      setState(() {
        recoveryCount = null;
        recoveryLoading = false;
        recoveryError = '초기화 요청을 불러오지 못했습니다.';
      });
    }
  }

  ItemStore get store => widget.store;

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> confirmReturn(RentalRecord rental) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반납 확인'),
        content: Text(
          '${rental.student}님의 ${rental.item.name}을 받으셨나요? 확인하면 재고에 반영됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('반납 완료'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (store.confirmReturn(rental)) {
      message('반납이 완료되었습니다.');
    } else {
      message('반납 요청 상태를 확인해 주세요.');
    }
  }

  Future<void> editItem([RentalItem? item]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminItemEditor(store: store, item: item),
      ),
    );
  }

  static const blue = Color(0xFF6654D9);

  Future<void> openRecovery() async {
    if (!mounted) return;
    final api = widget.authApi;
    final token = widget.accessToken;
    if (api == null || token == null) {
      message('실제 관리자 계정으로 로그인해 주세요.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminRecoveryScreen(authApi: api, token: token),
      ),
    );
    if (mounted && widget.accessToken == token) await loadRecoverySummary();
  }

  void openAccounts() {
    final account = widget.user;
    final onLogout = widget.onLogout;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: const Text('계정 지원')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '학생 계정 지원',
                style: Theme.of(routeContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('비밀번호 초기화 요청을 확인하고 본인 확인 후 처리합니다.'),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.lock_reset_rounded, color: blue),
                  title: const Text('비밀번호 초기화 요청'),
                  subtitle: const Text('대기 요청 확인 · 승인 · 거절'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: openRecovery,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '로그인한 관리자',
                style: Theme.of(routeContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text(account.name),
                  subtitle: Text('학번 · ${account.studentNumber ?? '학번 미등록'}'),
                ),
              ),
              if (onLogout != null)
                TextButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('로그아웃'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    itemSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([store, store.noticeStore]),
    builder: (context, _) => !widget.user.isAdmin
        ? Scaffold(
            appBar: AppBar(title: const Text('접근 제한')),
            body: const Center(child: Text('관리자 계정으로 로그인해 주세요.')),
          )
        : Scaffold(
            backgroundColor: const Color(0xFFFAF9FF),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                ['CyciRental', '물품 관리', '대여 승인', '반납 관리', '공지 관리'][tab],
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
              actions: [
                if (widget.onLogout != null)
                  TextButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('로그아웃'),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (store.isLoading) const LinearProgressIndicator(),
                  if (store.errorMessage != null)
                    MaterialBanner(
                      content: const Text(
                        '물품 목록을 새로 불러오지 못했습니다. 기존 정보가 표시될 수 있습니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: store.isLoading ? null : refreshData,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: switch (tab) {
                      0 => dashboard(),
                      1 => items(),
                      2 => requests(),
                      3 => returns(),
                      _ => AdminNoticesPanel(
                        store: store.noticeStore,
                        user: widget.user,
                      ),
                    },
                  ),
                ],
              ),
            ),
            bottomNavigationBar: NavigationBar(
              indicatorColor: const Color(0xFFE6DFFF),
              backgroundColor: Colors.white,
              selectedIndex: tab,
              onDestinationSelected: (value) {
                setState(() {
                  tab = value;
                  if (value == 2) requestFilter = '전체';
                  if (value == 3) returnFilter = '전체';
                });
                if (value == 0) loadRecoverySummary();
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: '현황',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: '물품 관리',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  label: '대여 승인',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_return_outlined),
                  label: '반납 관리',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_outlined),
                  label: '공지 관리',
                ),
              ],
            ),
            floatingActionButton: tab == 1
                ? FloatingActionButton.extended(
                    onPressed: () => editItem(),
                    icon: const Icon(Icons.add),
                    label: const Text('물품 등록'),
                  )
                : null,
          ),
  );

  Widget dashboard() => RefreshIndicator(
    key: const ValueKey('admin-tab-0'),
    onRefresh: refreshData,
    child: AdminDashboard(
      store: store,
      user: widget.user,
      onItems: () => setState(() => tab = 1),
      onRequests: () => openRequests('승인 대기'),
      onReturns: () => openReturns('반납 요청'),
      onActive: () => openReturns('대여 중'),
      onOverdue: () => openReturns('반납 지연'),
      onViewAll: openAllRequests,
      onRegister: () => editItem(),
      onNotice: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              NoticeEditor(store: store.noticeStore, user: widget.user),
        ),
      ),
      onAccounts: openAccounts,
      onApprove: approveRequest,
      onReject: rejectRequest,
      onConfirmReturn: confirmReturn,
      recoveryCount: recoveryCount,
      recoveryLoading: recoveryLoading,
      recoveryError: recoveryError,
      recoveryAvailable: widget.authApi != null && widget.accessToken != null,
      onRecovery: openRecovery,
      onRecoveryRetry: loadRecoverySummary,
    ),
  );

  Future<void> rejectRequest(DemoRequest request) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectionDialog(),
    );
    if (!mounted || reason == null) return;
    message(
      store.rejectRequest(request, reason: reason)
          ? '신청을 거절했습니다.'
          : '신청 상태와 거절 사유를 확인해 주세요.',
    );
  }

  Future<void> refreshData() async {
    store.refreshExpiredRequests();
    await Future.wait([store.loadItems(), loadRecoverySummary()]);
  }

  void openRequests(String filter) => setState(() {
    tab = 2;
    requestFilter = filter;
  });
  void openReturns(String filter) => setState(() {
    tab = 3;
    returnFilter = filter;
  });

  Future<void> openAllRequests() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '처리할 신청 전체 보기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('대여 신청 전체 보기'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, 2),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return_outlined),
              title: const Text('반납 요청 전체 보기'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, 3),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_rounded),
              title: const Text('비밀번호 초기화 요청 보기'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, 4),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 4) {
      await openRecovery();
    } else if (choice == 2) {
      openRequests('전체');
    } else {
      openReturns('반납 요청');
    }
  }

  Future<void> approveRequest(DemoRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대여 승인 확인'),
        content: Text(
          '${request.studentLabel}\n${request.item.name}\n반납 예정 ${dateText(request.due)}\n\n이 신청을 승인하시겠어요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('승인 확정'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    message(
      store.approveRequest(request)
          ? '대여를 승인했습니다.'
          : '재고와 반납일을 확인해 주세요. 신청일 기준 최대 14일입니다.',
    );
  }

  Widget filters(
    List<String> labels,
    String selected,
    ValueChanged<String> onSelected,
    String keyPrefix,
  ) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final label in labels)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: ValueKey('$keyPrefix-$label'),
              label: Text('$label (${filterCount(keyPrefix, label)})'),
              selected: selected == label,
              onSelected: (_) => onSelected(label),
            ),
          ),
      ],
    ),
  );

  int filterCount(String prefix, String label) {
    if (prefix == 'admin-requests') {
      return store.requests
          .where((r) => label == '전체' || requestStatusLabel(r.status) == label)
          .length;
    }
    if (prefix == 'admin-returns') {
      return store.rentals.where((r) => returnMatches(r, label)).length;
    }
    final query = itemQuery.trim().toLowerCase();
    return store.items
        .where(
          (item) =>
              '${item.name} ${item.category} ${item.location}'
                  .toLowerCase()
                  .contains(query) &&
              (label == '전체' ||
                  (label == '대여 가능'
                      ? store.available(item) > 0
                      : store.available(item) < item.total)),
        )
        .length;
  }

  bool returnMatches(RentalRecord rental, String filter) => switch (filter) {
    '반납 요청' => rental.isReturnPending,
    '대여 중' => rental.isActive,
    '반납 지연' =>
      rental.isActive &&
          dateOnly(rental.due).isBefore(dateOnly(DateTime.now())),
    '반납 완료' => !rental.isActive,
    _ => true,
  };

  Widget refreshable(List<Widget> children, {double bottom = 24}) =>
      RefreshIndicator(
        key: ValueKey('admin-tab-$tab'),
        onRefresh: refreshData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
          children: children,
        ),
      );

  Widget empty(String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Text(text)),
  );

  Widget items() {
    final query = itemQuery.trim().toLowerCase();
    final filtered = store.items.where((item) {
      final matches = '${item.name} ${item.category} ${item.location}'
          .toLowerCase()
          .contains(query);
      return matches &&
          (itemFilter == '전체' ||
              (itemFilter == '대여 가능'
                  ? store.available(item) > 0
                  : store.available(item) < item.total));
    }).toList();
    return refreshable([
      TextField(
        key: const Key('admin-item-search'),
        controller: itemSearchController,
        decoration: const InputDecoration(
          hintText: '물품명·카테고리·보관 장소 검색',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) => setState(() => itemQuery = value),
      ),
      const SizedBox(height: 12),
      filters(
        ['전체', '대여 가능', '대여 중'],
        itemFilter,
        (value) => setState(() => itemFilter = value),
        'admin-items',
      ),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        if (store.isLoading)
          empty('물품을 불러오는 중입니다.')
        else if (store.errorMessage != null)
          empty('물품 조회에 실패했습니다. 다시 시도해 주세요.')
        else
          empty(
            query.isNotEmpty || itemFilter != '전체'
                ? '조건에 맞는 물품이 없습니다.'
                : '등록된 물품이 없습니다.',
          ),
      for (final item in filtered)
        Card(
          child: InkWell(
            onTap: () => editItem(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProductVisual(item: item, width: 52, height: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              item.category,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '${item.name} 수정',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => editItem(item),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('보관 장소 ${item.location}'),
                  const SizedBox(height: 6),
                  Text(
                    '전체 ${item.total}${item.unit} · 대여 가능 ${store.available(item)}${item.unit}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
    ], bottom: 100);
  }

  Widget requests() {
    final filtered = store.requests
        .where(
          (request) =>
              requestFilter == '전체' ||
              requestStatusLabel(request.status) == requestFilter,
        )
        .toList();
    return refreshable([
      filters(
        ['전체', '승인 대기', '승인 완료', '거절됨', '취소됨', '만료됨'],
        requestFilter,
        (value) => setState(() => requestFilter = value),
        'admin-requests',
      ),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        empty(
          requestFilter == '전체' ? '대여 신청이 없습니다.' : '$requestFilter 신청이 없습니다.',
        ),
      for (final request in filtered)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProductVisual(item: request.item, width: 52, height: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request.item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(request.studentLabel),
                Text('신청 ${dateTimeLabel(request.requestedAt)}'),
                Text('반납 예정 ${dateText(request.due)}'),
                Text('보관 장소 ${request.item.location}'),
                if (request.rejectionReason != null)
                  Text('거절 사유: ${request.rejectionReason}'),
                const SizedBox(height: 8),
                if (request.status == RequestStatus.pending)
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => approveRequest(request),
                        child: const Text('승인'),
                      ),
                      OutlinedButton(
                        onPressed: () => rejectRequest(request),
                        child: const Text('거절'),
                      ),
                    ],
                  )
                else
                  Text(requestStatusLabel(request.status)),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget returns() {
    final today = dateOnly(DateTime.now());
    final filtered = store.rentals
        .where((rental) => returnMatches(rental, returnFilter))
        .toList();
    final active = filtered.where((rental) => rental.isActive).toList();
    final completed = filtered.where((rental) => !rental.isActive).toList();
    return refreshable([
      filters(
        ['전체', '반납 요청', '대여 중', '반납 지연', '반납 완료'],
        returnFilter,
        (value) => setState(() => returnFilter = value),
        'admin-returns',
      ),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        empty(
          returnFilter == '전체' ? '대여·반납 내역이 없습니다.' : '$returnFilter 내역이 없습니다.',
        ),
      for (final rental in active)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProductVisual(item: rental.item, width: 52, height: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rental.item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(rental.studentLabel),
                Text('대여 시작 ${dateText(rental.start)}'),
                Text('반납 예정 ${dateText(rental.due)}'),
                Text('보관 장소 ${rental.item.location}'),
                if (dateOnly(rental.due).isBefore(today))
                  Text(
                    '반납 지연',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (rental.returnRequestedAt != null)
                  Text('반납 요청 ${dateTimeLabel(rental.returnRequestedAt!)}'),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: rental.isReturnPending
                      ? () => confirmReturn(rental)
                      : null,
                  child: Text(rental.isReturnPending ? '반납 확인' : '학생 반납 요청 대기'),
                ),
              ],
            ),
          ),
        ),
      if (completed.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          '완료된 반납 ${completed.length}건',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final rental in completed)
          Card(
            child: ListTile(
              title: Text(rental.item.name),
              subtitle: Text(
                '${rental.studentLabel} · ${dateText(rental.returnedAt!)}',
              ),
              trailing: const Icon(Icons.check_circle_outline),
            ),
          ),
      ],
    ]);
  }

  String dateTimeLabel(DateTime value) =>
      '${dateText(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class AdminItemEditor extends StatefulWidget {
  const AdminItemEditor({super.key, required this.store, this.item});
  final ItemStore store;
  final RentalItem? item;
  @override
  State<AdminItemEditor> createState() => _AdminItemEditorState();
}

class _AdminItemEditorState extends State<AdminItemEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController location;
  late final TextEditingController total;
  late final TextEditingController available;
  late String category;
  late ProductKind kind;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    name = TextEditingController(text: item?.name ?? '');
    location = TextEditingController(text: item?.location ?? '');
    total = TextEditingController(text: '${item?.total ?? 1}');
    available = TextEditingController(
      text: '${item == null ? 1 : widget.store.available(item)}',
    );
    category = item?.category ?? '전자기기';
    kind = item?.kind ?? ProductKind.laptop;
  }

  @override
  void dispose() {
    for (final controller in [name, location, total, available]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? '내용을 입력해 주세요.' : null;
  String? number(String? value) =>
      int.tryParse(value ?? '') == null || int.parse(value!) < 0
      ? '0 이상의 정수를 입력해 주세요.'
      : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.item == null ? '물품 등록' : '물품 수정')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextFormField(
            key: const Key('admin-item-name'),
            controller: name,
            decoration: const InputDecoration(labelText: '물품명'),
            validator: requiredText,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: location,
            decoration: const InputDecoration(labelText: '보관 장소'),
            validator: requiredText,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: '분류'),
            items: ['전자기기', '촬영/영상', '실험/기타']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => category = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProductKind>(
            initialValue: kind,
            decoration: const InputDecoration(labelText: '물품 그림'),
            items: ProductKind.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(
                      const {
                        ProductKind.desktop: '본체',
                        ProductKind.monitor: '모니터',
                        ProductKind.vr: 'VR 기기',
                        ProductKind.projector: '프로젝터',
                        ProductKind.camera: '카메라',
                        ProductKind.tripod: '삼각대',
                        ProductKind.light: '조명',
                        ProductKind.laptop: '노트북',
                      }[value]!,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => kind = value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: total,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '전체 수량'),
            validator: number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: available,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '대여 가능 수량'),
            validator: number,
          ),
          const SizedBox(height: 12),
          const Text(
            '전체 수량은 1개 이상이어야 합니다. 수정 시 기존 대여 중·사용 불가 수량을 유지하도록 전체 수량과 대여 가능 수량을 함께 조정해 주세요.',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              if (widget.store.saveItem(
                original: widget.item,
                name: name.text,
                location: location.text,
                category: category,
                kind: kind,
                total: int.parse(total.text),
                availableCount: int.parse(available.text),
              )) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('수량을 확인해 주세요. 대여 중·사용 불가 수량은 유지해야 합니다.'),
                  ),
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ),
  );
}

class _RejectionDialog extends StatefulWidget {
  const _RejectionDialog();
  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final form = GlobalKey<FormState>();
  final reason = TextEditingController();
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('신청 거절'),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: TextFormField(
          key: const Key('rejection-reason'),
          controller: reason,
          decoration: const InputDecoration(
            labelText: '거절 사유',
            hintText: '학생에게 안내할 사유를 입력해 주세요.',
          ),
          minLines: 2,
          maxLines: 4,
          maxLength: 300,
          validator: (value) =>
              value == null || value.trim().isEmpty ? '거절 사유를 입력해 주세요.' : null,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, reason.text.trim());
          }
        },
        child: const Text('거절'),
      ),
    ],
  );
}
