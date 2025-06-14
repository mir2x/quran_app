import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/quran/view/widgets/audio_control_bar.dart';
import 'package:quran_app/features/quran/view/widgets/bottom_bar.dart';
import '../../../../core/theme.dart';
import 'widgets/quran_page.dart';
import '../viewmodel/ayah_highlight_viewmodel.dart';

class QuranViewerScreen extends ConsumerStatefulWidget {
  final Directory editionDir;
  final int imageWidth;
  final int imageHeight;

  const QuranViewerScreen({
    super.key,
    required this.editionDir,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  ConsumerState<QuranViewerScreen> createState() => _QuranViewerState();
}

class _QuranViewerState extends ConsumerState<QuranViewerScreen> {
  final _rootKey = GlobalKey<ScaffoldState>();

  PageController? _portraitCtrl;
  ScrollController? _landscapeCtrl;

  Orientation? _lastOri;

  late final Future<int> _pageCountF;

  double get _aspect => widget.imageWidth / widget.imageHeight;

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
                      // TabBarView comes first
                      Expanded(
                        child: TabBarView(
                          children: [
                            Center(child: Text('Surah list ⏤ TODO')),
                            Center(child: Text('Para list ⏤ TODO')),
                            _buildBookmarkTabView(),
                          ],
                        ),
                      ),
                      // TabBar comes after (at the bottom)
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
      child: Consumer(
        builder: (_, ref, __) {
          final bookmarksAsync = ref.watch(bookmarkProvider);
          return bookmarksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading bookmarks')),
            data: (bookmarks) {
              final ayahBookmarks = bookmarks
                  .where((b) => b.type == 'ayah')
                  .toList();
              final pageBookmarks = bookmarks
                  .where((b) => b.type == 'page')
                  .toList();

              return Column(
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
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          itemCount: ayahBookmarks.length,
                          itemBuilder: (_, i) {
                            final b = ayahBookmarks[i];
                            return ListTile(
                              title: Text(b.identifier),
                              subtitle: Text(
                                'Added: ${b.timestamp.toLocal().toString().split('.').first}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => ref
                                    .read(bookmarkProvider.notifier)
                                    .remove(b.identifier),
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          itemCount: pageBookmarks.length,
                          itemBuilder: (_, i) {
                            final b = pageBookmarks[i];
                            return ListTile(
                              title: Text('Page ${b.identifier.split('-')[1]}'),
                              subtitle: Text(
                                'Added: ${b.timestamp.toLocal().toString().split('.').first}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => ref
                                    .read(bookmarkProvider.notifier)
                                    .remove(b.identifier),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);
    ref.listen<int?>(navigateToPageCommandProvider, (
      prevPageNum,
      newPageNum,
    ) async {
      if (newPageNum != null) {
        final targetPageIndex = newPageNum - 1;

        final pageCount = await _pageCountF;

        if (targetPageIndex >= 0 && targetPageIndex < pageCount) {
          final currentOrientation = MediaQuery.of(context).orientation;
          final width = MediaQuery.of(context).size.width;

          if (currentOrientation == Orientation.portrait &&
              _portraitCtrl != null) {
            _portraitCtrl!.animateToPage(
              targetPageIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else if (currentOrientation == Orientation.landscape &&
              _landscapeCtrl != null) {
            final itemH = width / _aspect;
            final offset = targetPageIndex * itemH;

            _landscapeCtrl!.animateTo(
              offset,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }

          Future.microtask(() {
            ref.read(navigateToPageCommandProvider.notifier).state = null;
          });
        } else {
          debugPrint(
            'Navigation command received for invalid page number: $newPageNum',
          );
          Future.microtask(() {
            ref.read(navigateToPageCommandProvider.notifier).state = null;
          });
        }
      }
    });

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
              viewer = PageView.builder(
                controller: _portraitCtrl!,
                reverse: true,
                itemCount: pageCount,
                onPageChanged: (idx) {
                  ref.read(currentPageProvider.notifier).state = idx;
                  if (ref.watch(quranAudioProvider) == null) {
                    ref.read(selectedAyahProvider.notifier).clear();
                  }
                },
                itemBuilder: (_, idx) => QuranPage(
                  pageIndex: idx,
                  editionDir: widget.editionDir,
                  imageWidth: widget.imageWidth,
                  imageHeight: widget.imageHeight,
                ),
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
                  if (ref.watch(quranAudioProvider) == null) {
                    ref.read(selectedAyahProvider.notifier).clear();
                  }
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
                      imageWidth: widget.imageWidth,
                      imageHeight: widget.imageHeight,
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
              bottomNavigationBar: BottomBar(
                drawerOpen: ref.watch(drawerOpenProvider),
                rootKey: _rootKey,
              ),
              body: Stack(
                children: [
                  viewer,
                  Consumer(
                    builder: (context, ref, _) {
                      final audio = ref.watch(quranAudioProvider);
                      if (audio == null) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: AudioControllerBar(
                          color: Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
