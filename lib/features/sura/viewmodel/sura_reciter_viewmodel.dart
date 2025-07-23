import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/fileChecker.dart';
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