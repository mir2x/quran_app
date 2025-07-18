import 'dart:async';
import 'dart:math' as math; // For max/min

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/sura/view/widgets/ayah_card.dart';
import 'package:quran_app/features/sura/view/widgets/details_bottom_sheet.dart';
import 'package:quran_app/features/sura/view/widgets/translation_selection_dialog.dart';
// We are removing ScrollablePositionedList for this specific auto-scroll implementation
// import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../viewmodel/sura_viewmodel.dart'; // Ensure this provides Ayah list

// --- State Providers for Auto-Scroll ---
final isAutoScrollingProvider = StateProvider<bool>((ref) => false);
// Scroll speed now represents pixels per second, or a relative factor.
// Let's use a factor for now and calculate pixels/second internally.
final scrollSpeedFactorProvider = StateProvider<double>((ref) => 1.0); // 0.5x, 1.0x, 2.0x
final isAutoScrollPausedProvider = StateProvider<bool>((ref) => false);
// ---

class SurahPage extends ConsumerStatefulWidget {
  final int suraNumber;
  const SurahPage({
    super.key,
    required this.suraNumber,
  });

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> with TickerProviderStateMixin { // Added TickerProviderStateMixin
  final ScrollController _scrollController = ScrollController();
  AnimationController? _autoScrollAnimationController;
  double _currentScrollOffsetOnPause = 0.0; // To resume from the same position

  // We need to estimate or know the height of each item for precise calculations.
  // For simplicity, let's assume an average item height for now.
  // For true perfection, you'd measure each item or have them report their height.
  // This is a placeholder; a more robust solution would involve measuring.
  final double _averageItemHeight = 200.0; // Adjust based on your AyahCard's typical height

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollAnimationController?.dispose();
    super.dispose();
  }

  void _startAutoScroll(WidgetRef ref, int totalItems) {
    if (totalItems == 0 || _autoScrollAnimationController?.isAnimating == true) return;

    final currentSpeedFactor = ref.read(scrollSpeedFactorProvider);
    final isPaused = ref.read(isAutoScrollPausedProvider);

    // If resuming, use the paused offset. Otherwise, start from current or top.
    double initialScrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    if (isPaused && _currentScrollOffsetOnPause > 0) {
      initialScrollOffset = _currentScrollOffsetOnPause;
    }


    // Estimate total scrollable height
    // This is a simplification. For true accuracy with variable height items,
    // you'd need to sum the actual heights or use a more complex measurement.
    double estimatedTotalContentHeight = totalItems * _averageItemHeight;
    double maxScrollExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : estimatedTotalContentHeight - (_scrollController.hasClients ? _scrollController.position.viewportDimension : 600); // Estimate viewport

    if (maxScrollExtent <= 0) maxScrollExtent = estimatedTotalContentHeight * 0.7; // Fallback if viewport too large

    double remainingScroll = maxScrollExtent - initialScrollOffset;
    if (remainingScroll <= 0) { // Already at or past the end
      _stopAutoScroll(ref);
      return;
    }

    // Base pixels per second for 1.0x speed. Adjust this to your liking.
    const double basePixelsPerSecond = 50.0;
    double targetPixelsPerSecond = basePixelsPerSecond * currentSpeedFactor;

    // Duration to scroll the remaining distance
    Duration scrollDuration = Duration(seconds: (remainingScroll / targetPixelsPerSecond).round());

    _autoScrollAnimationController?.dispose();
    _autoScrollAnimationController = AnimationController(
      vsync: this,
      duration: scrollDuration,
    );

    Animation<double> scrollAnimation = Tween<double>(
      begin: initialScrollOffset,
      end: maxScrollExtent,
    ).animate(CurvedAnimation(
      parent: _autoScrollAnimationController!,
      curve: Curves.linear, // Linear for constant speed
    ));

    _autoScrollAnimationController!.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(scrollAnimation.value);
      }
    });

    _autoScrollAnimationController!.forward().whenComplete(() {
      _stopAutoScroll(ref);
    });

    ref.read(isAutoScrollingProvider.notifier).state = true;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;
  }

  void _stopAutoScroll(WidgetRef ref, {bool resetSpeed = false}) {
    _autoScrollAnimationController?.stop();
    // _autoScrollAnimationController?.dispose(); // Don't dispose immediately if we might resume
    ref.read(isAutoScrollingProvider.notifier).state = false;
    ref.read(isAutoScrollPausedProvider.notifier).state = false;
    _currentScrollOffsetOnPause = 0.0; // Reset pause offset
    if (resetSpeed) {
      ref.read(scrollSpeedFactorProvider.notifier).state = 1.0;
    }
  }

  void _togglePlayPauseAutoScroll(WidgetRef ref, int totalItems) {
    final isCurrentlyPaused = ref.read(isAutoScrollPausedProvider);
    if (ref.read(isAutoScrollingProvider)) { // Only act if scrolling is active
      if (isCurrentlyPaused) { // Is paused, so resume
        // _currentScrollOffsetOnPause is already set
        ref.read(isAutoScrollPausedProvider.notifier).state = false;
        _startAutoScroll(ref, totalItems); // Restart animation from paused offset
      } else { // Is playing, so pause
        _autoScrollAnimationController?.stop();
        if (_scrollController.hasClients) {
          _currentScrollOffsetOnPause = _scrollController.offset;
        }
        ref.read(isAutoScrollPausedProvider.notifier).state = true;
      }
    }
  }

  void _changeScrollSpeed(WidgetRef ref, double delta, int totalItems) {
    final currentSpeed = ref.read(scrollSpeedFactorProvider);
    double newSpeed = currentSpeed + delta;
    newSpeed = math.max(0.5, math.min(3.0, newSpeed)); // Clamp between 0.5x and 3.0x

    ref.read(scrollSpeedFactorProvider.notifier).state = newSpeed;

    // If scrolling and not paused, restart with the new speed
    if (ref.read(isAutoScrollingProvider) && !ref.read(isAutoScrollPausedProvider)) {
      _autoScrollAnimationController?.stop(); // Stop current animation
      if (_scrollController.hasClients) {
        _currentScrollOffsetOnPause = _scrollController.offset; // Preserve current position
      }
      _startAutoScroll(ref, totalItems); // Restart with new speed from current position
    }
  }


  @override
  Widget build(BuildContext context) {
    final suraAsyncValue = ref.watch(suraProvider(widget.suraNumber));
    final suraName = "সূরা ${widget.suraNumber}";
    final isAutoScrolling = ref.watch(isAutoScrollingProvider);
    final totalItems = suraAsyncValue.asData?.value.length ?? 0;

    return Scaffold(
      appBar: _buildAppBar(context, suraName),
      body: Stack(
        children: [
          suraAsyncValue.when(
            data: (ayahs) {
              if (ayahs.isEmpty) {
                return const Center(child: Text("No Ayahs to display."));
              }
              // If auto-scrolling was active and list reloads, try to restart
              // This is a basic way; more complex state preservation might be needed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (isAutoScrolling && !ref.read(isAutoScrollPausedProvider) && _autoScrollAnimationController?.isAnimating != true) {
                  if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
                    // Resume from _currentScrollOffsetOnPause if it was set
                    _startAutoScroll(ref, ayahs.length);
                  }
                }
              });

              return ListView.builder(
                controller: _scrollController, // Assign standard ScrollController
                itemCount: ayahs.length,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemBuilder: (context, index) {
                  return AyahCard(
                    ayah: ayahs[index],
                    suraName: suraName,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Failed to load Sura ${widget.suraNumber}:\n$error')),
          ),
          if (isAutoScrolling) _buildAutoScrollController(context, ref, totalItems),
        ],
      ),
      bottomNavigationBar: isAutoScrolling ? null : _buildBottomNavBar(context, ref, totalItems),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    // ... (same as before)
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'SolaimanLipi', color: Colors.white),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context, WidgetRef ref, int totalItems) {
    // ... (same as before, ensure index 3 logic is updated)
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

  Widget _buildAutoScrollController(BuildContext context, WidgetRef ref, int totalItems) {
    final scrollSpeedFactor = ref.watch(scrollSpeedFactorProvider);
    final isPaused = ref.watch(isAutoScrollPausedProvider);

    return Positioned(
      // ... (same UI as before)
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.green.shade700),
              onPressed: () => _togglePlayPauseAutoScroll(ref, totalItems),
              tooltip: isPaused ? 'Resume Scroll' : 'Pause Scroll',
            ),
            IconButton(
              icon: Icon(Icons.remove, color: Colors.blueGrey.shade700),
              onPressed: () => _changeScrollSpeed(ref, -0.5, totalItems),
              tooltip: 'Decrease Speed',
            ),
            Text(
              '${scrollSpeedFactor.toStringAsFixed(1)}x',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700, fontFamily: 'SolaimanLipi'),
            ),
            IconButton(
              icon: Icon(Icons.add, color: Colors.blueGrey.shade700),
              onPressed: () => _changeScrollSpeed(ref, 0.5, totalItems),
              tooltip: 'Increase Speed',
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red.shade700),
              onPressed: () => _stopAutoScroll(ref, resetSpeed: true),
              tooltip: 'Stop Auto Scroll',
            ),
          ],
        ),
      ),
    );
  }

  void _onNavBarTapped(int index, BuildContext context, WidgetRef ref, int totalItems) {
    switch (index) {
      case 0: // অনুবাদ
        showDialog(
          context: context,
          builder: (context) => const TranslatorSelectionDialog(),
        );
        break;
      case 1: // শব্দে শব্দে
        final currentState = ref.read(showWordByWordProvider);
        ref.read(showWordByWordProvider.notifier).state = !currentState;
        break;
      case 2: // অডিও শুনুন
      // Handle audio play
        break;
      case 3: // অটো স্ক্রল
        if (totalItems > 0) {
          if (ref.read(isAutoScrollingProvider)) {
            _stopAutoScroll(ref); // If already scrolling, tapping again might mean stop
          } else {
            // Reset pause state before starting fresh
            _currentScrollOffsetOnPause = _scrollController.hasClients ? _scrollController.offset : 0.0;
            ref.read(isAutoScrollPausedProvider.notifier).state = false;
            _startAutoScroll(ref, totalItems);
          }
        }
        break;
      case 4: // বিস্তারিত
        showDetailsBottomSheet(context);
        break;
      default:
        print('Bottom nav item tapped: $index');
    }
  }
}

// Ensure showWordByWordProvider is defined
// final showWordByWordProvider = StateProvider<bool>((ref) => false);
