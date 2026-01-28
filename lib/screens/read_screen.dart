import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../utils/show_toast.dart';
import '../utils/quran_devision.dart';
import 'settings_screen.dart';
import '../utils/quran_sajda.dart';

class ReaderScreen extends StatefulWidget {
  final int initialPage; // 1..604
  final bool night;
  final bool tajweed;
  final Set<int> bookmarks;

  const ReaderScreen({
    super.key,
    required this.initialPage,
    required this.night,
    required this.tajweed,
    required this.bookmarks,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  static const int totalPages = 606; // holy quran, plus 2 khatem pages
  late final PageController _pageController;
  late int _currentPage;
  late bool _night;
  late bool _tajweed;
  late Set<int> _bookmarks;
  bool _showUI = false; // Controls visibility of app bar and bottom nav

  // For 3D effect we keep track of page scroll
  // ignore: unused_field
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // keep screen on
    _currentPage = widget.initialPage.clamp(1, totalPages);
    _pageController = PageController(
      initialPage: totalPages - _currentPage,
    ); // RTL mapping
    _night = widget.night;
    _tajweed = widget.tajweed;
    _bookmarks = {...widget.bookmarks};

    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    WakelockPlus.disable(); // allow screen to sleep when app is closed
    super.dispose();
  }

  Future<void> _persistLastPage() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(PrefsKeys.lastPage, _currentPage);
  }

  Future<void> _persistBookmarks() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(
      PrefsKeys.bookmarks,
      _bookmarks.map((e) => e.toString()).toList(),
    );
  }

  String _assetForPage(int page) {
    if (page == 605) {
      return 'assets/images/khatem/page_1.jpg';
    } else if (page == 606) {
      return 'assets/images/khatem/page_2.jpg';
    }

    final idx = page.toString().padLeft(3, '0');
    final base = 'assets/images${_tajweed ? '/hafs' : '/warsh'}';

    return '$base/$idx.png';
  }

  // Map PageView index (0..totalPages-1) to actual page number RTL
  int _pageForIndex(int index) => totalPages - index;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = _pageForIndex(index);
    });
    _persistLastPage();
    final sajdah = quranSajdahData.firstWhere(
      (sajda) => sajda.page == _currentPage,
      orElse: () => SajdaInfo(0, "", 0, ""),
    );
    if (sajdah.page == _currentPage) {
      return showToast(" سجدة في هذه الصفحة "); //${sajdah.sajdahType}
    }
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarks.contains(_currentPage)) {
        _bookmarks.remove(_currentPage);
      } else {
        _bookmarks.add(_currentPage);
      }
    });
    _persistBookmarks();
  }

  void _jumpToPageDialog() async {
    final controller = TextEditingController(text: _currentPage.toString());
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اذهب إلى الصفحة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '1..606'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v == null) {
                Navigator.pop(ctx);
                return;
              } else if (v < 1 || v > totalPages) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('لا يوجد صفحة بهذا الرقم'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              } else {
                Navigator.pop(ctx, v.clamp(1, totalPages));
              }
            },
            child: const Text('اذهب'),
          ),
        ],
      ),
    );
    if (page != null) {
      setState(() => _currentPage = page);
      _pageController.jumpToPage(totalPages - _currentPage);
      _persistLastPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _night ? const Color(0xFF0F1115) : const Color(0xFFF2EFEA);
    final fg = _night ? Colors.white : Colors.black87;

    // Get device screen dimensions using MediaQuery
    final mediaQuery = MediaQuery.of(context);
    final deviceWidth = mediaQuery.size.width;
    final pageAspectRatio = 595 / 842; // portrait page ratio
    int huzbNumber = getHizbForPage(_currentPage).hizbNumber;
    int juzNumber = getJuzForPage(_currentPage).juzNumber;
    String rubType = getRubForPage(_currentPage).type;

    return Theme(
      data: _night
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      child: Scaffold(
        backgroundColor: bg,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: _showUI
            ? AppBar(
                backgroundColor: bg,
                foregroundColor: fg,
                title: Column(
                  children: [
                    Text(
                      'الصفحة $_currentPage', // / $totalPages
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'الحزب $huzbNumber | الجزء $juzNumber - $rubType',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    tooltip: 'قائمة الإشارات المرجعية',
                    icon: const Icon(Icons.bookmarks_outlined),
                    onPressed: () async {
                      final selected = await showModalBottomSheet<int>(
                        context: context,
                        showDragHandle: true,
                        builder: (ctx) {
                          final bms = _bookmarks.toList()..sort();
                          if (bms.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text('لا يوجد إشارات مرجعية بعد'),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: bms.length,
                            itemBuilder: (c, i) => ListTile(
                              leading: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setState(() {
                                    _bookmarks.remove(bms[i]);
                                  });
                                  _persistBookmarks();
                                  if (Navigator.canPop(c)) Navigator.pop(c);
                                },
                              ),
                              title: Text(
                                'الصفحة ${bms[i]}',
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                              ),
                              trailing: const Icon(Icons.bookmark_outline),
                              onTap: () => Navigator.pop(ctx, bms[i]),
                            ),
                          );
                        },
                      );
                      if (selected != null) {
                        setState(() => _currentPage = selected);
                        _pageController.jumpToPage(totalPages - _currentPage);
                        _persistLastPage();
                      }
                    },
                  ),
                ],
              )
            : null,
        body: SafeArea(
          child: Directionality(
            textDirection: TextDirection.ltr, // enforce RTL scroll
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) => false,
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: _onPageChanged,
                scrollDirection: Axis.horizontal,
                // physics remain default; RTL achieved by reversing index mapping
                itemBuilder: (ctx, index) {
                  final page = _pageForIndex(index);
                  final rotation = _computeYRotation(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _showUI = !_showUI;
                      });
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective
                        ..rotateY(rotation),
                      child: _showUI
                          ? Center(
                              child: InteractiveViewer(
                                minScale: 1.0,
                                maxScale: 3.0,
                                child: SizedBox(
                                  width: deviceWidth * 0.9,
                                  height: (deviceWidth * 0.9) / pageAspectRatio,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: bg,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: _night ? 0.6 : 0.2,
                                          ),
                                          // color: Colors.black.withOpacity(_night ? 0.6 : 0.2,),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildPageImage(
                                        _assetForPage(page),
                                        BoxFit.contain,
                                        width: deviceWidth * 0.9,
                                        height:
                                            (deviceWidth * 0.9) /
                                            pageAspectRatio,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : SizedBox.expand(
                              child: _buildPageImage(
                                _assetForPage(page),
                                BoxFit.fill,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        bottomNavigationBar: _showUI ? _buildBottomBar(context, bg, fg) : null,
        floatingActionButton: _showUI
            ? FloatingActionButton.extended(
                onPressed: _toggleBookmark,
                label: Text(
                  _bookmarks.contains(_currentPage) ? 'محفوظ' : 'وضع علامة',
                ),
                icon: Icon(
                  _bookmarks.contains(_currentPage)
                      ? Icons.bookmark_added
                      : Icons.bookmark_add_outlined,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPageImage(
    String asset,
    BoxFit fit, {
    double? width,
    double? height,
  }) {
    final image = Image.asset(
      asset,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (c, e, s) {
        return Center(
          child: Text(
            'Missing page',
            style: TextStyle(color: _night ? Colors.white : Colors.black87),
          ),
        );
      },
    );

    if (_night) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: image,
      );
    }
    return image;
  }

  double _computeYRotation(int index) {
    // 3D effect around the current scroll position
    final page = _pageController.hasClients
        ? (_pageController.page ?? 0.0)
        : _pageController.initialPage.toDouble();
    final delta = (page - index).clamp(-0.50, 0.50);
    // Rotate a small amount, flipping subtly as it transitions (LTR direction)
    return -delta * (math.pi / 24); // ~7.5 degrees (negated for LTR)
  }

  Widget _buildBottomBar(BuildContext context, Color bg, Color fg) {
    return Container(
      height: 50.0,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'الصفحة التالية',
              icon: const Icon(Icons.chevron_left), // RTL previous
              color: fg,
              onPressed: () {
                final target = (_currentPage + 1).clamp(1, totalPages);
                setState(() => _currentPage = target);
                _pageController.animateToPage(
                  totalPages - target,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
                _persistLastPage();
              },
            ),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Slider(
                  value: _currentPage.toDouble(),
                  min: 1,
                  max: totalPages.toDouble(),
                  divisions: totalPages - 1,
                  onChanged: (v) {
                    setState(() => _currentPage = v.round());
                  },
                  onChangeEnd: (v) {
                    _pageController.jumpToPage(totalPages - _currentPage);
                    _persistLastPage();
                  },
                ),
              ),
            ),
            IconButton(
              tooltip: 'الصفحة السابقة ',
              icon: const Icon(Icons.chevron_right), // RTL next
              color: fg,
              onPressed: () {
                final target = (_currentPage - 1).clamp(1, totalPages);
                setState(() => _currentPage = target);
                _pageController.animateToPage(
                  totalPages - target,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
                _persistLastPage();
              },
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _jumpToPageDialog,
              child: const Text('انتقل إلى الصفحة'),
            ),
          ],
        ),
      ),
    );
  }
}
