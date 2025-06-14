import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/services/audio_service.dart';
import '../model/audio_state.dart';
import '../model/ayah_box.dart';
import '../model/ayah_timing.dart';
import '../model/bookmark.dart';

final allBoxesProvider = FutureProvider<List<AyahBox>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/ayah_boxes.json');
  final decoded = jsonDecode(jsonStr) as List;
  return decoded.map((e) => AyahBox.fromJson(e)).toList(growable: false);
});

final boxesForPageProvider =
Provider.family<List<AyahBox>, int>((ref, pageIndex) {
  final all = ref.watch(allBoxesProvider).maybeWhen(
    data: (d) => d,
    orElse: () => const <AyahBox>[],
  );

  final logicalPage = pageIndex;
  if (logicalPage < kFirstPageNumber) {
    return const <AyahBox>[];
  }

  return all
      .where((b) => b.pageNumber == logicalPage)
      .toList(growable: false);
});

final boxesForPageProvider2 = FutureProvider.family<List<AyahBox>, int>((ref, pageIndex) async {
  final allAsync = ref.watch(allBoxesProvider);

  final all = await allAsync.when(
    data: (d) => d,
    loading: () => <AyahBox>[],
    error: (_, __) => <AyahBox>[],
  );


  if (pageIndex < kFirstPageNumber) return [];

  return all.where((b) => b.pageNumber == pageIndex).toList(growable: false);
});


class SelectedAyahState {
  final int ayahNumber;
  final Rect anchorRect;

  const SelectedAyahState(this.ayahNumber, this.anchorRect);
}

class SelectedAyahNotifier extends StateNotifier<SelectedAyahState?> {
  SelectedAyahNotifier() : super(null);

  void select(int ayah, Rect anchorRect) {
    if (state?.ayahNumber == ayah) {
      state = null;
    } else {
      state = SelectedAyahState(ayah, anchorRect);
    }
  }

  void clear() => state = null;

  void selectFromAudio(int ayah) {
    state = SelectedAyahState(ayah, Rect.zero); // No menu
  }
}

final selectedAyahProvider =
StateNotifierProvider<SelectedAyahNotifier, SelectedAyahState?>(
        (ref) => SelectedAyahNotifier());

final currentPageProvider = StateProvider<int>((_) => 0);

final currentSuraProvider = Provider<int>((ref) {
  final page = ref.watch(currentPageProvider) + 1;

  final allBoxes = ref.watch(allBoxesProvider);
  return allBoxes.maybeWhen(
    data: (d) {
      final pageBoxes = d
          .where((b) => b.pageNumber == page)
          .toList(growable: false);
      return pageBoxes.isEmpty ? 1 : pageBoxes.first.suraNumber;
    },
    orElse: () => 1,
  );
});



class TouchModeNotifier extends StateNotifier<bool> {
  TouchModeNotifier() : super(false);
  void toggle() => state = !state;
}

final touchModeProvider =
StateNotifierProvider<TouchModeNotifier, bool>((_) => TouchModeNotifier());

class OrientationToggle {
  static bool _isPortraitOnly = true;

  static Future<void> toggle() async {
    _isPortraitOnly = !_isPortraitOnly;
    if (_isPortraitOnly) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    }
  }
}

class DrawerNotifier extends StateNotifier<bool> {
  DrawerNotifier() : super(false);
  void open()  => state = true;
  void close() => state = false;
}

final drawerOpenProvider =
StateNotifierProvider<DrawerNotifier, bool>((_) => DrawerNotifier());

class BookmarkNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('bookmarks') ?? [];
    return raw.map((e) => Bookmark.fromJson(jsonDecode(e))).toList();
  }

  Future<void> add(Bookmark b) async {
    final list = List<Bookmark>.from(state.value ?? []);
    if (list.any((e) => e.identifier == b.identifier)) return;
    list.add(b);
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> remove(String id) async {
    final list = List<Bookmark>.from(state.value ?? []);
    list.removeWhere((b) => b.identifier == id);
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> _persist(List<Bookmark> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'bookmarks', data.map((b) => jsonEncode(b.toJson())).toList());
  }
}

final bookmarkProvider =
AsyncNotifierProvider<BookmarkNotifier, List<Bookmark>>(BookmarkNotifier.new);


final reciters = ['maher', 'huthaify', 'husary'];

final selectedReciterProvider = StateProvider<String>((_) => reciters.first);

final audioVMProvider = AsyncNotifierProvider<AudioVM, List<AyahTiming>>(AudioVM.new);

class AudioVM extends AsyncNotifier<List<AyahTiming>> {
  late String _reciter;

  @override
  Future<List<AyahTiming>> build() async {
    _reciter = ref.watch(selectedReciterProvider);
    return _loadTimingForReciter(_reciter);
  }

  Future<List<AyahTiming>> _loadTimingForReciter(String reciter) async {
    final jsonStr = await rootBundle.loadString('assets/$reciter/timings.json');
    final decoded = jsonDecode(jsonStr) as List;
    return decoded.map((e) => AyahTiming.fromJson(e)).toList(growable: false);
  }

  List<AyahTiming> getTimingsForSura(int sura) {
    return state.value?.where((t) => t.sura == sura).toList() ?? [];
  }

  int getLastAyah(int sura) {
    final timings = getTimingsForSura(sura);
    return timings.map((t) => t.ayah).where((a) => a != 999).fold<int>(1, (a, b) => b > a ? b : a);
  }

  String getAudioAssetPath(int sura) {
    final padded = sura.toString().padLeft(3, '0');
    return 'assets/$_reciter/$padded.mp3';
  }
}

final selectedStartAyahProvider = StateProvider<int>((_) => 1);
final selectedEndAyahProvider = StateProvider<int>((_) => 1);

class QuranAudioNotifier extends StateNotifier<QuranAudioState?> {
  QuranAudioNotifier() : super(null);

  void start(int surah, int ayah) {
    state = QuranAudioState(surah: surah, ayah: ayah, isPlaying: true);
  }

  void updateAyah(int ayah) {
    if (state != null) {
      state = state!.copyWith(ayah: ayah);
    }
  }

  void pause() {
    if (state != null) {
      state = state!.copyWith(isPlaying: false);
    }
  }

  void resume() {
    if (state != null) {
      state = state!.copyWith(isPlaying: true);
    }
  }

  void stop() {
    state = null;
  }
}

final quranAudioProvider = StateNotifierProvider<QuranAudioNotifier, QuranAudioState?>(
      (ref) => QuranAudioNotifier(),
);

final audioPlayerServiceProvider = Provider<AudioControllerService>((ref) {
  return AudioControllerService(ref);
});

final navigateToPageCommandProvider = StateProvider<int?>((_) => null);