import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/ayah.dart';
import '../model/raw_ayah_data.dart';
import '../model/word_by_word.dart';


class QuranDataService {
  List<Ayah>? _allAyahsCache;

  Future<List<RawAyahData>> _loadAndParse(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => RawAyahData.fromJson(json)).toList();
  }

  Future<List<WordByWord>> _loadAndParseWords(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => WordByWord.fromJson(json)).toList();
  }

  Future<List<Ayah>> loadAllAyahs() async {
    if (_allAyahsCache != null) {
      return _allAyahsCache!;
    }

    final sources = {
      'arabic': 'assets/quran/arabic.json',
      'মুফতী তাকী উসমানী': 'assets/quran/bn_taqi.json',
      'মাওলানা মুহিউদ্দিন খান': 'assets/quran/bn_mohiuddin.json',
      'ইসলামিক ফাউন্ডেশন': 'assets/quran/bn_islamic_foundation.json',
      'words': 'assets/quran/word.json',
    };

    // Load all data sources in parallel.
    final allData = await Future.wait([
      _loadAndParse(sources['arabic']!),
      _loadAndParse(sources['মুফতী তাকী উসমানী']!),
      _loadAndParse(sources['মাওলানা মুহিউদ্দিন খান']!),
      _loadAndParse(sources['ইসলামিক ফাউন্ডেশন']!),
      _loadAndParseWords(sources['words']!),
    ]);

    final arabicData = allData[0] as List<RawAyahData>;
    final taqiData = allData[1] as List<RawAyahData>;
    final mohiuddinData = allData[2] as List<RawAyahData>;
    final foundationData = allData[3] as List<RawAyahData>;
    final wordData = allData[4] as List<WordByWord>;

    // Use a map to efficiently merge data by a unique key (sura:ayah)
    final Map<String, Ayah> mergedAyahs = {};

    for (var ayahData in arabicData) {
      final key = '${ayahData.sura}:${ayahData.ayah}';
      mergedAyahs[key] = Ayah(
        sura: ayahData.sura,
        ayah: ayahData.ayah,
        arabicText: ayahData.text,
        translations: [],
        words: [],
      );
    }

    // Helper to add translation
    void addTranslation(List<RawAyahData> data, String translatorName) {
      for (var transData in data) {
        final key = '${transData.sura}:${transData.ayah}';
        if (mergedAyahs.containsKey(key)) {
          mergedAyahs[key]!.translations.add(Translation(
            translatorName: translatorName,
            text: transData.text,
          ));
        }
      }
    }

    addTranslation(taqiData, 'মুফতী তাকী উসমানী');
    addTranslation(mohiuddinData, 'মাওলানা মুহিউদ্দিন খান');
    addTranslation(foundationData, 'ইসলামিক ফাউন্ডেশন');

    // Add words
    for (var word in wordData) {
      final key = '${word.sura}:${word.ayah}';
      if (mergedAyahs.containsKey(key)) {
        mergedAyahs[key]!.words.add(word);
      }
    }

    final result = mergedAyahs.values.toList();
    // Cache the result
    _allAyahsCache = result;
    return result;
  }

  Future<List<Ayah>> loadSuraData(int suraNumber) async {
    final sources = {
      'arabic': 'assets/quran/arabic.json',
      'মুফতী তাকী উসমানী': 'assets/quran/bn_taqi.json',
      'মাওলানা মুহিউদ্দিন খান': 'assets/quran/bn_mohiuddin.json',
      'ইসলামিক ফাউন্ডেশন': 'assets/quran/bn_islamic_foundation.json',
      'words': 'assets/quran/word.json',
    };

    final arabicData = await _loadAndParse(sources['arabic']!);
    final taqiData = await _loadAndParse(sources['মুফতী তাকী উসমানী']!);
    final mohiuddinData = await _loadAndParse(sources['মাওলানা মুহিউদ্দিন খান']!);
    final foundationData = await _loadAndParse(sources['ইসলামিক ফাউন্ডেশন']!);
    final wordData = await _loadAndParseWords(sources['words']!);

    final suraArabic = arabicData.where((a) => a.sura == suraNumber).toList();
    final suraWords = wordData.where((w) => w.sura == suraNumber).toList();

    final Map<int, Ayah> mergedAyahs = {};

    for (var ayahData in suraArabic) {
      mergedAyahs[ayahData.ayah] = Ayah(
        sura: ayahData.sura,
        ayah: ayahData.ayah,
        arabicText: ayahData.text,
        translations: [],
        words: [],
      );
    }

    for (var transData in taqiData.where((t) => t.sura == suraNumber)) {
      if (mergedAyahs.containsKey(transData.ayah)) {
        mergedAyahs[transData.ayah]!.translations.add(Translation(
          translatorName: 'মুফতী তাকী উসমানী',
          text: transData.text,
        ));
      }
    }

    for (var transData in mohiuddinData.where((t) => t.sura == suraNumber)) {
      if (mergedAyahs.containsKey(transData.ayah)) {
        mergedAyahs[transData.ayah]!.translations.add(Translation(
          translatorName: 'মাওলানা মুহিউদ্দিন খান',
          text: transData.text,
        ));
      }
    }

    for (var transData in foundationData.where((t) => t.sura == suraNumber)) {
      if (mergedAyahs.containsKey(transData.ayah)) {
        mergedAyahs[transData.ayah]!.translations.add(Translation(
          translatorName: 'ইসলামিক ফাউন্ডেশন',
          text: transData.text,
        ));
      }
    }

    for (var word in suraWords) {
      if (mergedAyahs.containsKey(word.ayah)) {
        mergedAyahs[word.ayah]!.words.add(word);
      }
    }

    final result = mergedAyahs.values.toList();
    result.sort((a, b) => a.ayah.compareTo(b.ayah));
    return result;
  }
}


final suraProvider = FutureProvider.family<List<Ayah>, int>((ref, suraNumber) async {
  final dataService = QuranDataService();
  return dataService.loadSuraData(suraNumber);
});

//
// final selectedTranslatorsProvider = StateProvider<List<String>>((ref) => [
//   'মুফতী তাকী উসমানী',
// ]);

final selectedTranslatorsProvider = StateProvider<List<String>>((ref) => []);

final showTranslationsProvider = StateProvider<bool>((ref) => true);
final showWordByWordProvider = StateProvider<bool>((ref) => false);

final isAutoScrollingProvider = StateProvider<bool>((ref) => false);
final scrollSpeedFactorProvider = StateProvider<double>((ref) => 1.0);
final isAutoScrollPausedProvider = StateProvider<bool>((ref) => false);




