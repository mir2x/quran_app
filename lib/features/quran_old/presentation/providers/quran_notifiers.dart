import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/features/quran_old/presentation/providers/quran_state.dart';



class QuranNotifier extends StateNotifier<QuranState> {
  QuranNotifier() : super(const QuranState());

  // ───────── basic setters ─────────
  void setCurrentPage(int page) =>
      state = state.copyWith(currentPage: page, showAyahMenu: false, menuPosition: null);

  void setHighlightedAyah(String? key) => state = state.copyWith(highlightedAyah: key);

  void clearHighlightedAyah() {
    state = state.copyWith(highlightedAyah: null);
  }

  void setCurrentAyahIdx(int idx) => state = state.copyWith(currentAyahIdx: idx);

  void selectSurah(int surah) =>
      state = state.copyWith(selectedSurahIndex: surah, selectedAyahIndex: 0);

  void selectPara(int para) => state = state.copyWith(selectedParaIndex: para);

  void selectAyah(int ayah, String ayahKey) => state = state.copyWith(
    selectedAyahIndex: ayah,
    highlightedAyah: ayahKey,
    showBars: false,
    isDrawerOpen: false,
  );

  // ───────── toggles ─────────
  void toggleDrawer() => state = state.copyWith(
    isDrawerOpen: !state.isDrawerOpen,
    showBars: true,
  );

  void closeDrawer() => state = state.copyWith(isDrawerOpen: false);

  void toggleBars() => state = state.copyWith(showBars: !state.showBars);

  void toggleTouchMode() => state = state.copyWith(
    touchModeEnabled: !state.touchModeEnabled,
    highlightedAyah: state.touchModeEnabled ? null : state.highlightedAyah,
  );

  void togglePlaying() => state = state.copyWith(isPlaying: !state.isPlaying);

  // ───────── ayah-menu helpers ─────────
  void showAyahMenuAt(Offset pos, String ayahKey) => state = state.copyWith(
    showAyahMenu: true,
    menuPosition: pos,
    highlightedAyah: ayahKey,
  );

  void hideAyahMenu() =>
      state = state.copyWith(showAyahMenu: false, menuPosition: null);

  // ───────── audio helpers ─────────
  void setPlaying(bool playing) => state = state.copyWith(isPlaying: playing);

  void showAudioController(bool show) =>
      state = state.copyWith(showAudioController: show);

  void changeReciter(String reciter) =>
      state = state.copyWith(selectedReciter: reciter, highlightedAyah: null);

  // ───────── misc helpers ─────────
  void needScrollAdjustment() =>
      state = state.copyWith(needsScrollAdjustment: true);

  void doneScrollAdjustment() =>
      state = state.copyWith(needsScrollAdjustment: false);

  void setAyahBookmark({required String ayahKey, required bool showBars, required bool isDrawerOpen}) => state = state.copyWith(highlightedAyah: ayahKey, showBars: showBars, isDrawerOpen: isDrawerOpen);

  void setPageBookmark({required bool showBars, required bool isDrawerOpen}) => state = state.copyWith(showBars: showBars, isDrawerOpen: isDrawerOpen);

  void setShowBars(bool bool) => state = state.copyWith(showBars: bool);

  void setShowAyahMenu(bool bool) => state = state.copyWith(showAyahMenu: bool);

  void setMenuPosition(Offset? pos) => state = state.copyWith(menuPosition: pos);

  void setCurrentEndPosition(Duration duration) => state = state.copyWith(currentEndPosition: duration);

  void setLandscapeItemExtent(double value) => state = state.copyWith(landscapeItemExtent: value);

  void setLocalDirsReady() => state = state.copyWith(localDirsReady: true);

  void toggleAyahHighlight(String key, {Offset? menuPos}) {
    final bool same = state.highlightedAyah == key;

    state = state.copyWith(
      highlightedAyah: same ? null : key,
      showAyahMenu:    same ? false : true,
      menuPosition:    same ? null : menuPos,
    );
  }
}