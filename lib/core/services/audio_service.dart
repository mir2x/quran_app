import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import '../../features/quran/model/ayah_box.dart';
import '../../features/quran/viewmodel/ayah_highlight_viewmodel.dart';
import '../../features/quran/model/ayah_timing.dart';

class AudioControllerService {
  final Ref ref;
  final _player = AudioPlayer();
  List<AyahTiming> _timings = [];
  List<AyahBox> _ayahBoxes = [];
  int _currentIndex = 0;
  int _startAyah = 1;
  int _endAyah = 1;
  int _sura = 1;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  AudioControllerService(this.ref) {
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }
    });
  }

  void dispose() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    debugPrint('AudioControllerService disposed');
  }

  Future<void> playAyahs(int fromAyah, int toAyah) async {
    stop();

    final vmTimings = await ref.read(audioVMProvider.future);
    _ayahBoxes = await ref.read(allBoxesProvider.future);

    _timings = vmTimings.where((t) => t.sura == _sura && t.ayah != 999).toList();
    _timings.sort((a, b) => a.time.compareTo(b.time));

    _startAyah = fromAyah;
    _endAyah = toAyah;

    _currentIndex = _timings.indexWhere((e) => e.sura == _sura && e.ayah == _startAyah);

    if (_currentIndex == -1) {
      debugPrint('Error: Timing not found for Sura $_sura, Start Ayah $_startAyah');
      return;
    }

    final actualStartAyahTiming = _timings[_currentIndex];
    _startAyah = actualStartAyahTiming.ayah;

    final audioPath = ref.read(audioVMProvider.notifier).getAudioAssetPath(_sura);

    try {
      await _player.setAsset(audioPath);
    } catch (e) {
      debugPrint('Error loading audio asset: $audioPath, Error: $e');
      return;
    }

    await _player.seek(Duration(milliseconds: actualStartAyahTiming.time));

    _player.play();
    ref.read(quranAudioProvider.notifier).start(_sura, _startAyah);

    _highlightAndNavigateToAyahBoxPage(_sura, _startAyah);

    _positionSub?.cancel();
    _positionSub = _player.positionStream.listen((position) {
      _onAudioPosition(position);
    });

    debugPrint('Started playback for Sura $_sura, Ayahs $_startAyah - $_endAyah');
  }

  void _onAudioPosition(Duration position) {
    if (_currentIndex >= _timings.length) {
      return;
    }

    final currentTimeMs = position.inMilliseconds;

    int nextIndexCandidate = _currentIndex + 1;
    while (nextIndexCandidate < _timings.length &&
        _timings[nextIndexCandidate].time <= currentTimeMs) {
      nextIndexCandidate++;
    }

    if (nextIndexCandidate > _currentIndex + 1) {
      final potentialNewAyahIndex = nextIndexCandidate - 1;
      final potentialNewAyah = _timings[potentialNewAyahIndex].ayah;

      final currentlyHighlightedAyah = ref.read(quranAudioProvider)?.ayah;

      if (currentlyHighlightedAyah != potentialNewAyah) {
        _currentIndex = potentialNewAyahIndex;
        final currentTiming = _timings[_currentIndex];

        if (currentTiming.ayah > _endAyah) {
          debugPrint('Reached end ayah $_endAyah, stopping playback.');
          stop();
          return;
        }

        ref.read(quranAudioProvider.notifier).updateAyah(currentTiming.ayah);
        _highlightAndNavigateToAyahBoxPage(_sura, currentTiming.ayah);
        debugPrint('Processing Ayah ${currentTiming.ayah} at time ${position.inMilliseconds}ms');
      }
    }
  }

  void _highlightAndNavigateToAyahBoxPage(int sura, int ayah) {
    final firstAyahBox = _ayahBoxes.firstWhereOrNull(
          (box) => box.suraNumber == sura && box.ayahNumber == ayah,
    );

    if (firstAyahBox != null) {
      final ayahPage = firstAyahBox.pageNumber;

      ref.read(selectedAyahProvider.notifier).selectFromAudio(ayah);

      final currentPageIndex = ref.read(currentPageProvider);
      final currentPageNumber = currentPageIndex + 1;

      if (ayahPage != currentPageNumber) {
        debugPrint('Audio Navigating: Sura $sura Ayah $ayah (Box Page $ayahPage) vs Current Page $currentPageNumber');
        ref.read(navigateToPageCommandProvider.notifier).state = ayahPage;
      }
    } else {
      debugPrint('Warning: First AyahBox not found for Sura $sura, Ayah $ayah. Cannot navigate.');
    }
  }

  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
      ref.read(quranAudioProvider.notifier).pause();
      debugPrint('Audio paused.');
    } else {
      ref.read(quranAudioProvider.notifier).resume();
      _player.play();
      debugPrint('Audio resumed.');
    }
  }

  void stop() {
    _player.stop();
    _positionSub?.cancel();
    _positionSub = null;

    ref.read(quranAudioProvider.notifier).stop();
    ref.read(selectedAyahProvider.notifier).clear();
    debugPrint('Audio playback stopped.');
  }

  void playNext() {
    final currentAyah = ref.read(quranAudioProvider)?.ayah;
    if (currentAyah == null) {
      debugPrint('Cannot play next: No current ayah playing.');
      return;
    }

    final nextIndex = _timings.indexWhere(
            (t) => t.sura == _sura && t.ayah > currentAyah && t.ayah <= _endAyah,
        _currentIndex + 1
    );

    if (nextIndex != -1) {
      debugPrint('Playing next ayah: ${_timings[nextIndex].ayah}');
      _seekToAyahIndex(nextIndex);
    } else {
      debugPrint('No more ayahs in the selected range to play next.');
      stop();
    }
  }

  void playPrev() {
    final currentAyah = ref.read(quranAudioProvider)?.ayah;
    if (currentAyah == null || currentAyah <= _startAyah) {
      debugPrint('Cannot play previous: Already at or before start ayah.');
      if (currentAyah != null && currentAyah > _startAyah) {
        final startIndex = _timings.indexWhere((t) => t.sura == _sura && t.ayah == _startAyah);
        if (startIndex != -1) {
          debugPrint('Seeking to start ayah: $_startAyah');
          _seekToAyahIndex(startIndex);
        }
      }
      return;
    }

    int prevIndex = -1;
    for(int i = _currentIndex - 1; i >= 0; i--) {
      if (_timings[i].sura == _sura && _timings[i].ayah < currentAyah && _timings[i].ayah >= _startAyah) {
        prevIndex = i;
        break;
      }
    }

    if (prevIndex != -1) {
      debugPrint('Playing previous ayah: ${_timings[prevIndex].ayah}');
      _seekToAyahIndex(prevIndex);
    } else {
      debugPrint('Could not find previous ayah within the selected range.');
    }
  }

  void _seekToAyahIndex(int index) {
    if (index < 0 || index >= _timings.length) {
      debugPrint('Seek failed: Invalid timing index $index');
      return;
    }

    final t = _timings[index];
    _currentIndex = index;

    _player.seek(Duration(milliseconds: t.time));

    ref.read(quranAudioProvider.notifier).updateAyah(t.ayah);
    _highlightAndNavigateToAyahBoxPage(_sura, t.ayah);

    if (!_player.playing && ref.read(quranAudioProvider)?.isPlaying == true) {
      _player.play();
    }
    debugPrint('Seeked to Sura ${t.sura}, Ayah ${t.ayah}');
  }

  void setCurrentSura(int sura) {
    _sura = sura;
    debugPrint('Current sura set to $_sura');
  }
}

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