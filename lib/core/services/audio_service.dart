import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../features/quran/viewmodel/ayah_highlight_viewmodel.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final Ref _ref;

  int? _endAyahLimit;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _indexSub;

  AudioPlayerService(this._ref) {
    debugPrint("✅ [AudioPlayerService] INITIALIZED");
    // FIX: DO NOT set up listeners in the constructor.
    // _setupStateListeners();
  }

  Future<bool> _isSuraDownloaded(String reciterId, int sura) async {
    final pathService = _ref.read(audioPathServiceProvider);
    final suraDir = await pathService.getSuraDirectory(reciterId, sura);
    if (await suraDir.exists()) {
      return suraDir.listSync().isNotEmpty;
    }
    return false;
  }

  Future<bool> playAyahs(int startAyah, int endAyah) async {
    debugPrint("▶️ [playAyahs] CALLED for Sura ${_ref.read(selectedAudioSuraProvider)}, Ayahs $startAyah-$endAyah");
    await stop();

    _endAyahLimit = endAyah;
    final reciterId = _ref.read(selectedReciterProvider);
    final sura = _ref.read(selectedAudioSuraProvider);

    if (!await _isSuraDownloaded(reciterId, sura)) {
      debugPrint("  [playAyahs] Sura not downloaded. Starting download...");
      final downloadManager = _ref.read(downloadManagerProvider);
      final success = await downloadManager.downloadSura(reciterId: reciterId, sura: sura);
      if (!success) {
        debugPrint("  [playAyahs] ❌ Download FAILED.");
        return false;
      }
      debugPrint("  [playAyahs] ✅ Download COMPLETED.");
    }

    final pathService = _ref.read(audioPathServiceProvider);
    final suraDir = await pathService.getSuraDirectory(reciterId, sura);
    final files = suraDir.listSync()
      ..sort((a,b) {
        final numA = int.parse(a.path.split(Platform.pathSeparator).last.split('.').first);
        final numB = int.parse(b.path.split(Platform.pathSeparator).last.split('.').first);
        return numA.compareTo(numB);
      });

    final audioSources = files.map((file) => AudioSource.uri(Uri.file(file.path))).toList();
    if (audioSources.isEmpty) {
      debugPrint("  [playAyahs] ❌ ERROR: No audio files found for Surah $sura");
      return false;
    }

    final playlist = ConcatenatingAudioSource(children: audioSources);

    // FIX: Set up new listeners for THIS session before playing.
    _setupStateListeners();

    _ref.read(quranAudioProvider.notifier).start(sura, startAyah);
    debugPrint("  [playAyahs] Fired quranAudioProvider.start with $sura:$startAyah");
    _highlightAndNavigate(sura, startAyah);

    await _player.setAudioSource(playlist, initialIndex: startAyah - 1, initialPosition: Duration.zero);
    debugPrint("  [playAyahs] Audio source set. Starting playback.");
    _player.play();

    return true;
  }

  void _setupStateListeners() {
    // Cancel any old listeners just in case before creating new ones.
    _indexSub?.cancel();
    _playerStateSub?.cancel();

    _indexSub = _player.currentIndexStream.listen((index) {
      debugPrint("📢 [Listener] currentIndexStream FIRED with index: $index");
      final quranAudioState = _ref.read(quranAudioProvider);
      if (index != null && quranAudioState != null) {
        final currentAyah = index + 1;
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

    // FIX: Cancel listeners to prevent them from firing with stale data.
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
    final currentAyah = _ref.read(quranAudioProvider)?.ayah;
    if (currentAyah != null && _endAyahLimit != null && currentAyah >= _endAyahLimit!) {
      debugPrint("  [playNext] At end ayah limit. Stopping.");
      stop();
      return;
    }
    _player.seekToNext();
  }

  void togglePlayPause() => _player.playing ? _player.pause() : _player.play();
  void playPrev() => _player.seekToPrevious();

  void dispose() {
    debugPrint('AudioPlayerService disposed');
    _indexSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
  }
}

final audioPlayerServiceProvider = Provider.autoDispose<AudioPlayerService>((ref) {
  final service = AudioPlayerService(ref);
  ref.onDispose(service.dispose);
  return service;
});

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}