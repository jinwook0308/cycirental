import 'package:flutter/material.dart';

void main() => runApp(const DeptRentalApp());

const navy = Color(0xFF203764);
const blue = Color(0xFF5078D7);
const pale = Color(0xFFEAF1FF);
const background = Color(0xFFF8FAFF);

class RentalItem {
  const RentalItem(
    this.name,
    this.category,
    this.description,
    this.total,
    this.available,
    this.icon,
  );
  final String name;
  final String category;
  final String description;
  final int total;
  final int available;
  final IconData icon;
}

const items = <RentalItem>[
  RentalItem('VR 기기', '실험/기타', '가상현실 체험 장비', 5, 3, Icons.view_in_ar_outlined),
  RentalItem('빔프로젝터', '전자기기', '발표와 강의용 장비', 3, 2, Icons.videocam_outlined),
  RentalItem(
    '카메라 (DSLR)',
    '촬영/영상',
    '사진과 영상 촬영용',
    2,
    0,
    Icons.photo_camera_outlined,
  ),
  RentalItem('삼각대', '촬영/영상', '촬영 보조 장비', 5, 4, Icons.camera_outdoor_outlined),
  RentalItem('조명 세트', '촬영/영상', '영상 촬영 조명', 4, 2, Icons.lightbulb_outline),
  RentalItem('노트북', '전자기기', '영상 편집용', 1, 0, Icons.laptop_outlined),
];

class DemoRental {
  const DemoRental(this.item, this.start, this.due);
  final RentalItem item;
  final DateTime start;
  final DateTime due;
}

class DemoStore extends ChangeNotifier {
  final rentals = <DemoRental>[];

  int available(RentalItem item) =>
      item.available - rentals.where((rental) => rental.item == item).length;

  bool rent(RentalItem item, DateTime due) {
    if (available(item) < 1 || !due.isAfter(DateTime.now())) return false;
    rentals.add(DemoRental(item, DateTime.now(), due));
    notifyListeners();
    return true;
  }
}

String dateText(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.'
    '${date.day.toString().padLeft(2, '0')}.';

class DeptRentalApp extends StatefulWidget {
  const DeptRentalApp({super.key});

  @override
  State<DeptRentalApp> createState() => _DeptRentalAppState();
}

class _DeptRentalAppState extends State<DeptRentalApp> {
  final store = DemoStore();
  bool entered = false;

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DeptRental',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(seedColor: blue, primary: blue),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: navy,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFDCE5F5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: entered
        ? AppShell(store: store)
        : LoginScreen(onEnter: () => setState(() => entered = true)),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onEnter});
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school_outlined, size: 82, color: navy),
                const SizedBox(height: 18),
                const Text(
                  '학과 대여 물품 관리 앱',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    color: navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'DeptRental',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '함께 쓰는 물품, 더 나은 내일',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF667999)),
                ),
                const SizedBox(height: 44),
                const TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: '학번 / 아이디 · 추후 연결',
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  enabled: false,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: '비밀번호 · 추후 연결',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onEnter,
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: const Text('데모 화면 둘러보기'),
                ),
                const SizedBox(height: 10),
                const Text(
                  '로그인/회원가입은 백엔드 인증 연동 후 활성화됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF7788A4)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
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

  void openItem(RentalItem item) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DetailScreen(item: item, store: widget.store),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(['홈', '물품 목록', '내 대여 현황', '알림'][tab]),
        actions: [
          if (tab != 3)
            IconButton(
              tooltip: '알림',
              icon: const Icon(Icons.notifications_none),
              onPressed: () => setState(() => tab = 3),
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
          ),
          ItemsScreen(store: widget.store, openItem: openItem),
          RentalsScreen(store: widget.store),
          AlertsScreen(store: widget.store),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: '물품',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: '내 대여',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
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
  });
  final DemoStore store;
  final ValueChanged<RentalItem> openItem;
  final VoidCallback openItems;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        '안녕하세요!\n좋은 하루 보내세요 :)',
        style: TextStyle(
          color: navy,
          fontSize: 23,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: pale,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                '함께 쓰는 물품,\n더 스마트한 학과 생활\n— DeptRental —',
                style: TextStyle(
                  color: navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.school_outlined, size: 64, color: blue),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          StatCard(
            icon: Icons.inventory_2_outlined,
            label: '대여 가능',
            value:
                '${items.where((item) => store.available(item) > 0).length}종',
            color: Color(0xFFDDF8FF),
          ),
          const SizedBox(width: 8),
          StatCard(
            icon: Icons.assignment_outlined,
            label: '내 대여',
            value: '${store.rentals.length}건',
            color: const Color(0xFFE8E9FF),
          ),
          const SizedBox(width: 8),
          const StatCard(
            icon: Icons.notifications_none,
            label: '알림',
            value: '확인',
            color: Color(0xFFFFEAE8),
          ),
        ],
      ),
      const SizedBox(height: 25),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '추천 물품',
            style: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextButton(onPressed: openItems, child: const Text('더보기  ›')),
        ],
      ),
      SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return SizedBox(
              width: 145,
              child: Card(
                child: InkWell(
                  onTap: () => openItem(item),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: ItemPicture(item: item, size: 80)),
                        const SizedBox(height: 7),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          store.available(item) > 0
                              ? '대여 가능 ${store.available(item)}대'
                              : '대여 불가',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF667999),
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
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '공지사항',
                style: TextStyle(color: navy, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text('• 대여 물품 이용 수칙을 확인해 주세요.'),
              Text('• 현재 화면의 물품과 대여는 데모 데이터입니다.'),
            ],
          ),
        ),
      ),
    ],
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 108,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: navy),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: navy),
          ),
          Text(
            value,
            style: const TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
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
  String query = '';
  String category = '전체';
  static const categories = ['전체', '전자기기', '촬영/영상', '실험/기타'];

  @override
  Widget build(BuildContext context) {
    final visible = items
        .where(
          (item) =>
              (category == '전체' || item.category == category) &&
              item.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '물품명으로 검색하세요',
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (context, index) => ChoiceChip(
              label: Text(categories[index]),
              selected: category == categories[index],
              onSelected: (_) => setState(() => category = categories[index]),
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('검색 결과가 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    final available = widget.store.available(item);
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => widget.openItem(item),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ItemPicture(item: item, size: 74),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: navy,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      item.description,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '$available / ${item.total} 대',
                                      style: const TextStyle(
                                        color: navy,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Availability(available: available),
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

class ItemPicture extends StatelessWidget {
  const ItemPicture({super.key, required this.item, this.size = 90});
  final RentalItem item;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: pale,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(item.icon, size: size * 0.48, color: navy),
  );
}

class Availability extends StatelessWidget {
  const Availability({super.key, required this.available});
  final int available;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: available > 0 ? const Color(0xFFDDF8FF) : const Color(0xFFFFE6E8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      available > 0 ? '대여 가능' : '대여 불가',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: available > 0 ? navy : const Color(0xFFBA4751),
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
  late DateTime due = DateTime.now().add(const Duration(days: 3));

  @override
  Widget build(BuildContext context) {
    final available = widget.store.available(widget.item);
    return Scaffold(
      appBar: AppBar(title: const Text('물품 상세')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: ItemPicture(item: widget.item, size: 240)),
          const SizedBox(height: 20),
          Text(
            widget.item.name,
            style: const TextStyle(
              color: navy,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            widget.item.description,
            style: const TextStyle(color: Color(0xFF667999)),
          ),
          const SizedBox(height: 14),
          const Text('수업, 발표, 프로젝트에 함께 활용하는 학과 공용 물품입니다.'),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  InfoRow('전체 수량', '${widget.item.total}대'),
                  const Divider(),
                  InfoRow('대여 가능 수량', '$available대'),
                  const Divider(),
                  InfoRow('종류', widget.item.category),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  InfoRow('대여일', dateText(DateTime.now())),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('반납 예정일'),
                    subtitle: Text(dateText(due)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final today = DateTime.now();
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: due,
                        firstDate: today.add(const Duration(days: 1)),
                        lastDate: today.add(const Duration(days: 90)),
                      );
                      if (selected != null) setState(() => due = selected);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: available > 0
                ? () {
                    final success = widget.store.rent(widget.item, due);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? '데모 대여 신청이 저장되었습니다.' : '대여 가능한 수량이 없습니다.',
                        ),
                      ),
                    );
                    if (success) Navigator.of(context).pop();
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              minimumSize: const Size.fromHeight(54),
            ),
            child: const Text('대여 신청 (데모)'),
          ),
          const SizedBox(height: 8),
          const Text(
            '실제 DB에는 저장되지 않습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7788A4), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(
        value,
        style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class RentalsScreen extends StatelessWidget {
  const RentalsScreen({super.key, required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) => store.rentals.isEmpty
      ? const Center(
          child: Text(
            '아직 데모 대여 내역이 없습니다.\n물품 목록에서 신청해 보세요.',
            textAlign: TextAlign.center,
          ),
        )
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: store.rentals.length,
          itemBuilder: (context, index) {
            final rental = store.rentals[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ItemPicture(item: rental.item, size: 68),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            rental.item.name,
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Text('대여 중', style: TextStyle(color: blue)),
                      ],
                    ),
                    const Divider(height: 20),
                    InfoRow('대여일', dateText(rental.start)),
                    const SizedBox(height: 6),
                    InfoRow('반납 예정일', dateText(rental.due)),
                  ],
                ),
              ),
            );
          },
        );
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        '반납 일정',
        style: TextStyle(
          color: navy,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      if (store.rentals.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('표시할 알림이 없습니다. 대여 후 반납 일정이 여기에 표시됩니다.'),
          ),
        ),
      for (final rental in store.rentals)
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: blue,
            ),
            title: Text('${rental.item.name} 반납 예정일'),
            subtitle: Text(dateText(rental.due)),
          ),
        ),
      const SizedBox(height: 12),
      const Text(
        '푸시 알림은 추후 서버 연동 후 구현합니다.',
        style: TextStyle(color: Color(0xFF7788A4), fontSize: 12),
      ),
    ],
  );
}
