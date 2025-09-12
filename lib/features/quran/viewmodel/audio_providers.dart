import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_app/features/quran/viewmodel/reciter_providers.dart';
import 'package:quran_app/shared/extensions.dart';
import '../../downloader/view/show_download_dialog.dart';
import '../../downloader/view/show_download_permission_dialog.dart';
import '../../downloader/viewmodel/download_providers.dart';
import '../model/audio_state.dart';
import '../model/sura_audio_data.dart';
import 'ayah_highlight_viewmodel.dart';


class AudioDataSource {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://islami-jindegi-backend.fly.dev';

  Future<SuraAudioData?> getSuraAudioUrls(String reciterId, int sura) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/get-sura-audio-urls',
        data: {
          'reciterId': reciterId,
          'sura': sura,
        },
      );
      if (response.statusCode == 200) {
        return SuraAudioData.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Failed to get audio URLs: $e');
      return null;
    }
  }
}

final audioDataSourceProvider = Provider<AudioDataSource>((ref) {
  return AudioDataSource();
});

class AudioFileManager {
  Future<Directory> getSuraDirectory(String reciterId, int sura) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return Directory('${docsDir.path}/$reciterId/$sura');
  }

  Future<String> getLocalPathForAyah(String reciterId, int sura, int ayah) async {
    final suraDir = await getSuraDirectory(reciterId, sura);
    // Ensure the directory exists before returning the path, though download manager should create it.
    if (!await suraDir.exists()) {
      await suraDir.create(recursive: true);
    }
    return '${suraDir.path}/$ayah.mp3';
  }

  Future<bool> isAyahDownloaded(String reciterId, int sura, int ayah) async {
    final path = await getLocalPathForAyah(reciterId, sura, ayah);
    return File(path).exists();
  }
}
final audioFileManagerProvider = Provider((ref) => AudioFileManager());

class QuranAudioNotifier extends StateNotifier<QuranAudioState?> {
  QuranAudioNotifier() : super(null);
  void start(int surah, int ayah) => state = QuranAudioState(surah: surah, ayah: ayah, isPlaying: true);
  void updateAyah(int ayah) { if (state != null && state!.ayah != ayah) state = state!.copyWith(ayah: ayah); }
  void pause() { if (state != null) state = state!.copyWith(isPlaying: false); }
  void resume() { if (state != null) state = state!.copyWith(isPlaying: true); }
  void stop() => state = null;
}

final quranAudioProvider = StateNotifierProvider<QuranAudioNotifier, QuranAudioState?>((ref) => QuranAudioNotifier());

final selectedAudioSuraProvider = StateProvider<int>((_) => 1);
final selectedStartAyahProvider = StateProvider<int>((_) => 1);
final selectedEndAyahProvider = StateProvider<int>((_) => 1);

class QuranAudioPlayer {
  final AudioPlayer _player; // Initialize player here
  final Ref _ref;

  int? _endAyahLimit;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _indexSub;

  QuranAudioPlayer(this._ref) : _player = AudioPlayer() { // Player initialized in constructor
    debugPrint("✅ [QuranAudioPlayer] INITIALIZED");
  }

  Future<List<int>> _getAyahsToDownload(String reciterId, int sura, int startAyah, int endAyah) async {
    final audioFileManager = _ref.read(audioFileManagerProvider);
    final List<int> ayahsNeeded = [];
    for (int i = startAyah; i <= endAyah; i++) {
      if (!await audioFileManager.isAyahDownloaded(reciterId, sura, i)) {
        ayahsNeeded.add(i);
      }
    }
    return ayahsNeeded;
  }

  Future<bool> playAyahs(int startAyah, int endAyah, BuildContext context) async {
    await stop();

    _endAyahLimit = endAyah;
    final reciterId = _ref.read(selectedReciterProvider);
    final sura = _ref.read(selectedAudioSuraProvider);
    final audioFileManager = _ref.read(audioFileManagerProvider);

    final ayahsToDownload = await _getAyahsToDownload(reciterId, sura, startAyah, endAyah);

    // If ayahs are missing, trigger the unified download flow.
    if (ayahsToDownload.isNotEmpty) {
      final confirmed = await showDownloadPermissionDialog(
        context,
        assetName: 'Audio for Surah $sura (${ayahsToDownload.first}-${ayahsToDownload.last})',
      );
      if (!confirmed || !context.mounted) return false;

      // 1. Fetch the audio URLs needed for the download task.
      final suraAudioData = await _ref.read(audioDataSourceProvider).getSuraAudioUrls(reciterId, sura);
      if (suraAudioData == null) {
        // Optionally show an error to the user here.
        debugPrint("Could not fetch audio URLs to start download.");
        return false;
      }

      // 2. Prepare the map of URLs to local file paths for the task.
      final Map<String, String> urlToPathMap = {};
      for (int ayahNum in ayahsToDownload) {
        if (ayahNum > 0 && ayahNum <= suraAudioData.urls.length) {
          final remoteUrl = suraAudioData.urls[ayahNum - 1];
          final localPath = await audioFileManager.getLocalPathForAyah(reciterId, sura, ayahNum);
          urlToPathMap[remoteUrl] = localPath;
        }
      }

      // 3. Create the specific download task.
      final audioDownloadTask = MultiFileDownloadTask(
        id: 'reciter_${reciterId}_sura_$sura',
        displayName: 'Downloading Audio for Surah $sura',
        urlToPathMap: urlToPathMap,
      );

      // 4. Show the unified dialog and start the download.
      showDownloadDialog(context);
      final success = await _ref.read(downloadManagerProvider).startDownload(audioDownloadTask);

      // 5. If the download failed or was cancelled, stop here.
      if (!success) {
        debugPrint("Download failed or was cancelled. Aborting playback.");
        return false;
      }
    }

    // --- Playback logic (unchanged) ---
    final List<AudioSource> audioSources = [];
    for (int i = startAyah; i <= endAyah; i++) {
      final localPath = await audioFileManager.getLocalPathForAyah(reciterId, sura, i);
      if (await File(localPath).exists()) {
        audioSources.add(AudioSource.uri(Uri.file(localPath)));
      } else {
        debugPrint("WARNING: Ayah $i was expected but not found locally after download check.");
      }
    }

    if (audioSources.isEmpty) {
      debugPrint("ERROR: No audio files found for the selected range $startAyah-$endAyah");
      return false;
    }

    _setupStateListeners();
    _ref.read(quranAudioProvider.notifier).start(sura, startAyah);
    _highlightAndNavigate(sura, startAyah);

    final playlist = ConcatenatingAudioSource(children: audioSources);
    await _player.setAudioSource(playlist, initialIndex: 0, initialPosition: Duration.zero);
    _player.play();

    return true;
  }

  void _setupStateListeners() {
    // Cancel existing subscriptions if any, to avoid duplicate listeners
    _indexSub?.cancel();
    _playerStateSub?.cancel();

    _indexSub = _player.currentIndexStream.listen((index) {
      debugPrint("📢 [Listener] currentIndexStream FIRED with index: $index");
      final quranAudioState = _ref.read(quranAudioProvider);
      if (index != null && quranAudioState != null) {
        final actualStartAyah = _ref.read(selectedStartAyahProvider);
        final currentAyah = actualStartAyah + index;

        if (_endAyahLimit != null && currentAyah > _endAyahLimit!) {
          debugPrint("  [Listener] 🏁 Reached end ayah limit ($_endAyahLimit). Stopping playback.");
          stop();
          return;
        }
        _ref.read(quranAudioProvider.notifier).updateAyah(currentAyah);
        _highlightAndNavigate(quranAudioState.surah, currentAyah);
      } else {
        // This might fire with null initially or during state transitions.
        debugPrint("  [Listener] ⚠️ SKIPPED: index or quranAudioState is null (player not ready or stopped).");
      }
    });

    _playerStateSub = _player.playerStateStream.listen((state) {
      final quranAudioState = _ref.read(quranAudioProvider);
      if (quranAudioState == null) return;

      debugPrint("🎵 [Listener] playerStateStream FIRED: Playing=${state.playing}, ProcessingState=${state.processingState}");

      if(state.playing) {
        _ref.read(quranAudioProvider.notifier).resume();
      } else {
        if (state.processingState == ProcessingState.completed) {
          debugPrint("  [Listener] Player completed playback. Stopping.");
          stop(); // Stop when the playlist finishes
        } else {
          _ref.read(quranAudioProvider.notifier).pause();
        }
      }
    });
  }

  void _highlightAndNavigate(int sura, int ayah) {
    debugPrint("🎨 [_highlightAndNavigate] CALLED for Sura: $sura, Ayah: $ayah");
    final allAyahBoxes = _ref.read(allBoxesProvider).valueOrNull;

    if (allAyahBoxes == null) {
      debugPrint("  [HN] ❌ ERROR: Ayah boxes data is NULL. Cannot highlight.");
      return;
    }

    final firstBoxForAyah = allAyahBoxes.firstWhereOrNull((box) => box.suraNumber == sura && box.ayahNumber == ayah);
    if (firstBoxForAyah != null) {
      debugPrint("  [HN] ✅ Found AyahBox for $sura:$ayah on Page ${firstBoxForAyah.pageNumber}. Setting selectedAyahProvider.");
      _ref.read(selectedAyahProvider.notifier).selectByAudio(sura, ayah);
      final targetPage = firstBoxForAyah.pageNumber;
      final currentPage = _ref.read(currentPageProvider) + 1;
      if (targetPage != currentPage) {
        debugPrint("  [HN]  NAVIGATING from page $currentPage to $targetPage.");
        _ref.read(navigateToPageCommandProvider.notifier).state = targetPage;
      }
    } else {
      debugPrint("  [HN] ❌ WARNING: Could not find AyahBox for Sura $sura, Ayah: $ayah. Ensure ayah box data is correct.");
    }
  }

  Future<void> stop() async {
    debugPrint("⏹️ [stop] CALLED. Stopping player and clearing state.");
    // Only cancel subscriptions, do NOT dispose the player here
    await _indexSub?.cancel();
    await _playerStateSub?.cancel();
    _indexSub = null;
    _playerStateSub = null;

    await _player.stop(); // Stop the audio playback
    _ref.read(quranAudioProvider.notifier).stop(); // Clear audio state
    _ref.read(selectedAyahProvider.notifier).clear(); // Clear ayah highlight
    _endAyahLimit = null;
  }

  void playNext() {
    final currentAyahInPlaylistIndex = _player.currentIndex;
    final startAyah = _ref.read(selectedStartAyahProvider);

    if (currentAyahInPlaylistIndex == null) {
      debugPrint("  [playNext] No current ayah in playlist. Cannot seek next.");
      return;
    }

    final currentActualAyah = startAyah + currentAyahInPlaylistIndex;
    if (_endAyahLimit != null && currentActualAyah >= _endAyahLimit!) {
      debugPrint("  [playNext] At end ayah limit ($_endAyahLimit). Stopping.");
      stop();
      return;
    }

    if (currentAyahInPlaylistIndex < (_player.sequence.length ?? 0) - 1) {
      _player.seekToNext();
    } else {
      debugPrint("  [playNext] Reached end of current playlist. Stopping.");
      stop();
    }
  }

  void togglePlayPause() => _player.playing ? _player.pause() : _player.play();

  void playPrev() {
    final currentAyahInPlaylistIndex = _player.currentIndex;
    if (currentAyahInPlaylistIndex == null || currentAyahInPlaylistIndex == 0) {
      debugPrint("  [playPrev] At the start of the playlist or no current ayah. Cannot seek previous.");
      return;
    }
    _player.seekToPrevious();
  }

  // This dispose method will only be called when the provider itself is disposed
  // by Riverpod (e.g., if it's autoDispose and nothing is listening, or if explicitly done).
  void dispose() {
    debugPrint('🗑️ [QuranAudioPlayer] DISPOSED');
    _indexSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose(); // Dispose the actual audio player instance here
  }
}

final  quranAudioPlayerProvider = Provider<QuranAudioPlayer>((ref) {
  final service = QuranAudioPlayer(ref);
  ref.onDispose(service.dispose);
  return service;
});
