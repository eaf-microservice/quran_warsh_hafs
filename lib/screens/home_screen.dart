import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/quran_devision.dart';
import '../utils/quran_surahs.dart';
import '../widgets/about.dart' show AboutMe;
import 'read_screen.dart';
import 'settings_screen.dart';

class PrefsKeys {
  static const lastPage = 'last_page';
  static const bookmarks = 'bookmarks'; // List<int>
  static const nightMode = 'night_mode';
  static const tajweed = 'tajweed_enabled';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _lastPage;
  Set<int> _bookmarks = {};
  bool _night = false;
  bool _tajweed = false;
  String _query = '';
  bool _showSurahs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _lastPage = sp.getInt(PrefsKeys.lastPage);
      _bookmarks = (sp.getStringList(PrefsKeys.bookmarks) ?? [])
          .map((e) => int.tryParse(e) ?? -1)
          .where((e) => e > 0)
          .toSet();
      _night = sp.getBool(PrefsKeys.nightMode) ?? false;
      _tajweed = sp.getBool(PrefsKeys.tajweed) ?? false;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final sp = await SharedPreferences.getInstance();
    if (value is bool) await sp.setBool(key, value);
    if (value is int) await sp.setInt(key, value);
    if (value is List<String>) await sp.setStringList(key, value);
  }

  List<SurahInfo> get _filteredSurahs {
    if (_query.trim().isEmpty) return kSurahs;
    final q = _query.toLowerCase();
    return kSurahs.where((s) {
      return s.arabic.contains(_query) ||
          s.english.toLowerCase().contains(q) ||
          s.index.toString() == q;
    }).toList();
  }

  Future<void> _showAboutMe() {
    return AboutMe(
      applicationName: 'القرآن الكريم برواية ورش وحفص',
      logo: Image.asset('assets/icon/icon.png', width: 100, height: 100),
      version: '1.0.7',
      legalese: 'جميع الحقوق محفوظة © فؤاد العزبي',
      description:
          'المصحف مزود بخاصية البحث عن السور، والإشارات المرجعية، والوضع الليلي. والتصفح عن طريق السور أو الأجزاء',
    ).showCustomAbout(context);
  }

  void _openReader({int? initialPage}) async {
    // navigate and await for possible updates
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          initialPage: initialPage ?? _lastPage ?? 1,
          night: _night,
          tajweed: _tajweed,
          bookmarks: _bookmarks,
        ),
      ),
    );
    if (result != null) {
      // result is last read page
      setState(() => _lastPage = result);
      _savePref(PrefsKeys.lastPage, result);
    }
    // reload prefs in case bookmarks/toggles changed inside reader
    _loadPrefs();
  }

  ThemeData _theme(bool dark) {
    final base = dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: Colors.teal,
        secondary: Colors.tealAccent,
      ),
      appBarTheme: base.appBarTheme.copyWith(centerTitle: true, elevation: 0),
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0F1115)
          : const Color(0xFFF8F8F8),
      listTileTheme: ListTileThemeData(
        iconColor: dark ? Colors.white70 : Colors.black54,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(false),
      darkTheme: _theme(true),
      themeMode: _night ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('القرآن الكريم'),
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                await _loadPrefs();
                setState(() {});
              },
            ),
            IconButton(
              tooltip: 'عن التطبيق',
              icon: const Icon(Icons.info_outline),
              onPressed: () async {
                _showAboutMe();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن السور (عربي/انجليزي أو رقم السورة)',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
            if (_lastPage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  child: ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.bookmark_added_outlined),
                      onPressed: () => _openReader(initialPage: _lastPage),
                    ),
                    title: const Text(
                      'استمر في القراءة',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    subtitle: Text(
                      'الصفحة $_lastPage',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    onTap: () => _openReader(initialPage: _lastPage),
                    trailing: const Icon(Icons.play_circle_outline),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('فهرس السور'),
                    icon: Icon(Icons.list),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('فهرس الأجزاء'),
                    icon: Icon(Icons.grid_view_outlined),
                  ),
                ],
                selected: {_showSurahs},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _showSurahs = newSelection.first;
                  });
                },
              ),
            ),
            Expanded(
              child: _showSurahs
                  ? ListView.builder(
                      itemCount: _filteredSurahs.length,
                      itemBuilder: (ctx, i) {
                        final s = _filteredSurahs[i];
                        return Card(
                          child: ListTile(
                            leading: IconButton(
                              tooltip: 'افتح',
                              icon: const Icon(Icons.menu_book_outlined),
                              onPressed: () =>
                                  _openReader(initialPage: s.startPage),
                            ),
                            title: Text(
                              s.arabic,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                            subtitle: Text(
                              '${s.english} • p${s.startPage}-${s.endPage}',
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                            trailing: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                '${s.index}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () => _openReader(initialPage: s.startPage),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: quranJuzData.length,
                      itemBuilder: (ctx, i) {
                        final juz = quranJuzData[i];
                        return Card(
                          child: ListTile(
                            leading: IconButton(
                              tooltip: 'افتح',
                              icon: const Icon(Icons.menu_book_outlined),
                              onPressed: () =>
                                  _openReader(initialPage: juz.pageStart),
                            ),
                            title: Text(
                              'الجزء ${juz.juzNumber}',
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'بداية من الصفحة ${juz.pageStart}',
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                            trailing: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                '${juz.juzNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onTap: () =>
                                _openReader(initialPage: juz.pageStart),
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
}
