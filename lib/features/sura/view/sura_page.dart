import 'dart:async'; // Import for Timer
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/view/widgets/audio_control_bar.dart';
import 'package:quran_app/features/sura/view/widgets/audio_range_selection_dialog.dart';
import 'package:quran_app/features/sura/view/widgets/ayah_card.dart';
import 'package:quran_app/features/sura/view/widgets/details_bottom_sheet.dart';
import 'package:quran_app/features/sura/view/widgets/translation_selection_dialog.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../viewmodel/sura_reciter_viewmodel.dart';
import '../viewmodel/sura_viewmodel.dart';

class SurahPage extends ConsumerStatefulWidget {
  final int suraNumber;
  const SurahPage({super.key, required this.suraNumber});

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  // --- SCROLL CONTROLLERS ---
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  // --- TIMED AUTO-SCROLL STATE ---
  Timer? _timedScrollTimer;
  int _currentTimedScrollIndex = 0;

  @override
  void initState() {
    super.initState();
    // AUDIO-DRIVEN SCROLL: This listener handles scrolling when audio is playing.
    ref.listenManual(quranAudioProvider, (previous, next) {
      if (next != null && next.isPlaying && itemScrollController.isAttached) {
        final ayahIndex = next.ayah - 1;
        itemScrollController.scrollTo(
          index: ayahIndex,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          alignment: 0.3,
        );
      }
    });
  }

  @override
  void dispose() {
    _timedScrollTimer?.cancel(); // Important: cancel timer to prevent memory leaks
    super.dispose();
  }

  // --- TIMED, SILENT AUTO-SCROLL LOGIC ---

  void _startAutoScroll(WidgetRef ref, int totalItems) {
    if (_timedScrollTimer?.isActive == true) return; // Don't start if already running

    ref.read(isAutoScrollingProvider.notifier).state = true;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;

    // Get the first visible item's index to start from there.
    _currentTimedScrollIndex = itemPositionsListener.itemPositions.value
        .where((item) => item.itemLeadingEdge < 1)
        .reduce((max, item) => item.index > max.index ? item : max)
        .index;

    // Function to perform a single scroll step
    void scrollStep() {
      if (_currentTimedScrollIndex < totalItems - 1) {
        _currentTimedScrollIndex++;
        itemScrollController.scrollTo(
          index: _currentTimedScrollIndex,
          duration: const Duration(seconds: 2), // How long the scroll animation takes
          curve: Curves.easeInOut,
        );
      } else {
        _stopAutoScroll(ref, resetSpeed: true); // Stop when it reaches the end
      }
    }

    // Calculate delay based on speed factor
    final speedFactor = ref.read(scrollSpeedFactorProvider);
    final delayInSeconds = (5 / speedFactor).clamp(2, 10); // Base 5 seconds, clamped

    scrollStep(); // Scroll to the first item immediately
    _timedScrollTimer = Timer.periodic(Duration(seconds: delayInSeconds.toInt()), (timer) {
      scrollStep();
    });
  }

  void _stopAutoScroll(WidgetRef ref, {bool resetSpeed = false}) {
    _timedScrollTimer?.cancel();
    ref.read(isAutoScrollingProvider.notifier).state = false;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;
    if (resetSpeed) {
      ref.read(scrollSpeedFactorProvider.notifier).state = 1.0;
    }
  }

  void _togglePlayPauseAutoScroll(WidgetRef ref, int totalItems) {
    final isPaused = ref.read(isAutoScrollPausedProvider);
    if (isPaused) {
      // Resume
      ref.read(isAutoScrollPausedProvider.notifier).state = false;
      _startAutoScroll(ref, totalItems);
    } else {
      // Pause
      _timedScrollTimer?.cancel();
      ref.read(isAutoScrollPausedProvider.notifier).state = true;
    }
  }

  void _changeScrollSpeed(WidgetRef ref, double delta, int totalItems) {
    final currentSpeed = ref.read(scrollSpeedFactorProvider);
    double newSpeed = (currentSpeed + delta).clamp(0.5, 3.0);
    ref.read(scrollSpeedFactorProvider.notifier).state = newSpeed;

    // If it's playing, restart the timer with the new speed
    if (ref.read(isAutoScrollingProvider) && !ref.read(isAutoScrollPausedProvider)) {
      _timedScrollTimer?.cancel();
      _startAutoScroll(ref, totalItems);
    }
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final suraAsyncValue = ref.watch(suraProvider(widget.suraNumber));
    final suraName = "সূরা ${widget.suraNumber}";
    final quranAudioState = ref.watch(quranAudioProvider);
    final isTimedScrolling = ref.watch(isAutoScrollingProvider);
    final totalItems = suraAsyncValue.asData?.value.length ?? 0;

    final showBottomNav = !isTimedScrolling && quranAudioState == null;

    return Scaffold(
      appBar: _buildAppBar(context, suraName),
      body: Column(
        children: [
          Expanded(
            child: suraAsyncValue.when(
              data: (ayahs) => Stack(
                children: [
                  ScrollablePositionedList.builder(
                    itemCount: ayahs.length,
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                    padding: const EdgeInsets.only(bottom: 80.0, top: 8.0),
                    itemBuilder: (context, index) {
                      final ayah = ayahs[index];
                      // Highlight logic is driven ONLY by the audio state.
                      final isHighlighted = quranAudioState != null &&
                          quranAudioState.surah == widget.suraNumber &&
                          quranAudioState.ayah == ayah.ayah;

                      return AyahCard(
                        ayah: ayah,
                        suraName: suraName,
                        isHighlighted: isHighlighted,
                      );
                    },
                  ),
                  if (isTimedScrolling)
                    _buildAutoScrollController(context, ref, totalItems),
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
      bottomNavigationBar: showBottomNav ? _buildBottomNavBar(context, ref, totalItems) : null,
    );
  }

  // --- WIDGET BUILDERS & ON-TAP LOGIC ---

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(/* ... same as before ... */);
  }

  Widget _buildAutoScrollController(BuildContext context, WidgetRef ref, int totalItems) {
    final scrollSpeedFactor = ref.watch(scrollSpeedFactorProvider);
    final isPaused = ref.watch(isAutoScrollPausedProvider);

    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomAppBarTheme.color,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, -2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.green.shade700),
              onPressed: () => _togglePlayPauseAutoScroll(ref, totalItems),
            ),
            IconButton(icon: const Icon(Icons.remove), onPressed: () => _changeScrollSpeed(ref, -0.5, totalItems)),
            Text('${scrollSpeedFactor.toStringAsFixed(1)}x', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            IconButton(icon: const Icon(Icons.add), onPressed: () => _changeScrollSpeed(ref, 0.5, totalItems)),
            IconButton(icon: Icon(Icons.close, color: Colors.red.shade700), onPressed: () => _stopAutoScroll(ref, resetSpeed: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, WidgetRef ref, int totalItems) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green.shade700,
      unselectedItemColor: Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontFamily: 'SolaimanLipi'),
      unselectedLabelStyle: const TextStyle(fontFamily: 'SolaimanLipi'),
      onTap: (index) => _onNavBarTapped(index, context, ref, totalItems),
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'অনুবাদ'),
        BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: 'শব্দে শব্দে'),
        BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill_outlined), label: 'অডিও শুনুন'),
        BottomNavigationBarItem(icon: Icon(Icons.swipe_outlined), label: 'অটো স্ক্রল'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'বিস্তারিত'),
      ],
    );
  }

  void _onNavBarTapped(int index, BuildContext context, WidgetRef ref, int totalItems) {
    switch (index) {
      case 0: // অনুবাদ
        showDialog(context: context, builder: (context) => const TranslatorSelectionDialog());
        break;
      case 1: // শব্দে শব্দে
        final currentState = ref.read(showWordByWordProvider);
        ref.read(showWordByWordProvider.notifier).state = !currentState;
        break;
      case 2: // অডিও শুনুন
        if (totalItems > 0) {
          _stopAutoScroll(ref, resetSpeed: true); // MUTUAL EXCLUSION
          showDialog(
            context: context,
            builder: (context) => AudioRangeSelectionDialog(totalAyahs: totalItems, suraNumber: widget.suraNumber),
          );
        }
        break;
      case 3: // অটো স্ক্রল
        if (totalItems > 0) {
          ref.read(audioPlayerServiceProvider).stop(); // MUTUAL EXCLUSION
          if (ref.read(isAutoScrollingProvider)) {
            _stopAutoScroll(ref);
          } else {
            _startAutoScroll(ref, totalItems);
          }
        }
        break;
      case 4: // বিস্তারিত
        showDetailsBottomSheet(context);
        break;
    }
  }
}