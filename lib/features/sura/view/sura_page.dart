import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huge_listview/huge_listview.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:quran_app/features/sura/model/sura_audio_state.dart';
import 'package:quran_app/features/sura/view/widgets/audio_control_bar.dart';
import 'package:quran_app/features/sura/view/widgets/ayah_card.dart';
import 'package:quran_app/features/sura/view/widgets/ayah_placeholders.dart';
import 'package:quran_app/features/sura/view/widgets/sura_app_bar.dart';
import 'package:quran_app/features/sura/view/widgets/sura_bottom_nav_bar.dart';
import '../viewmodel/sura_reciter_viewmodel.dart';
import 'package:quran_app/features/sura/viewmodel/sura_viewmodel.dart';
import '../../../shared/quran_data.dart';

class SurahPage extends ConsumerStatefulWidget {
  final int suraNumber;
  final int? initialScrollIndex;
  const SurahPage({super.key, required this.suraNumber, this.initialScrollIndex});

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  final GlobalKey<HugeListViewState> _hugeListKey = GlobalKey<HugeListViewState>();
  final ItemScrollController _itemScrollController = ItemScrollController();
  late final HugeListViewController _hugeListController;

  Timer? _timedScrollTimer;
  int _totalItems = 0;
  int _topVisibleIndex = 0;
  // --- NEW ---: State variable to track the current index for auto-scrolling
  int _currentAutoScrollIndex = 0;
  bool _showScrollToTopButton = false;

  late final StateController<Set<int>> _activePagesNotifier;

  static const int _pageSize = 24;

  void _log(String msg) {
    // ignore: avoid_print
    print('[SurahPage] $msg');
  }


  @override
  void initState() {
    super.initState();
    _hugeListController = HugeListViewController(totalItemCount: 0);
    _activePagesNotifier = ref.read(activeSurahPagesProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activePagesNotifier.update((state) => {...state, widget.suraNumber});
    });
  }

  @override
  void dispose() {
    _activePagesNotifier.update((state) => state..remove(widget.suraNumber));
    _timedScrollTimer?.cancel();
    super.dispose();
  }

  int _getTopVisibleIndex() {
    final positions = _hugeListKey.currentState?.listener.itemPositions.value;
    if (positions == null || positions.isEmpty) return _topVisibleIndex;
    return positions.map((p) => p.index).reduce(math.min);
  }

  void _startAutoScroll() {
    if (_timedScrollTimer?.isActive == true || _totalItems == 0) return;

    ref.read(isAutoScrollingProvider.notifier).state = true;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;

    final speedFactor = ref.read(scrollSpeedFactorProvider);
    final perItemDuration = Duration(milliseconds: (800 ~/ speedFactor));

    int currentIndex = _getTopVisibleIndex();

    _timedScrollTimer = Timer.periodic(perItemDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (currentIndex >= _totalItems - 1) {
        _stopAutoScroll(resetSpeed: true);
        return;
      }
      currentIndex++;
      _itemScrollController.scrollTo(
        index: currentIndex,
        duration: perItemDuration,
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    });
  }

  void _stopAutoScroll({bool resetSpeed = false}) {
    _log('Stopping auto scroll. resetSpeed=$resetSpeed');
    if (!mounted) return;
    _timedScrollTimer?.cancel();

    // No need to jump, the view is already where it should be.
    // If you still want to jump to the top visible item after stop:
    // if (_itemScrollController.isAttached) {
    //   _itemScrollController.jumpTo(index: _getTopVisibleIndex());
    // }

    ref.read(isAutoScrollingProvider.notifier).state = false;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;
    if (resetSpeed) {
      ref.read(scrollSpeedFactorProvider.notifier).state = 1.0;
    }
  }

  void _togglePlayPauseAutoScroll() {
    final bool isPaused = ref.read(isAutoScrollPausedProvider);
    if (isPaused) {
      // If it was paused, resume scrolling
      ref.read(isAutoScrollPausedProvider.notifier).state = false;
      _startAutoScroll();
    } else {
      // If it was playing, pause it
      _timedScrollTimer?.cancel();
      ref.read(isAutoScrollPausedProvider.notifier).state = true;
    }
  }

  void _changeScrollSpeed(double delta) {
    final currentSpeed = ref.read(scrollSpeedFactorProvider);
    final newSpeed = (currentSpeed + delta).clamp(0.5, 3.0);
    ref.read(scrollSpeedFactorProvider.notifier).state = newSpeed;

    final isPlaying = ref.read(isAutoScrollingProvider) && !ref.read(isAutoScrollPausedProvider);
    if (isPlaying) {
      // Restart the timer with the new speed
      _timedScrollTimer?.cancel();
      _startAutoScroll();
    }
  }

  void _scrollToTop() {
    if (_itemScrollController.isAttached) {
      // Stop autoscroll if it's active when scrolling to top
      if (ref.read(isAutoScrollingProvider)) {
        _stopAutoScroll(resetSpeed: true);
      }
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... THE REST OF THE BUILD METHOD REMAINS EXACTLY THE SAME ...
    // --- NO CHANGES NEEDED IN THE WIDGET TREE ---
    final suraDataAsync = ref.watch(suraDataProvider(widget.suraNumber));
    final suraName = "সূরা ${suraNames[widget.suraNumber - 1]}";
    final quranAudioState = ref.watch(suraAudioProvider);
    final isTimedScrolling = ref.watch(isAutoScrollingProvider);
    final showBottomNav = !isTimedScrolling && quranAudioState == null;

    ref.listen<ScrollCommand?>(suraScrollCommandProvider, (previous, next) {
      if (next != null && next.suraNumber == widget.suraNumber && _itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: next.scrollIndex,
          alignment: 0.5,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
        ref.read(suraScrollCommandProvider.notifier).state = null;
      }
    });

    ref.listen<AsyncValue<List<dynamic>>>(suraDataProvider(widget.suraNumber), (previous, next) {
      if (previous is AsyncLoading && next is AsyncData) {
        if (widget.initialScrollIndex != null && _itemScrollController.isAttached) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _itemScrollController.jumpTo(
              index: widget.initialScrollIndex!,
              alignment: 0.5,
            );
          });
        }
      }
    });

    ref.listen<SuraAudioState?>(suraAudioProvider, (previous, next) {
      if (next != null && next.isPlaying) {
        final ayahIndex = next.ayah - 1;
        if (ayahIndex >= 0 && ayahIndex < _totalItems && _itemScrollController.isAttached) {
          _itemScrollController.scrollTo(
            index: ayahIndex,
            alignment: 0.5,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });

    return SafeArea(
      child: Scaffold(
        appBar: SuraAppBar(title: suraName),
        body: Column(
          children: [
            Expanded(
              child: suraDataAsync.when(
                loading: () => ListView.builder(
                  itemCount: 15,
                  itemBuilder: (_, __) => const AyahPlaceholder(),
                ),
                error: (error, stack) => Center(child: Text('Failed to load Sura details:\n$error')),
                data: (ayahs) {
                  _totalItems = ayahs.length;
                  _hugeListController.totalItemCount = _totalItems;

                  return Stack(
                    children: [
                      HugeListView<dynamic>(
                        key: _hugeListKey,
                        scrollController: _itemScrollController,
                        listViewController: _hugeListController,

                        pageSize: _pageSize,
                        startIndex: widget.initialScrollIndex ?? 0,
                        pageFuture: (page) async {
                          final from = page * _pageSize;
                          final to = math.min(ayahs.length, from + _pageSize);
                          if (from >= to) return const <dynamic>[];
                          return ayahs.sublist(from, to);
                        },

                        itemBuilder: (context, index, entry) {
                          final isHighlighted = quranAudioState != null &&
                              quranAudioState.surah == widget.suraNumber &&
                              quranAudioState.ayah == entry.ayah;

                          return AyahCard(
                            suraNumber: widget.suraNumber,
                            ayah: entry,
                            suraName: suraName,
                            isHighlighted: isHighlighted,
                          );
                        },
                        placeholderBuilder: (context, index) => const AyahPlaceholder(),
                        waitBuilder: (context) => ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 15,
                          itemBuilder: (_, __) => const AyahPlaceholder(),
                        ),
                        emptyBuilder: (context) => const Center(child: Text('No ayahs found')),
                        errorBuilder: (context, error) => Center(child: Text('Error: $error')),

                        padding: const EdgeInsets.only(bottom: 80.0),
                        firstShown: (index) {
                          if (!mounted) return;
                          // We still use this to show/hide the scroll-to-top button
                          setState(() {
                            _topVisibleIndex = index;
                            _showScrollToTopButton = index > 5;
                          });
                        },

                        thumbBuilder: DraggableScrollbarThumbs.SemicircleThumb,
                        thumbHeight: 48,
                        thumbBackgroundColor: Colors.white,
                        thumbDrawColor: Colors.green,
                        alwaysVisibleThumb: false,
                      ),

                      if (ref.watch(isAutoScrollingProvider)) _buildAutoScrollController(context),
                    ],
                  );
                },
              ),
            ),
            if (quranAudioState != null)
              AudioControllerBar(color: Theme.of(context).primaryColor),
          ],
        ),
        bottomNavigationBar: showBottomNav
            ? SuraBottomNavBar(
          totalAyahs: _totalItems,
          suraNumber: widget.suraNumber,
          onStartAutoScroll: _startAutoScroll,
          onStopAutoScroll: () => _stopAutoScroll(resetSpeed: true),
        )
            : null,
        floatingActionButton: _showScrollToTopButton
            ? FloatingActionButton(
          onPressed: _scrollToTop,
          mini: true,
          backgroundColor: Colors.green,
          child: const Icon(Icons.arrow_upward, color: Colors.white),
        )
            : null,
      ),
    );
  }

  Widget _buildAutoScrollController(BuildContext context) {
    // ... THIS METHOD REMAINS EXACTLY THE SAME ...
    final scrollSpeedFactor = ref.watch(scrollSpeedFactorProvider);
    final isPaused = ref.watch(isAutoScrollPausedProvider);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.green.shade900),
              onPressed: _togglePlayPauseAutoScroll,
            ),
            IconButton(
                icon: Icon(Icons.remove, color: Colors.green.shade900),
                onPressed: () => _changeScrollSpeed(-0.5)),
            Text('${scrollSpeedFactor.toStringAsFixed(1)}x',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900)),
            IconButton(
                icon: Icon(Icons.add, color: Colors.green.shade900),
                onPressed: () => _changeScrollSpeed(0.5)),
            IconButton(
                icon: Icon(Icons.close, color: Colors.green.shade900),
                onPressed: () => _stopAutoScroll(resetSpeed: true)),
          ],
        ),
      ),
    );
  }
}