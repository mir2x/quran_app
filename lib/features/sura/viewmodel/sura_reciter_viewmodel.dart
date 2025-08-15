import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/fileChecker.dart'; // Assuming this exists
import '../../quran/model/audio_state.dart'; // Renamed from quran_audio_state.dart
import '../../quran/model/ayah_timing.dart';
import '../../quran/model/reciter_asset.dart';

// --- RECITER PROVIDERS (Unchanged) ---
final Map<String, String> reciters = {
  'মাহের আল মুয়াইক্বিলি': 'maher_muaiqly',
  'সৌদ আল-শুরাইম': 'saud_shuraim',
  'আলী জাবের': 'ali_jaber',
  'আব্দুল মুনিম আব্দুল মুবদি': 'abdul_munim_mubdi',
};
final selectedReciterProvider = StateProvider<String>((_) => reciters.values.first);
final reciterCatalogueProvider = Provider<List<ReciterAsset>>((_) => const [ /* ... */ ]);


// --- AUDIO VIEWMODEL (Unchanged) ---
final audioVMProvider = AsyncNotifierProvider<AudioVM, List<AyahTiming>>(AudioVM.new);

class AudioVM extends AsyncNotifier<List<AyahTiming>> {
  // ... (No changes in this class)
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

class QuranAudioNotifier extends StateNotifier<QuranAudioState?> {
  QuranAudioNotifier() : super(null);

  void start(int surah, int ayah) {
    state = QuranAudioState(surah: surah, ayah: ayah, isPlaying: true);
    debugPrint("Audio state started: Sura $surah, Ayah $ayah");
  }

  void updateAyah(int ayah) {
    if (state != null && state!.ayah != ayah) {
      state = state!.copyWith(ayah: ayah);
      debugPrint("Audio state updated: Ayah $ayah");
    }
  }

  void pause() {
    if (state != null && state!.isPlaying) {
      state = state!.copyWith(isPlaying: false);
      debugPrint("Audio state paused");
    }
  }

  void resume() {
    if (state != null && !state!.isPlaying) {
      state = state!.copyWith(isPlaying: true);
      debugPrint("Audio state resumed");
    }
  }

  void stop() {
    if (state != null) {
      state = null;
      debugPrint("Audio state stopped");
    }
  }
}

final quranAudioProvider = StateNotifierProvider<QuranAudioNotifier, QuranAudioState?>(
      (ref) => QuranAudioNotifier(),
);


// --- AUDIO CONTROLLER SERVICE (Updated) ---
class AudioControllerService {
  final Ref ref;
  final _player = AudioPlayer();
  List<AyahTiming> _timings = [];
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

  void setCurrentSura(int sura) {
    _sura = sura;
    debugPrint('Audio Service: Sura set to $_sura');
  }

  Future<void> playAyahs(int fromAyah, int toAyah) async {
    print('playAyahs called with fromAyah: $fromAyah, toAyah: $toAyah for Sura $_sura');
    stop();
    try {

      await ref.read(audioVMProvider.notifier).loadTimings();
      final vmTimings = await ref.read(audioVMProvider.future);

      _timings = vmTimings
          .where((t) => t.sura == _sura && t.ayah != 999)
          .toList();
      _timings.sort((a, b) => a.time.compareTo(b.time));

      if (_timings.isEmpty) {
        print('Error: No timings found for Sura $_sura');
        return;
      }
      print('Timings loaded for Sura $_sura: ${_timings.length} entries.');

      _startAyah = fromAyah;
      _endAyah = toAyah;

      _currentIndex = _timings.indexWhere((e) => e.ayah >= _startAyah && e.ayah <= _endAyah);

      if (_currentIndex == -1) {
        print('Error: Could not find any ayah within range $_startAyah - $_endAyah in timings for Sura $_sura.');
        // Optionally, find the first available ayah if the start is not found but within the sura
        _currentIndex = _timings.indexWhere((e) => e.ayah >= _startAyah);
        if (_currentIndex == -1) {
          print('Error: Also could not find start Ayah $_startAyah in timings at all.');
          return;
        }
        print('Adjusted _currentIndex to $_currentIndex (Ayah ${_timings[_currentIndex].ayah}) as start ayah not found.');
        // Re-check if the adjusted index is within the end range
        if (_timings[_currentIndex].ayah > _endAyah) {
          print('Error: Adjusted start ayah ${_timings[_currentIndex].ayah} is beyond the end ayah $_endAyah.');
          return;
        }
      }

      print('Initial _currentIndex set to $_currentIndex (Ayah ${_timings[_currentIndex].ayah})');

      // Get the audio file path
      final audioPath = await ref.read(audioVMProvider.notifier).getAudioAssetPath(_sura);
      await _player.setFilePath(audioPath);
      print('Audio file set to: $audioPath');

      // Seek to the determined starting ayah and start playback
      _seekToAyahIndex(_currentIndex, shouldPlay: true);

      // Start listening to position changes
      _positionSub?.cancel(); // Cancel any old listener
      _positionSub = _player.positionStream.listen(_onAudioPosition);
      print('Playback initiated for Sura $_sura, Ayahs $_startAyah - $_endAyah.');

    } catch (e, stacktrace) {
      print('Error in playAyahs: $e');
      print('Stacktrace: $stacktrace');
      stop();
    }
  }

  void _onAudioPosition(Duration position) {
    if (_timings.isEmpty || _currentIndex < 0 || _currentIndex >= _timings.length) {
      return;
    }

    final currentTimeMs = position.inMilliseconds;
    if (_currentIndex < _timings.length - 1) {
      final nextAyahTiming = _timings[_currentIndex + 1];
      if (currentTimeMs >= nextAyahTiming.time) {
        print('Debug: Advancing to next ayah. Current index: $_currentIndex, Next Ayah: ${nextAyahTiming.ayah}');
        if (nextAyahTiming.ayah > _endAyah) {
          print('Debug: Next ayah ${nextAyahTiming.ayah} is beyond the end ayah $_endAyah. Stopping playback.');
          stop();
          return;
        }
        _currentIndex++;
        ref.read(quranAudioProvider.notifier).updateAyah(nextAyahTiming.ayah);
      }
    } else {
      if (_player.playing && _currentIndex == _timings.length - 1) {
        print('Debug: Reached the last loaded ayah. Stopping playback.');
        stop();
      }
    }
  }

  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
      ref.read(quranAudioProvider.notifier).pause();
      print('Toggled to Pause');
    } else if (ref.read(quranAudioProvider) != null) {
      _player.play();
      ref.read(quranAudioProvider.notifier).resume();
      print('Toggled to Play');
    } else {
      print('Cannot resume: No active audio session.');
    }
  }

  void stop() {
    if (_player.playing) {
      _player.stop();
    }
    _positionSub?.cancel();
    _positionSub = null;
    ref.read(quranAudioProvider.notifier).stop();
    _timings.clear();
    _currentIndex = -1;
    print('Playback stopped and state reset.');
  }

  void playNext() {
    print('playNext called.');
    if (ref.read(quranAudioProvider) == null || _currentIndex < 0) {
      print('Cannot playNext: No active audio session or invalid _currentIndex.');
      return;
    }

    if (_currentIndex >= _timings.length - 1) {
      print('Cannot playNext: Already at the last loaded ayah ($_currentIndex). Stopping.');
      stop();
      return;
    }

    final nextTiming = _timings[_currentIndex + 1];

    if (nextTiming.ayah > _endAyah) {
      print('Cannot playNext: Next ayah ${nextTiming.ayah} is beyond the end ayah $_endAyah. Stopping.');
      stop();
      return;
    }

    _seekToAyahIndex(_currentIndex + 1);
    print('Called _seekToAyahIndex for next ayah.');
  }

  void playPrev() {
    print('playPrev called.');
    if (ref.read(quranAudioProvider) == null || _currentIndex <= 0) {
      print('Cannot playPrev: No active audio session or _currentIndex is 0 or less.');
      return;
    }

    final prevTiming = _timings[_currentIndex - 1];

    if (prevTiming.ayah < _startAyah) {
      print('Cannot playPrev: Previous ayah ${prevTiming.ayah} is before the start ayah $_startAyah. Doing nothing.');
      return;
    }

    _seekToAyahIndex(_currentIndex - 1);
    print('Called _seekToAyahIndex for previous ayah.');
  }

  void _seekToAyahIndex(int index, {bool shouldPlay = false}) {
    print('_seekToAyahIndex called for index: $index');
    if (index < 0 || index >= _timings.length) {
      print('Error: _seekToAyahIndex called with invalid index $index. Max index is ${_timings.length - 1}.');
      return;
    }

    _currentIndex = index;
    final timing = _timings[index];
    print('Seeking to Ayah: ${timing.ayah} (Index: $_currentIndex) at time ${timing.time}ms');

    _player.seek(Duration(milliseconds: timing.time));

    
    final ayahForState = timing.ayah; // The ayah number to report in the state
    final quranStateNotifier = ref.read(quranAudioProvider.notifier);

    if (shouldPlay) {
      _player.play();
      if (ref.read(quranAudioProvider) == null) {
        quranStateNotifier.start(_sura, ayahForState);
      } else {
        quranStateNotifier.updateAyah(ayahForState);
        quranStateNotifier.resume(); // Ensure it's playing
      }
      print('Seeked and started playing Ayah: $ayahForState');
    } else {
      // If not explicitly told to play, just update the Ayah in the state
      // This is useful for navigation (prev/next) when the player might already be playing
      if (ref.read(quranAudioProvider) != null) {
        quranStateNotifier.updateAyah(ayahForState);
      }
      print('Seeked to Ayah: $ayahForState (Player state not forced to play)');
    }
  }
}


// --- SERVICE PROVIDER (Unchanged) ---
final audioPlayerServiceProvider = Provider<AudioControllerService>((ref) {
  final service = AudioControllerService(ref);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});