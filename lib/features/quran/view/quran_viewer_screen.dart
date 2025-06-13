import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart'; // primaryColor, bottomBarHeight
import 'widgets/quran_page.dart';
import '../viewmodel/ayah_highlight_viewmodel.dart';

class QuranViewerScreen extends ConsumerStatefulWidget {
  const QuranViewerScreen({super.key, required this.editionDir});

  final Directory editionDir;

  @override
  ConsumerState<QuranViewerScreen> createState() => _QuranViewerState();
}

class _QuranViewerState extends ConsumerState<QuranViewerScreen> {
  final _rootKey = GlobalKey<ScaffoldState>();
  PageController? _portraitCtrl;
  ScrollController? _landscapeCtrl;

  Orientation? _lastOri; // track current orientation

  /* total number of PNGs (loaded once) */
  late final Future<int> _pageCountF;

  /* original scan aspect ratio */
  static const double _aspect = 720 / 1057;

  /* dummy reciters for the dropdown */
  static const List<String> reciters = [
    'Al-Afasy',
    'Al-Hudhaify',
    'Abdul Basit',
  ];

  @override
  void initState() {
    super.initState();
    _pageCountF = _detectPageCount();
  }

  Future<int> _detectPageCount() async =>
      (await widget.editionDir
              .list()
              .where((f) => f.path.endsWith('.png'))
              .toList())
          .length;

  @override
  void dispose() {
    _portraitCtrl?.dispose();
    _landscapeCtrl?.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    leading: Builder(
      // ② tap → openDrawer()
      builder: (ctx) => IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(ctx).openDrawer(),
      ),
    ),
    title: const Text(
      'কুরআন মজীদ',
      style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 22),
    ),
    centerTitle: true,
    actions: [
      IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      IconButton(icon: const Icon(Icons.nightlight_outlined), onPressed: () {}),
      IconButton(icon: const Icon(Icons.g_translate), onPressed: () {}),
    ],
  );

  Widget _buildBottomBar(bool drawerOpen) => BottomAppBar(
    height: bottomBarHeight,
    child: Row(
      children: [
        /* left icon */
        IconButton(icon: const Icon(Icons.play_arrow), onPressed: () {}),

        /* expandable dropdown */
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: reciters.first,
              isExpanded: true,
              items: reciters
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (_) {},
            ),
          ),
        ),

        /* trailing icons */
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer(
              builder: (_, ref, __) {
                final on = ref.watch(touchModeProvider); // true = locked
                return IconButton(
                  icon: Icon(
                    Icons.touch_app_outlined,
                    color: on ? Colors.orangeAccent : Colors.white,
                  ),
                  tooltip: 'Touch mode',
                  onPressed: () {
                    // toggle first …
                    ref.read(touchModeProvider.notifier).toggle();

                    // … then clear highlight *if the mode is now locked*
                    if (!ref.read(touchModeProvider))
                      return; // on just turned ON
                    ref.read(selectedAyahProvider.notifier).clear();
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.screen_rotation_outlined),
              tooltip: 'Toggle orientation',
              onPressed: () => OrientationToggle.toggle(),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {},
            ),
            IconButton(
              tooltip: drawerOpen ? 'Close drawer' : 'Open drawer',
              icon: Icon(
                drawerOpen
                    ? Icons
                          .keyboard_arrow_left // drawer is open → show "close"
                    : Icons
                          .keyboard_arrow_right, // drawer closed  → show "open"
              ),
              onPressed: () {
                if (drawerOpen) {
                  Navigator.of(context).pop(); // closes drawer
                } else {
                  _rootKey.currentState?.openDrawer(); // opens drawer
                }
                // provider is updated via onDrawerOpened / onDrawerClosed above
              },
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildSideDrawer() {
    return Align(
      alignment: Alignment.topLeft,
      child: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          final double topInset = kToolbarHeight + media.padding.top; // AppBar
          final double bottomInset = bottomBarHeight + media.padding.bottom;

          return Padding(
            padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
            child: SizedBox(
              width: 250,
              child: Material(
                // identical look to Drawer
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        color: primaryColor,
                        child: const TabBar(
                          labelColor: Colors.white,
                          indicatorColor: Colors.white,
                          tabs: [
                            Tab(text: 'সূরা'),
                            Tab(text: 'পারা'),
                            Tab(text: 'বুকমার্ক'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Center(child: Text('Surah list ⏤ TODO')),
                            Center(child: Text('Para list ⏤ TODO')),
                            _buildBookmarkTabView(),
                          ],
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
    );
  }

  Widget _buildBookmarkTabView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: primaryColor.withOpacity(.1),
            child: const TabBar(
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'আয়াত'),
                Tab(text: 'পৃষ্ঠা'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                Center(child: Text('Ayah bookmarks ⏤ TODO')),
                Center(child: Text('Page bookmarks ⏤ TODO')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ─────────────  build  ───────────── */

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);

    return FutureBuilder<int>(
      future: _pageCountF,
      builder: (_, s) {
        if (!s.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final pageCount = s.data!;
        return OrientationBuilder(
          builder: (_, ori) {
            final width = MediaQuery.of(context).size.width;
            final itemH = width / _aspect;

            /* create the proper controller if orientation changed */
            if (ori != _lastOri) {
              if (ori == Orientation.portrait) {
                _portraitCtrl?.dispose();
                _portraitCtrl = PageController(initialPage: currentPage);
              } else {
                _landscapeCtrl?.dispose();
                _landscapeCtrl = ScrollController(
                  initialScrollOffset: currentPage * itemH,
                );
              }
              _lastOri = ori;
            }

            Widget viewer;
            if (ori == Orientation.portrait) {
              /* horizontal RTL page-snap */
              viewer = PageView.builder(
                controller: _portraitCtrl!,
                reverse: true,
                itemCount: pageCount,
                onPageChanged: (idx) {
                  ref.read(currentPageProvider.notifier).state = idx;
                  ref.read(selectedAyahProvider.notifier).clear();
                },
                itemBuilder: (_, idx) =>
                    QuranPage(pageIndex: idx, editionDir: widget.editionDir),
              );
            } else {
              /* vertical continuous scroll */
              viewer = NotificationListener<ScrollUpdateNotification>(
                onNotification: (n) {
                  final p = (n.metrics.pixels / itemH).round().clamp(
                    0,
                    math.max(0, pageCount - 1),
                  );
                  ref.read(currentPageProvider.notifier).state = p.toInt();
                  ref.read(selectedAyahProvider.notifier).clear();
                  return false;
                },
                child: ListView.builder(
                  controller: _landscapeCtrl!,
                  physics: const BouncingScrollPhysics(),
                  itemCount: pageCount,
                  itemBuilder: (_, idx) => SizedBox(
                    height: itemH,
                    width: double.infinity,
                    child: QuranPage(
                      pageIndex: idx,
                      editionDir: widget.editionDir,
                    ),
                  ),
                ),
              );
            }

            return Scaffold(
              key: _rootKey,
              drawer: _buildSideDrawer(),
              onDrawerChanged: (isOpen) {
                final drawer = ref.read(drawerOpenProvider.notifier);
                isOpen ? drawer.open() : drawer.close();
              },
              appBar: _buildAppBar(),
              bottomNavigationBar: _buildBottomBar(
                ref.watch(drawerOpenProvider),
              ),
              body: viewer,
            );
          },
        );
      },
    );
  }
}

class AyahMenu extends StatelessWidget {
  const AyahMenu({super.key, required this.anchorRect});

  final Rect anchorRect;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const menuWidth = 300.0;
    const menuHeight = 56.0;
    const verticalOffset = 10.0;

    return Positioned(
      left: (screenWidth - menuWidth) / 2,
      top: math.max(anchorRect.top - menuHeight - verticalOffset, 0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        child: SizedBox(
          height: menuHeight,
          width: menuWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(6, (index) {
              return IconButton(
                icon: Icon(Icons.star),
                onPressed: () {
                  // TODO: handle action
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
