import 'package:flutter/material.dart';

import 'demo_auth.dart';
import 'notice_store.dart';

String noticeDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

void showNotice(BuildContext context, AppNotice notice) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(notice.displayTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '수정 ${noticeDate(notice.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(notice.body),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key, required this.store});
  final NoticeStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('공지사항')),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, _) => store.notices.isEmpty
          ? const Center(child: Text('등록된 공지사항이 없습니다.'))
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: store.notices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notice = store.notices[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      notice.isImportant
                          ? Icons.push_pin_outlined
                          : Icons.campaign_outlined,
                    ),
                    title: Text(
                      notice.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(noticeDate(notice.updatedAt)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showNotice(context, notice),
                  ),
                );
              },
            ),
    ),
  );
}

class AdminNoticesPanel extends StatelessWidget {
  const AdminNoticesPanel({super.key, required this.store, required this.user});
  final NoticeStore store;
  final AppUser user;

  void edit(BuildContext context, [AppNotice? notice]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoticeEditor(store: store, user: user, notice: notice),
      ),
    );
  }

  Future<void> delete(BuildContext context, AppNotice notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지 삭제'),
        content: Text('${notice.title} 공지를 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final removed = store.delete(notice, actor: user);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(removed ? '공지를 삭제했습니다. (임시)' : '공지 상태와 권한을 확인해 주세요.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!user.isAdmin) return const Center(child: Text('관리자만 공지를 관리할 수 있습니다.'));
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () => edit(context),
            icon: const Icon(Icons.add),
            label: const Text('공지 작성'),
          ),
          const SizedBox(height: 10),
          const Text(
            '공지 변경은 현재 앱에만 임시 반영됩니다. DB 저장은 API 연결 후 제공됩니다.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (store.notices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('등록된 공지사항이 없습니다.'),
              ),
            ),
          for (final notice in store.notices)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '수정 ${noticeDate(notice.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notice.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => showNotice(context, notice),
                          child: const Text('미리보기'),
                        ),
                        TextButton(
                          key: ValueKey('edit-notice-${notice.id}'),
                          onPressed: () => edit(context, notice),
                          child: const Text('수정'),
                        ),
                        TextButton(
                          key: ValueKey('delete-notice-${notice.id}'),
                          onPressed: () => delete(context, notice),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NoticeEditor extends StatefulWidget {
  const NoticeEditor({
    super.key,
    required this.store,
    required this.user,
    this.notice,
  });
  final NoticeStore store;
  final AppUser user;
  final AppNotice? notice;
  @override
  State<NoticeEditor> createState() => _NoticeEditorState();
}

class _NoticeEditorState extends State<NoticeEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController body;
  late bool important;
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.notice?.title ?? '');
    body = TextEditingController(text: widget.notice?.body ?? '');
    important = widget.notice?.isImportant ?? false;
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.notice == null ? '공지 작성' : '공지 수정')),
    body: !widget.user.isAdmin
        ? const Center(child: Text('관리자 계정으로 로그인해 주세요.'))
        : Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                TextFormField(
                  key: const Key('notice-title'),
                  controller: title,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: '공지 제목'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '제목을 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('중요 공지'),
                  subtitle: const Text('홈에서 일반 공지보다 먼저 표시합니다.'),
                  value: important,
                  onChanged: (value) => setState(() => important = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('notice-body'),
                  controller: body,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: 5000,
                  decoration: const InputDecoration(labelText: '공지 내용'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '내용을 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  '현재는 임시 저장입니다. 실제 DB에 저장되지 않습니다.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (!form.currentState!.validate()) return;
                    final saved = widget.store.save(
                      actor: widget.user,
                      original: widget.notice,
                      title: title.text,
                      body: body.text,
                      isImportant: important,
                    );
                    if (saved) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('공지 내용과 권한을 확인해 주세요.')),
                      );
                    }
                  },
                  child: const Text('임시 저장'),
                ),
              ],
            ),
          ),
  );
}
