import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/downloader.dart';
import '../model/audio_state.dart';
import '../model/ayah_box.dart';
import '../model/ayah_timing.dart';
import '../model/bookmark.dart';
import '../model/reciter_asset.dart';
import '../view/widgets/download_dialog.dart';

final ayahCountsProvider = Provider<List<int>>((ref) {
  return [
    7,
    286,
    200,
    176,
    120,
    165,
    206,
    75,
    129,
    109,
    123,
    111,
    43,
    52,
    99,
    128,
    111,
    110,
    98,
    135,
    112,
    78,
    118,
    64,
    77,
    227,
    93,
    88,
    69,
    60,
    34,
    30,
    73,
    54,
    45,
    83,
    182,
    88,
    75,
    85,
    54,
    53,
    89,
    59,
    37,
    35,
    38,
    29,
    18,
    45,
    60,
    49,
    62,
    55,
    78,
    96,
    29,
    22,
    24,
    13,
    14,
    11,
    11,
    18,
    12,
    12,
    30,
    52,
    52,
    44,
    28,
    28,
    20,
    56,
    40,
    31,
    50,
    40,
    46,
    42,
    29,
    19,
    36,
    25,
    22,
    17,
    19,
    26,
    30,
    20,
    15,
    21,
    11,
    8,
    8,
    19,
    5,
    8,
    8,
    11,
    11,
    8,
    3,
    9,
    5,
    4,
    7,
    3,
    6,
    3,
    5,
    4,
    5,
    6
  ];
});


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
    if (state?.ayahNumber != ayah) {
      state = SelectedAyahState(ayah, Rect.zero);
    }
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


final Map<String, String> reciters = {
  'মাহের আল মুয়াইক্বিলি': 'maher_muaiqly',
  'সৌদ আল-শুরাইম': 'saud_shuraim',
  'আলী জাবের': 'ali_jaber',
  'আব্দুল মুনিম আব্দুল মুবদি': 'abdul_munim_mubdi',
};

final selectedReciterProvider = StateProvider<String>((_) => reciters.values.first);

final reciterCatalogueProvider = Provider<List<ReciterAsset>>((_) => const [
  ReciterAsset(
    id: 'maher_muaiqly',
    name: 'মাহের আল মুয়াইক্বিলি',
    zipUrl: 'https://ntgkoryrbfyhcbqfnsbx.supabase.co/storage/v1/object/public/assets/audio/maher_muaiqly.zip',
    sizeBytes: 51097600,
  ),
  ReciterAsset(
    id: 'ali_jaber',
    name: 'আলী জাবের',
    zipUrl: 'https://example.com/assets/ali_jaber.zip',
    sizeBytes: 10000000,
  ),
]);

final audioVMProvider = AsyncNotifierProvider<AudioVM, List<AyahTiming>>(AudioVM.new);

class AudioVM extends AsyncNotifier<List<AyahTiming>> {
  late String _reciter;

  @override
  Future<List<AyahTiming>> build() async {
    _reciter = ref.watch(selectedReciterProvider);
    return [];
  }

  Future<void> loadTimings() async {
    _reciter = ref.read(selectedReciterProvider);
    final timings = await _loadTimingFromLocal(_reciter);
    state = AsyncData(timings);
  }

  Future<List<AyahTiming>> _loadTimingFromLocal(String reciter) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$reciter/$reciter/timings.json');
    final jsonStr = await file.readAsString();
    final decoded = jsonDecode(jsonStr) as List;
    return decoded.map((e) => AyahTiming.fromJson(e)).toList(growable: false);
  }

  Future<String> getAudioAssetPath(int sura) async {
    final padded = sura.toString().padLeft(3, '0');
    final path = await getLocalReciterPath(_reciter);
    return '$path/$_reciter/$padded.mp3';
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
    // Only update the ayah number if it has changed
    if (state != null && state!.ayah != ayah) {
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
  final service = AudioControllerService(ref);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final navigateToPageCommandProvider = StateProvider<int?>((_) => null);

void navigateToPage({required WidgetRef ref, required int pageNumber}) {
  ref.read(navigateToPageCommandProvider.notifier).state = pageNumber;
}