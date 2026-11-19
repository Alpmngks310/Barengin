import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../models/barengin_models.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'activity_detail_screen.dart';
import 'favorites_screen.dart';
import 'create_activity_screen.dart';
import 'host_management_screen.dart';
import 'profile_edit_screen.dart';
import 'safety_screens.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _myActivityVersion = 0;

  void _go(int index) {
    setState(() {
      _index = index;
      if (index == 3) _myActivityVersion++;
    });
  }

  void _showCreatedActivity() {
    setState(() {
      _index = 3;
      _myActivityVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeTab(onExplore: () => _go(1), onCreate: () => _go(2)),
      const ExploreTab(),
      CreateActivityScreen(onCreated: _showCreatedActivity),
      MyActivityTab(key: ValueKey('my-activities-$_myActivityVersion')),
      const ProfileTab(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 96,
            child: IndexedStack(index: _index, children: pages),
          ),
          // Floating Bottom Navigation
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.line.withValues(alpha: 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: 0.12),
                      blurRadius: 25,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _FloatingNavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: _index == 0,
                      onTap: () => _go(0),
                    ),
                    _FloatingNavItem(
                      icon: Icons.travel_explore_rounded,
                      label: 'Explore',
                      selected: _index == 1,
                      onTap: () => _go(1),
                    ),
                    // Create Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _go(2),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 39,
                              height: 39,
                              decoration: BoxDecoration(
                                color: _index == 2
                                    ? AppColors.forest
                                    : AppColors.forest.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: _index == 2
                                    ? Colors.white
                                    : AppColors.forest,
                                size: 25,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Create',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: _index == 2
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: _index == 2
                                    ? AppColors.forest
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _FloatingNavItem(
                      icon: Icons.calendar_month_rounded,
                      label: 'Activity',
                      selected: _index == 3,
                      onTap: () => _go(3),
                    ),
                    _FloatingNavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      selected: _index == 4,
                      onTap: () => _go(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.forest.withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? AppColors.forest : AppColors.muted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  color: selected ? AppColors.forest : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onExplore, required this.onCreate});
  final VoidCallback onExplore;
  final VoidCallback onCreate;
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final session = context.read<SessionController>();
    final categories = await session.getCategories();
    final query = <String, dynamic>{'per_page': 8};
    final city = session.user?.city ?? '';
    if (city.isNotEmpty) query['city'] = city;
    final activities = await session.getActivities(query: query);
    return _HomeData(categories, activities);
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    final future = _load();

    setState(() {
      _future = future;
    });

    try {
      await future;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    final firstName =
        (user?.displayName.isNotEmpty == true
                ? user!.displayName
                : user?.name ?? 'Teman')
            .split(' ')
            .first;
    return Scaffold(
      appBar: AppBar(
        title: const BrandMark(compact: true),
        actions: [
          IconButton(
            onPressed: widget.onExplore,
            icon: const Icon(Icons.search_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: AppAvatar(
              name: user?.displayName ?? user?.name ?? 'B',
              imageUrl: user?.avatarUrl,
              size: 34,
            ),
          ),
        ],
      ),
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: EmptyState(
                title: 'Belum bisa memuat beranda',
                message: snapshot.error.toString(),
                actionLabel: 'Coba lagi',
                onAction: _refresh,
              ),
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 25),
              children: [
                Text(
                  'Hai, $firstName! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: -.6,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Mau ngapain hari ini?',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                if (user?.interests.isEmpty ?? true) ...[
                  const SizedBox(height: 13),
                  InkWell(
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen(),
                          ),
                        ).then(
                          (_) => context.read<SessionController>().reloadUser(),
                        ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.forest,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Biar rekomendasinya makin relate',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AppColors.forest,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Pilih 3–6 minat dan lengkapi area kamu.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.forest,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                InkWell(
                  onTap: widget.onExplore,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppColors.sageDark),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cari aktivitas, tempat, atau keseruan...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.tune_rounded,
                          color: AppColors.muted,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.forest, Color(0xFF597762)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -18,
                        top: -16,
                        child: Icon(
                          Icons.diversity_3_rounded,
                          size: 125,
                          color: Colors.white.withValues(alpha: .09),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'YOUR NEXT GOOD STORY STARTS HERE',
                              style: TextStyle(
                                color: Colors.white,
                                letterSpacing: .7,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Satu minat.\nBanyak kemungkinan.',
                            style: TextStyle(
                              fontSize: 23,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cari circle baru, coba hal baru, dan bikin rencana jadi nyata.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 39,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.forest,
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                ),
                              ),
                              onPressed: widget.onCreate,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'Buat aktivitas',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 23),
                SectionTitle(
                  'Cari sesuai vibe kamu',
                  actionLabel: 'Lihat semua',
                  onAction: widget.onExplore,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = data.categories[index];
                      return InkWell(
                        onTap: widget.onExplore,
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: 88,
                          child: Column(
                            children: [
                              CategoryIcon(category: category, size: 54),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SectionTitle(
                  'Aktivitas buat kamu',
                  actionLabel: 'Lihat semua',
                  onAction: widget.onExplore,
                ),
                const SizedBox(height: 9),
                if (data.activities.isEmpty)
                  const EmptyState(
                    title: 'Belum ada aktivitas di sini',
                    message:
                        'Jadi yang pertama bikin rencana. Ajak orang lain untuk ikut seru-seruan!',
                    icon: Icons.celebration_outlined,
                  )
                else
                  ...data.activities.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ActivityCard(
                        activity: activity,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ActivityDetailScreen(activity: activity),
                          ),
                        ).then((_) => _refresh()),
                      ),
                    ),
                  ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.lemon.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: AppColors.forest,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tip kecil: mulai dari aktivitas sederhana seperti ngopi, jalan sore, atau belajar bareng.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.forest,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeData {
  const _HomeData(this.categories, this.activities);
  final List<Category> categories;
  final List<Activity> activities;
}

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _search = TextEditingController();
  String _selectedSlug = '';
  String _city = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int? _budgetMax;
  String _participantLevel = '';
  late final TextEditingController _cityController;
  List<Category> _categories = [];
  late Future<List<Activity>> _future;
  bool _loadingCategories = true;
  bool _locating = false;
  double? _latitude;
  double? _longitude;

  bool get _supportsGps =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _city = context.read<SessionController>().user?.city ?? '';
    _cityController = TextEditingController(text: _city);
    _future = _load();
    _loadCategories();
  }

  @override
  void dispose() {
    _search.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await context.read<SessionController>().getCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<List<Activity>> _load() {
    final query = <String, dynamic>{'per_page': 30};
    if (_search.text.trim().isNotEmpty) query['q'] = _search.text.trim();
    if (_selectedSlug.isNotEmpty) query['category_slug'] = _selectedSlug;
    if (_city.trim().isNotEmpty && _latitude == null) {
      query['city'] = _city.trim();
    }
    if (_dateFrom != null) {
      query['date_from'] = _dateFrom!.toIso8601String().split('T').first;
    }
    if (_dateTo != null) {
      query['date_to'] = _dateTo!.toIso8601String().split('T').first;
    }
    if (_budgetMax != null) query['budget_max'] = _budgetMax;
    if (_participantLevel.isNotEmpty) {
      query['participant_level'] = _participantLevel;
    }
    if (_latitude != null && _longitude != null) {
      query['latitude'] = _latitude;
      query['longitude'] = _longitude;
      query['radius_km'] = 10;
    }
    return context.read<SessionController>().getActivities(query: query);
  }

  Future<void> _apply() async {
    if (!mounted) return;

    final future = _load();

    setState(() {
      _future = future;
    });

    try {
      await future;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  Future<void> _useNearby() async {
    setState(() => _locating = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _future = _load();
      });
      showAppMessage(
        context,
        'Menampilkan aktivitas dalam radius 10 km dari lokasimu.',
      );
    } catch (error) {
      if (mounted) {
        showAppMessage(
          context,
          error.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openFilters() async {
    final budgetController = TextEditingController(
      text: _budgetMax?.toString() ?? '',
    );
    DateTime? from = _dateFrom;
    DateTime? to = _dateTo;
    String level = _participantLevel;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Filter aktivitas',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Atur jadwal, budget, dan level peserta sesuai kebutuhanmu.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tanggal mulai',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 7),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: from ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setModalState(() => from = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  from == null ? 'Pilih tanggal mulai' : formatDate(from),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tanggal akhir',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 7),
              OutlinedButton.icon(
                onPressed: () async {
                  final firstAllowedDate = from ?? DateTime.now();

                  final initialAllowedDate =
                      to != null && !to!.isBefore(firstAllowedDate)
                      ? to!
                      : firstAllowedDate;

                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: initialAllowedDate,
                    firstDate: firstAllowedDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );

                  if (picked != null) {
                    setModalState(() => to = picked);
                  }
                },
                icon: const Icon(Icons.event_available_outlined),
                label: Text(
                  to == null ? 'Pilih tanggal akhir' : formatDate(to),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Budget maksimal per orang',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: 'Kosongkan jika bebas budget',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Level peserta',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 7),
              DropdownButtonFormField<String>(
                initialValue: level,
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Semua level')),
                  DropdownMenuItem(value: 'beginner', child: Text('Pemula')),
                  DropdownMenuItem(
                    value: 'all_levels',
                    child: Text('Semua level / terbuka'),
                  ),
                  DropdownMenuItem(
                    value: 'experienced',
                    child: Text('Berpengalaman'),
                  ),
                ],
                onChanged: (value) => setModalState(() => level = value ?? ''),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _search.clear();
                          _selectedSlug = '';
                          _city =
                              context.read<SessionController>().user?.city ??
                              '';
                          _cityController.text = _city;
                          _latitude = null;
                          _longitude = null;
                          _dateFrom = null;
                          _dateTo = null;
                          _budgetMax = null;
                          _participantLevel = '';
                          _future = _load();
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final budgetText = budgetController.text.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        final budget = budgetText.isEmpty
                            ? null
                            : int.tryParse(budgetText);
                        if (from != null && to != null && to!.isBefore(from!)) {
                          showAppMessage(
                            context,
                            'Tanggal akhir tidak boleh sebelum tanggal mulai.',
                            error: true,
                          );
                          return;
                        }
                        Navigator.pop(sheetContext);
                        setState(() {
                          _dateFrom = from;
                          _dateTo = to;
                          _budgetMax = budget;
                          _participantLevel = level;
                          _future = _load();
                        });
                      },
                      child: const Text('Terapkan filter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    budgetController.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Explore',
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Aktivitas tersimpan',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          ),
          icon: const Icon(Icons.bookmark_border_rounded),
        ),
        IconButton(
          tooltip: 'Filter aktivitas',
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _search.clear();
              _selectedSlug = '';
              _latitude = null;
              _longitude = null;
              _future = _load();
            });
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _apply(),
                decoration: InputDecoration(
                  hintText: 'Cari aktivitas atau tempat...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _apply,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.sageDark,
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      onSubmitted: (value) {
                        _city = value;
                        _latitude = null;
                        _longitude = null;
                        _apply();
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        hintText: 'Semua kota / area',
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  if (_supportsGps)
                    TextButton.icon(
                      onPressed: _locating ? null : _useNearby,
                      icon: _locating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 15),
                      label: const Text(
                        'Sekitar saya',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                ],
              ),
              if (!_loadingCategories)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: const Text('Semua'),
                          selected: _selectedSlug.isEmpty,
                          onSelected: (_) {
                            setState(() => _selectedSlug = '');
                            _apply();
                          },
                        ),
                      ),
                      ..._categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text(category.name),
                            selected: _selectedSlug == category.slug,
                            onSelected: (_) {
                              setState(
                                () => _selectedSlug =
                                    _selectedSlug == category.slug
                                    ? ''
                                    : category.slug,
                              );
                              _apply();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Activity>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: EmptyState(
                    title: 'Explore belum bisa dimuat',
                    message: snapshot.error.toString(),
                    actionLabel: 'Coba lagi',
                    onAction: _apply,
                  ),
                );
              }
              final activities = snapshot.data ?? [];
              if (activities.isEmpty) {
                return const EmptyState(
                  title: 'Belum ada aktivitas yang cocok',
                  message:
                      'Coba kata kunci atau kategori lain. Kamu juga bisa jadi Host pertama di area ini.',
                  icon: Icons.search_off_rounded,
                );
              }
              return RefreshIndicator(
                onRefresh: _apply,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                  children: [
                    Text(
                      '${activities.length} aktivitas ditemukan',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 11),
                    ...activities.map(
                      (activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ActivityCard(
                          activity: activity,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ActivityDetailScreen(activity: activity),
                            ),
                          ).then((_) => _apply()),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class MyActivityTab extends StatefulWidget {
  const MyActivityTab({super.key});
  @override
  State<MyActivityTab> createState() => _MyActivityTabState();
}

class _MyActivityTabState extends State<MyActivityTab> {
  int _tab = 0;
  late Future<List<dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() async {
    final session = context.read<SessionController>();
    if (_tab == 2) return session.getMyJoinRequests();
    return session.getMyActivities(role: _tab == 0 ? 'host' : 'member');
  }

  Future<void> _switch(int value) async {
    setState(() {
      _tab = value;
      _future = _load();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    final future = _load();

    setState(() {
      _future = future;
    });

    try {
      await future;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Aktivitas saya',
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<int>(value: 0, label: Text('Host')),
                      ButtonSegment<int>(value: 1, label: Text('Member')),
                      ButtonSegment<int>(value: 2, label: Text('Request')),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (value) => _switch(value.first),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: EmptyState(
                        title: 'Aktivitas belum bisa dimuat',
                        message: snapshot.error.toString(),
                        actionLabel: 'Coba lagi',
                        onAction: _refresh,
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: EmptyState(
                          title: _tab == 0
                              ? 'Belum ada aktivitas buatanmu'
                              : _tab == 1
                              ? 'Belum ada aktivitas yang kamu ikuti'
                              : 'Belum ada permintaan bergabung',
                          message: _tab == 0
                              ? 'Buat kegiatan pertama dan ajak orang lain untuk ikut.'
                              : _tab == 1
                              ? 'Cari aktivitas yang cocok dengan minatmu, lalu ajukan permintaan.'
                              : 'Permintaan yang kamu kirim akan muncul di sini.',
                          icon: Icons.event_note_rounded,
                          actionLabel: 'Muat ulang',
                          onAction: _refresh,
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      if (_tab == 2)
                        ...items.map((raw) {
                          final request = raw as JoinRequest;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          request.activityTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      StatusPill(request.status),
                                    ],
                                  ),
                                  if (request.message.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 7),
                                      child: Text(
                                        request.message,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ),
                                  if (request.status == 'pending')
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () async {
                                          try {
                                            await context
                                                .read<SessionController>()
                                                .cancelMyJoinRequest(
                                                  request.id,
                                                );
                                            await _refresh();

                                            if (context.mounted) {
                                              showAppMessage(
                                                context,
                                                'Permintaan dibatalkan.',
                                              );
                                            }
                                          } on ApiException catch (e) {
                                            if (context.mounted) {
                                              showAppMessage(
                                                context,
                                                e.firstFieldError,
                                                error: true,
                                              );
                                            }
                                          }
                                        },
                                        child: const Text(
                                          'Batalkan permintaan',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        })
                      else
                        ...items.whereType<Activity>().map((activity) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ActivityCard(
                              activity: activity,
                              trailing: StatusPill(activity.status),
                              onTap: () {
                                if (_tab == 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HostManagementScreen(
                                        activity: activity,
                                      ),
                                    ),
                                  ).then((_) => _refresh());
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ActivityDetailScreen(
                                        activity: activity,
                                        isMember: _tab == 1,
                                      ),
                                    ),
                                  ).then((_) => _refresh());
                                }
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user;
    final name = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : user?.name ?? 'Pengguna';
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await session.reloadUser();
              } catch (e) {
                if (context.mounted) {
                  showAppMessage(context, e.toString(), error: true);
                }
              }
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  AppAvatar(name: name, imageUrl: user?.avatarUrl, size: 82),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.username.isNotEmpty == true
                        ? '@${user!.username}'
                        : user?.email ?? '',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  if ((user?.city ?? '').isNotEmpty ||
                      (user?.area ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.sageDark,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            [
                              user?.area,
                              user?.city,
                            ].where((e) => (e ?? '').isNotEmpty).join(', '),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if ((user?.bio ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        user!.bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileEditScreen(),
                        ),
                      ).then((_) => session.reloadUser()),
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit profil'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Minat kamu'),
          if (user?.interests.isNotEmpty == true)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user!.interests
                  .map((c) => Chip(label: Text(c.name)))
                  .toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Text(
                'Tambahkan minimal 3 minat agar rekomendasi aktivitas lebih relevan.',
                style: TextStyle(fontSize: 11, color: AppColors.forest),
              ),
            ),
          const SizedBox(height: 21),
          const SectionTitle('Pengaturan & privasi'),
          _ProfileAction(
            icon: Icons.tune_rounded,
            title: 'Edit data diri dan minat',
            subtitle: 'Perbarui profil dan preferensi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            ).then((_) => session.reloadUser()),
          ),
          _ProfileAction(
            icon: Icons.shield_outlined,
            title: 'Pusat keamanan',
            subtitle: 'Kelola akun yang diblokir dan tips keamanan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyCenterScreen()),
            ),
          ),
          _ProfileAction(
            icon: Icons.privacy_tip_outlined,
            title: 'Privasi & penggunaan data',
            subtitle: 'Lokasi hanya dipakai untuk pencarian saat diperlukan',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.white,
              builder: (context) => const Padding(
                padding: EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privasi kamu penting',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Barengin menggunakan data profil dan minat untuk personalisasi. Lokasi GPS hanya boleh dikirim saat kamu memberi izin dan digunakan untuk pencarian aktivitas, bukan disimpan sebagai lokasi profil.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: Color(0xFFEBD2CE)),
            ),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar dari akun?'),
                  content: const Text('Kamu bisa masuk lagi kapan saja.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                try {
                  await session.logout();
                } on ApiException catch (e) {
                  if (context.mounted) {
                    showAppMessage(context, e.message, error: true);
                  }
                }
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar dari akun'),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'BARENGIN · Find Your People, Make It Happen.',
              style: TextStyle(fontSize: 9, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.sageLight,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppColors.forest, size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10, color: AppColors.muted),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    ),
  );
}
