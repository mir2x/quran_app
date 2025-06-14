import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../features/quran/model/ayah_timing.dart';
import '../../features/quran/viewmodel/ayah_highlight_viewmodel.dart';

class AudioControllerService {
  final Ref ref;
  final _player = AudioPlayer();
  List<AyahTiming> _timings = [];
  int _currentIndex = 0;
  int _startAyah = 1;
  int _endAyah = 1;
  int _sura = 1;
  StreamSubscription<Duration>? _positionSub;

  AudioControllerService(this.ref);

  Future<void> playAyahs(int fromAyah, int toAyah) async {
    final vm = await ref.read(audioVMProvider.future);
    _timings = vm.where((t) => t.sura == _sura && t.ayah != 999).toList();
    _timings.sort((a, b) => a.time.compareTo(b.time));

    _startAyah = fromAyah;
    _endAyah = toAyah;

    _currentIndex =
        _timings.indexWhere((e) => e.ayah == _startAyah && e.sura == _sura);

    final audioPath =
    ref.read(audioVMProvider.notifier).getAudioAssetPath(_sura);

    await _player.setAsset(audioPath);

    _player.play();
    ref.read(quranAudioProvider.notifier).start(_sura, _startAyah);

    _positionSub?.cancel();
    _positionSub = _player.positionStream.listen((position) {
      _onAudioPosition(position);
    });
  }

  void _onAudioPosition(Duration position) {
    if (_currentIndex >= _timings.length) return;

    final currentTimeMs = position.inMilliseconds;

    for (int i = _currentIndex; i < _timings.length; i++) {
      final t = _timings[i];
      final isLast = i == _timings.length - 1;
      final isNextAfterEnd = t.ayah > _endAyah;

      if (isNextAfterEnd) {
        stop(); // We've passed the last ayah in range
        return;
      }

      if (t.time <= currentTimeMs &&
          (isLast || _timings[i + 1].time > currentTimeMs)) {
        _currentIndex = i;
        ref.read(quranAudioProvider.notifier).updateAyah(t.ayah);
        ref.read(selectedAyahProvider.notifier).selectFromAudio(t.ayah);
        break;
      }
    }
  }


  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
      ref.read(quranAudioProvider.notifier).pause();
    } else {
      _player.play();
      ref.read(quranAudioProvider.notifier).resume();
    }
  }

  void stop() {
    _player.stop();
    ref.read(quranAudioProvider.notifier).stop();
    _positionSub?.cancel();
  }

  void playNext() {
    final nextIndex = _currentIndex + 1;
    if (nextIndex < _timings.length &&
        _timings[nextIndex].ayah <= _endAyah) {
      _seekToAyahIndex(nextIndex);
    }
  }

  void playPrev() {
    final prevIndex = _currentIndex - 1;
    if (prevIndex >= 0 && _timings[prevIndex].ayah >= _startAyah) {
      _seekToAyahIndex(prevIndex);
    }
  }

  void _seekToAyahIndex(int index) {
    final t = _timings[index];
    _currentIndex = index;
    _player.seek(Duration(milliseconds: t.time));
    ref.read(quranAudioProvider.notifier).updateAyah(t.ayah);
    ref.read(selectedAyahProvider.notifier).selectFromAudio(t.ayah); // highlight it
  }

  void setCurrentSura(int sura) {
    _sura = sura;
  }
}
