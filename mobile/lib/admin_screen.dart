import 'package:flutter/material.dart';

import 'item_model.dart';
import 'item_store.dart';
import 'demo_auth.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.store, required this.user});
  final AppUser user;
  final ItemStore store;
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int tab = 0;
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => !widget.user.isAdmin
        ? Scaffold(
            appBar: AppBar(title: const Text('접근 제한')),
            body: const Center(child: Text('관리자 계정으로 로그인해 주세요.')),
          )
        : Scaffold(
            appBar: AppBar(title: const Text('관리자 모드')),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Text(
                    '관리자 임시 기능 · 서버에 저장되지 않습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: switch (tab) {
                    0 => dashboard(),
                    1 => items(),
                    2 => requests(),
                    _ => returns(),
                  },
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (value) => setState(() => tab = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
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

  Widget dashboard() {
    final overdue = store.allActiveRentals
        .where(
          (rental) => dateOnly(rental.due).isBefore(dateOnly(DateTime.now())),
        )
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('학과 대여 관리', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        metric(
          '등록 물품',
          '${store.items.length}종',
          Icons.inventory_2_outlined,
          1,
        ),
        metric(
          '승인 대기',
          '${store.pendingRequests.length}건',
          Icons.pending_actions,
          2,
        ),
        metric(
          '대여 중',
          '${store.allActiveRentals.length}건',
          Icons.assignment_outlined,
          3,
        ),
        metric('반납 지연', '$overdue건', Icons.warning_amber_rounded, 3),
        const SizedBox(height: 16),
        const Text(
          '학생의 대여 신청을 승인하면 대여가 시작됩니다. 승인 전에는 물품을 이용할 수 없습니다.\n실제 서비스에서는 관리자 권한 인증과 서버 연결이 필요합니다.',
        ),
      ],
    );
  }

  Widget metric(String title, String value, IconData icon, int destination) =>
      Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(value),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => tab = destination),
        ),
      );

  Widget items() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
    children: [
      for (final item in store.items)
        Card(
          child: ListTile(
            title: Text(item.name),
            subtitle: Text(
              '${item.category} · ${item.location}\n전체 ${item.total}${item.unit} / 대여 가능 ${store.available(item)}${item.unit}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: '${item.name} 수정',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => editItem(item),
            ),
          ),
        ),
    ],
  );

  Widget requests() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (store.pendingRequests.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('승인 대기 신청이 없습니다.'),
          ),
        ),
      for (final request in store.requests)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${request.student} · ${request.studentId}'),
                Text('반납 예정 ${dateText(request.due)}'),
                if (request.rejectionReason != null)
                  Text('거절 사유: ${request.rejectionReason}'),
                const SizedBox(height: 8),
                if (request.status == RequestStatus.pending)
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () {
                          if (store.approveRequest(request)) {
                            message('대여를 승인했습니다.');
                          } else {
                            message('재고와 반납일을 확인해 주세요. 신청일 기준 최대 14일입니다.');
                          }
                        },
                        child: const Text('승인'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final reason = await showDialog<String>(
                            context: context,
                            builder: (_) => const _RejectionDialog(),
                          );
                          if (!mounted || reason == null) return;
                          if (store.rejectRequest(request, reason: reason)) {
                            message('신청을 거절했습니다.');
                          } else {
                            message('신청 상태와 거절 사유를 확인해 주세요.');
                          }
                        },
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
    ],
  );

  Widget returns() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (store.allActiveRentals.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('대여 중인 물품이 없습니다.'),
          ),
        ),
      for (final rental in store.allActiveRentals)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rental.item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${rental.student} · ${rental.studentId}'),
                Text('반납 예정 ${dateText(rental.due)}'),
                if (dateOnly(rental.due).isBefore(dateOnly(DateTime.now())))
                  Text(
                    '반납 지연',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 8),
                if (rental.isReturnPending)
                  Text('반납 요청 ${dateText(rental.returnRequestedAt!)}'),
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
      const SizedBox(height: 16),
      Text('반납 완료', style: Theme.of(context).textTheme.titleMedium),
      for (final rental in store.rentals.where((rental) => !rental.isActive))
        Card(
          child: ListTile(
            title: Text(rental.item.name),
            subtitle: Text(
              '${rental.student} · ${dateText(rental.returnedAt!)}',
            ),
            trailing: const Icon(Icons.check_circle_outline),
          ),
        ),
    ],
  );
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
