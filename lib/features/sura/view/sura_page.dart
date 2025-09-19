import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/model/sura_audio_state.dart';
import 'package:quran_app/features/sura/view/widgets/audio_control_bar.dart';
import 'package:quran_app/features/sura/view/widgets/audio_range_selection_dialog.dart';
import 'package:quran_app/features/sura/view/widgets/ayah_card.dart';
import 'package:quran_app/features/sura/view/widgets/ayah_placeholders.dart';
import 'package:quran_app/features/sura/view/widgets/details_bottom_sheet.dart';
import 'package:quran_app/features/sura/view/widgets/search_page.dart';
import 'package:quran_app/features/sura/view/widgets/translation_selection_dialog.dart';
import 'package:quran_app/features/sura/viewmodel/sura_reciter_viewmodel.dart';
import 'package:quran_app/features/sura/viewmodel/sura_viewmodel.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../shared/quran_data.dart';

class SurahPage extends ConsumerStatefulWidget {
  final int suraNumber;
  final int? initialScrollIndex;
  const SurahPage({super.key, required this.suraNumber, this.initialScrollIndex});

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  Timer? _timedScrollTimer;
  int _totalItems = 0;
  bool _showScrollToTopButton = false;

  late final StateController<Set<int>> _activePagesNotifier;

  @override
  void initState() {
    super.initState();

    _activePagesNotifier = ref.read(activeSurahPagesProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the stored notifier
      _activePagesNotifier.update((state) => {...state, widget.suraNumber});
    });

    _itemPositionsListener.itemPositions.addListener(() {
      final visibleIndices = _itemPositionsListener.itemPositions.value.map((item) => item.index).toList();
      if (visibleIndices.isNotEmpty) {
        if (mounted) {
          setState(() {
            _showScrollToTopButton = visibleIndices.first > 5;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _activePagesNotifier.update((state) => state..remove(widget.suraNumber));
    _timedScrollTimer?.cancel();
    super.dispose();
  }

  // --- MIGRATE: _startAutoScroll ---
  void _startAutoScroll() {
    if (_timedScrollTimer?.isActive == true || _totalItems == 0) return;

    ref.read(isAutoScrollingProvider.notifier).state = true;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;

    final speedFactor = ref.read(scrollSpeedFactorProvider);
    const double secondsPerItem = 4.0;
    final adjustedSecondsPerItem = secondsPerItem / speedFactor;

    final currentPositions = _itemPositionsListener.itemPositions.value;
    final lastVisibleIndex = currentPositions.isEmpty ? 0 : currentPositions.last.index;

    final remainingItems = _totalItems - lastVisibleIndex;
    if (remainingItems <= 0) {
      _stopAutoScroll(resetSpeed: true);
      return;
    }

    final durationInSeconds = (remainingItems * adjustedSecondsPerItem).round();

    _itemScrollController.scrollTo(
      index: _totalItems - 1,
      duration: Duration(seconds: durationInSeconds),
      curve: Curves.linear,
    );

    _timedScrollTimer = Timer(Duration(seconds: durationInSeconds + 1), () {
      if (mounted) {
        _stopAutoScroll(resetSpeed: true);
      }
    });
  }

  // --- MIGRATE: _stopAutoScroll ---
  void _stopAutoScroll({bool resetSpeed = false}) {
    if (!mounted) return;
    _timedScrollTimer?.cancel();

    if (_itemScrollController.isAttached) {
      final currentPositions = _itemPositionsListener.itemPositions.value;
      if (currentPositions.isNotEmpty) {
        _itemScrollController.jumpTo(index: currentPositions.first.index);
      }
    }

    ref.read(isAutoScrollingProvider.notifier).state = false;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;
    if (resetSpeed) {
      ref.read(scrollSpeedFactorProvider.notifier).state = 1.0;
    }
  }

  // NO CHANGE NEEDED (logic is sound)
  void _togglePlayPauseAutoScroll() {
    if (!mounted) return;
    final bool isPlaying = _timedScrollTimer?.isActive ?? false;
    if (isPlaying) {
      _stopAutoScroll();
      ref.read(isAutoScrollPausedProvider.notifier).state = true;
    } else {
      ref.read(isAutoScrollPausedProvider.notifier).state = false;
      _startAutoScroll();
    }
  }

  // NO CHANGE NEEDED (logic is sound)
  void _changeScrollSpeed(double delta) {
    if (!mounted) return;
    final currentSpeed = ref.read(scrollSpeedFactorProvider);
    double newSpeed = (currentSpeed + delta).clamp(0.5, 3.0);
    ref.read(scrollSpeedFactorProvider.notifier).state = newSpeed;
    final bool isPlayingAndNotPaused = ref.read(isAutoScrollingProvider) && !ref.read(isAutoScrollPausedProvider);
    if (isPlayingAndNotPaused) {
      _stopAutoScroll();
      _startAutoScroll();
    }
  }

  // --- MIGRATE: _scrollToTop ---
  void _scrollToTop() {
    _itemScrollController.scrollTo(
      index: 0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final suraDataAsync = ref.watch(suraDataProvider(widget.suraNumber));
    final suraName = "সূরা ${suraNames[widget.suraNumber - 1]}";
    final quranAudioState = ref.watch(suraAudioProvider);
    final isTimedScrolling = ref.watch(isAutoScrollingProvider);
    final showBottomNav = !isTimedScrolling && quranAudioState == null;

    ref.listen<ScrollCommand?>(suraScrollCommandProvider, (previous, next) {
      // Check if a new, valid command has been issued
      if (next != null && next.suraNumber == widget.suraNumber) {
        // The command is for THIS surah page.
        // We use scrollTo for a smooth animation, which is better UX when returning to a page.
        _itemScrollController.scrollTo(
          index: next.scrollIndex,
          alignment: 0.5,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );

        // VERY IMPORTANT: Consume the command by resetting the provider to null.
        // This prevents the scroll from happening again on every rebuild.
        ref.read(suraScrollCommandProvider.notifier).state = null;
      }
    });


    ref.listen<AsyncValue<List<dynamic>>>(suraDataProvider(widget.suraNumber), (previous, next) {
      // We listen for the state to change.
      // We only care about the moment it goes from loading to having data.
      if (previous is AsyncLoading && next is AsyncData) {
        if (widget.initialScrollIndex != null) {
          // Use a post-frame callback to ensure the list is painted before we try to scroll.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _itemScrollController.isAttached) {
              _itemScrollController.jumpTo(
                index: widget.initialScrollIndex!,
                alignment: 0.5,
              );
            }
          });
        }
      }
    });

    // --- MIGRATE: The audio sync listener ---
    ref.listen<SuraAudioState?>(suraAudioProvider, (previous, next) {
      if (next != null && next.isPlaying) {
        final ayahIndex = next.ayah - 1;
        if (ayahIndex >= 0 && ayahIndex < _totalItems) {
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
        appBar: _buildAppBar(context, suraName),
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

                  return Stack(
                    children: [
                      // --- MIGRATE: Replace the entire scrollable area ---
                      ScrollablePositionedList.builder(
                        itemCount: ayahs.length + 1, // Add 1 for the bottom padding
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        itemBuilder: (context, index) {
                          if (index == ayahs.length) {
                            return const SizedBox(height: 80.0);
                          }

                          final ayah = ayahs[index];
                          final isHighlighted = quranAudioState != null &&
                              quranAudioState.surah == widget.suraNumber &&
                              quranAudioState.ayah == ayah.ayah;

                          return AyahCard(
                            suraNumber: widget.suraNumber,
                            ayah: ayah,
                            suraName: suraName,
                            isHighlighted: isHighlighted,
                          );
                        },
                      ),
                      if (isTimedScrolling) _buildAutoScrollController(context),
                    ],
                  );
                },
              ),
            ),
            if (quranAudioState != null) AudioControllerBar(color: Theme.of(context).primaryColor)
          ],
        ),
        bottomNavigationBar: showBottomNav ? _buildBottomNavBar(context) : null,
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

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAutoScrollController(BuildContext context) {
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

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green.shade700,
      unselectedItemColor: Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontFamily: 'SolaimanLipi'),
      unselectedLabelStyle: const TextStyle(fontFamily: 'SolaimanLipi'),
      onTap: (index) => _onNavBarTapped(index),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'অনুবাদ'),
        BottomNavigationBarItem(
            icon: Icon(Icons.text_fields), label: 'শব্দে শব্দে'),
        BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill_outlined), label: 'অডিও শুনুন'),
        BottomNavigationBarItem(
            icon: Icon(Icons.swipe_outlined), label: 'অটো স্ক্রল'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'বিস্তারিত'),
      ],
    );
  }

  void _onNavBarTapped(int index) {
    if (!mounted) return;

    switch (index) {
      case 0:
        showDialog(
            context: context,
            builder: (context) => const TranslatorSelectionDialog());
        break;
      case 1:
        final currentState = ref.read(showWordByWordProvider);
        ref.read(showWordByWordProvider.notifier).state = !currentState;
        break;
      case 2:
        if (_totalItems > 0) {
          _stopAutoScroll(resetSpeed: true);
          showDialog(
            context: context,
            builder: (context) => AudioRangeSelectionDialog(
                totalAyahs: _totalItems, suraNumber: widget.suraNumber),
          );
        }
        break;
      case 3:
        if (_totalItems > 0) {
          ref.read(suraAudioPlayerProvider).stop();
          if (ref.read(isAutoScrollingProvider)) {
            _stopAutoScroll();
          } else {
            _startAutoScroll();
          }
        }
        break;
      case 4:
        showDetailsBottomSheet(context);
        break;
    }
  }
}