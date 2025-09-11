import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran_app/features/quran/viewmodel/reciter_providers.dart';
import '../../quran/view/widgets/download_dialog.dart';
import '../../quran/viewmodel/audio_providers.dart';
import '../../quran/viewmodel/download_providers.dart';
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
    debugPrint("▶️ [playAyahs] CALLED for Sura ${_ref.read(selectedAudioSuraProvider)}, Ayahs $startAyah-$endAyah");
    await stop();

    _endAyahLimit = endAyah;
    final reciterId = _ref.read(selectedReciterProvider);
    final sura = _ref.read(selectedAudioSuraProvider);
    final downloadManager = _ref.read(downloadManagerProvider);
    final audioFileManager = _ref.read(audioFileManagerProvider);

    final ayahsToDownload = await _getAyahsToDownload(reciterId, sura, startAyah, endAyah);

    if (ayahsToDownload.isNotEmpty) {
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
      ) ?? false;

      if (!confirmDownload) {
        debugPrint("  [playAyahs] Download declined by user.");
        return false;
      }

      if (!context.mounted) return false;
      showDownloadDialog(context);

      final success = await downloadManager.downloadAyahs(
        reciterId: reciterId,
        sura: sura,
        ayahsToDownload: ayahsToDownload,
      );

      if (!context.mounted) return false;
      Navigator.of(context).pop();

      if (!success) {
        debugPrint("  [playAyahs] ❌ Download FAILED.");
        return false;
      }
      debugPrint("  [playAyahs] ✅ Download COMPLETED for required ayahs.");
    } else {
      debugPrint("  [playAyahs] All required ayahs are already downloaded. Playing directly.");
    }

    final List<AudioSource> audioSources = [];
    for (int i = startAyah; i <= endAyah; i++) {
      final localPath = await audioFileManager.getLocalPathForAyah(reciterId, sura, i);
      if (await File(localPath).exists()) {
        audioSources.add(AudioSource.uri(Uri.file(localPath)));
      } else {
        debugPrint("  [playAyahs] WARNING: Ayah $i was expected but not found locally.");
      }
    }

    if (audioSources.isEmpty) {
      debugPrint("  [playAyahs] ❌ ERROR: No audio files found for the selected range $startAyah-$endAyah");
      return false;
    }

    final playlist = ConcatenatingAudioSource(children: audioSources);

    _setupStateListeners();

    _ref.read(suraAudioProvider.notifier).start(sura, startAyah);
    debugPrint("  [playAyahs] Fired suraAudioProvider.start with $sura:$startAyah");

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