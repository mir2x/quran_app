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
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../../shared/quran_data.dart';

class SurahPage extends ConsumerStatefulWidget {
  final int suraNumber;
  final int? initialScrollIndex;
  const SurahPage(
      {super.key, required this.suraNumber, this.initialScrollIndex});

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  late AutoScrollController _autoScrollController;
  Timer? _timedScrollTimer;
  int _totalItems = 0;
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    _autoScrollController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );
    _autoScrollController.addListener(() {
      if (mounted) {
        setState(() {
          _showScrollToTopButton = _autoScrollController.offset > 400;
        });
      }
    });
    // Initial scroll logic remains the same
    if (widget.initialScrollIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _autoScrollController.scrollToIndex(
            widget.initialScrollIndex!,
            preferPosition: AutoScrollPosition.middle,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timedScrollTimer?.cancel();
    _autoScrollController.dispose();
    super.dispose();
  }

  // --- All controller methods (_startAutoScroll, _scrollToTop, etc.) remain unchanged ---
  void _startAutoScroll() {
    if (_timedScrollTimer?.isActive == true || _totalItems == 0) return;

    ref.read(isAutoScrollingProvider.notifier).state = true;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;

    final speedFactor = ref.read(scrollSpeedFactorProvider);
    final double pixelsPerSecond = 50.0 * speedFactor;

    final currentOffset = _autoScrollController.offset;
    final maxOffset = _autoScrollController.position.maxScrollExtent;
    final remainingDistance = maxOffset - currentOffset;

    if (remainingDistance <= 0) {
      _stopAutoScroll(resetSpeed: true);
      return;
    }

    final durationInSeconds = remainingDistance / pixelsPerSecond;

    _autoScrollController.animateTo(
      maxOffset,
      duration: Duration(seconds: durationInSeconds.round()),
      curve: Curves.linear,
    );

    _timedScrollTimer =
        Timer(Duration(seconds: durationInSeconds.round() + 1), () {
          if (mounted) {
            _stopAutoScroll(resetSpeed: true);
          }
        });
  }

  void _stopAutoScroll({bool resetSpeed = false}) {
    if (!mounted) return;
    _timedScrollTimer?.cancel();

    if (_autoScrollController.hasClients) {
      _autoScrollController.jumpTo(_autoScrollController.offset);
    }

    ref.read(isAutoScrollingProvider.notifier).state = false;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;
    if (resetSpeed) {
      ref.read(scrollSpeedFactorProvider.notifier).state = 1.0;
    }
  }

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

  void _changeScrollSpeed(double delta) {
    if (!mounted) return;
    final currentSpeed = ref.read(scrollSpeedFactorProvider);
    double newSpeed = (currentSpeed + delta).clamp(0.5, 3.0);
    ref.read(scrollSpeedFactorProvider.notifier).state = newSpeed;
    final bool isPlayingAndNotPaused = ref.read(isAutoScrollingProvider) &&
        !ref.read(isAutoScrollPausedProvider);
    if (isPlayingAndNotPaused) {
      _stopAutoScroll();
      _startAutoScroll();
    }
  }

  void _scrollToTop() {
    _autoScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // STEP 1: Watch the new provider that gets the whole surah's data.
    final suraDataAsync = ref.watch(suraDataProvider(widget.suraNumber));

    final suraName = "সূরা ${suraNames[widget.suraNumber - 1]}";
    final quranAudioState = ref.watch(suraAudioProvider);
    final isTimedScrolling = ref.watch(isAutoScrollingProvider);
    final showBottomNav = !isTimedScrolling && quranAudioState == null;

    // Audio listener logic remains the same
    ref.listen<SuraAudioState?>(suraAudioProvider, (previous, next) {
      if (next != null && next.isPlaying) {
        final ayahIndex = next.ayah - 1;
        if (ayahIndex >= 0 && ayahIndex < _totalItems) {
          _autoScrollController.scrollToIndex(
            ayahIndex,
            preferPosition: AutoScrollPosition.middle,
            duration: const Duration(milliseconds: 700),
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
              // STEP 2: The main .when() is now on our new provider.
              child: suraDataAsync.when(
                // Show a list of placeholders for a visually stable loading state.
                loading: () => ListView.builder(
                  itemCount: 15, // Show a decent number of placeholders
                  itemBuilder: (_, __) => const AyahPlaceholder(),
                ),
                error: (error, stack) =>
                    Center(child: Text('Failed to load Sura details:\n$error')),
                // DATA IS FULLY LOADED!
                data: (ayahs) {
                  // Update total items for other controls
                  _totalItems = ayahs.length;

                  return Stack(
                    children: [
                      ScrollbarTheme(
                        data: ScrollbarThemeData(
                            thumbColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.dragged)) {
                                return Colors.green;
                              }
                              return Colors.grey.shade400;
                            }), thickness: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.dragged)) {
                            return 12.0;
                          }
                          return 6.0;
                        })),
                        child: Scrollbar(
                          controller: _autoScrollController,
                          thumbVisibility: true,
                          interactive: true,
                          radius: const Radius.circular(6),
                          child: CustomScrollView(
                            controller: _autoScrollController,
                            slivers: <Widget>[
                              SliverPadding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, left: 4.0, right: 4.0),
                                sliver: SliverList.builder(
                                  // STEP 3: Build the list from the fully loaded data.
                                  itemCount: ayahs.length,
                                  itemBuilder: (context, index) {
                                    final ayah = ayahs[index];
                                    final isHighlighted = quranAudioState != null &&
                                        quranAudioState.surah == widget.suraNumber &&
                                        quranAudioState.ayah == ayah.ayah;

                                    // NO MORE NESTED CONSUMER NEEDED!
                                    return AutoScrollTag(
                                      key: ValueKey(index),
                                      controller: _autoScrollController,
                                      index: index,
                                      child: AyahCard(
                                        suraNumber: widget.suraNumber,
                                        ayah: ayah,
                                        suraName: suraName,
                                        isHighlighted: isHighlighted,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(height: 80.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isTimedScrolling) _buildAutoScrollController(context),
                    ],
                  );
                },
              ),
            ),
            if (quranAudioState != null)
              AudioControllerBar(color: Theme.of(context).primaryColor)
          ],
        ),
        bottomNavigationBar:
        showBottomNav ? _buildBottomNavBar(context) : null,
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

  // --- All your helper methods (_buildAppBar, _buildBottomNavBar, etc.) remain unchanged ---
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