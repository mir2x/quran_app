import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/fileChecker.dart';
import '../../quran/model/audio_state.dart';
import '../../quran/model/ayah_timing.dart';
import '../../quran/model/reciter_asset.dart';

final Map<String, String> reciters = {
  'মাহের আল মুয়াইক্বিলি': 'maher_muaiqly',
  'সৌদ আল-শুরাইম': 'saud_shuraim',
  'আলী জাবের': 'ali_jaber',
  'আব্দুল মুনিম আব্দুল মুবদি': 'abdul_munim_mubdi',
};

final selectedReciterProvider = StateProvider<String>((_) => reciters.values.first);

final reciterCatalogueProvider = Provider<List<ReciterAsset>>((_) => const [
  ReciterAsset(
    id: 'maher_muaiqly',
    name: 'মাহের আল মুয়াইক্বিলি',
    zipUrl: 'https://ntgkoryrbfyhcbqfnsbx.supabase.co/storage/v1/object/public/assets/audio/maher_muaiqly.zip',
    sizeBytes: 51097600,
  ),
  ReciterAsset(
    id: 'ali_jaber',
    name: 'আলী জাবের',
    zipUrl: 'https://example.com/assets/ali_jaber.zip',
    sizeBytes: 10000000,
  ),
]);

final audioVMProvider = AsyncNotifierProvider<AudioVM, List<AyahTiming>>(AudioVM.new);

class AudioVM extends AsyncNotifier<List<AyahTiming>> {
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

  // New method to set the current sura
  void setCurrentSura(int sura) {
    _sura = sura;
    debugPrint('Audio Service: Sura set to $_sura');
  }

  Future<void> playAyahs(int fromAyah, int toAyah) async {
    // Stop any previous playback
    stop();

    try {
      // Fetch timings for the current sura
      final vmTimings = await ref.read(audioVMProvider.future);
      _timings = vmTimings.where((t) => t.sura == _sura && t.ayah != 999).toList();
      _timings.sort((a, b) => a.time.compareTo(b.time));

      if (_timings.isEmpty) {
        debugPrint('Error: No timings found for Sura $_sura');
        return;
      }

      _startAyah = fromAyah;
      _endAyah = toAyah;

      // Find the index of the first ayah to play
      _currentIndex = _timings.indexWhere((e) => e.ayah >= _startAyah);
      if (_currentIndex == -1) {
        debugPrint('Error: Could not find start Ayah $_startAyah in timings.');
        return;
      }

      // Get audio file path
      final audioPath = await ref.read(audioVMProvider.notifier).getAudioAssetPath(_sura);
      await _player.setFilePath(audioPath);

      // Seek to the start time of the first ayah
      final startTime = _timings[_currentIndex].time;
      await _player.seek(Duration(milliseconds: startTime));

      // Start playing
      _player.play();

      // Update the UI state
      final currentAyahNumber = _timings[_currentIndex].ayah;
      ref.read(quranAudioProvider.notifier).start(_sura, currentAyahNumber);

      // Listen to position updates to advance to the next ayah
      _positionSub = _player.positionStream.listen(_onAudioPosition);
      debugPrint('Started playback for Sura $_sura, Ayahs $_startAyah - $_endAyah');

    } catch (e) {
      debugPrint('Error in playAyahs: $e');
      stop();
    }
  }

  void _onAudioPosition(Duration position) {
    if (_currentIndex >= _timings.length -1) return;

    final currentTimeMs = position.inMilliseconds;
    final nextAyahTiming = _timings[_currentIndex + 1];

    // Check if we have passed the start time of the next ayah
    if (currentTimeMs >= nextAyahTiming.time) {
      // Check if the next ayah is within the selected range
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
    } else {
      _player.play();
      ref.read(quranAudioProvider.notifier).resume();
    }
  }

  void stop() {
    _player.stop();
    _positionSub?.cancel();
    ref.read(quranAudioProvider.notifier).stop();
  }

  // Placeholder implementations for Next/Prev
  void playNext() {
    // This requires more complex logic to find the next valid index
    debugPrint('Play Next: Not yet implemented');
  }

  void playPrev() {
    // This requires more complex logic to find the previous valid index
    debugPrint('Play Previous: Not yet implemented');
  }
}



final audioPlayerServiceProvider = Provider<AudioControllerService>((ref) {
  final service = AudioControllerService(ref);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

