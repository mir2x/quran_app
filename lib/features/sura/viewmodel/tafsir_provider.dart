// file: viewmodel/tafsir_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../downloader/viewmodel/download_providers.dart';
import '../model/tafsir.dart';

// AyahIdentifier class remains the same
class AyahIdentifier {
  final int sura;
  final int ayah;
  AyahIdentifier({required this.sura, required this.ayah});
  @override
  bool operator ==(Object other) => other is AyahIdentifier && other.sura == sura && other.ayah == ayah;
  @override
  int get hashCode => sura.hashCode ^ ayah.hashCode;
}


class TafsirRepository {
  // Source of truth for all available Tafsirs
  final List<Map<String, dynamic>> _availableTafsirsMetadata = [
    {
      'id': 'tafsir_taqi_usmani_bn',
      'title': 'তাফসীর (তাকী উসমানী)',
      'url': 'https://www.dropbox.com/scl/fi/m93j8ayyk32zinfviao1g/tafsir_taqi_usmani_bn.json?rlkey=hrvjuyubm9jatvio2iojyu33j&st=2hmdshcv&dl=1',
      'sizeBytes': 23 * 1024 * 1024, // Approx 23 MB
    },
    {
      'id': 'tafsir_ibn_kathir_bn',
      'title': 'তাফসীরে ইবনে কাছীর',
      'url': 'https://www.dropbox.com/scl/fi/8radxi6rlde38nm52kda4/tafsir_ibn_kathir_bn.json?rlkey=vfow6gnoo120n0he353lmquf1&st=zydxlgth&dl=1',
      'sizeBytes': 145 * 1024 * 1024, // Approx 145 MB
    },
    {
      'id': 'tafsir_maariful_quran_bn',
      'title': 'তাফসীরে মা\'আরিফুল কুরআন',
      'url': 'https://www.dropbox.com/scl/fi/rq8z4o4h59cw3wso1vk0f/tafsir_maariful_quran_bn.json?rlkey=0zlo3h7qnqmkqa874q94xkqwt&st=e7un19yw&dl=1',
      'sizeBytes': 100 * 1024 * 1024, // Approx 100 MB
    },
    // Add the English versions here if needed
  ];

  // Helper to get the consistent local path for a tafsir file
  Future<String> getLocalTafsirPath(String sourceId) async {
    final docDir = await getApplicationDocumentsDirectory();
    return '${docDir.path}/tafsir/$sourceId.json';
  }

  // Fetches the Tafsir text from a LOCAL file
  Future<String?> _getTafsirContentForAyah(String sourceId, int sura, int ayah) async {
    try {
      final localPath = await getLocalTafsirPath(sourceId);
      final file = File(localPath);

      if (!await file.exists()) {
        return null; // File not downloaded, return null
      }

      final jsonString = await file.readAsString();
      final List<dynamic> allTafsirs = jsonDecode(jsonString);

      final tafsirData = allTafsirs.firstWhere(
            (item) => item['sura'] == sura && item['ayah'] == ayah,
        orElse: () => null,
      );

      return tafsirData != null ? tafsirData['tafsir'] : "এই আয়াতের জন্য কোনো তাফসীর পাওয়া যায়নি।";
    } catch (e) {
      print("Error reading local tafsir for $sourceId: $e");
      return "তাফসীর ফাইলটি পড়তে সমস্যা হয়েছে।";
    }
  }

  // Gets the complete state for ALL Tafsirs for a specific Ayah
  Future<List<TafsirSource>> getAllTafsirsForAyah(int sura, int ayah) async {
    final List<Future<TafsirSource>> futureTafsirs = _availableTafsirsMetadata.map((meta) async {
      final id = meta['id'] as String;

      // Check SharedPreferences to see if it's marked as downloaded
      final isDownloaded = await isAssetDownloaded(id);
      String? content;

      if (isDownloaded) {
        // If it's marked as downloaded, try to read the content
        content = await _getTafsirContentForAyah(id, sura, ayah);
      }

      return TafsirSource(
        id: id,
        title: meta['title'] as String,
        url: meta['url'] as String,
        sizeBytes: meta['sizeBytes'] as int,
        isDownloaded: isDownloaded,
        content: content,
      );
    }).toList();

    return await Future.wait(futureTafsirs);
  }
}

final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) => TafsirRepository());

final tafsirProvider = FutureProvider.family<List<TafsirSource>, AyahIdentifier>((ref, ayahIdentifier) {
  final repository = ref.watch(tafsirRepositoryProvider);
  return repository.getAllTafsirsForAyah(ayahIdentifier.sura, ayahIdentifier.ayah);
});