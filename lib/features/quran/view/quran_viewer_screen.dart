import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/quran/view/widgets/audio_control_bar.dart';
import 'package:quran_app/features/quran/view/widgets/bottom_bar.dart';
import 'package:quran_app/features/quran/view/widgets/drawer/side_drawer.dart';
import 'widgets/quran_page.dart';
import '../viewmodel/ayah_highlight_viewmodel.dart';

class QuranViewerScreen extends ConsumerStatefulWidget {
  final Directory editionDir;
  final int imageWidth;
  final int imageHeight;
  final String imageExt;

  const QuranViewerScreen({
    super.key,
    required this.editionDir,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageExt,
  });

  @override
  ConsumerState<QuranViewerScreen> createState() => _QuranViewerState();
}

class _QuranViewerState extends ConsumerState<QuranViewerScreen> {
  final _rootKey = GlobalKey<ScaffoldState>();

  PageController? _portraitCtrl;
  ScrollController? _landscapeCtrl;

  Orientation? _lastOri;
  double get _aspect => widget.imageWidth / widget.imageHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editionConfigProvider.notifier).set(EditionConfig(
        dir: widget.editionDir,
        imageWidth: widget.imageWidth,
        imageHeight: widget.imageHeight,
        imageExt: widget.imageExt,
      ));
    });
  }


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

  @override
  Widget build(BuildContext context) {
    final allBoxesAsync = ref.watch(allBoxesProvider);

    ref.listen<int?>(navigateToPageCommandProvider, (
        prevPageNum,
        newPageNum,
        ) async {
      final totalPageCountAsync = ref.read(totalPageCountProvider);
      final pageCount = totalPageCountAsync.value ?? 604;

      if (newPageNum != null) {
        final targetPageIndex = newPageNum - 1;

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

    return allBoxesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: Text('Error loading Quran data: ${e.toString()}\n$s')),
      ),
      data: (allBoxes) {
        final totalPageCountAsync = ref.watch(totalPageCountProvider);
        return totalPageCountAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Scaffold(
            appBar: _buildAppBar(),
            body: Center(child: Text('Error loading page count: ${e.toString()}\n$s')),
          ),
          data: (pageCount) {
            return OrientationBuilder(
              builder: (_, ori) {
                final width = MediaQuery.of(context).size.width;
                final itemH = width / _aspect;
                if (ori != _lastOri) {
                  if (ori == Orientation.portrait) {
                    _portraitCtrl?.dispose();
                    _portraitCtrl = PageController(initialPage: ref.read(currentPageProvider));
                  } else {
                    _landscapeCtrl?.dispose();
                    _landscapeCtrl = ScrollController(
                      initialScrollOffset: ref.read(currentPageProvider) * itemH,
                    );
                  }
                  _lastOri = ori;
                }

                Widget viewer;
                if (ori == Orientation.portrait) {
                  viewer = PageView.builder(
                    controller: _portraitCtrl!,
                    reverse: true,
                    itemCount: pageCount, // Use the loaded pageCount
                    onPageChanged: (idx) {
                      ref.read(currentPageProvider.notifier).state = idx;
                      final currentSelectedState = ref.read(selectedAyahProvider);
                      // Clear the selected ayah ONLY if it was selected by audio.
                      if (currentSelectedState?.source == AyahSelectionSource.tap) {
                        ref.read(selectedAyahProvider.notifier).clear();
                      }
                    },
                    itemBuilder: (_, idx) => QuranPage(
                      pageIndex: idx, // Pass 0-based index
                      editionDir: widget.editionDir,
                      imageWidth: widget.imageWidth,
                      imageHeight: widget.imageHeight,
                      imageExt: widget.imageExt,
                    ),
                  );
                } else {
                  /* vertical continuous scroll */
                  viewer = NotificationListener<ScrollUpdateNotification>(
                    onNotification: (n) {
                      final p = (n.metrics.pixels / itemH).round().clamp(
                        0,
                        math.max(0, pageCount - 1), // Use the loaded pageCount
                      );
                      ref.read(currentPageProvider.notifier).state = p.toInt();
                      final currentSelectedState = ref.read(selectedAyahProvider);
                      // Clear the selected ayah ONLY if it was selected by audio.
                      if (currentSelectedState?.source == AyahSelectionSource.tap) {
                        ref.read(selectedAyahProvider.notifier).clear();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _landscapeCtrl!,
                      physics: const BouncingScrollPhysics(),
                      itemCount: pageCount, // Use the loaded pageCount
                      itemBuilder: (_, idx) => SizedBox(
                        height: itemH,
                        width: double.infinity,
                        child: QuranPage(
                          pageIndex: idx, // Pass 0-based index
                          editionDir: widget.editionDir,
                          imageWidth: widget.imageWidth,
                          imageHeight: widget.imageHeight,
                          imageExt: widget.imageExt,
                        ),
                      ),
                    ),
                  );
                }

                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) async {
                    if (didPop) return;
                    final orientation = MediaQuery.of(context).orientation;
                    if (orientation == Orientation.landscape) {
                      OrientationToggle.toggle();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Scaffold(
                    key: _rootKey,
                    drawer: const SideDrawer(),
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
