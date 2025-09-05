import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_app/shared/extensions.dart';
import '../../sura/viewmodel/sura_reciter_viewmodel.dart';
import '../model/audio_state.dart';
import '../model/sura_audio_data.dart';
import 'ayah_highlight_viewmodel.dart';
import 'download_providers.dart';

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
    return '${suraDir.path}/$ayah.mp3';
  }

  // New method to check if a single ayah is downloaded
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
  final AudioPlayer _player = AudioPlayer();
  final Ref _ref;

  int? _endAyahLimit;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _indexSub;

  QuranAudioPlayer(this._ref) {
    debugPrint("✅ [AudioPlayerService] INITIALIZED");
  }

  // Helper to determine which ayahs need downloading
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
    debugPrint("▶️ [playAyahs] CALLED for Sura ${_ref.read(selectedAudioSuraProvider)}, Ayahs $startAyah-$endAyah");
    await stop(); // Stop any currently playing audio

    _endAyahLimit = endAyah;
    final reciterId = _ref.read(selectedReciterProvider);
    final sura = _ref.read(selectedAudioSuraProvider);
    final downloadManager = _ref.read(downloadManagerProvider);
    final audioFileManager = _ref.read(audioFileManagerProvider);

    final ayahsToDownload = await _getAyahsToDownload(reciterId, sura, startAyah, endAyah);

    if (ayahsToDownload.isNotEmpty) {
      // If there are ayahs to download, ask the user
      final bool confirmDownload = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Download Audio'),
            content: Text(
                'Audio for Ayahs ${ayahsToDownload.first} - ${ayahsToDownload.last} of Surah $sura is not downloaded. Do you want to download it?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Yes'),
              ),
            ],
          );
        },
      ) ?? false; // Default to false if dialog is dismissed

      if (!confirmDownload) {
        debugPrint("  [playAyahs] Download declined by user.");
        return false;
      }

      // User confirmed, now show the download progress dialog and start download
      if (!context.mounted) return false;
      _showDownloadDialog(context); // Pass context here

      final success = await downloadManager.downloadAyahs(
        reciterId: reciterId,
        sura: sura,
        ayahsToDownload: ayahsToDownload,
      );

      if (!context.mounted) return false;
      Navigator.of(context).pop(); // Pop the download progress dialog

      if (!success) {
        debugPrint("  [playAyahs] ❌ Download FAILED.");
        return false;
      }
      debugPrint("  [playAyahs] ✅ Download COMPLETED for required ayahs.");
    } else {
      debugPrint("  [playAyahs] All required ayahs are already downloaded. Playing directly.");
    }

    // Now, load all available ayahs for the selected range into the playlist
    final List<AudioSource> audioSources = [];
    for (int i = startAyah; i <= endAyah; i++) {
      final localPath = await audioFileManager.getLocalPathForAyah(reciterId, sura, i);
      // Only add to playlist if the file actually exists
      if (await File(localPath).exists()) {
        audioSources.add(AudioSource.uri(Uri.file(localPath)));
      } else {
        // This case should ideally not happen if download was successful,
        // but good to have a fallback/warning.
        debugPrint("  [playAyahs] WARNING: Ayah $i was expected but not found locally.");
      }
    }

    if (audioSources.isEmpty) {
      debugPrint("  [playAyahs] ❌ ERROR: No audio files found for the selected range $startAyah-$endAyah");
      return false;
    }

    final playlist = ConcatenatingAudioSource(children: audioSources);

    _setupStateListeners();

    _ref.read(quranAudioProvider.notifier).start(sura, startAyah);
    debugPrint("  [playAyahs] Fired quranAudioProvider.start with $sura:$startAyah");
    _highlightAndNavigate(sura, startAyah);

    // Initial index needs to be adjusted because the playlist only contains ayahs from startAyah to endAyah
    // and its 0-indexed. So startAyah-startAyah = 0.
    await _player.setAudioSource(playlist, initialIndex: 0, initialPosition: Duration.zero);
    debugPrint("  [playAyahs] Audio source set. Starting playback.");
    _player.play();

    return true;
  }

  void _setupStateListeners() {
    _indexSub?.cancel();
    _playerStateSub?.cancel();

    _indexSub = _player.currentIndexStream.listen((index) {
      debugPrint("📢 [Listener] currentIndexStream FIRED with index: $index");
      final quranAudioState = _ref.read(quranAudioProvider);
      if (index != null && quranAudioState != null) {
        // The current index here refers to the index within the *currently playing playlist*,
        // which starts from `startAyah`. So, we need to add `_ref.read(selectedStartAyahProvider)`
        // to get the actual ayah number.
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
        debugPrint("  [Listener] ⚠️ SKIPPED: index or quranAudioState is null.");
      }
    });

    _playerStateSub = _player.playerStateStream.listen((state) {
      final quranAudioState = _ref.read(quranAudioProvider);
      if (quranAudioState == null) return;
      if(state.playing) {
        _ref.read(quranAudioProvider.notifier).resume();
      } else {
        if (state.processingState == ProcessingState.completed) {
          stop();
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
      debugPrint("  [HN] ❌ WARNING: Could not find AyahBox for Sura $sura, Ayah: $ayah.");
    }
  }

  Future<void> stop() async {
    debugPrint("⏹️ [stop] CALLED. Stopping player and clearing state.");
    await _indexSub?.cancel();
    await _playerStateSub?.cancel();
    _indexSub = null;
    _playerStateSub = null;

    await _player.stop();
    _ref.read(quranAudioProvider.notifier).stop();
    _ref.read(selectedAyahProvider.notifier).clear();
    _endAyahLimit = null;
  }

  void playNext() {
    final currentAyahInPlaylistIndex = _player.currentIndex;
    final startAyah = _ref.read(selectedStartAyahProvider);

    if (currentAyahInPlaylistIndex == null) {
      debugPrint("  [playNext] No current ayah in playlist.");
      return;
    }

    final currentAyahActual = startAyah + currentAyahInPlaylistIndex;

    if (_endAyahLimit != null && currentAyahActual >= _endAyahLimit!) {
      debugPrint("  [playNext] At end ayah limit ($_endAyahLimit). Stopping.");
      stop();
      return;
    }

    // Only seek to next if there are more items in the playlist
    if (currentAyahInPlaylistIndex < (_player.sequence?.length ?? 0) - 1) {
      _player.seekToNext();
    } else {
      // If it's the last item in the current playlist
      debugPrint("  [playNext] Reached end of current playlist. Stopping.");
      stop();
    }
  }


  void togglePlayPause() => _player.playing ? _player.pause() : _player.play();

  void playPrev() {
    final currentAyahInPlaylistIndex = _player.currentIndex;
    final startAyah = _ref.read(selectedStartAyahProvider);

    if (currentAyahInPlaylistIndex == null || currentAyahInPlaylistIndex <= 0) {
      // Cannot go to previous if at the very beginning of the playlist
      debugPrint("  [playPrev] At the start of the playlist or no current ayah.");
      return;
    }

    // Just_Audio's seekToPrevious handles the index correctly within the current playlist
    _player.seekToPrevious();
  }


  void dispose() {
    debugPrint('AudioPlayerService disposed');
    _indexSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
  }
}

final  quranAudioPlayerProvider = Provider.autoDispose<QuranAudioPlayer>((ref) {
  final service = QuranAudioPlayer(ref);
  ref.onDispose(service.dispose);
  return service;
});

// Original _showDownloadDialog (moved to be accessible)
void _showDownloadDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return PopScope(
        canPop: false,
        child: Consumer(
          builder: (context, ref, _) {
            final progress = ref.watch(downloadProgressProvider);
            // Use a consistent text style
            final textStyle = Theme.of(context).textTheme.titleMedium;

            if (progress.error != null) {
              return AlertDialog(
                title: const Text('Download Error'),
                content: Text(progress.error!, style: textStyle),
                actions: [
                  TextButton(
                    onPressed: () {
                      ref.read(downloadProgressProvider.notifier).reset();
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            }

            final bool isDownloading = progress.totalCount > 0;
            final String progressText = isDownloading
                ? 'Downloading...\n${progress.downloadedCount} / ${progress.totalCount}'
                : 'Preparing audio...';

            return AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(value: isDownloading ? progress.percentage : null),
                  SizedBox(width: 20), // Use fixed size instead of .w if not using responsive design setup
                  Text(progressText, style: textStyle),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}