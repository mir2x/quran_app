import 'package:flutter/material.dart';

@immutable
class QuranState {
  // ────────────────── navigation ──────────────────
  final int currentPage;
  final int currentAyahIdx;
  final int? selectedSurahIndex;
  final int? selectedParaIndex;
  final int? selectedAyahIndex;

  // ────────────────── ui toggles ──────────────────
  final bool showBars;
  final bool touchModeEnabled;
  final bool isDrawerOpen;
  final bool showAyahMenu;
  final bool showAudioController;
  final bool localDirsReady;

  // ────────────────── audio ──────────────────
  final bool isPlaying;
  final String selectedReciter;
  final Duration? currentEndPosition;

  // ────────────────── helpers ──────────────────
  final bool needsScrollAdjustment;
  final String? highlightedAyah;
  final Offset? menuPosition;
  final double landscapeItemExtent;

  static const _sentinel = Object();

  const QuranState({
    this.currentPage = 1,
    this.currentAyahIdx = 0,
    this.selectedSurahIndex = 0,
    this.selectedParaIndex = 0,
    this.selectedAyahIndex = 0,
    this.showBars = true,
    this.touchModeEnabled = true,
    this.isDrawerOpen = false,
    this.showAyahMenu = false,
    this.showAudioController = false,
    this.localDirsReady = false,
    this.isPlaying = false,
    this.selectedReciter = 'সৌদ আল-শুরাইম',
    this.currentEndPosition,
    this.needsScrollAdjustment = false,
    this.highlightedAyah,
    this.menuPosition,
    this.landscapeItemExtent = 0,
  });

  QuranState copyWith({
    int? currentPage,
    int? currentAyahIdx,
    int? selectedSurahIndex,
    int? selectedParaIndex,
    int? selectedAyahIndex,
    bool? showBars,
    bool? touchModeEnabled,
    bool? isDrawerOpen,
    bool? showAyahMenu,
    bool? showAudioController,
    bool? isPlaying,
    bool? localDirsReady,
    String? selectedReciter,
    Duration? currentEndPosition,
    bool? needsScrollAdjustment,
    String? highlightedAyah,
    Offset? menuPosition,
    double? landscapeItemExtent,
  }) {
    return QuranState(
      currentPage: currentPage ?? this.currentPage,
      currentAyahIdx: currentAyahIdx ?? this.currentAyahIdx,
      selectedSurahIndex: selectedSurahIndex ?? this.selectedSurahIndex,
      selectedParaIndex: selectedParaIndex ?? this.selectedParaIndex,
      selectedAyahIndex: selectedAyahIndex ?? this.selectedAyahIndex,
      showBars: showBars ?? this.showBars,
      touchModeEnabled: touchModeEnabled ?? this.touchModeEnabled,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
      showAyahMenu: showAyahMenu ?? this.showAyahMenu,
      showAudioController: showAudioController ?? this.showAudioController,
      localDirsReady: localDirsReady ?? this.localDirsReady,
      isPlaying: isPlaying ?? this.isPlaying,
      selectedReciter: selectedReciter ?? this.selectedReciter,
      currentEndPosition: currentEndPosition ?? this.currentEndPosition,
      needsScrollAdjustment: needsScrollAdjustment ?? this.needsScrollAdjustment,
      highlightedAyah: identical(highlightedAyah, _sentinel)
          ? this.highlightedAyah
          : highlightedAyah as String?,
      menuPosition: menuPosition ?? this.menuPosition,
      landscapeItemExtent: landscapeItemExtent ?? this.landscapeItemExtent,
    );
  }
}
