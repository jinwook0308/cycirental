import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'item_model.dart';
import 'app_user.dart';
import 'auth_api.dart';
import 'recovery_screens.dart';
import 'admin_screen.dart';
import 'notice_screens.dart';
import 'account_screens.dart';
import 'item_store.dart';
import 'product_visual.dart';
import 'student_dashboard.dart';

void main() => runApp(const DeptRentalApp());

const ink = Color(0xFF17203E);
const primaryBlue = Color(0xFF6654D9);
const lilac = Color(0xFF6C71DC);
const muted = Color(0xFF7182A1);
const line = Color(0xFFDDE6F5);
const page = Color(0xFFFAF9FF);
const ice = Color(0xFFE7F7FF);
const blush = Color(0xFFFFEBEE);
const danger = Color(0xFFE34D5D);

class DeptRentalApp extends StatefulWidget {
  const DeptRentalApp({super.key, this.store, this.authApi});

  final ItemStore? store;
  final AuthApi? authApi;

  @override
  State<DeptRentalApp> createState() => _DeptRentalAppState();
}

class _DeptRentalAppState extends State<DeptRentalApp>
    with WidgetsBindingObserver {
  late final ItemStore store;
  late final bool ownsStore;
  late final AuthApi authApi;
  late final bool ownsAuthApi;
  bool signedIn = false;
  AppUser? user;
  String? accessToken;
  Timer? _expiryTimer;
  StreamSubscription<String>? _sessionExpirySubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ownsStore = widget.store == null;
    store = widget.store ?? ItemStore();
    ownsAuthApi = widget.authApi == null;
    authApi = widget.authApi ?? AuthApi();
    _sessionExpirySubscription = authApi.expiredSessions.listen((token) {
      // A late response from an earlier login must not log out a new session.
      if (mounted && signedIn && token == accessToken) _clearSession();
    });
    _expiryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => store.refreshExpiredRequests(),
    );
    if (ownsStore) unawaited(store.loadItems());
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    unawaited(_sessionExpirySubscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    if (ownsStore) store.dispose();
    if (ownsAuthApi) authApi.close();
    super.dispose();
  }

  void _enter(AppUser account, String? token) {
    setState(() {
      user = account;
      accessToken = token;
      store.currentUserId = account.userId == null
          ? account.id
          : 'user:${account.userId}';
      store.currentUserName = account.name;
      store.currentUserStudentNumber = account.studentNumber ?? '';
      store.refreshExpiredRequests();
      signedIn = true;
    });
  }

  void _clearSession() {
    if (!mounted) return;
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      signedIn = false;
      user = null;
      accessToken = null;
      store.currentUserId = '';
      store.currentUserName = '';
      store.currentUserStudentNumber = '';
    });
  }

  Future<void> _logout() async {
    final token = accessToken;
    _clearSession();
    if (token != null) {
      try {
        await authApi.logout(token);
      } catch (_) {
        // Local logout is complete even if the server is unreachable.
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) store.refreshExpiredRequests();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    title: 'CyciRental',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: page,
      colorScheme: ColorScheme.fromSeed(
        seedColor: user?.isAdmin == true
            ? const Color(0xFF6654D9)
            : primaryBlue,
        primary: user?.isAdmin == true ? const Color(0xFF6654D9) : primaryBlue,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: ink,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: const BorderSide(color: line),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFE9E2FF),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink),
        ),
      ),
    ),
    home: signedIn
        ? user!.mustChangePassword
              ? PasswordChangeScreen(
                  authApi: authApi,
                  token: accessToken!,
                  onChanged: (session) => _enter(
                    AppUser(
                      userId: session.userId,
                      studentNumber: session.studentNumber,
                      id: session.loginId,
                      name: session.displayName,
                      role: session.isAdmin ? UserRole.admin : UserRole.student,
                    ),
                    session.accessToken,
                  ),
                  onLogout: () => unawaited(_logout()),
                )
              : user!.isAdmin
              ? AdminScreen(
                  store: store,
                  user: user!,
                  authApi: authApi,
                  accessToken: accessToken,
                  onLogout: () => unawaited(_logout()),
                )
              : AppShell(
                  store: store,
                  user: user!,
                  authApi: authApi,
                  accessToken: accessToken,
                  onLogout: () => unawaited(_logout()),
                )
        : LoginScreen(authApi: authApi, onEnter: _enter),
  );
}

typedef LoginCallback = void Function(AppUser account, String? accessToken);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onEnter, required this.authApi});
  final LoginCallback onEnter;
  final AuthApi authApi;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final studentNumber = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool isSubmitting = false;

  @override
  void dispose() {
    studentNumber.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (isSubmitting) return;
    setState(() {
      error = null;
      isSubmitting = true;
    });
    try {
      final session = await widget.authApi.login(
        studentNumber.text.trim(),
        password.text,
      );
      if (!mounted) return;
      widget.onEnter(
        AppUser(
          userId: session.userId,
          studentNumber: session.studentNumber,
          mustChangePassword: session.mustChangePassword,
          id: session.loginId,
          name: session.displayName,
          role: session.isAdmin ? UserRole.admin : UserRole.student,
        ),
        session.accessToken,
      );
    } on AuthApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) setState(() => error = '서버에 연결하지 못했습니다.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEE9FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: primaryBlue,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        '학과 물품을\n간편하게 대여하세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'CyciRental',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: primaryBlue,
                        ),
                      ),
                      const Text(
                        '함께 쓰는 물품, 더 나은 내일',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 14),
                      ),
                      const SizedBox(height: 35),
                      TextField(
                        key: const Key('login-id'),
                        keyboardType: TextInputType.number,
                        controller: studentNumber,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          hintText: '학번',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        key: const Key('login-password'),
                        controller: password,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => signIn(),
                        decoration: const InputDecoration(
                          hintText: '비밀번호',
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      PrimaryAction(
                        label: isSubmitting ? '로그인 중...' : '로그인',
                        onPressed: isSubmitting ? null : signIn,
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: danger),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SignupScreen(authApi: widget.authApi),
                              ),
                            ),
                            child: const Text('회원가입'),
                          ),
                          const Text('│', style: TextStyle(color: line)),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PasswordResetRequestScreen(
                                  authApi: widget.authApi,
                                ),
                              ),
                            ),
                            child: const Text('비밀번호 초기화 요청'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: primaryBlue,
      disabledBackgroundColor: const Color(0xFFB9C6DD),
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
    child: Text(label),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.store,
    required this.user,
    required this.onLogout,
    this.authApi,
    this.accessToken,
  });
  final AppUser user;
  final ItemStore store;
  final VoidCallback onLogout;
  final AuthApi? authApi;
  final String? accessToken;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  int rentalTab = 0;
  int rentalRevision = 0;

  void openRentals([int initialTab = 0]) => setState(() {
    tab = 2;
    rentalTab = initialTab;
    rentalRevision++;
  });

  void openAlerts() {
    final store = widget.store;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('알림')),
          body: AnimatedBuilder(
            animation: store,
            builder: (context, _) => AlertsScreen(store: store),
          ),
        ),
      ),
    );
  }

  Future<void> openItem(RentalItem item) async {
    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DetailScreen(item: item, store: widget.store),
      ),
    );
    if (!mounted || booked != true) return;
    openRentals();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('신청이 접수됐습니다. 관리자 승인 후 이용할 수 있습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(
          ['CyciRental', '물품 목록', '내 대여 현황', '설정'][tab],
          style: const TextStyle(fontFamily: 'Roboto'),
        ),
        actions: [
          IconButton(
            tooltip: '알림 보기',
            onPressed: openAlerts,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: tab,
          children: [
            HomeScreen(
              store: widget.store,
              openItem: openItem,
              openItems: () => setState(() => tab = 1),
              openRentals: openRentals,
              onRentalTab: openRentals,
              openAlerts: openAlerts,
              user: widget.user,
            ),
            ItemsScreen(store: widget.store, openItem: openItem),
            RentalsScreen(
              key: ValueKey('student-rentals-$rentalTab-$rentalRevision'),
              store: widget.store,
              initialIndex: rentalTab,
            ),
            SettingsScreen(
              store: widget.store,
              user: widget.user,
              onLogout: widget.onLogout,
              authApi: widget.authApi,
              accessToken: widget.accessToken,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) {
          if (index == 2) {
            openRentals();
          } else {
            setState(() => tab = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: '물품',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: '내 대여',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '설정',
          ),
        ],
      ),
    ),
  );
}

class _ItemsLoadingView extends StatelessWidget {
  const _ItemsLoadingView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 14),
        Text('물품 정보를 불러오는 중입니다.', style: TextStyle(color: muted)),
      ],
    ),
  );
}

class _ItemsErrorView extends StatelessWidget {
  const _ItemsErrorView({required this.store});

  final ItemStore store;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: danger, size: 42),
          const SizedBox(height: 12),
          Text(
            store.errorMessage ?? '물품 정보를 불러올 수 없습니다.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: ink, height: 1.5),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: store.loadItems,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.store,
    required this.openItem,
    required this.openItems,
    required this.openRentals,
    required this.openAlerts,
    this.onRentalTab,
  });
  final AppUser user;
  final ItemStore store;
  final ValueChanged<RentalItem> openItem;
  final VoidCallback openItems, openRentals, openAlerts;
  final ValueChanged<int>? onRentalTab;

  @override
  Widget build(BuildContext context) => StudentDashboard(
    user: user,
    store: store,
    onItem: openItem,
    onItems: openItems,
    onRentals: onRentalTab ?? (_) => openRentals(),
    onProfile: () =>
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ProfileScreen(user: user))),
    onNotices: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoticesScreen(store: store.noticeStore),
      ),
    ),
    onNotice: (notice) => showNotice(context, notice),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.action,
    this.onPressed,
  });
  final String title;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onPressed,
          child: Text(
            '$action  ›',
            style: const TextStyle(fontSize: 12, color: primaryBlue),
          ),
        ),
    ],
  );
}

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key, required this.store, required this.openItem});
  final ItemStore store;
  final ValueChanged<RentalItem> openItem;

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final search = TextEditingController();
  String query = '';
  String category = '전체';
  bool onlyAvailable = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final categories = [
      '전체',
      ...store.items.map((item) => item.category).toSet(),
    ];
    final selectedCategory = categories.contains(category) ? category : '전체';
    final visible = store.items
        .where(
          (item) =>
              '${item.name} ${item.category} ${item.location}'
                  .toLowerCase()
                  .contains(query.trim().toLowerCase()) &&
              (selectedCategory == '전체' || item.category == selectedCategory) &&
              (!onlyAvailable || store.available(item) > 0),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: TextField(
            key: const Key('item-search'),
            controller: search,
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: '물품명·카테고리·보관 장소 검색',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('item-search-clear'),
                      tooltip: '검색어 지우기',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        search.clear();
                        setState(() => query = '');
                      },
                    ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Tooltip(
                message: '대여 가능 물품만 보기',
                child: FilterChip(
                  key: const Key('student-available-only'),
                  label: const Text('대여 가능만'),
                  selected: onlyAvailable,
                  onSelected: (value) => setState(() => onlyAvailable = value),
                ),
              ),
              const SizedBox(width: 8),
              for (final value in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(value),
                    selected: selectedCategory == value,
                    onSelected: (_) => setState(() => category = value),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              store.isLoading && store.items.isEmpty
                  ? '물품 조회 중…'
                  : store.errorMessage != null && store.items.isEmpty
                  ? '물품 조회 실패'
                  : '${visible.length}개 물품',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: store.loadItems,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              children: [
                if (store.isLoading && store.items.isEmpty)
                  const SizedBox(height: 230, child: _ItemsLoadingView())
                else if (store.errorMessage != null && store.items.isEmpty)
                  SizedBox(height: 260, child: _ItemsErrorView(store: store))
                else ...[
                  if (store.errorMessage != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            const Text('물품을 새로 불러오지 못했습니다. 이전 정보가 표시됩니다.'),
                            TextButton(
                              onPressed: store.loadItems,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          '검색 결과가 없습니다.',
                          style: TextStyle(color: muted),
                        ),
                      ),
                    ),
                  for (final item in visible)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => widget.openItem(item),
                        borderRadius: BorderRadius.circular(17),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ProductVisual(
                                    item: item,
                                    width: 64,
                                    height: 60,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            color: ink,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          item.category,
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: primaryBlue,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '보관 장소 ${item.location}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  AvailabilityPill(
                                    available: store.available(item),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '대여 가능 ${store.available(item)} / ${item.total}${item.unit}',
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({super.key, required this.available});
  final int available;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: available > 0 ? ice : blush,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      available > 0 ? '대여 가능' : '대여 불가',
      style: TextStyle(
        color: available > 0 ? ink : danger,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.item, required this.store});
  final RentalItem item;
  final ItemStore store;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late DateTime due = dateOnly(DateTime.now()).add(const Duration(days: 3));

  Future<void> _chooseDue() async {
    final today = dateOnly(DateTime.now());
    final first = today.add(const Duration(days: 1));
    final last = latestReturnDate(today);
    final initial = due.isBefore(first)
        ? first
        : (due.isAfter(last) ? last : due);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (selected != null && mounted) setState(() => due = selected);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final item =
          widget.store.items
              .where((candidate) => candidate.id == widget.item.id)
              .firstOrNull ??
          widget.item;
      final count = widget.store.available(item);
      final pending = widget.store.myRequests.any(
        (request) =>
            request.item.id == item.id &&
            request.status == RequestStatus.pending,
      );
      return Scaffold(
        appBar: AppBar(title: const Text('물품 상세')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            ProductVisual(item: item, width: double.infinity, height: 190),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AvailabilityPill(available: count),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: const TextStyle(color: muted, height: 1.6, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  children: [
                    InfoLine(
                      icon: Icons.category_outlined,
                      title: '카테고리',
                      value: item.category,
                    ),
                    const Divider(height: 22, color: line),
                    InfoLine(
                      icon: Icons.inventory_2_outlined,
                      title: '전체 수량',
                      value: '${item.total} ${item.unit}',
                    ),
                    const Divider(height: 22, color: line),
                    InfoLine(
                      icon: Icons.lock_open_outlined,
                      title: '대여 가능 수량',
                      value: '$count ${item.unit}',
                    ),
                    const Divider(height: 22, color: line),
                    InfoLine(
                      icon: Icons.place_outlined,
                      title: '보관 장소',
                      value: item.location,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  children: [
                    InfoLine(
                      icon: Icons.calendar_today_outlined,
                      title: '신청일',
                      value: dateText(DateTime.now()),
                    ),
                    const Divider(height: 22, color: line),
                    InkWell(
                      onTap: _chooseDue,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '반납 예정일 (최대 14일)',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_outlined,
                                  color: primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dateText(due),
                                    style: const TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: primaryBlue,
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
            ),
            const SizedBox(height: 14),
            const Text(
              '신청 후 관리자 승인이 완료되면 물품을 이용할 수 있습니다.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: line)),
            ),
            child: PrimaryAction(
              label: pending
                  ? '승인 대기 중'
                  : count > 0
                  ? '대여 신청'
                  : '현재 대여 불가',
              onPressed: count > 0 && !pending
                  ? () {
                      if (widget.store.requestRental(item, due)) {
                        Navigator.pop(context, true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '재고·반납일·중복 신청을 확인해 주세요. 최대 대여 기간은 14일입니다.',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ),
        ),
      );
    },
  );
}

class InfoLine extends StatelessWidget {
  const InfoLine({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: ink, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, style: const TextStyle(color: muted, fontSize: 12)),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class RentalsScreen extends StatelessWidget {
  const RentalsScreen({super.key, required this.store, this.initialIndex = 0});
  final ItemStore store;
  final int initialIndex;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    initialIndex: initialIndex,
    length: 3,
    child: Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            labelColor: primaryBlue,
            unselectedLabelColor: muted,
            indicatorColor: primaryBlue,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: '신청 내역 (${store.myUnapprovedRequests.length})'),
              Tab(text: '대여 중 (${store.activeRentals.length})'),
              Tab(text: '대여 내역 (${store.history.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              store.myUnapprovedRequests.isEmpty
                  ? const _EmptyPanel(message: '신청 내역이 없습니다.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(17),
                      itemCount: store.myUnapprovedRequests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) => _RequestCard(
                        request: store.myUnapprovedRequests[index],
                        onCancel: () async {
                          final request = store.myUnapprovedRequests[index];
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('신청 취소'),
                              content: Text(
                                '${request.item.name} 신청을 취소하시겠어요?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('닫기'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('신청 취소'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) store.cancelRequest(request);
                        },
                      ),
                    ),
              store.activeRentals.isEmpty
                  ? const _EmptyPanel(
                      message: '대여 중인 물품이 없습니다.\n물품 목록에서 신청해 보세요.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(17),
                      itemCount: store.activeRentals.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final rental = store.activeRentals[index];
                        return _RentalCard(
                          rental: rental,
                          onReturn: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('반납 요청'),
                                content: Text(
                                  '${rental.item.name}의 반납을 요청하시겠어요? 관리자 확인 후 반납이 완료됩니다.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('반납 요청'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) store.requestReturn(rental);
                          },
                        );
                      },
                    ),
              store.history.isEmpty
                  ? const _EmptyPanel(message: '완료된 대여 내역이 없습니다.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(17),
                      itemCount: store.history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) =>
                          _RentalCard(rental: store.history[index]),
                    ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, this.onCancel});
  final DemoRequest request;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final pending = request.status == RequestStatus.pending;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProductVisual(item: request.item, width: 48, height: 46),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.item.name,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(requestStatusLabel(request.status)),
                  backgroundColor: pending ? const Color(0xFFE7EDFF) : blush,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '신청일  ${dateText(request.requestedAt)}',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            Text(
              '반납 예정일  ${dateText(request.due)}',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              switch (request.status) {
                RequestStatus.pending => '관리자 승인 후 이용할 수 있습니다.',
                RequestStatus.rejected =>
                  '거절 사유: ${request.rejectionReason ?? "사유 없음"}',
                RequestStatus.cancelled => '신청을 취소했습니다.',
                RequestStatus.expired =>
                  '반납 예정일에 도달해 승인 가능 기간이 지났습니다. 다시 신청해 주세요.',
                RequestStatus.approved => '승인되었습니다.',
              },
              style: TextStyle(
                color: pending ? primaryBlue : danger,
                fontSize: 12,
              ),
            ),
            if (pending && onCancel != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('신청 취소'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFFADC3E9),
          size: 56,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.5),
        ),
      ],
    ),
  );
}

class _RentalCard extends StatelessWidget {
  const _RentalCard({required this.rental, this.onReturn});
  final RentalRecord rental;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final remaining = dateOnly(rental.due)
        .difference(dateOnly(DateTime.now()))
        .inDays;
    final status = !rental.isActive
        ? '반납 완료'
        : rental.isReturnPending
        ? '반납 확인 대기'
        : '대여 중';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProductVisual(item: rental.item, width: 56, height: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.item.name,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        rental.item.location,
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: rental.isActive
                    ? const Color(0xFFEEE9FF)
                    : const Color(0xFFE7F4EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '대여일  ${dateText(rental.start)}',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              '반납 예정일  ${dateText(rental.due)}',
              style: const TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (rental.returnedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '반납 완료일  ${dateText(rental.returnedAt!)}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
            if (rental.isActive &&
                !rental.isReturnPending &&
                remaining <= 1) ...[
              const SizedBox(height: 12),
              _ReminderBanner(rental: rental),
            ],
            if (rental.isActive && onReturn != null) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: rental.isReturnPending ? null : onReturn,
                  icon: const Icon(Icons.assignment_return_outlined, size: 18),
                  label: Text(
                    rental.isReturnPending ? '관리자 반납 확인 대기' : '반납 요청',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.rental});
  final RentalRecord rental;

  @override
  Widget build(BuildContext context) {
    final remaining = dateOnly(rental.due)
        .difference(dateOnly(DateTime.now()))
        .inDays;
    final message = remaining < 0
        ? '${rental.item.name}의 반납 예정일이 지났습니다.'
        : remaining == 0
        ? '${rental.item.name}의 반납 예정일이 오늘입니다.'
        : '${rental.item.name}의 반납 예정일이 내일입니다.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: blush,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: danger, size: 19),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: danger,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.store});
  final ItemStore store;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    return ListView(
      padding: const EdgeInsets.all(17),
      children: [
        const Text('대여 상태와 반납 일정을 확인하세요.', style: TextStyle(color: muted)),
        if (store.activeRentals.isEmpty && store.myRequests.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('확인할 알림이 없습니다.')),
          ),
        const SizedBox(height: 10),
        for (final rental in store.activeRentals)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _AlertRow(
              urgent: rental.due.difference(today).inDays <= 1,
              icon: Icons.notifications_active_outlined,
              message: _alertText(rental, today),
              time: dateText(rental.due),
            ),
          ),
        for (final request in store.myRequests)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _AlertRow(
              urgent: false,
              icon: request.status == RequestStatus.approved
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              message:
                  '${request.item.name}: ${switch (request.status) {
                    RequestStatus.pending => '관리자 승인 대기 중입니다.',
                    RequestStatus.approved => '대여 신청이 승인되었습니다.',
                    RequestStatus.rejected => '신청 거절: ${request.rejectionReason ?? "사유 없음"}',
                    RequestStatus.cancelled => '대여 신청을 취소했습니다.',
                    RequestStatus.expired => '대여 신청이 만료되었습니다.',
                  }}',
              time: dateText(request.requestedAt),
            ),
          ),
      ],
    );
  }

  String _alertText(RentalRecord rental, DateTime today) {
    final remaining = rental.due.difference(today).inDays;
    if (remaining < 0) return '${rental.item.name}의 반납 예정일이 지났습니다.';
    if (remaining == 0) return '${rental.item.name}의 반납 예정일이 오늘입니다.';
    if (remaining == 1) return '${rental.item.name}의 반납 예정일이 내일입니다.';
    return '${rental.item.name}의 반납 예정일은 ${dateText(rental.due)}입니다.';
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.urgent,
    required this.icon,
    required this.message,
    required this.time,
  });
  final bool urgent;
  final IconData icon;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: urgent ? blush : Colors.white,
      border: Border.all(color: urgent ? const Color(0xFFFFD3DB) : line),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Icon(icon, color: urgent ? danger : primaryBlue, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: urgent ? danger : ink,
              fontSize: 12,
              fontWeight: urgent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(time, style: const TextStyle(color: muted, fontSize: 10)),
      ],
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('내 프로필')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFFE8EFFF),
          child: Icon(
            Icons.person_outline_rounded,
            size: 40,
            color: primaryBlue,
          ),
        ),
        SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(title: const Text('이름'), subtitle: Text(user.name)),
              ListTile(
                title: const Text('학번'),
                subtitle: Text(user.studentNumber ?? '미등록'),
              ),
              ListTile(
                title: const Text('계정 유형'),
                subtitle: Text(user.isAdmin ? '관리자' : '학생'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.user,
    required this.onLogout,
    this.authApi,
    this.accessToken,
  });
  final ItemStore store;
  final AppUser user;
  final VoidCallback onLogout;
  final AuthApi? authApi;
  final String? accessToken;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEEE9FF),
            child: Icon(Icons.person_outline_rounded, color: primaryBlue),
          ),
          title: Text(
            widget.user.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('학번 ${widget.user.studentNumber ?? '미등록'}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            final account = widget.user;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfileScreen(user: account)),
            );
          },
        ),
      ),
      const SizedBox(height: 14),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('알림 설정'),
              subtitle: const Text('대여 및 반납 알림'),
              value: notificationsEnabled,
              onChanged: (value) =>
                  setState(() => notificationsEnabled = value),
            ),
            ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: primaryBlue,
              ),
              title: const Text('앱 정보'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('CYCIRENTAL'),
                  content: const Text('버전 1.0.0\n학과 대여 물품 관리 앱'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined, color: primaryBlue),
              title: const Text('공지사항'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      NoticesScreen(store: widget.store.noticeStore),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.help_outline_rounded,
                color: primaryBlue,
              ),
              title: const Text('이용 안내'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UsageGuideScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: danger),
              title: const Text('로그아웃', style: TextStyle(color: danger)),
              onTap: widget.onLogout,
            ),
          ],
        ),
      ),
    ],
  );
}
