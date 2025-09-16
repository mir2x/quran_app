import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';
import 'package:quran_app/features/quran/viewmodel/reciter_providers.dart';
import 'package:quran_app/shared/quran_data.dart';
import '../../downloader/view/show_download_dialog.dart';
import '../../downloader/view/show_download_permission_dialog.dart';
import '../../downloader/viewmodel/download_providers.dart';
import '../../quran/viewmodel/audio_providers.dart';
import '../model/sura_audio_state.dart';

class SuraAudioNotifier extends StateNotifier<SuraAudioState?> {
  SuraAudioNotifier() : super(null);
  void start(int surah, int ayah) => state = SuraAudioState(surah: surah, ayah: ayah, isPlaying: true);
  void updateAyah(int ayah) { if (state != null && state!.ayah != ayah) state = state!.copyWith(ayah: ayah); }
  void pause() { if (state != null) state = state!.copyWith(isPlaying: false); }
  void resume() { if (state != null) state = state!.copyWith(isPlaying: true); }
  void stop() => state = null;
}

final suraAudioProvider = StateNotifierProvider<SuraAudioNotifier, SuraAudioState?>((ref) => SuraAudioNotifier());

final selectedAudioSuraProvider = StateProvider<int>((_) => 1);
final selectedStartAyahProvider = StateProvider<int>((_) => 1);
final selectedEndAyahProvider = StateProvider<int>((_) => 1);

class SuraAudioPlayer {
  final AudioPlayer _player;
  final Ref _ref;

  int? _endAyahLimit;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _indexSub;

  SuraAudioPlayer(this._ref) : _player = AudioPlayer() {
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
        assetName: 'সুরা ${suraNames[sura]} আয়াত (${ayahsToDownload.first.toBengaliDigit()}-${ayahsToDownload.last.toBengaliDigit()})',
      );
      if (!confirmed || !context.mounted) return false;

      // 1. Fetch the audio URLs needed for the download task.
      final suraAudioData = await _ref.read(audioDataSourceProvider).getSuraAudioUrls(reciterId, sura);
      if (suraAudioData == null) {
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
        id: 'reciter_${reciterId}_sura_$sura', // Unique ID for this download operation
        displayName: 'সুরা ${suraNames[sura]}',
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
    _ref.read(suraAudioProvider.notifier).start(sura, startAyah);
    debugPrint("Fired suraAudioProvider.start with $sura:$startAyah");

    final playlist = ConcatenatingAudioSource(children: audioSources);
    await _player.setAudioSource(playlist, initialIndex: 0, initialPosition: Duration.zero);
    _player.play();

    return true;
  }

  void _setupStateListeners() {
    _indexSub?.cancel();
    _playerStateSub?.cancel();

    _indexSub = _player.currentIndexStream.listen((index) {
      debugPrint("📢 [Listener] currentIndexStream FIRED with index: $index");
      final suraAudioState = _ref.read(suraAudioProvider);
      if (index != null && suraAudioState != null) {
        final actualStartAyah = _ref.read(selectedStartAyahProvider);
        final currentAyah = actualStartAyah + index;

        if (_endAyahLimit != null && currentAyah > _endAyahLimit!) {
          debugPrint("  [Listener] 🏁 Reached end ayah limit ($_endAyahLimit). Stopping playback.");
          stop();
          return;
        }
        _ref.read(suraAudioProvider.notifier).updateAyah(currentAyah);
      } else {
        debugPrint("  [Listener] ⚠️ SKIPPED: index or suraAudioState is null (player not ready or stopped).");
      }
    });

    _playerStateSub = _player.playerStateStream.listen((state) {
      final suraAudioState = _ref.read(suraAudioProvider);
      if (suraAudioState == null) return;

      debugPrint("🎵 [Listener] playerStateStream FIRED: Playing=${state.playing}, ProcessingState=${state.processingState}");

      if(state.playing) {
        _ref.read(suraAudioProvider.notifier).resume();
      } else {
        if (state.processingState == ProcessingState.completed) {
          debugPrint("  [Listener] Player completed playback. Stopping.");
          stop();
        } else {
          _ref.read(suraAudioProvider.notifier).pause();
        }
      }
    });
  }

  // Removed: _highlightAndNavigate method completely

  Future<void> stop() async {
    debugPrint("⏹️ [stop] CALLED. Stopping player and clearing state.");
    await _indexSub?.cancel();
    await _playerStateSub?.cancel();
    _indexSub = null;
    _playerStateSub = null;

    await _player.stop();
    _ref.read(suraAudioProvider.notifier).stop();
    // Removed: _ref.read(selectedAyahProvider.notifier).clear(); // No longer highlighting
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

    if (currentAyahInPlaylistIndex < (_player.sequence?.length ?? 0) - 1) {
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

  void dispose() {
    debugPrint('🗑️ [QuranAudioPlayer] DISPOSED');
    _indexSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
  }
}

final suraAudioPlayerProvider = Provider<SuraAudioPlayer>((ref) {
  final service = SuraAudioPlayer(ref);
  ref.onDispose(service.dispose);
  return service;
});