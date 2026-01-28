import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class PrefsKeys {
  static const nightMode = 'night_mode';
  static const tajweed = 'tajweed_enabled';
  static const lastPage = 'last_page';
  static const bookmarks = 'bookmarks';
}

enum ReadingMode { normal, tajweed }

enum AppTheme { light, dark }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ReadingMode _mode = ReadingMode.normal;
  AppTheme _theme = AppTheme.light;
  int? _lastPage;
  int _bookmarksCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _shareApp() {
    Share.share(
      //'https://play.google.com/store/apps/details?id=com.eafmicroservice.quran_hafs_warsh&pcampaignid=web_share'
      'https://play.google.com/store/apps/details?id=com.eafmicroservice.quran_hafs_warsh',
    );
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _mode = (sp.getBool(PrefsKeys.tajweed) ?? false)
          ? ReadingMode.tajweed
          : ReadingMode.normal;
      _theme = (sp.getBool(PrefsKeys.nightMode) ?? false)
          ? AppTheme.dark
          : AppTheme.light;
      _lastPage = sp.getInt(PrefsKeys.lastPage);
      _bookmarksCount =
          (sp.getStringList(PrefsKeys.bookmarks) ?? const []).length;
    });
  }

  Future<void> _saveMode(ReadingMode m) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(PrefsKeys.tajweed, m == ReadingMode.tajweed);
  }

  Future<void> _saveTheme(AppTheme t) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(PrefsKeys.nightMode, t == AppTheme.dark);
  }

  Future<void> _resetLastPage() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(PrefsKeys.lastPage);
    setState(() => _lastPage = null);
  }

  Future<void> _clearBookmarks() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(PrefsKeys.bookmarks);
    setState(() => _bookmarksCount = 0);
  }

  ThemeData _buildTheme(bool dark) {
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

  Widget _buildReadingModeOption(
    BuildContext context,
    ReadingMode mode,
    String title,
    String subtitle,
    String imagePath,
  ) {
    final isSelected = _mode == mode;
    return InkWell(
      onTap: () {
        setState(() => _mode = mode);
        _saveMode(mode);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Radio button and text (appears on right in RTL)
            Expanded(
              child: RadioListTile<ReadingMode>(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  title,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                subtitle: Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                value: mode,
                groupValue: _mode,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _mode = v);
                  _saveMode(v);
                },
              ),
            ),
            const SizedBox(width: 12),
            // Preview image on the left (trailing in RTL)
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    // color: Colors.black.withOpacity(0.1),
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _theme == AppTheme.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: _buildTheme(isDark),
        child: Scaffold(
          appBar: AppBar(title: const Text('الإعدادات'), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'وضع القراءة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              _buildReadingModeOption(
                context,
                ReadingMode.normal,
                'المصحف برواية ورش',
                ' ',
                'assets/images/warsh/001.png',
              ),
              const SizedBox(height: 8),
              _buildReadingModeOption(
                context,
                ReadingMode.tajweed,
                'المصحف برواية حفص',
                ' ',
                'assets/images/hafs/001.png',
              ),
              const Divider(height: 32),
              Text(
                'الوضع',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              RadioListTile<AppTheme>(
                title: const Text(
                  'الوضع الفاتح',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                value: AppTheme.light,
                groupValue: _theme,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _theme = v);
                  _saveTheme(v);
                },
              ),
              RadioListTile<AppTheme>(
                title: const Text(
                  'الوضع الليلي',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                value: AppTheme.dark,
                groupValue: _theme,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _theme = v);
                  _saveTheme(v);
                },
              ),
              const Divider(height: 32),
              Text(
                'البيانات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text(
                  'آخر صفحة قراءة',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                subtitle: Text(
                  _lastPage == null ? 'غير محدد' : 'الصفحة $_lastPage',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                trailing: TextButton(
                  onPressed: _lastPage == null ? null : _resetLastPage,
                  child: const Text('حذف'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bookmarks_outlined),
                title: const Text(
                  'الإشارات المرجعية',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                subtitle: Text(
                  '$_bookmarksCount محفوظة',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                trailing: TextButton(
                  onPressed: _bookmarksCount == 0
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                title: const Text(
                                  'حذف جميع الإشارات المرجعية؟',
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                ),
                                content: const Text(
                                  'هذا لا يمكن التراجع عنه.',
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('إلغاء'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (ok == true) {
                            await _clearBookmarks();
                          }
                        },
                  child: const Text('حذف'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                // onPressed: () => Navigator.pop(context, true),
                onPressed: () => _shareApp(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('شارك التطبيق'),
                    SizedBox(width: 8),
                    Icon(Icons.share),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
