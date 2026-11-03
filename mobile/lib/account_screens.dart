import 'package:flutter/material.dart';

import 'auth_api.dart';
import 'item_store.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.authApi});
  final AuthApi authApi;
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final loginId = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  @override
  void dispose() {
    for (final controller in [name, loginId, email, password, confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool isSubmitting = false;

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => isSubmitting = true);
    try {
      await widget.authApi.signUp(
        loginId: loginId.text.trim(),
        password: password.text,
        displayName: name.text.trim(),
        email: email.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해 주세요.')));
      Navigator.pop(context);
    } on AuthApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(exception.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('서버에 연결하지 못했습니다.')));
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('회원가입')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '학생 계정 만들기',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('입력한 정보는 서버에 전송되어 계정 생성에 사용됩니다.'),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('signup-name'),
                  controller: name,
                  textInputAction: TextInputAction.next,
                  maxLength: 30,
                  decoration: const InputDecoration(labelText: '이름'),
                  validator: (value) => value == null || value.trim().length < 2
                      ? '이름을 2자 이상 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('signup-login-id'),
                  controller: loginId,
                  textInputAction: TextInputAction.next,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    helperText: '영문·숫자·밑줄·하이픈 4~50자',
                  ),
                  validator: (value) =>
                      !RegExp(r'^[a-zA-Z0-9_-]{4,50}$')
                          .hasMatch(value?.trim() ?? '')
                      ? '아이디 형식을 확인해 주세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('signup-email'),
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  maxLength: 255,
                  decoration: const InputDecoration(labelText: '이메일'),
                  validator: (value) =>
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value?.trim() ?? '')
                      ? '올바른 이메일을 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('signup-password'),
                  controller: password,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  maxLength: 64,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    helperText: '8~64자',
                  ),
                  validator: (value) =>
                      value == null || value.length < 8 || value.trim().isEmpty
                      ? '비밀번호를 8자 이상 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('signup-confirm'),
                  controller: confirm,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: '비밀번호 확인'),
                  onFieldSubmitted: (_) => submit(),
                  validator: (value) =>
                      value == null || value.isEmpty || value != password.text
                      ? '비밀번호가 일치하지 않습니다.'
                      : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('signup-submit'),
                  onPressed: isSubmitting ? null : submit,
                  child: Text(isSubmitting ? '가입 처리 중...' : '회원가입'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('로그인으로 돌아가기'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class UsageGuideScreen extends StatelessWidget {
  const UsageGuideScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('이용 안내')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _section(
          context,
          Icons.inventory_2_outlined,
          '대여 신청',
          '물품 목록에서 재고와 보관 장소를 확인하고 반납 예정일을 선택해 신청합니다. 최대 대여 기간은 $maxRentalDays일입니다.',
        ),
        _section(
          context,
          Icons.fact_check_outlined,
          '승인 및 수령',
          '승인 대기 중에는 물품을 이용할 수 없습니다. 관리자가 승인한 뒤 학과 사무실에 수령 방법을 확인해 주세요. 승인 대기 신청은 취소할 수 있습니다.',
        ),
        _section(
          context,
          Icons.assignment_return_outlined,
          '반납',
          '반납 예정일까지 안내받은 장소에 물품을 전달하고 앱에서 반납 요청을 해 주세요. 관리자가 실물 반납을 확인해야 반납 완료로 처리됩니다.',
        ),
        _section(
          context,
          Icons.warning_amber_outlined,
          '일정 변경 및 문제 발생',
          '반납 지연, 고장, 분실 또는 일정 변경이 필요한 경우 학과 사무실에 문의해 주세요. 승인 전 반납 예정일에 도달한 신청은 만료되어 다시 신청해야 합니다.',
        ),
        _section(
          context,
          Icons.campaign_outlined,
          '공지 확인',
          '학과 운영 변경과 물품 이용 안내는 공지사항에서 확인해 주세요.',
        ),
        const SizedBox(height: 12),
        const Text(
          '현재 로그인·공지 관리·대여 신청·반납 처리는 임시 기능입니다. 실제 운영 안내는 학과 공지를 기준으로 확인해 주세요.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );

  Widget _section(
    BuildContext context,
    IconData icon,
    String title,
    String body,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body),
        ],
      ),
    ),
  );
}
