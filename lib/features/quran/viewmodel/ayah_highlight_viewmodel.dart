import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants.dart';
import '../../../core/services/audio_service.dart';
import '../model/audio_state.dart';
import '../model/ayah_box.dart';
import '../model/selected_ayah_state.dart';
import '../model/sura_audio_data.dart';


class DownloadProgress {
  final int downloadedCount;
  final int totalCount;
  final String? error;

  DownloadProgress({this.downloadedCount = 0, this.totalCount = 0, this.error});
  double get percentage => totalCount == 0 ? 0.0 : downloadedCount / totalCount;
}

final ayahCountsProvider = Provider<List<int>>((ref) {
  return [ 7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6 ];
});

class EditionConfig {
  final Directory dir;
  final int imageWidth;
  final int imageHeight;
  final String imageExt;
  const EditionConfig({ required this.dir, required this.imageWidth, required this.imageHeight, required this.imageExt });
}

class EditionConfigNotifier extends StateNotifier<EditionConfig?> {
  EditionConfigNotifier() : super(null);
  void set(EditionConfig config) => state = config;
  void clear() => state = null;
}

final editionConfigProvider = StateNotifierProvider<EditionConfigNotifier, EditionConfig?>((_) => EditionConfigNotifier());

final allBoxesProvider = FutureProvider<List<AyahBox>>((ref) async {
  final config = ref.watch(editionConfigProvider);
  if (config == null) throw Exception('edition config not set');
  final jsonFile = File('${config.dir.path}/ayah_boxes.json');
  final jsonStr = await jsonFile.readAsString();
  final decoded = jsonDecode(jsonStr) as List;
  return decoded.map((e) => AyahBox.fromJson(e)).toList(growable: false);
});

final totalPageCountProvider = FutureProvider<int>((ref) async {
  final config = ref.watch(editionConfigProvider);
  if (config == null) throw Exception('edition config not set');
  final fileList = await config.dir.list().where((f) => f.path.endsWith('.${config.imageExt}')).toList();
  return fileList.length;
});

final boxesForPageProvider = Provider.family<List<AyahBox>, int>((ref, pageIndex) {
  final all = ref.watch(allBoxesProvider).maybeWhen(data: (d) => d, orElse: () => const <AyahBox>[]);
  final logicalPage = pageIndex;
  if (logicalPage < kFirstPageNumber) return const <AyahBox>[];
  return all.where((b) => b.pageNumber == logicalPage).toList(growable: false);
});

class SelectedAyahNotifier extends StateNotifier<SelectedAyahState?> {
  SelectedAyahNotifier() : super(null);
  void selectByTap(int sura, int ayah) {
    if (state?.suraNumber == sura && state?.ayahNumber == ayah && state?.source == AyahSelectionSource.tap) {
      state = null;
    } else {
      state = SelectedAyahState(sura, ayah, AyahSelectionSource.tap);
    }
  }
  void selectByAudio(int sura, int ayah) {
    if (state == null || state!.suraNumber != sura || state!.ayahNumber != ayah || state!.source != AyahSelectionSource.audio) {
      state = SelectedAyahState(sura, ayah, AyahSelectionSource.audio);
    }
  }
  void selectByNavigation(int sura, int ayah) {
    if (state == null || state!.suraNumber != sura || state!.ayahNumber != ayah || state!.source != AyahSelectionSource.navigation) {
      state = SelectedAyahState(sura, ayah, AyahSelectionSource.navigation);
    }
  }
  void clear() => state = null;
}

final selectedAyahProvider = StateNotifierProvider<SelectedAyahNotifier, SelectedAyahState?>((ref) => SelectedAyahNotifier());
final currentPageProvider = StateProvider<int>((_) => 0);

final currentSuraProvider = Provider<int>((ref) {
  final page = ref.watch(currentPageProvider) + 1;
  if (page <= 2) return page;
  final suraMapping = ref.watch(suraPageMappingProvider);
  if (suraMapping.isEmpty) return 1;
  int currentSura = 1;
  final sortedSuraStarts = List.from(suraMapping.entries.toList()..sort((a, b) => a.value.compareTo(b.value)));
  for (final entry in sortedSuraStarts) {
    if (entry.value <= page) {
      currentSura = entry.key;
    } else {
      break;
    }
  }
  return currentSura;
});

// --- AUDIO SELECTION AND STATE PROVIDERS (UNCHANGED) ---

final selectedAudioSuraProvider = StateProvider<int>((_) => 1);
final selectedStartAyahProvider = StateProvider<int>((_) => 1);
final selectedEndAyahProvider = StateProvider<int>((_) => 1);

final Map<String, String> reciters = {
  'আব্দুল্লাহ আল জুহানী': 'abdullah-al-joohani',
  'আব্দুর রহমান আল সুদাইস': 'abdur-rahman-al-sudais',
  'ফারিস আব্বাদ': 'farees-abbad',
  'মিশারি রাশিদ আলাফাসি': 'mishary-bin-rashid-alafasy',
  'আব্দুল বাসিত আব্দুস সামাদ': 'qari-abdul-basit',
  'মাহের আল মুয়াইক্বিলি': 'qari-maher-al-muaiqly',
  'সৌদ আল-শুরাইম': 'qari-saud-bin-ibrahim-ash-shuraim',
};

final selectedReciterProvider = StateProvider<String>((_) => reciters.values.first);

class QuranAudioNotifier extends StateNotifier<QuranAudioState?> {
  QuranAudioNotifier() : super(null);
  void start(int surah, int ayah) => state = QuranAudioState(surah: surah, ayah: ayah, isPlaying: true);
  void updateAyah(int ayah) { if (state != null && state!.ayah != ayah) state = state!.copyWith(ayah: ayah); }
  void pause() { if (state != null) state = state!.copyWith(isPlaying: false); }
  void resume() { if (state != null) state = state!.copyWith(isPlaying: true); }
  void stop() => state = null;
}

final quranAudioProvider = StateNotifierProvider<QuranAudioNotifier, QuranAudioState?>((ref) => QuranAudioNotifier());


// --- NEW AUDIO BACKEND SERVICES AND PROVIDERS ---

// Service to talk to your backend API
class AudioApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://islami-jindegi-backend.fly.dev';

  Future<SuraAudioData?> getSuraAudioUrls(String reciterId, int sura) async {
    try {
      final response = await _dio.post('$_baseUrl/get-sura-audio-urls', data: {'reciterId': reciterId, 'sura': sura});
      return (response.statusCode == 200) ? SuraAudioData.fromJson(response.data) : null;
    } catch (e) {
      print('Failed to get audio URLs: $e');
      return null;
    }
  }
}
final audioApiServiceProvider = Provider((ref) => AudioApiService());

// Service to manage local file paths
class AudioPathService {
  Future<Directory> getSuraDirectory(String reciterId, int sura) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return Directory('${docsDir.path}/$reciterId/$sura');
  }
  Future<String> getLocalPathForAyah(String reciterId, int sura, int ayah) async {
    final suraDir = await getSuraDirectory(reciterId, sura);
    return '${suraDir.path}/$ayah.mp3';
  }
}
final audioPathServiceProvider = Provider((ref) => AudioPathService());

// Notifier and Provider for Download Progress UI
class DownloadProgressNotifier extends StateNotifier<DownloadProgress> {
  DownloadProgressNotifier() : super(DownloadProgress());
  void start(int total) => state = DownloadProgress(totalCount: total);
  void increment() => state = DownloadProgress(downloadedCount: state.downloadedCount + 1, totalCount: state.totalCount);
  void setError(String errorMsg) => state = DownloadProgress(error: errorMsg, totalCount: state.totalCount, downloadedCount: state.downloadedCount);
  void reset() => state = DownloadProgress();
}
final downloadProgressProvider = StateNotifierProvider<DownloadProgressNotifier, DownloadProgress>((ref) => DownloadProgressNotifier());

// Service to manage downloading surahs
class DownloadManager {
  final Dio _dio = Dio();
  final Ref _ref;
  DownloadManager(this._ref);

  Future<bool> downloadSura({required String reciterId, required int sura}) async {
    final apiService = _ref.read(audioApiServiceProvider);
    final pathService = _ref.read(audioPathServiceProvider);
    final progressNotifier = _ref.read(downloadProgressProvider.notifier);

    final suraAudioData = await apiService.getSuraAudioUrls(reciterId, sura);
    if (suraAudioData == null) {
      progressNotifier.setError('Could not fetch audio info.');
      return false;
    }

    final remoteUrls = suraAudioData.urls;
    progressNotifier.start(remoteUrls.length);

    try {
      for (int i = 0; i < remoteUrls.length; i++) {
        final localPath = await pathService.getLocalPathForAyah(reciterId, sura, i + 1);
        await _dio.download(remoteUrls[i], localPath);
        progressNotifier.increment();
      }
      return true;
    } catch (e) {
      print('Download failed: $e');
      progressNotifier.setError('Download failed.');
      final suraDir = await pathService.getSuraDirectory(reciterId, sura);
      if (await suraDir.exists()) await suraDir.delete(recursive: true);
      return false;
    }
  }
}
final downloadManagerProvider = Provider((ref) => DownloadManager(ref));

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService(ref);
  ref.onDispose(service.dispose);
  return service;
});


// --- OTHER UI AND NAVIGATION PROVIDERS (UNCHANGED) ---

class TouchModeNotifier extends StateNotifier<bool> {
  TouchModeNotifier() : super(false);
  void toggle() => state = !state;
}
final touchModeProvider = StateNotifierProvider<TouchModeNotifier, bool>((_) => TouchModeNotifier());

class OrientationToggle {
  static bool _isPortraitOnly = true;
  static Future<void> toggle() async {
    _isPortraitOnly = !_isPortraitOnly;
    if (_isPortraitOnly) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    }
  }
}

class DrawerNotifier extends StateNotifier<bool> {
  DrawerNotifier() : super(false);
  void open() => state = true;
  void close() => state = false;
}
final drawerOpenProvider = StateNotifierProvider<DrawerNotifier, bool>((_) => DrawerNotifier());

final navigateToPageCommandProvider = StateProvider<int?>((_) => null);
void navigateToPage({required WidgetRef ref, required int pageNumber}) {
  ref.read(navigateToPageCommandProvider.notifier).state = pageNumber;
}

const List<(int sura, int ayah)> paraStarts = [ (1, 1), (2, 142), (2, 253), (3, 93), (4, 24), (4, 148), (5, 83), (6, 111), (7, 88), (8, 41), (9, 93), (11, 6), (12, 53), (15, 1), (17, 1), (18, 75), (21, 1), (23, 1), (25, 21), (27, 56), (29, 46), (33, 31), (36, 22), (39, 32), (41, 47), (46, 1), (51, 31), (58, 1), (67, 1), (78, 1) ];

final suraPageMappingProvider = Provider<Map<int, int>>((ref) {
  return ref.watch(allBoxesProvider).maybeWhen(
    data: (boxes) {
      final Map<int, int> suraMapping = {};
      for (final box in boxes) {
        if (!suraMapping.containsKey(box.suraNumber)) {
          suraMapping[box.suraNumber] = box.pageNumber;
        }
      }
      return suraMapping;
    },
    orElse: () => const {},
  );
});

final ayahPageMappingProvider = Provider<Map<(int, int), int>>((ref) {
  return ref.watch(allBoxesProvider).maybeWhen(
    data: (boxes) {
      final Map<(int, int), int> mapping = {};
      for (final box in boxes) {
        final key = (box.suraNumber, box.ayahNumber);
        if (!mapping.containsKey(key)) {
          mapping[key] = box.pageNumber;
        }
      }
      return mapping;
    },
    orElse: () => const {},
  );
});

const List<String> suraNames = [ 'আল-ফাতিহা', 'আল-বাকারা', 'আল-ইমরান', 'আন-নিসা', 'আল-মায়েদাহ', 'আল-আনআম', 'আল-আরাফ', 'আল-আনফাল', 'আত-তাওবাহ', 'ইউনুস', 'হুদ', 'ইউসুফ', 'আর-রাদ', 'ইবরাহিম', 'আল-হিজর', 'আন-নাহল', 'আল-ইসরা', 'আল-কাহফ', 'মারইয়াম', 'ত্বা-হা', 'আল-আম্বিয়া', 'আল-হাজ্জ', 'আল-মুমিনুন', 'আন-নুর', 'আল-ফুরকান', 'আশ-শুআরা', 'আন-নামল', 'আল-কাসাস', 'আল-আনকাবুত', 'আর-রুম', 'লুকমান', 'আস-সাজদাহ', 'আল-আহযাব', 'সাবা', 'ফাতির', 'ইয়া-সীন', 'আস-সাফফাত', 'সা-দ', 'আয-যুমার', 'গাফির', 'ফুসসিলাত', 'আশ-শূরা', 'আয-যুখরুফ', 'আদ-দুখান', 'আল-জাছিয়াহ', 'আল-আহকাফ', 'মুহাম্মাদ', 'আল-ফাতহ', 'আল-হুজুরাত', 'ক্বাফ', 'আয-যারিয়াত', 'আত-তূর', 'আন-নাজম', 'আল-ক্বামার', 'আর-রহমান', 'আল-ওয়াকিআ', 'আল-হাদীদ', 'আল-মুজাদিলা', 'আল-হাশর', 'আল-মুমতাহিনাহ', 'আস-সাফ', 'আল-জুমুআ', 'আল-মুনাফিকুন', 'আত-তাগাবুন', 'আত-ত্বালাক্ব', 'আত-তাহরীম', 'আল-মুলক', 'আল-ক্বালাম', 'আল-হাক্কাহ', 'আল-মাআরিজ', 'নূহ', 'আল-জিন', 'আল-মুযযাম্মিল', 'আল-মুদ্দাসসির', 'আল-ক্বিয়ামাহ', 'আল-ইনসান', 'আল-মুরসালাত', 'আন-নাবা', 'আন-নাযিয়াত', 'আবাসা', 'আত-তাকভীর', 'আল-ইনফিতার', 'আল-মুতাফফিফীন', 'আল-ইনশিক্বাক্ব', 'আল-বুরুজ', 'আত-তারিক্ব', 'আল-আলা', 'আল-গাশিয়াহ', 'আল-ফাজর', 'আল-বালাদ', 'আশ-শামস', 'আল-লাইল', 'আদ-দুহা', 'আল-ইনশিরাহ', 'আত-তীন', 'আল-আলাক্ব', 'আল-ক্বদর', 'আল-বাইয়্যিনাহ', 'আয-যালযালাহ', 'আল-আদিয়াত', 'আল-ক্বারিআহ', 'আত-তাকাছুর', 'আল-আসর', 'আল-হুমাযাহ', 'আল-ফীল', 'কুরাইশ', 'আল-মাউন', 'আল-কাওসার', 'আল-কাফিরুন', 'আন-নাসর', 'আল-মাসাদ', 'আল-ইখলাস', 'আল-ফালাক্ব', 'আন-নাস' ];

final suraNamesProvider = Provider<List<String>>((_) => suraNames);
final selectedNavigationSurahProvider = StateProvider<int?>((_) => null);
final paraPageMappingProvider = Provider<Map<int, int>>((ref) { /* ... unchanged ... */ return {}; });
final paraPageRangesProvider = Provider<Map<int, List<int>>>((ref) { /* ... unchanged ... */ return {}; });
final selectedNavigationParaProvider = StateProvider<int?>((_) => null);

class QuranInfoService {
  final Ref _ref;
  QuranInfoService(this._ref);
  int getParaBySuraAyah(int sura, int ayah) { /* ... unchanged ... */ return 0; }
  int? getParaByPage(int page) { /* ... unchanged ... */ return null; }
  int? getSuraByPage(int page) { /* ... unchanged ... */ return null; }
  int? getPageBySuraAyah(int sura, int ayah) { /* ... unchanged ... */ return null; }
}
final quranInfoServiceProvider = Provider<QuranInfoService>((ref) => QuranInfoService(ref));

class BarsVisibilityNotifier extends StateNotifier<bool> {
  Timer? _hideTimer;
  static const Duration _hideDuration = Duration(seconds: 5);
  bool _autoHideArmed = true;
  BarsVisibilityNotifier() : super(true) { _startAutoHideTimer(); }
  void _startAutoHideTimer() { /* ... unchanged ... */ }
  void show() { /* ... unchanged ... */ }
  void hide() { /* ... unchanged ... */ }
  void toggle() { /* ... unchanged ... */ }
  @override
  void dispose() { _hideTimer?.cancel(); super.dispose(); }
}
final barsVisibilityProvider = StateNotifierProvider<BarsVisibilityNotifier, bool>((ref) => BarsVisibilityNotifier());