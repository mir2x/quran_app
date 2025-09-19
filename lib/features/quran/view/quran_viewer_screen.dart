import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import screenutil
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:quran_app/features/quran/view/widgets/audio_control_bar.dart';
import 'package:quran_app/features/quran/view/widgets/bottom_bar.dart';
import 'package:quran_app/features/quran/view/widgets/custom_app_bar.dart';
import 'package:quran_app/features/quran/view/widgets/drawer/side_drawer.dart';
import '../model/selected_ayah_state.dart';
import '../viewmodel/audio_providers.dart';
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
  PageController? _portraitController;
  ScrollController? _landscapeController;

  Orientation? _lastOrientation;

  double get _aspectRatio => widget.imageWidth / widget.imageHeight;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  static const double _bottomBarHeight = 64.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pageInfoVisibilityProvider.notifier).show();
      ref
          .read(editionConfigProvider.notifier)
          .set(
            EditionConfig(
              dir: widget.editionDir,
              imageWidth: widget.imageWidth,
              imageHeight: widget.imageHeight,
              imageExt: widget.imageExt,
            ),
          );
    });
  }

  @override
  void dispose() {
    _portraitController?.dispose();
    _landscapeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBoxesAsync = ref.watch(allBoxesProvider);

    final barsVisible = ref.watch(barsVisibilityProvider);
    final barsVisibilityNotifier = ref.read(barsVisibilityProvider.notifier);

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
              _portraitController != null) {
            _portraitController!.animateToPage(
              targetPageIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else if (currentOrientation == Orientation.landscape &&
              _landscapeController != null) {
            final itemH = width / _aspectRatio;
            final offset = targetPageIndex * itemH;

            _landscapeController!.animateTo(
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(
        appBar: CustomAppBar(),
        body: Center(
          child: Text(
            'Error loading Quran data: ${e.toString()}\n$s',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      ),
      data: (allBoxes) {
        final totalPageCountAsync = ref.watch(totalPageCountProvider);
        return totalPageCountAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => Scaffold(
            appBar: CustomAppBar(),
            body: Center(
              child: Text(
                'Error loading page count: ${e.toString()}\n$s',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
          data: (pageCount) {
            return OrientationBuilder(
              builder: (_, ori) {
                final width = MediaQuery.of(context).size.width;
                final itemH = width / _aspectRatio;

                if (ori != _lastOrientation) {
                  if (ori == Orientation.portrait) {
                    _portraitController?.dispose();
                    _portraitController = PageController(
                      initialPage: ref.read(currentPageProvider),
                    );
                  } else {
                    _landscapeController?.dispose();
                    _landscapeController = ScrollController(
                      initialScrollOffset:
                          ref.read(currentPageProvider) * itemH,
                    );
                  }
                  _lastOrientation = ori;
                }

                Widget viewer;
                if (ori == Orientation.portrait) {
                  viewer = PageView.builder(
                    controller: _portraitController!,
                    reverse: true,
                    itemCount: pageCount,
                    onPageChanged: (idx) {
                      ref.read(currentPageProvider.notifier).state = idx;
                      ref.read(pageInfoVisibilityProvider.notifier).show();
                      final currentSelectedState = ref.read(
                        selectedAyahProvider,
                      );
                      if (currentSelectedState?.source ==
                          AyahSelectionSource.tap) {
                        ref.read(selectedAyahProvider.notifier).clear();
                      }
                    },

                    itemBuilder: (_, idx) => QuranPage(
                      pageIndex: idx,
                      // Pass 0-based index
                      editionDir: widget.editionDir,
                      imageWidth: widget.imageWidth,
                      imageHeight: widget.imageHeight,
                      imageExt: widget.imageExt,
                    ),
                  );
                } else {
                  viewer = NotificationListener<ScrollUpdateNotification>(
                    onNotification: (n) {
                      final p = (n.metrics.pixels / itemH).round().clamp(
                        0,
                        math.max(0, pageCount - 1),
                      );
                      if (ref.read(currentPageProvider) != p.toInt()) {
                        ref.read(currentPageProvider.notifier).state = p.toInt();
                        ref.read(pageInfoVisibilityProvider.notifier).show();
                        final currentSelectedState = ref.read(
                          selectedAyahProvider,
                        );
                        if (currentSelectedState?.source ==
                            AyahSelectionSource.tap) {
                          ref.read(selectedAyahProvider.notifier).clear();
                        }
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _landscapeController!,
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
                    body: GestureDetector(
                      onDoubleTap: barsVisibilityNotifier.toggle,
                      child: SafeArea(
                        child: Stack(
                          children: [
                            viewer,
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: AnimatedOpacity(
                                opacity: barsVisible ? 1.0 : 0.0,
                                duration: _animationDuration,
                                curve: Curves.easeInOut,
                                child: IgnorePointer(
                                  ignoring: !barsVisible,
                                  child: CustomAppBar(),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: AnimatedOpacity(
                                opacity: barsVisible ? 1.0 : 0.0,
                                duration: _animationDuration,
                                curve: Curves.easeInOut,
                                child: IgnorePointer(
                                  ignoring: !barsVisible,
                                  child: BottomBar(
                                    drawerOpen: ref.watch(drawerOpenProvider),
                                    rootKey: _rootKey,
                                  ),
                                ),
                              ),
                            ),

                            Consumer(
                              builder: (context, ref, _) {
                                final audio = ref.watch(quranAudioProvider);
                                final isAudioPlaying = audio != null;
                                if (!isAudioPlaying) {
                                  return const SizedBox.shrink(); // Hide when not playing
                                }

                                final double safeAreaBottom = MediaQuery.of(
                                  context,
                                ).padding.bottom;

                                // Use scaled bottom bar height
                                final double dynamicBottom = barsVisible
                                    ? _bottomBarHeight
                                          .h // Scale the static bottom bar height
                                    : safeAreaBottom;

                                return AnimatedPositioned(
                                  duration: _animationDuration,
                                  curve: Curves.easeInOut,
                                  left: 0,
                                  right: 0,
                                  bottom: dynamicBottom,
                                  child: AudioControllerBar(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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
