import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/view/widgets/audio_control_bar.dart';
import 'package:quran_app/features/sura/view/widgets/audio_range_selection_dialog.dart';
import 'package:quran_app/features/sura/view/widgets/ayah_card.dart';
import 'package:quran_app/features/sura/view/widgets/details_bottom_sheet.dart';
import 'package:quran_app/features/sura/view/widgets/search_page.dart';
import 'package:quran_app/features/sura/view/widgets/translation_selection_dialog.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../model/sura_audio_state.dart';
import '../viewmodel/sura_reciter_viewmodel.dart';
import '../viewmodel/sura_viewmodel.dart';

class SurahPage extends ConsumerStatefulWidget {
  final int suraNumber;
  final int? initialScrollIndex;
  const SurahPage({super.key, required this.suraNumber, this.initialScrollIndex});

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  late AutoScrollController _autoScrollController;

  Timer? _timedScrollTimer;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _autoScrollController = AutoScrollController(
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: Axis.vertical,
    );
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

    _timedScrollTimer = Timer(Duration(seconds: durationInSeconds.round() + 1), () {
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
    final bool isPlayingAndNotPaused = ref.read(isAutoScrollingProvider) && !ref.read(isAutoScrollPausedProvider);
    if (isPlayingAndNotPaused) {
      _stopAutoScroll();
      _startAutoScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final suraAsyncValue = ref.watch(suraProvider(widget.suraNumber));
    _totalItems = suraAsyncValue.asData?.value.length ?? 0;

    ref.listen<SuraAudioState?>(suraAudioProvider, (previous, next) {
      if (next != null && next.isPlaying) {
        final ayahIndex = next.ayah;
        _autoScrollController.scrollToIndex(
          ayahIndex,
          preferPosition: AutoScrollPosition.middle,
          duration: const Duration(milliseconds: 700),
        );
      }
    });

    final suraName = "সূরা ${widget.suraNumber}";
    final quranAudioState = ref.watch(suraAudioProvider);
    final isTimedScrolling = ref.watch(isAutoScrollingProvider);
    final showBottomNav = !isTimedScrolling && quranAudioState == null;

    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context, suraName),
        body: Column(
          children: [
            Expanded(
              child: suraAsyncValue.when(
                data: (ayahs) => Stack(
                  children: [
                    ListView.builder(
                      controller: _autoScrollController,
                      itemCount: ayahs.length,
                      padding: const EdgeInsets.only(bottom: 80.0, top: 8.0),
                      itemBuilder: (context, index) {
                        final ayah = ayahs[index];
                        final isHighlighted = quranAudioState != null &&
                            quranAudioState.surah == widget.suraNumber &&
                            quranAudioState.ayah == ayah.ayah;
      
                        return AutoScrollTag(
                          key: ValueKey(index),
                          controller: _autoScrollController,
                          index: index,
                          highlightColor: Colors.amber.withOpacity(0.3),
                          child: AyahCard(
                            suraNumber: widget.suraNumber,
                            ayah: ayah,
                            suraName: suraName,
                            isHighlighted: isHighlighted,
                          ),
                        );
                      },
                    ),
                    if (isTimedScrolling)
                      _buildAutoScrollController(context),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Failed to load Sura ${widget.suraNumber}:\n$error')),
              ),
            ),
            if (quranAudioState != null)
              AudioControllerBar(color: Theme.of(context).primaryColor)
          ],
        ),
        bottomNavigationBar: showBottomNav ? _buildBottomNavBar(context) : null,
      ),
    );
  }


  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      title: Text(title, /* ... */),
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
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, -2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.green.shade900),
              onPressed: _togglePlayPauseAutoScroll,
            ),
            IconButton(icon: Icon(Icons.remove, color: Colors.green.shade900), onPressed: () => _changeScrollSpeed(-0.5)),
            Text('${scrollSpeedFactor.toStringAsFixed(1)}x', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
            IconButton(icon: Icon(Icons.add, color: Colors.green.shade900), onPressed: () => _changeScrollSpeed(0.5)),
            IconButton(icon: Icon(Icons.close, color: Colors.green.shade900), onPressed: () => _stopAutoScroll(resetSpeed: true)),
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
        BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'শব্দে শব্দে'),
        BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill_outlined), label: 'অডিও শুনুন'),
        BottomNavigationBarItem(icon: Icon(Icons.swipe_outlined), label: 'অটো স্ক্রল'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'বিস্তারিত'),
      ],
    );
  }

  void _onNavBarTapped(int index) {
    if (!mounted) return;

    switch (index) {
      case 0:
        showDialog(context: context, builder: (context) => const TranslatorSelectionDialog());
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
            builder: (context) => AudioRangeSelectionDialog(totalAyahs: _totalItems, suraNumber: widget.suraNumber),
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