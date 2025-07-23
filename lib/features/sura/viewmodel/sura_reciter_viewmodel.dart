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


// --- QURAN AUDIO NOTIFIER (Unchanged) ---
class QuranAudioNotifier extends StateNotifier<QuranAudioState?> {
  // ... (No changes in this class)
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
    stop();
    try {
      await ref.read(audioVMProvider.notifier).loadTimings();
      final vmTimings = await ref.read(audioVMProvider.future);
      _timings = vmTimings.where((t) => t.sura == _sura && t.ayah != 999).toList();
      _timings.sort((a, b) => a.time.compareTo(b.time));

      if (_timings.isEmpty) {
        debugPrint('Error: No timings found for Sura $_sura');
        return;
      }

      _startAyah = fromAyah;
      _endAyah = toAyah;
      _currentIndex = _timings.indexWhere((e) => e.ayah >= _startAyah);

      if (_currentIndex == -1) {
        debugPrint('Error: Could not find start Ayah $_startAyah in timings.');
        return;
      }

      final audioPath = await ref.read(audioVMProvider.notifier).getAudioAssetPath(_sura);
      await _player.setFilePath(audioPath);

      // We call our new helper method to start the process
      _seekToAyahIndex(_currentIndex, shouldPlay: true);

      _positionSub?.cancel(); // Cancel any old listener
      _positionSub = _player.positionStream.listen(_onAudioPosition);
      debugPrint('Started playback for Sura $_sura, Ayahs $_startAyah - $_endAyah');
    } catch (e) {
      debugPrint('Error in playAyahs: $e');
      stop();
    }
  }

  void _onAudioPosition(Duration position) {
    if (_currentIndex >= _timings.length - 1) return;
    final currentTimeMs = position.inMilliseconds;
    final nextAyahTiming = _timings[_currentIndex + 1];

    if (currentTimeMs >= nextAyahTiming.time) {
      if (nextAyahTiming.ayah > _endAyah) {
        stop();
        return;
      }
      _currentIndex++;
      ref.read(quranAudioProvider.notifier).updateAyah(nextAyahTiming.ayah);
    }
  }

  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
      ref.read(quranAudioProvider.notifier).pause();
    } else if (ref.read(quranAudioProvider) != null) { // Only resume if there's an active session
      _player.play();
      ref.read(quranAudioProvider.notifier).resume();
    }
  }

  void stop() {
    _player.stop();
    _positionSub?.cancel();
    _positionSub = null;
    ref.read(quranAudioProvider.notifier).stop();
  }

  // --- NEW: Implementation for playNext ---
  void playNext() {
    // Ensure there is an active audio session
    if (ref.read(quranAudioProvider) == null) return;

    // Check if we are already at the last item in the list
    if (_currentIndex >= _timings.length - 1) {
      stop(); // No more ayahs in the surah
      return;
    }

    final nextTiming = _timings[_currentIndex + 1];

    // Check if the next ayah is outside the user's selected range
    if (nextTiming.ayah > _endAyah) {
      stop(); // Reached the end of the selected range
      return;
    }

    // If all checks pass, seek to the next ayah
    _seekToAyahIndex(_currentIndex + 1);
  }

  // --- NEW: Implementation for playPrev ---
  void playPrev() {
    // Ensure there is an active audio session
    if (ref.read(quranAudioProvider) == null) return;

    // Check if we are at the beginning of the list
    if (_currentIndex <= 0) return; // Cannot go back further

    final prevTiming = _timings[_currentIndex - 1];

    // Check if the previous ayah is outside the user's selected range
    if (prevTiming.ayah < _startAyah) {
      return; // Already at the start of the selected range
    }

    // If all checks pass, seek to the previous ayah
    _seekToAyahIndex(_currentIndex - 1);
  }

  // --- NEW: Helper method to handle seeking and state updates ---
  void _seekToAyahIndex(int index, {bool shouldPlay = false}) {
    if (index < 0 || index >= _timings.length) return; // Boundary check

    _currentIndex = index;
    final timing = _timings[index];

    _player.seek(Duration(milliseconds: timing.time));

    // If the player should start/continue playing after seek
    if (shouldPlay || _player.playing) {
      _player.play();
      // Use start() if it's the beginning, otherwise updateAyah()
      if (ref.read(quranAudioProvider) == null) {
        ref.read(quranAudioProvider.notifier).start(_sura, timing.ayah);
      } else {
        ref.read(quranAudioProvider.notifier).updateAyah(timing.ayah);
        ref.read(quranAudioProvider.notifier).resume();
      }
    } else {
      // If paused, just update the highlighted ayah without changing play state
      ref.read(quranAudioProvider.notifier).updateAyah(timing.ayah);
    }
    debugPrint('Seeked to Ayah: ${timing.ayah}');
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