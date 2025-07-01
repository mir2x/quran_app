import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../features/sura/viewmodel/sura_viewmodel.dart';

class AutoScrollService {
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final WidgetRef ref;

  Timer? _timer;
  int totalItemCount = 0;

  AutoScrollService({
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.ref,
  });

  /// Starts the periodic timer to scroll the list.
  void startAutoScroll() {
    // Prevent multiple timers from running
    if (_timer?.isActive ?? false) return;

    ref.read(autoScrollActiveProvider.notifier).state = true;

    // Calculate duration based on speed
    final speed = ref.read(autoScrollSpeedProvider);
    final scrollInterval = _getIntervalFromSpeed(speed);

    _timer = Timer.periodic(scrollInterval, (timer) {
      _scrollToNext();
    });
  }

  /// Stops the auto-scroll timer and updates the state.
  void stopAutoScroll() {
    _timer?.cancel();
    _timer = null;
    // Check if the provider state is already false to avoid unnecessary rebuilds
    if (ref.read(autoScrollActiveProvider)) {
      ref.read(autoScrollActiveProvider.notifier).state = false;
    }
  }

  /// Toggles the auto-scroll state.
  void toggleAutoScroll() {
    if (_timer?.isActive ?? false) {
      stopAutoScroll();
    } else {
      startAutoScroll();
    }
  }

  /// Increases the scroll speed and restarts the timer if it's active.
  void increaseSpeed() {
    final currentSpeed = ref.read(autoScrollSpeedProvider);
    // Set a maximum speed limit, e.g., 5x
    if (currentSpeed < 5) {
      ref.read(autoScrollSpeedProvider.notifier).state = currentSpeed + 1;
      _restartTimerIfActive();
    }
  }

  /// Decreases the scroll speed and restarts the timer if it's active.
  void decreaseSpeed() {
    final currentSpeed = ref.read(autoScrollSpeedProvider);
    // Set a minimum speed limit, e.g., 1x
    if (currentSpeed > 1) {
      ref.read(autoScrollSpeedProvider.notifier).state = currentSpeed - 1;
      _restartTimerIfActive();
    }
  }

  void _scrollToNext() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final currentPosition = positions.first.index;
    final nextIndex = currentPosition + 1;

    // Use the dynamic totalItemCount property now
    if (nextIndex >= totalItemCount) {
      stopAutoScroll();
      ref.read(autoScrollControllerVisibleProvider.notifier).state = false;
      return;
    }

    itemScrollController.scrollTo(
      index: nextIndex,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Restarts the timer to apply the new speed setting immediately.
  void _restartTimerIfActive() {
    if (_timer?.isActive ?? false) {
      stopAutoScroll();
      startAutoScroll();
    }
  }

  /// Converts the speed multiplier (e.g., 1x, 2x) into a timer duration.
  /// Higher speed means a shorter interval.
  Duration _getIntervalFromSpeed(double speed) {
    // Base interval is 10 seconds. 2x speed means 5 seconds, etc.
    final baseMilliseconds = 10000;
    final interval = (baseMilliseconds / speed).round();
    return Duration(milliseconds: interval);
  }
}