// viewmodel/tafsir_providers.dart
import 'dart:convert';
import 'package:flutter/services.dart';

import '../model/tafsir.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';


// A simple class to pass Sura and Ayah numbers to the provider family
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
  // Define all your available Tafsir sources here
  final List<TafsirSource> _availableTafsirs = [
    TafsirSource(title: 'তাফসীর (মুফতী তাকী উসমানী)', sourceId: 'tafsir_taki_usmani.json'),
    TafsirSource(title: 'তাফসীরে মা\'আরিফুল কুরআন', sourceId: 'tafsir_maariful_quran.json'),
    TafsirSource(title: 'তাফসীরে ইবনে কাছীর', sourceId: 'tafsir_ibn_kathir.json'),
  ];

  // Fetches the Tafsir text for a SINGLE source
  Future<String> _getTafsirContentForAyah(String sourceId, int sura, int ayah) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/tafsir/$sourceId');
      final List<dynamic> allTafsirs = jsonDecode(jsonString);

      final tafsirData = allTafsirs.firstWhere(
            (item) => item['sura'] == sura && item['ayah'] == ayah,
        orElse: () => null,
      );

      return tafsirData != null ? tafsirData['tafsir'] : "এই আয়াতের জন্য কোনো তাফসীর পাওয়া যায়নি।";
    } catch (e) {
      print("Error loading tafsir for $sourceId: $e");
      return "তাফসীর ফাইল লোড করা যায়নি।";
    }
  }

  // Fetches the Tafsir text for ALL defined sources for a specific Ayah
  Future<List<TafsirSource>> getAllTafsirsForAyah(int sura, int ayah) async {
    final List<Future<TafsirSource>> futureTafsirs = _availableTafsirs.map((source) async {
      final content = await _getTafsirContentForAyah(source.sourceId, sura, ayah);
      return TafsirSource(title: source.title, sourceId: source.sourceId, content: content);
    }).toList();

    return await Future.wait(futureTafsirs);
  }
}

// Provider for the Repository
final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) => TafsirRepository());

// Provider.family to fetch the list of Tafsirs for a specific Ayah
final tafsirProvider = FutureProvider.family<List<TafsirSource>, AyahIdentifier>((ref, ayahIdentifier) {
  final repository = ref.watch(tafsirRepositoryProvider);
  return repository.getAllTafsirsForAyah(ayahIdentifier.sura, ayahIdentifier.ayah);
});