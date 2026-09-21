import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'demo_data.dart';
import 'product_visual.dart';

void main() => runApp(const DeptRentalApp());

const ink = Color(0xFF1D315B);
const primaryBlue = Color(0xFF4C76D8);
const lilac = Color(0xFF6C71DC);
const muted = Color(0xFF7182A1);
const line = Color(0xFFDDE6F5);
const page = Color(0xFFF9FBFF);
const ice = Color(0xFFE7F7FF);
const blush = Color(0xFFFFEBEE);
const danger = Color(0xFFE34D5D);

class DeptRentalApp extends StatefulWidget {
  const DeptRentalApp({super.key});

  @override
  State<DeptRentalApp> createState() => _DeptRentalAppState();
}

class _DeptRentalAppState extends State<DeptRentalApp> {
  final DemoStore store = DemoStore();
  bool signedIn = false;

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DeptRental',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: page,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        titleTextStyle: TextStyle(
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
        indicatorColor: Color(0xFFE7EDFF),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink),
        ),
      ),
    ),
    home: signedIn
        ? AppShell(store: store)
        : LoginScreen(onEnter: () => setState(() => signedIn = true)),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onEnter});
  final VoidCallback onEnter;

  void _notReady(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('계정 기능은 서버 연동 후 제공됩니다. 데모로 둘러보세요.')),
    );
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
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE9F0FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: ink,
                            size: 55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        '학과 대여 물품 관리 앱',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'DeptRental',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '함께 쓰는 물품, 더 나은 내일',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 14),
                      ),
                      const SizedBox(height: 35),
                      const TextField(
                        decoration: InputDecoration(
                          hintText: '학번 / 아이디',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '비밀번호',
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      PrimaryAction(label: '로그인 · 데모 체험', onPressed: onEnter),
                      const SizedBox(height: 11),
                      const Text(
                        '입력한 계정 정보는 사용하지 않는 화면 데모입니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => _notReady(context),
                            child: const Text('회원가입'),
                          ),
                          const Text('│', style: TextStyle(color: line)),
                          TextButton(
                            onPressed: () => _notReady(context),
                            child: const Text('아이디 찾기'),
                          ),
                          const Text('│', style: TextStyle(color: line)),
                          TextButton(
                            onPressed: () => _notReady(context),
                            child: const Text('비밀번호 찾기'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const CampusArtwork(),
                      const SizedBox(height: 6),
                      const Text(
                        '우리의 학과, 함께 만들어가는 스마트한 공유 문화!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
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
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    child: Text(label),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final DemoStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;

  Future<void> openItem(RentalItem item) async {
    final booked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DetailScreen(item: item, store: widget.store),
      ),
    );
    if (!mounted || booked != true) return;
    setState(() => tab = 2);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('데모 대여 신청이 완료됐습니다. 내 대여 현황을 확인해 보세요.')),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(['DeptRental', '물품 목록', '내 대여 현황', '알림'][tab]),
        actions: [
          if (tab != 3)
            IconButton(
              tooltip: '알림 보기',
              onPressed: () => setState(() => tab = 3),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: [
          HomeScreen(
            store: widget.store,
            openItem: openItem,
            openItems: () => setState(() => tab = 1),
            openRentals: () => setState(() => tab = 2),
          ),
          ItemsScreen(store: widget.store, openItem: openItem),
          RentalsScreen(store: widget.store),
          AlertsScreen(store: widget.store),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
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
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: '알림',
          ),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.openItem,
    required this.openItems,
    required this.openRentals,
  });

  final DemoStore store;
  final ValueChanged<RentalItem> openItem;
  final VoidCallback openItems;
  final VoidCallback openRentals;

  @override
  Widget build(BuildContext context) {
    final availableCount = rentalItems.fold<int>(
      0,
      (sum, item) => sum + store.available(item),
    );
    final dueSoon = store.activeRentals
        .where(
          (rental) =>
              dateOnly(rental.due)
                  .difference(dateOnly(DateTime.now()))
                  .inDays <=
              1,
        )
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                '안녕하세요!\n좋은 하루 보내세요 :)',
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.28,
                ),
              ),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFE8EFFF),
              child: Icon(Icons.person_outline_rounded, color: primaryBlue),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _HomeBanner(),
        const SizedBox(height: 14),
        Row(
          children: [
            _StatTile(
              icon: Icons.inventory_2_outlined,
              label: '대여 가능한\n물품',
              count: '$availableCount개',
              tint: ice,
            ),
            const SizedBox(width: 8),
            _StatTile(
              icon: Icons.assignment_outlined,
              label: '내 대여\n현황',
              count: '${store.activeRentals.length}개',
              tint: const Color(0xFFEAEAFF),
            ),
            const SizedBox(width: 8),
            _StatTile(
              icon: Icons.notifications_none_rounded,
              label: '읽지 않은\n알림',
              count: '$dueSoon개',
              tint: const Color(0xFFFFEEEA),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionHeading(title: '추천 물품', action: '더보기', onPressed: openItems),
        const SizedBox(height: 10),
        SizedBox(
          height: 191,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final item = rentalItems[index];
              return SizedBox(
                width: 143,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => openItem(item),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductVisual(item: item, width: 123, height: 104),
                          const SizedBox(height: 8),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            store.available(item) > 0
                                ? '대여 가능 ${store.available(item)}${item.unit}'
                                : '현재 대여 불가',
                            style: TextStyle(
                              color: store.available(item) > 0
                                  ? primaryBlue
                                  : danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
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
        SectionHeading(
          title: '내 대여 일정',
          action: '내역 보기',
          onPressed: openRentals,
        ),
        const SizedBox(height: 10),
        if (store.activeRentals.isNotEmpty)
          InkWell(
            onTap: openRentals,
            borderRadius: BorderRadius.circular(17),
            child: _ReminderBanner(rental: store.activeRentals.first),
          ),
        const SizedBox(height: 20),
        const SectionHeading(title: '공지사항'),
        const SizedBox(height: 10),
        const Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign_outlined, color: ink, size: 20),
                    SizedBox(width: 7),
                    Text(
                      '학과 물품 이용 안내',
                      style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                SizedBox(height: 9),
                Text('· 대여 물품 이용 수칙을 확인해 주세요.', style: TextStyle(fontSize: 12)),
                Text(
                  '· 현재 물품과 알림은 시연용 예시 데이터입니다.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeBanner extends StatelessWidget {
  const _HomeBanner();

  @override
  Widget build(BuildContext context) => Container(
    height: 124,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE8F4FF), Color(0xFFE8E9FF)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -20,
          top: -35,
          child: Container(
            width: 128,
            height: 128,
            decoration: const BoxDecoration(
              color: Color(0x66FFFFFF),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Positioned(
          right: 14,
          bottom: 5,
          child: Icon(
            Icons.groups_2_outlined,
            color: Color(0xFF7997DD),
            size: 96,
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '함께 쓰는 물품,',
                style: TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '더 스마트한 학과 생활',
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '– DeptRental –',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.tint,
  });
  final IconData icon;
  final String label;
  final String count;
  final Color tint;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ink, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ink,
              fontSize: 11,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
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
  final DemoStore store;
  final ValueChanged<RentalItem> openItem;

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  static const categories = ['전체', '전자기기', '촬영/영상', '실험/기타'];
  String query = '';
  String category = '전체';
  bool onlyAvailable = false;

  @override
  Widget build(BuildContext context) {
    final visible = rentalItems.where((item) {
      final matchesText =
          item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(query.toLowerCase());
      return matchesText &&
          (category == '전체' || item.category == category) &&
          (!onlyAvailable || widget.store.available(item) > 0);
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 18, 17, 2),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('item-search'),
                  onChanged: (text) => setState(() => query = text),
                  decoration: const InputDecoration(
                    hintText: '물품명으로 검색하세요...',
                    prefixIcon: Icon(Icons.search_rounded, color: ink),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '대여 가능 물품만 보기',
                onPressed: () => setState(() => onlyAvailable = !onlyAvailable),
                icon: Icon(
                  onlyAvailable
                      ? Icons.filter_alt_rounded
                      : Icons.filter_alt_outlined,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 57,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (context, index) => ChoiceChip(
              label: Text(categories[index]),
              selected: category == categories[index],
              onSelected: (_) => setState(() => category = categories[index]),
              selectedColor: const Color(0xFFE5EAFE),
              side: const BorderSide(color: line),
              labelStyle: TextStyle(
                color: category == categories[index] ? primaryBlue : ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 6, 19, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '전체 ${visible.length}개 물품',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: Text('검색 결과가 없습니다.', style: TextStyle(color: muted)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(17, 7, 17, 22),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    final count = widget.store.available(item);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () => widget.openItem(item),
                        borderRadius: BorderRadius.circular(17),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ProductVisual(item: item, width: 82, height: 76),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$count / ${item.total} ${item.unit}',
                                      style: const TextStyle(
                                        color: ink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              AvailabilityPill(available: count),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
  final DemoStore store;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late DateTime due = dateOnly(DateTime.now()).add(const Duration(days: 3));

  Future<void> _chooseDue() async {
    final today = dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: due,
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 90)),
    );
    if (selected != null && mounted) setState(() => due = selected);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.store.available(widget.item);
    return Scaffold(
      appBar: AppBar(title: const Text('물품 상세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
        children: [
          Center(
            child: ProductVisual(
              item: widget.item,
              width: double.infinity,
              height: 225,
            ),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.name,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AvailabilityPill(available: count),
            ],
          ),
          Text(
            widget.item.subtitle,
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            widget.item.description,
            style: const TextStyle(color: ink, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                children: [
                  InfoLine(
                    icon: Icons.inventory_2_outlined,
                    title: '전체 수량',
                    value: '${widget.item.total} ${widget.item.unit}',
                  ),
                  const Divider(height: 21, color: line),
                  InfoLine(
                    icon: Icons.lock_open_outlined,
                    title: '대여 가능 수량',
                    value: '$count ${widget.item.unit}',
                  ),
                  const Divider(height: 21, color: line),
                  InfoLine(
                    icon: Icons.place_outlined,
                    title: '위치',
                    value: widget.item.location,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                children: [
                  InfoLine(
                    icon: Icons.calendar_today_outlined,
                    title: '대여일',
                    value: dateText(DateTime.now()),
                  ),
                  const Divider(height: 21, color: line),
                  InkWell(
                    onTap: _chooseDue,
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined, color: ink, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '반납 예정일',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ),
                        Text(
                          dateText(due),
                          style: const TextStyle(
                            color: ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: primaryBlue,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryAction(
                label: count > 0 ? '대여 신청' : '현재 대여 불가',
                onPressed: count > 0
                    ? () {
                        if (widget.store.rent(widget.item, due)) {
                          Navigator.pop(context, true);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 5),
              const Text(
                '데모 신청은 이 기기에만 임시로 표시되며 실제 DB에는 저장되지 않습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  const RentalsScreen({super.key, required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            labelColor: primaryBlue,
            unselectedLabelColor: muted,
            indicatorColor: primaryBlue,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: '대여 중 (${store.activeRentals.length})'),
              Tab(text: '대여 내역 (${store.history.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              store.activeRentals.isEmpty
                  ? const _EmptyPanel(
                      message: '대여 중인 물품이 없습니다.\n물품 목록에서 신청해 보세요.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(17),
                      itemCount: store.activeRentals.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        if (index == store.activeRentals.length) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 9),
                            child: Text(
                              '표시된 대여 내역은 시연용이며 서버에 저장되지 않습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted, fontSize: 11),
                            ),
                          );
                        }
                        final rental = store.activeRentals[index];
                        return _RentalCard(
                          rental: rental,
                          onReturn: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('데모 반납 처리'),
                                content: Text(
                                  '${rental.item.name}을 반납 완료로 표시할까요? 실제 서버에는 반영되지 않습니다.',
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
                                    child: const Text('반납 완료'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) store.returnItem(rental);
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
  final DemoRental rental;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final remaining = dateOnly(rental.due)
        .difference(dateOnly(DateTime.now()))
        .inDays;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ProductVisual(item: rental.item, width: 72, height: 70),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.item.name,
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (rental.isSample)
                        const Text(
                          '예시 대여 내역',
                          style: TextStyle(color: muted, fontSize: 10),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        '대여일    ${dateText(rental.start)}',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      Text(
                        '반납 예정일    ${dateText(rental.due)}',
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: rental.isActive
                        ? const Color(0xFFE5F0FF)
                        : const Color(0xFFF0F2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rental.isActive ? '대여 중' : '반납 완료',
                    style: TextStyle(
                      color: rental.isActive ? primaryBlue : muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            if (rental.isActive && remaining <= 1) ...[
              const SizedBox(height: 10),
              _ReminderBanner(rental: rental),
            ],
            if (onReturn != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.check_circle_outline, size: 17),
                  label: const Text('반납 완료로 표시'),
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
  final DemoRental rental;

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
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    return ListView(
      padding: const EdgeInsets.all(17),
      children: [
        const SectionHeading(title: '알림'),
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
        const _AlertRow(
          urgent: false,
          icon: Icons.check_circle_outline,
          message: '대여 신청이 승인되었습니다. (예시 알림)',
          time: '데모',
        ),
        const SizedBox(height: 18),
        const Text(
          '푸시 알림은 아직 발송되지 않습니다. 이 화면은 시연용입니다.',
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
    );
  }

  String _alertText(DemoRental rental, DateTime today) {
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
