import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_api.dart';

class PasswordResetRequestScreen extends StatefulWidget {
  const PasswordResetRequestScreen({super.key, required this.authApi});
  final AuthApi authApi;
  @override
  State<PasswordResetRequestScreen> createState() =>
      _PasswordResetRequestState();
}

class _PasswordResetRequestState extends State<PasswordResetRequestScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final number = TextEditingController();
  bool busy = false;
  bool done = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    number.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.authApi.requestPasswordReset(
        name.text.trim(),
        number.text.trim(),
      );
      if (mounted) setState(() => done = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is AuthApiException ? e.message : '서버에 연결하지 못했습니다.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 76,
      title: const Text(
        '비밀번호 초기화\n요청',
        maxLines: 2,
        softWrap: true,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, height: 1.2),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: done
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('입력한 정보와 일치하는 계정이 있으면\n관리자에게 요청이 전달됩니다.'),
                    const SizedBox(height: 12),
                    const Text(
                      '학과 사무실에서 본인 확인을 받아 주세요.\n\n안내받은 임시 비밀번호는 24시간 동안 사용할 수 있습니다.\n로그인 후 새 비밀번호를 설정해 주세요.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('로그인으로 돌아가기'),
                    ),
                  ],
                )
              : Form(
                  key: form,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        '이름과 학번을 입력해 주세요.\n관리자가 본인 확인 후\n비밀번호 초기화를 도와드립니다.',
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('reset-name'),
                        controller: name,
                        maxLength: 30,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: '이름'),
                        validator: (v) =>
                            (v?.trim().length ?? 0) < 2 ? '이름을 입력해 주세요.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('reset-student-number'),
                        controller: number,
                        maxLength: 12,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(labelText: '학번'),
                        validator: (v) =>
                            RegExp(r'^(001|[0-9]{6,12})$').hasMatch(v ?? '')
                            ? null
                            : '학번을 숫자 6~12자리로 입력해 주세요.',
                      ),
                      if (error != null)
                        Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const Key('reset-submit'),
                        onPressed: busy ? null : submit,
                        child: Text(busy ? '요청 중...' : '초기화 요청'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    ),
  );
}

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({
    super.key,
    required this.authApi,
    required this.token,
    required this.onChanged,
    required this.onLogout,
  });
  final AuthApi authApi;
  final String token;
  final ValueChanged<AuthSession> onChanged;
  final VoidCallback onLogout;
  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeState();
}

class _PasswordChangeState extends State<PasswordChangeScreen> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final session = await widget.authApi.changePassword(
        widget.token,
        current.text,
        next.text,
      );
      if (session.mustChangePassword) {
        throw const AuthApiException('비밀번호 변경이 완료되지 않았습니다.');
      }
      if (mounted) widget.onChanged(session);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is AuthApiException ? e.message : '서버에 연결하지 못했습니다.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('새 비밀번호 설정'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('계정을 보호하기 위해 임시 비밀번호를 새 비밀번호로 변경해 주세요.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('change-current'),
                    controller: current,
                    obscureText: true,
                    maxLength: 64,
                    decoration: const InputDecoration(labelText: '임시 비밀번호'),
                    validator: (v) =>
                        v == null || v.isEmpty ? '임시 비밀번호를 입력해 주세요.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('change-new'),
                    controller: next,
                    obscureText: true,
                    maxLength: 64,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호',
                      helperText: '8~64자',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty || v.length < 8
                        ? '비밀번호를 8자 이상 입력해 주세요.'
                        : v == current.text
                        ? '다른 새 비밀번호를 입력해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('change-confirm'),
                    controller: confirm,
                    obscureText: true,
                    maxLength: 64,
                    decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
                    validator: (v) => v != next.text || (v?.isEmpty ?? true)
                        ? '비밀번호가 일치하지 않습니다.'
                        : null,
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('change-submit'),
                    onPressed: busy ? null : submit,
                    child: Text(busy ? '변경 중...' : '비밀번호 변경'),
                  ),
                  TextButton(
                    onPressed: busy ? null : widget.onLogout,
                    child: const Text('로그인으로 돌아가기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AdminRecoveryScreen extends StatefulWidget {
  const AdminRecoveryScreen({
    super.key,
    required this.authApi,
    required this.token,
  });
  final AuthApi authApi;
  final String token;
  @override
  State<AdminRecoveryScreen> createState() => _AdminRecoveryState();
}

class _AdminRecoveryState extends State<AdminRecoveryScreen> {
  List<Map<String, dynamic>> rows = [];
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.authApi.recoveryRequests(widget.token);
      if (mounted) setState(() => rows = result);
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              error = e is AuthApiException ? e.message : '요청 목록을 불러오지 못했습니다.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> process(Map<String, dynamic> row, bool approve) async {
    bool checked = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(approve ? '본인 확인 후 초기화' : '요청 거절'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${row['displayName']} · ${row['studentNumber']}'),
                if (approve)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('학생증 등으로 본인 확인을 완료했습니다.'),
                    value: checked,
                    onChanged: (v) =>
                        setDialogState(() => checked = v ?? false),
                  ),
                if (approve)
                  const Text('기존 로그인은 해제됩니다. 발급된 임시 비밀번호를 본인에게 직접 전달해 주세요.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: approve && !checked
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(approve ? '초기화' : '거절'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.authApi.processRecovery(
        widget.token,
        row['id'] as int,
        approve,
      );
      if (!mounted) return;
      if (result != null) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('임시 비밀번호 발급'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${row['displayName']} · ${row['studentNumber']}'),
                    const SizedBox(height: 12),
                    SelectableText(result['temporaryPassword'] as String),
                    const SizedBox(height: 12),
                    const Text(
                      '이 화면에서만 확인할 수 있습니다. 본인에게 직접 전달해 주세요.\n유효 시간: 24시간\n로그인 후 새 비밀번호 설정이 필요합니다.',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('전달할 비밀번호 확인 완료'),
                ),
              ],
            ),
          ),
        );
      }
      if (mounted) await load();
    } catch (e) {
      // A timeout may follow a successful reset. Refresh before attempting to process again.
      if (mounted) {
        await load();
        if (mounted) {
          setState(
            () => error = e is AuthApiException
                ? e.message
                : '처리 결과를 확인하지 못했습니다. 목록을 새로고침해 주세요. 이미 처리됐다면 다시 요청을 접수해야 합니다.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 76,
      title: const Text(
        '비밀번호 초기화\n요청',
        maxLines: 2,
        softWrap: true,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, height: 1.2),
      ),
      actions: [
        IconButton(
          tooltip: '새로고침',
          onPressed: busy ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('대기 요청을 오래된 순으로 표시합니다.\n반드시 본인 확인 후 처리해 주세요.'),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(error!),
            ),
          if (!busy && error == null && rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('대기 중인 요청이 없습니다.'),
            ),
          for (final row in rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${row['displayName']} · ${row['studentNumber']}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton(
                          onPressed: busy ? null : () => process(row, true),
                          child: const Text('본인 확인 · 초기화'),
                        ),
                        TextButton(
                          onPressed: busy ? null : () => process(row, false),
                          child: const Text('거절'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
