import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/fileChecker.dart';
import '../model/audio_state.dart';
import '../model/ayah_box.dart';
import '../model/ayah_timing.dart';
import '../model/bookmark.dart';
import '../model/reciter_asset.dart';

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


// final allBoxesProvider = FutureProvider.family<List<AyahBox>, String>((ref, path) async {
//   final jsonStr = await rootBundle.loadString(path);
//   final decoded = jsonDecode(jsonStr) as List;
//   return decoded.map((e) => AyahBox.fromJson(e)).toList(growable: false);
// });

class EditionDirNotifier extends StateNotifier<Directory?> {
  EditionDirNotifier() : super(null);

  void set(Directory dir) => state = dir;

  void clear() => state = null;
}

final editionDirProvider =
StateNotifierProvider<EditionDirNotifier, Directory?>(
        (_) => EditionDirNotifier());

final allBoxesProvider = FutureProvider<List<AyahBox>>((ref) async {
  final dir = ref.watch(editionDirProvider);
  if (dir == null) throw Exception('editionDir not set');

  final jsonFile = File('${dir.path}/ayah_boxes.json');
  final jsonStr = await jsonFile.readAsString();
  final decoded = jsonDecode(jsonStr) as List;
  return decoded.map((e) => AyahBox.fromJson(e)).toList(growable: false);
});


// final allBoxesProvider = FutureProvider<List<AyahBox>>((ref) async {
//   final jsonStr = await rootBundle.loadString('assets/ayah_boxes.json');
//   final decoded = jsonDecode(jsonStr) as List;
//   return decoded.map((e) => AyahBox.fromJson(e)).toList(growable: false);
// });

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
    final file = File('${dir.path}/$reciter/timings.json');
    final jsonStr = await file.readAsString();
    final decoded = jsonDecode(jsonStr) as List;
    return decoded.map((e) => AyahTiming.fromJson(e)).toList(growable: false);
  }

  Future<String> getAudioAssetPath(int sura) async {
    final padded = sura.toString().padLeft(3, '0');
    final path = await getLocalPath(_reciter);
    return '$path/$padded.mp3';
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

const List<(int sura, int ayah)> paraStarts = [
  (1, 1),   // Para 1 starts Sura 1, Ayah 1 (Al-Fatiha)
  (2, 142), // Para 2 starts Sura 2, Ayah 142 (Al-Baqarah)
  (2, 253), // Para 3 starts Sura 2, Ayah 253 (Al-Baqarah)
  (3, 93),  // Para 4 starts Sura 3, Ayah 93 (Al-Imran)
  (4, 24),  // Para 5 starts Sura 4, Ayah 24 (An-Nisa)
  (4, 148), // Para 6 starts Sura 4, Ayah 148 (An-Nisa)
  (5, 83),  // Para 7 starts Sura 5, Ayah 83 (Al-Ma'idah)
  (6, 111), // Para 8 starts Sura 6, Ayah 111 (Al-An'am)
  (7, 88),  // Para 9 starts Sura 7, Ayah 88 (Al-A'raf)
  (8, 41),  // Para 10 starts Sura 8, Ayah 41 (Al-Anfal)
  (9, 93),  // Para 11 starts Sura 9, Ayah 93 (At-Tawbah)
  (11, 6),  // Para 12 starts Sura 11, Ayah 6 (Hud)
  (12, 53), // Para 13 starts Sura 12, Ayah 53 (Yusuf)
  (15, 1),  // Para 14 starts Sura 15, Ayah 1 (Al-Hijr)
  (17, 1),  // Para 15 starts Sura 17, Ayah 1 (Al-Isra)
  (18, 75), // Para 16 starts Sura 18, Ayah 75 (Al-Kahf)
  (21, 1),  // Para 17 starts Sura 21, Ayah 1 (Al-Anbiya)
  (23, 1),  // Para 18 starts Sura 23, Ayah 1 (Al-Mu'minun)
  (25, 21), // Para 19 starts Sura 25, Ayah 21 (Al-Furqan)
  (27, 56), // Para 20 starts Sura 27, Ayah 56 (An-Naml)
  (29, 46), // Para 21 starts Sura 29, Ayah 46 (Al-'Ankabut)
  (33, 31), // Para 22 starts Sura 33, Ayah 31 (Al-Ahzab)
  (36, 22), // Para 23 starts Sura 36, Ayah 22 (Ya-Sin)
  (39, 32), // Para 24 starts Sura 39, Ayah 32 (Az-Zumar)
  (41, 47), // Para 25 starts Sura 41, Ayah 47 (Fussilat)
  (46, 1),  // Para 26 starts Sura 46, Ayah 1 (Al-Ahqaf)
  (51, 31), // Para 27 starts Sura 51, Ayah 31 (Adh-Dhariyat)
  (58, 1),  // Para 28 starts Sura 58, Ayah 1 (Al-Mujadila)
  (67, 1),  // Para 29 starts Sura 67, Ayah 1 (Al-Mulk)
  (78, 1),  // Para 30 starts Sura 78, Ayah 1 (An-Naba)
];


final suraPageMappingProvider = Provider<Map<int, int>>((ref) {
  final allBoxesAsync = ref.watch(allBoxesProvider);

  return allBoxesAsync.maybeWhen(
    data: (boxes) {
      final Map<int, int> suraMapping = {};
      final Set<int> foundSuras = {};
      for (final box in boxes) {
        if (box.suraNumber >= 1 && box.suraNumber <= 114 && box.ayahNumber >= 1) {
          if (!foundSuras.contains(box.suraNumber)) {
            suraMapping[box.suraNumber] = box.pageNumber;
            foundSuras.add(box.suraNumber);
          }
        }
      }
      for (int i = 1; i <= 114; i++) {
        if (!suraMapping.containsKey(i)) {
        }
      }

      return suraMapping;
    },
    orElse: () => const {},
  );
});

final ayahPageMappingProvider = Provider<Map<(int, int), int>>((ref) {
  final allBoxesAsync = ref.watch(allBoxesProvider);

  return allBoxesAsync.maybeWhen(
    data: (boxes) {
      final Map<(int, int), int> mapping = {};

      // Iterate through the boxes and map (sura, ayah) to the first page they appear on.
      // We only store the page number for the first box encountered for each (sura, ayah) pair.
      for (final box in boxes) {
        final key = (box.suraNumber, box.ayahNumber);
        // Only add if the key is not already in the map.
        // This ensures we get the *first* page number for the ayah.
        if (!mapping.containsKey(key)) {
          mapping[key] = box.pageNumber;
        }
      }
      return mapping;
    },
    orElse: () => const {}, // Return empty map while loading or if error
  );
});

const List<String> suraNames = [
  'আল-ফাতিহা', // 1
  'আল-বাকারা', // 2
  'আল-ইমরান', // 3
  'আন-নিসা', // 4
  'আল-মায়েদাহ', // 5
  'আল-আনআম', // 6
  'আল-আরাফ', // 7
  'আল-আনফাল', // 8
  'আত-তাওবাহ', // 9
  'ইউনুস', // 10
  'হুদ', // 11
  'ইউসুফ', // 12
  'আর-রাদ', // 13
  'ইবরাহিম', // 14
  'আল-হিজর', // 15
  'আন-নাহল', // 16
  'আল-ইসরা', // 17
  'আল-কাহফ', // 18
  'মারইয়াম', // 19
  'ত্বা-হা', // 20
  'আল-আম্বিয়া', // 21
  'আল-হাজ্জ', // 22
  'আল-মুমিনুন', // 23
  'আন-নুর', // 24
  'আল-ফুরকান', // 25
  'আশ-শুআরা', // 26
  'আন-নামল', // 27
  'আল-কাসাস', // 28
  'আল-আনকাবুত', // 29
  'আর-রুম', // 30
  'লুকমান', // 31
  'আস-সাজদাহ', // 32
  'আল-আহযাব', // 33
  'সাবা', // 34
  'ফাতির', // 35
  'ইয়া-সীন', // 36
  'আস-সাফফাত', // 37
  'সা-দ', // 38
  'আয-যুমার', // 39
  'গাফির', // 40
  'ফুসসিলাত', // 41
  'আশ-শূরা', // 42
  'আয-যুখরুফ', // 43
  'আদ-দুখান', // 44
  'আল-জাছিয়াহ', // 45
  'আল-আহকাফ', // 46
  'মুহাম্মাদ', // 47
  'আল-ফাতহ', // 48
  'আল-হুজুরাত', // 49
  'ক্বাফ', // 50
  'আয-যারিয়াত', // 51
  'আত-তূর', // 52
  'আন-নাজম', // 53
  'আল-ক্বামার', // 54
  'আর-রহমান', // 55
  'আল-ওয়াকিআ', // 56
  'আল-হাদীদ', // 57
  'আল-মুজাদিলা', // 58
  'আল-হাশর', // 59
  'আল-মুমতাহিনাহ', // 60
  'আস-সাফ', // 61
  'আল-জুমুআ', // 62
  'আল-মুনাফিকুন', // 63
  'আত-তাগাবুন', // 64
  'আত-ত্বালাক্ব', // 65
  'আত-তাহরীম', // 66
  'আল-মুলক', // 67
  'আল-ক্বালাম', // 68
  'আল-হাক্কাহ', // 69
  'আল-মাআরিজ', // 70
  'নূহ', // 71
  'আল-জিন', // 72
  'আল-মুযযাম্মিল', // 73
  'আল-মুদ্দাসসির', // 74
  'আল-ক্বিয়ামাহ', // 75
  'আল-ইনসান', // 76
  'আল-মুরসালাত', // 77
  'আন-নাবা', // 78
  'আন-নাযিয়াত', // 79
  'আবাসা', // 80
  'আত-তাকভীর', // 81
  'আল-ইনফিতার', // 82
  'আল-মুতাফফিফীন', // 83
  'আল-ইনশিক্বাক্ব', // 84
  'আল-বুরুজ', // 85
  'আত-তারিক্ব', // 86
  'আল-আলা', // 87
  'আল-গাশিয়াহ', // 88
  'আল-ফাজর', // 89
  'আল-বালাদ', // 90
  'আশ-শামস', // 91
  'আল-লাইল', // 92
  'আদ-দুহা', // 93
  'আল-ইনশিরাহ', // 94
  'আত-তীন', // 95
  'আল-আলাক্ব', // 96
  'আল-ক্বদর', // 97
  'আল-বাইয়্যিনাহ', // 98
  'আয-যালযালাহ', // 99
  'আল-আদিয়াত', // 100
  'আল-ক্বারিআহ', // 101
  'আত-তাকাছুর', // 102
  'আল-আসর', // 103
  'আল-হুমাযাহ', // 104
  'আল-ফীল', // 105
  'কুরাইশ', // 106
  'আল-মাউন', // 107
  'আল-কাওসার', // 108
  'আল-কাফিরুন', // 109
  'আন-নাসর', // 110
  'আল-মাসাদ', // 111
  'আল-ইখলাস', // 112
  'আল-ফালাক্ব', // 113
  'আন-নাস' // 114
];

final suraNamesProvider = Provider<List<String>>((_) => suraNames);

final selectedNavigationSurahProvider = StateProvider<int?>((_) => null);

final paraPageMappingProvider = Provider<Map<int, int>>((ref) {
  final allBoxesAsync = ref.watch(allBoxesProvider);

  return allBoxesAsync.maybeWhen(
    data: (boxes) {
      final Map<int, int> paraMapping = {};
      for (int i = 0; i < paraStarts.length; i++) {
        final paraNum = i + 1;
        final (startSura, startAyah) = paraStarts[i];
        final startBox = boxes.firstWhereOrNull(
              (box) =>
          box.suraNumber == startSura &&
              box.ayahNumber == startAyah,
        );

        if (startBox != null) {
          paraMapping[paraNum] = startBox.pageNumber;
        } else {
          print('Warning: Start box for Para $paraNum ($startSura:$startAyah) not found in ayah_boxes.json');
        }
      }
      return paraMapping;
    },
    orElse: () => const {},
  );
});